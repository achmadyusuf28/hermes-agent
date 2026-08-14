"""
Handler functions for hermes-iii-worker — chat, ask, ping, capabilities.
"""
from __future__ import annotations

import asyncio
import json
import logging
import time
import uuid
from typing import Any

from workers.hermes_iii_worker.agent_runner import run_oneshot, run_session, run_session_streaming
from workers.hermes_iii_worker.config import MANIFEST_MODEL

log = logging.getLogger(__name__)
_WORKER_START = time.time()


def handle_ping(_data: dict) -> dict:
    """Return health check info."""
    return {
        "status": "ok",
        "uptime_seconds": int(time.time() - _WORKER_START),
        "model": MANIFEST_MODEL or "auto",
        "timestamp": _iso_now(),
        "version": "2.0.0",
        "description": "Hermes agent — full system prompt, tools, memory, skills",
    }


def handle_capabilities(functions: list[dict]) -> dict:
    """Return the full function registry."""
    return {
        "worker": "hermes-agent",
        "functions": functions,
    }


async def handle_ask(ws, data: dict) -> dict:
    """hermes::ask — stateless Q&A (fast path, no tools by default)."""
    prompt = (data.get("prompt") or "").strip()
    if not prompt:
        return {"error": "prompt is required"}

    system = data.get("system")
    use_tools = _to_bool(data.get("tools", False))
    user_id = str(data.get("user_id", "")).strip()
    session_id = str(data.get("session_id", "")).strip()

    if session_id:
        # Multi-turn — use agent session
        result = run_session(
            prompt=prompt,
            session_id=session_id,
            user_id=user_id or None,
            system=system,
            use_tools=use_tools,
        )
    else:
        # Stateless — use oneshot
        result = run_oneshot(
            prompt=prompt,
            system=system,
            use_tools=use_tools,
        )

    return result


async def handle_chat(ws, data: dict) -> dict:
    """hermes::chat — full conversational agent with tools, memory, skills.

    Same as hermes::ask but always runs with full tools enabled and creates
    a proper AIAgent session. Intended for worker-to-agent interaction where
    the caller wants the complete Hermes experience.
    """
    prompt = (data.get("prompt") or "").strip()
    if not prompt:
        return {"error": "prompt is required"}

    system = data.get("system")
    session_id = str(data.get("session_id", "")).strip() or _random_id("chat")
    user_id = str(data.get("user_id", "")).strip()

    result = run_session(
        prompt=prompt,
        session_id=session_id,
        user_id=user_id or None,
        system=system,
        use_tools=True,
    )

    # Include the session_id so the caller can continue the conversation
    result["session_id"] = session_id
    return result


async def handle_research(ws, data: dict) -> dict:
    """hermes::research — multi-perspective research synthesis.

    Ported from the original hermes-worker.py. Runs multiple LLM calls from
    different perspectives then synthesizes into a coherent analysis.
    """
    topic = (data.get("topic") or "").strip()
    if not topic:
        return {"error": "topic is required"}

    depth = data.get("depth", "standard")
    focus_areas = data.get("focus_areas", []) or []
    num_perspectives = {"quick": 1, "standard": 3, "deep": 5}.get(depth, 3)

    # We use run_oneshot with tools=false for the research calls (no tool
    # overhead needed), then a final synthesis call.
    research_system = (
        "You are a thorough research analyst. Provide well-structured, "
        "evidence-based analysis. Be specific and avoid vague generalities."
    )

    perspectives: list[dict] = []
    for i in range(num_perspectives):
        perspective_prompt = f"Research perspective {i + 1}/{num_perspectives} on: {topic}\n\n"
        if focus_areas:
            area = focus_areas[i % len(focus_areas)]
            perspective_prompt += f"Focus specifically on: {area}\n\n"
        perspective_prompt += (
            "Provide a thorough, well-reasoned analysis from this perspective. "
            "Include specific details, examples, and evidence. "
            "Be critical and consider counterarguments."
        )

        result = run_oneshot(
            prompt=perspective_prompt,
            system=research_system,
        )
        perspectives.append({
            "perspective": i + 1,
            "content": result.get("response", ""),
        })

    # Synthesize
    synthesis_prompt = (
        f"Synthesize the following {num_perspectives} research perspectives "
        f"on: {topic}\n\n"
    )
    for p in perspectives:
        synthesis_prompt += f"--- Perspective {p['perspective']} ---\n{p['content']}\n\n"
    synthesis_prompt += (
        "Provide a coherent synthesis that highlights key insights, "
        "areas of agreement and disagreement, and actionable conclusions."
    )

    synthesis = run_oneshot(
        prompt=synthesis_prompt,
        system="You are a research synthesis expert. Distill multiple perspectives "
               "into a coherent, actionable analysis.",
    )

    return {
        "topic": topic,
        "depth": depth,
        "num_perspectives": num_perspectives,
        "perspectives": perspectives,
        "synthesis": synthesis.get("response", ""),
        "model": synthesis.get("model", ""),
    }


