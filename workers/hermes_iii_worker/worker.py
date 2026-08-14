"""
Main iii worker — WebSocket connection, protocol dispatch, function routing.

Connects to the iii engine at III_WS_URL (default ws://127.0.0.1:49134),
registers all Hermes functions, and dispatches incoming invocations to the
appropriate handler.

Handles:
- Connection lifecycle (connect → register → listen → reconnect on failure)
- Function dispatch to handlers/* modules
- iii-state calls for task management (tasks::* functions)
- Heartbeat / ping
- Agent session pruning
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import signal
import sys
import time
import uuid
from typing import Any, Callable

import websockets
from websockets.asyncio.client import connect as ws_connect

from workers.hermes_iii_worker.iii_protocol import (
    invocation_result,
    register_function,
    register_worker_metadata,
    register_http_trigger,
)
from workers.hermes_iii_worker.handlers import (
    handle_ping,
    handle_capabilities,
    handle_ask,
    handle_chat,
    handle_research,
    handle_delegate,
    handle_chat_streaming,
)
from workers.hermes_iii_worker.handlers.tasks import TASKS_DISPATCH, PENDING_INVOCATIONS
from workers.hermes_iii_worker.agent_runner import prune_idle_sessions

log = logging.getLogger("iii-hermes")

# ── Cross-worker invocation state ──────────────────────────────────────
# PENDING_INVOCATIONS lives in handlers/tasks.py (used by tasks:: functions).
# We alias it here so worker.py and handlers can both access it.
PENDING_INVOCATIONS = PENDING_INVOCATIONS

# ── Function Registry ───────────────────────────────────────────────────

FUNCTIONS: list[dict[str, Any]] = [
    {
        "id": "hermes::ping",
        "description": "Health check — returns status, uptime, model, and worker version",
        "handler": handle_ping,
    },
    {
        "id": "hermes::capabilities",
        "description": "List all registered functions with their schemas",
        "handler": handle_capabilities,
    },
    {
        "id": "hermes::ask",
        "description": "Prompt the LLM and get a response. Stateless by default (no tools). "
                       "Supports: prompt (required), system, user_id, session_id (for multi-turn), "
                       "tools (bool — enable Hermes tool calling)",
        "handler": handle_ask,
    },
    {
        "id": "hermes::chat",
        "description": "Full conversational agent — system prompt, tools, memory, skills. "
                       "Same capabilities as a Hermes CLI session. Supports: prompt (required), "
                       "system, session_id (auto-generated if omitted), user_id",
        "handler": handle_chat,
    },
    {
        "id": "hermes::chat-streaming",
        "description": "Streaming conversational agent — emits intermediate messages to "
                       "telegram::send-message (or another registered callback) as each "
                       "sentence/thought completes. Returns final InvocationResult with "
                       "the complete response. "
                       "Supports: prompt, chat_id (required for per-sentence delivery), "
                       "session_id, system, user_id",
        "handler": handle_chat_streaming,
    },
    {
        "id": "hermes::front",
        "description": "Alias for hermes::chat — full front-facing agent with all capabilities",
        "handler": handle_chat,
    },
    {
        "id": "hermes::research",
        "description": "Multi-perspective research on a topic. "
                       "Supports: topic (required), depth (quick|standard|deep), focus_areas (list)",
        "handler": handle_research,
    },
    {
        "id": "hermes::delegate",
        "description": "Delegate parallel subtasks to worker agents. "
                       "Supports: goal, subtasks (list of goal/context pairs), system",
        "handler": handle_delegate,
    },
]

# Add tasks::* functions
for fn_id, fn_handler in TASKS_DISPATCH.items():
    descriptions = {
        "tasks::create": "Create a new task in iii-state",
        "tasks::list": "List/filter tasks from iii-state",
        "tasks::get": "Get a task by ID from iii-state",
        "tasks::update": "Update a task in iii-state",
        "tasks::delete": "Soft-delete a task (marks as cancelled)",
        "tasks::backlog": "Compact open-task summary for session context",
        "tasks::append-note": "Append a note/workpad entry to a task",
        "tasks::get-workpad": "Read the full workpad for a task",
        "tasks::check-overdue": "Daily maintenance — check for overdue tasks",
    }
    FUNCTIONS.append({
        "id": fn_id,
        "description": descriptions.get(fn_id, fn_id.replace("::", " ").replace("-", " ").title()),
        "handler": fn_handler,
    })

# Build dispatch map
_handler_map: dict[str, Callable] = {fn["id"]: fn["handler"] for fn in FUNCTIONS}
_worker_start = time.time()


# ── Invocation dispatch ────────────────────────────────────────────────

async def handle_invocation(
    ws: websockets.WebSocketClientProtocol,
    function_id: str,
    data: dict,
    invocation_id: str,
) -> None:
    """Dispatch a single function invocation and send the result back."""
    t0 = time.time()
    result: dict | None = None
    error: str | None = None

    try:
        handler = _handler_map.get(function_id)
        if handler is None:
            error = f"function not found: {function_id}"
            log.warning("unknown function: %s", function_id)
        else:
            if function_id.startswith("tasks::"):
                result = await handler(ws, data)
            elif function_id in ("hermes::capabilities",):
                result = handler(FUNCTIONS)
            elif function_id == "hermes::ping":
                result = handler(data)
            else:
                result = await handler(ws, data)

            if result is None:
                result = {"status": "ok"}
    except Exception as e:
        error = str(e)
        log.exception("error handling %s: %s", function_id, e)

    elapsed = time.time() - t0
    await ws.send(invocation_result(invocation_id, function_id, result, error))
    log.info(
        "result[%s] %s %s (%.2fs)",
        invocation_id[:8],
        function_id,
        "error" if error else "success",
        elapsed,
    )


# ── Event loop access for thread-safe scheduling ───────────────────────

_worker_event_loop: asyncio.AbstractEventLoop | None = None


def get_worker_loop() -> asyncio.AbstractEventLoop | None:
    return _worker_event_loop


# ── iii_call helper (for cross-worker invocations from handlers) ────────

async def iii_call(
    ws: websockets.WebSocketClientProtocol,
    function_id: str,
    data: dict | None = None,
    *,
    pending: dict | None = None,
    timeout: int = 120,
) -> dict:
    """Invoke a function on the iii engine and wait for the result.

    Used by handlers that need to call other registered functions (e.g.
    telegram::send-message). The ``pending`` dict defaults to the worker's
    PENDING_INVOCATIONS dict which is populated by the message listener loop.
    """
    inv_id = str(uuid.uuid4())
    future = asyncio.get_running_loop().create_future()
    pending = pending or PENDING_INVOCATIONS
    pending[inv_id] = future
    try:
        await ws.send(json.dumps({
            "type": "invokefunction",
            "function_id": function_id,
            "invocation_id": inv_id,
            "data": data or {},
        }))
        result = await asyncio.wait_for(future, timeout=timeout)
        return result if isinstance(result, dict) else {"response": str(result)}
    except asyncio.TimeoutError:
        return {"error": f"timed out waiting for {function_id}"}
    except Exception as e:
        return {"error": str(e)}
    finally:
        pending.pop(inv_id, None)


# ── Message handler ────────────────────────────────────────────────────

async def _handle_message(ws: websockets.WebSocketClientProtocol, raw: str) -> None:
    """Process a single WebSocket message from the main connection."""
    try:
        msg = json.loads(raw)
    except json.JSONDecodeError:
        log.warning("invalid JSON from engine: %.200s", raw)
        return

    msg_type = msg.get("type", "")

    if msg_type == "invokefunction":
        function_id = msg.get("function_id", "")
        invocation_id = msg.get("invocation_id", "")
        if not invocation_id:
            log.warning("invokefunction missing invocation_id for %s", function_id)
            return

        data = msg.get("data", {}) or {}

        # Normalize HTTP envelope — engine wraps body
        if "body" in data and "path" in data:
            data = data.get("body", {}) or {}

        asyncio.create_task(handle_invocation(ws, function_id, data, invocation_id))

    elif msg_type == "invocationresult":
        inv_id = msg.get("invocation_id", "")
        if inv_id in PENDING_INVOCATIONS:
            future = PENDING_INVOCATIONS.pop(inv_id, None)
            if future and not future.done():
                if msg.get("error"):
                    future.set_exception(Exception(msg["error"]))
                else:
                    future.set_result(msg.get("result"))

    elif msg_type == "workerregistered":
        worker_id = msg.get("worker_id", "?")
        log.info("registered as worker %s", worker_id)

    elif msg_type == "error":
        log.error("engine error: %s", msg)

    else:
        log.debug("unhandled message type: %s", msg_type)


# ── Main worker loop ───────────────────────────────────────────────────

async def worker_loop() -> None:
    """Main worker loop — connect, register, listen, reconnect on failure."""
    ws_url = os.environ.get("III_WS_URL", "ws://127.0.0.1:49134")
    log.info("hermes-iii-worker v2 starting — connecting to iii at %s", ws_url)

    global _worker_event_loop
    _worker_event_loop = asyncio.get_running_loop()

    prune_interval = 300

    while True:
        try:
            async with ws_connect(ws_url, ping_interval=30) as ws:
                log.info("connected to iii engine")

                # Register all functions
                for fn in FUNCTIONS:
                    msg = register_function(
                        fn["id"],
                        fn["description"],
                        fn.get("request_format"),
                        fn.get("response_format"),
                    )
                    await ws.send(msg)
                log.info("registered %d functions", len(FUNCTIONS))

                # Register worker metadata
                await ws.send(register_worker_metadata())

                # Register HTTP triggers for key functions
                http_triggers = [
                    ("hermes::ask", "POST", "/hermes/ask"),
                    ("hermes::chat", "POST", "/hermes/chat"),
                    ("hermes::chat-streaming", "POST", "/hermes/chat-streaming"),
                    ("hermes::research", "POST", "/hermes/research"),
                    ("hermes::ping", "GET", "/hermes/ping"),
                ]
                for fn_id, method, path in http_triggers:
                    await ws.send(register_http_trigger(fn_id, method, path))
                log.info("registered HTTP triggers")

                # Listen loop
                last_prune = time.time()
                async for raw in ws:
                    await _handle_message(ws, raw)

                    now = time.time()
                    if now - last_prune > prune_interval:
                        prune_idle_sessions()
                        last_prune = now

        except websockets.ConnectionClosed:
            log.warning("connection closed — reconnecting in 5s")
        except Exception as e:
            log.exception("connection error: %s — reconnecting in 10s", e)

        await asyncio.sleep(5)


# ── Entry Point ─────────────────────────────────────────────────────────

def main() -> None:
    """Entry point for the hermes-iii-worker."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [iii-hermes] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    log.info("starting hermes-iii-worker v2 (callback-based streaming)")
    asyncio.run(worker_loop())


if __name__ == "__main__":
    main()
