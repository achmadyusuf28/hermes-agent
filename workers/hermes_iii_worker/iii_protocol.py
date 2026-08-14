"""
iii WebSocket protocol helpers — v0.20.0 message types.

Minimal helpers for building and parsing iii engine protocol frames.
"""
from __future__ import annotations

import json
import uuid
from typing import Any


def register_function(
    function_id: str,
    description: str,
    request_format: dict | None = None,
    response_format: dict | None = None,
) -> str:
    """Build a RegisterFunction frame."""
    msg: dict[str, Any] = {
        "type": "registerfunction",
        "id": function_id,
        "description": description,
    }
    if request_format:
        msg["request_format"] = request_format
    if response_format:
        msg["response_format"] = response_format
    return json.dumps(msg)


def register_worker_metadata(
    name: str = "hermes-agent",
    description: str = "Conversational AI agent with full Hermes capability (tools, memory, skills)",
    version: str = "0.20.0",
) -> str:
    """Build a fire-and-forget invokefunction to register worker metadata."""
    return json.dumps({
        "type": "invokefunction",
        "function_id": "engine::workers::register",
        "invocation_id": str(uuid.uuid4()),
        "data": {
            "runtime": "python",
            "version": version,
            "name": name,
            "description": description,
            "os": _os_str(),
            "pid": os_getpid(),
            "isolation": None,
            "telemetry": {
                "language": "python",
                "framework": "hermes-agent",
                "project_name": "hermes-iii-worker",
            },
        },
        "action": {"type": "void"},
    })


def invocation_result(
    invocation_id: str,
    function_id: str,
    result: dict | None = None,
    error: str | None = None,
) -> str:
    """Build an InvocationResult frame.

    For HTTP-triggered invocations, the engine v0.20.0 extracts the result
    directly, so we pass it as the ``body`` key alongside ``result``.
    """
    msg: dict[str, Any] = {
        "type": "invocationresult",
        "invocation_id": invocation_id,
        "function_id": function_id,
    }
    if error:
        msg["error"] = error
        msg["result"] = {"error": error}
        msg["body"] = json.dumps({"error": error})
    else:
        clean = result or {}
        msg["result"] = clean
        msg["body"] = json.dumps(clean)
        msg["statusCode"] = 200
    return json.dumps(msg)


def invoke_function(
    function_id: str,
    data: dict | None = None,
    action: dict | None = None,
    timeout: int = 60,
) -> tuple[str, str]:
    """Build an invokefunction frame and return a (frame, inv_id) pair.

    The caller should register the pending future so the message loop can
    resolve it when the invocationresult comes back.
    """
    inv_id = str(uuid.uuid4())
    msg = {
        "type": "invokefunction",
        "function_id": function_id,
        "invocation_id": inv_id,
        "data": data or {},
    }
    if action:
        msg["action"] = action
    return json.dumps(msg), inv_id


def register_http_trigger(
    function_id: str,
    http_method: str = "POST",
    api_path: str = "",
) -> str:
    """Build a RegisterTrigger frame for an HTTP endpoint.

    The iii engine v0.20.0 expects ``api_path`` and ``http_method``
    (not ``path`` / ``method``).
    """
    return json.dumps({
        "type": "registertrigger",
        "id": f"{function_id}@http",
        "trigger_type": "http",
        "function_id": function_id,
        "config": {
            "http_method": http_method,
            "api_path": api_path or f"/{function_id.replace('::', '/')}",
        },
    })


def register_cron_trigger(
    trigger_id: str,
    function_id: str,
    schedule: str,
    data: dict | None = None,
) -> str:
    """Build a RegisterTrigger frame for a cron schedule."""
    return json.dumps({
        "type": "registertrigger",
        "id": trigger_id,
        "trigger_type": "cron",
        "function_id": function_id,
        "config": {
            "schedule": schedule,
            "data": data or {},
        },
    })


# ── Helpers ──────────────────────────────────────────────────────────────

def _os_str() -> str:
    import platform
    return f"{platform.system()} {platform.release()} ({platform.machine()})"


def os_getpid() -> int:
    import os
    return os.getpid()
