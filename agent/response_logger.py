"""
Per-turn response logging to JSONL.

Appends one JSONL line per completed conversation turn to:
  ~/.hermes/logs/responses/YYYY-MM-DD.jsonl

Fields logged:
  - timestamp, session_id
  - user_message (truncated to 500 chars)
  - final_response (truncated to 500 chars)
  - tool_call_count (number of tool calls made by the model)
  - api_calls (API round-trips)
  - response_length (chars)
  - has_follow_up (whether the response ends with a question mark)

No PII is intentionally collected. User message is truncated and the
log is purely for post-hoc analysis — response length trends, tool call
patterns, follow-up frequency.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


def _log_dir() -> Path:
    """Return the responses log directory, creating it if needed."""
    from hermes_constants import get_hermes_home
    path = get_hermes_home() / "logs" / "responses"
    path.mkdir(parents=True, exist_ok=True)
    return path


def log_turn(
    agent: Any,
    user_message: str,
    result: Dict[str, Any],
) -> None:
    """Log one conversation turn to today's JSONL file.

    Args:
        agent: The AIAgent instance (accessed for session_id, etc.)
        user_message: The raw user message string
        result: The result dict from run_conversation (must contain
                'final_response', 'api_calls', etc.)
    """
    try:
        final_response = result.get("final_response") or ""
        api_calls = result.get("api_calls", 0)
        completed = result.get("completed", True)
        partial = result.get("partial", False)

        # Count tool calls from the response's messages/trajectory
        messages = result.get("messages", [])
        tool_call_count = sum(
            1 for m in messages
            if isinstance(m, dict) and m.get("tool_calls")
        )

        entry = {
            "timestamp": datetime.now().isoformat(),
            "session_id": getattr(agent, "session_id", ""),
            "user_message": user_message[:500],
            "final_response": final_response[:500],
            "response_length": len(final_response),
            "tool_call_count": tool_call_count,
            "api_calls": api_calls,
            "has_follow_up": final_response.strip().endswith("?"),
            "completed": completed,
            "partial": partial,
        }

        log_path = _log_dir() / f"{datetime.now().strftime('%Y-%m-%d')}.jsonl"
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:
        logger.warning("Failed to log turn (non-fatal)", exc_info=True)