async def handle_delegate(ws, data: dict) -> dict:
    """hermes::delegate — spawn parallel subtask workers.

    Accepts a list of subtasks, runs each through run_oneshot in parallel
    (or sequentially if only one), and returns aggregated results.
    """
    goal = str(data.get("goal", "")).strip()
    subtasks = data.get("subtasks", [])
    if not subtasks:
        # Single task mode
        if not goal:
            return {"error": "goal or subtasks required"}
        result = run_oneshot(prompt=goal, system=data.get("system"))
        return {"results": [{"goal": goal, "response": result.get("response", "")}], "total": 1}

    # Multi-task mode — run sequentially to avoid overwhelming the LLM proxy
    results: list[dict] = []
    for task in subtasks:
        task_goal = str(task.get("goal", task) if isinstance(task, dict) else task)
        task_context = str(task.get("context", "")) if isinstance(task, dict) else ""
        system = data.get("system", "")
        if task_context:
            system = f"{system}\n\nContext for this subtask:\n{task_context}".strip()
        result = run_oneshot(prompt=task_goal, system=system or None)
        results.append({"goal": task_goal, "response": result.get("response", "")})

    return {"results": results, "total": len(results)}


async def handle_chat_streaming(ws, data: dict) -> dict:
    """hermes::chat-streaming — conversational agent with live per-sentence output.

    Runs the full Hermes AIAgent with streaming enabled. Each completed
    sentence/thought is delivered to the caller's chat via a cross-worker
    ``telegram::send-message`` invocation. This gives the illusion of
    natural multi-message conversation (like a live Telegram chat).

    Requires ``chat_id`` in the invocation data (passed by the telegram-relay
    or any front-end worker that registered a message callback).

    Returns:
        {
            "response": full_text,        # Complete response
            "session_id": "...",           # For multi-turn
            "messages_count": N,           # Total sentences delivered
            "model": "...",
        }
    """
    prompt = (data.get("prompt") or "").strip()
    if not prompt:
        return {"error": "prompt is required"}

    chat_id = data.get("chat_id")
    if not chat_id:
        return {"error": "chat_id is required for streaming delivery"}

    system = data.get("system")
    session_id = str(data.get("session_id", "")).strip() or _random_id("chat")
    user_id = str(data.get("user_id", "")).strip()

    from workers.hermes_iii_worker.handlers.tasks import PENDING_INVOCATIONS
    from workers.hermes_iii_worker.sentence_buffer import TurnBuffer

    async def _send_message(text: str) -> dict:
        """Send one message chunk via cross-worker invocation."""
        inv_id = str(uuid.uuid4())
        future = asyncio.get_running_loop().create_future()
        PENDING_INVOCATIONS[inv_id] = future
        try:
            await ws.send(json.dumps({
                "type": "invokefunction",
                "function_id": "telegram::send-message",
                "invocation_id": inv_id,
                "data": {
                    "chat_id": chat_id,
                    "text": text,
                    "parse_mode": "Markdown",
                },
            }))
            return await asyncio.wait_for(future, timeout=30)
        except asyncio.TimeoutError:
            return {"error": "timeout"}
        except Exception as e:
            return {"error": str(e)}
        finally:
            PENDING_INVOCATIONS.pop(inv_id, None)

    loop = asyncio.get_running_loop()
    msg_count = 0

    # TurnBuffer groups sentences into conversational turns
    turn_buffer = TurnBuffer(max_sentences=2)

    # Run the streaming agent in an executor (non-blocking for the async loop)
    def on_sentence(text: str, seq: int) -> None:
        """Called from executor thread for each completed thought.

        Feeds the TurnBuffer, which accumulates sentences and emits
        them as conversational turns (fewer, richer messages instead
        of a machine-gun burst).
        """
        nonlocal msg_count
        turn_buffer.accumulate(text, seq)

    def _flush_turn_buffer() -> None:
        """Flush any remaining buffered turn (call after executor completes)."""
        remaining = turn_buffer.flush()

    def _deliver_turn(combined: str, turn_num: int) -> None:
        """Deliver an accumulated turn to the user's chat."""
        nonlocal msg_count
        msg_count += 1
        try:
            asyncio.run_coroutine_threadsafe(
                _send_message(combined), loop
            ).result(timeout=35)
        except Exception as exc:
            log.warning("turn delivery failed (#%d): %s", msg_count, exc)

    turn_buffer.on_turn = _deliver_turn

    def on_tool_start(tool_name: str) -> None:
        """Called when a tool call begins — send a status message."""
        nonlocal msg_count
        msg_count += 1
        try:
            asyncio.run_coroutine_threadsafe(
                _send_message(f"Let me check that using **{tool_name}**..."),
                loop,
            ).result(timeout=35)
        except Exception:
            pass

    result = await loop.run_in_executor(
        None,
        lambda: run_session_streaming(
            prompt=prompt,
            session_id=session_id,
            on_sentence=on_sentence,
            on_tool_start=on_tool_start,
            user_id=user_id or None,
            system=system,
        ),
    )

    # Flush any remaining turn the agent generated but didn't complete
    turn_buffer.flush()

    return {
        "response": result.get("response", ""),
        "tokens": result.get("tokens", {}),
        "model": result.get("model", ""),
        "session_id": session_id,
        "messages_count": msg_count,
    }


# ── Helpers ──────────────────────────────────────────────────────────────

def _to_bool(val: Any) -> bool:
    if isinstance(val, bool):
        return val
    if isinstance(val, str):
        return val.lower() in ("true", "1", "yes")
    return bool(val)


def _random_id(prefix: str = "") -> str:
    import uuid
    return f"{prefix}_{uuid.uuid4().hex[:12]}"


def _iso_now() -> str:
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()
