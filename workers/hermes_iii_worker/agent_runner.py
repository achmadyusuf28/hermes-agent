"""
Agent runner — wraps Hermes AIAgent lifecycle for iii worker invocations.

Each call to ``run_session()`` or ``run_oneshot()`` creates a proper AIAgent
instance using the same initialization path as the CLI's oneshot mode, then
calls ``run_conversation()`` and returns the response.

For multi-turn sessions (``run_session`` with a session_id), the AIAgent is
cached in a dict so subsequent calls reuse the same agent (with session
history intact). Agents are pruned after a configurable idle timeout.
"""
from __future__ import annotations

import logging
import os
import threading
import time
from typing import Any, Callable

log = logging.getLogger(__name__)

# ── Session store — one AIAgent per session_id ──────────────────────────
# Guarded by _sessions_lock for thread safety.
_session_lock = threading.Lock()
_sessions: dict[str, _SessionEntry] = {}
_SESSION_TTL = 3600  # seconds — agents idle longer get pruned


class _SessionEntry:
    """Holds a cached AIAgent + its last-used timestamp."""

    __slots__ = ("agent", "last_used")

    def __init__(self, agent: Any) -> None:
        self.agent = agent
        self.last_used = time.time()


def _build_agent(
    enabled_toolsets: list[str] | None = None,
    quiet: bool = True,
    platform: str = "iii",
    skip_memory: bool = False,
    use_tools: bool = True,
) -> Any:
    """Create an AIAgent configured like the Hermes CLI oneshot mode.

    This is the same initialization path as ``hermes_cli/oneshot.py`` —
    reads the user's config.yaml, resolves the model/provider, and builds
    a fully functional agent with the Hermes system prompt, tools, and
    settings.
    """
    from run_agent import AIAgent
    from hermes_cli.config import load_config
    from hermes_cli.runtime_provider import resolve_runtime_provider
    from hermes_cli.tools_config import _get_platform_tools
    from hermes_cli.fallback_config import get_fallback_chain
    from hermes_state import SessionDB

    cfg = load_config()

    # Resolve model from config
    model_cfg = cfg.get("model") or {}
    if isinstance(model_cfg, str):
        effective_model = model_cfg
    else:
        effective_model = model_cfg.get("default") or model_cfg.get("model") or ""

    # Resolve provider
    runtime = resolve_runtime_provider(
        requested=None,
        target_model=effective_model or None,
    )

    # Resolve toolsets
    if enabled_toolsets is not None:
        toolsets_list = enabled_toolsets
    else:
        toolsets_list = sorted(_get_platform_tools(cfg, platform))

    # Session DB for recall support
    session_db: Any = None
    try:
        session_db = SessionDB()
    except Exception as exc:
        log.debug("SessionDB not available: %s", exc)

    # Fallback chain
    fallback = get_fallback_chain(cfg) or None

    agent = AIAgent(
        api_key=runtime.get("api_key"),
        base_url=runtime.get("base_url"),
        provider=runtime.get("provider"),
        api_mode=runtime.get("api_mode"),
        model=effective_model,
        enabled_toolsets=toolsets_list if use_tools else [],
        quiet_mode=quiet,
        platform=platform,
        session_db=session_db,
        credential_pool=runtime.get("credential_pool"),
        fallback_model=fallback,
        skip_memory=skip_memory,
    )

    # Suppress streaming chatter — the iii worker has no terminal
    agent.suppress_status_output = True
    agent.stream_delta_callback = None
    agent.tool_gen_callback = None

    return agent


def run_oneshot(
    prompt: str,
    system: str | None = None,
    temperature: float | None = None,
    use_tools: bool = False,
) -> dict[str, Any]:
    """Run a single, stateless agent turn and return the response.

    No session persistence, no memory. Fast path for simple Q&A from other
    workers.
    """
    # YOLO mode + accept hooks for non-interactive operation
    os.environ["HERMES_YOLO_MODE"] = "1"
    os.environ["HERMES_ACCEPT_HOOKS"] = "1"

    agent = _build_agent(
        enabled_toolsets=[] if not use_tools else None,
        quiet=True,
        platform="iii-oneshot",
        skip_memory=True,
        use_tools=use_tools,
    )

    if system:
        # Inject as ephemeral system prompt context
        agent.ephemeral_system_prompt = system

    result = agent.run_conversation(prompt)
    return {
        "response": result.get("final_response", ""),
        "tokens": result.get("usage", {}),
        "model": agent.model,
    }


def run_session(
    prompt: str,
    session_id: str,
    user_id: str | None = None,
    system: str | None = None,
    use_tools: bool = True,
) -> dict[str, Any]:
    """Run a conversational turn in a multi-turn session.

    The AIAgent is cached by session_id so subsequent turns retain
    conversation history and the full Hermes experience (memory, skills,
    context compression, etc.).
    """
    os.environ["HERMES_YOLO_MODE"] = "1"
    os.environ["HERMES_ACCEPT_HOOKS"] = "1"

    with _session_lock:
        entry = _sessions.get(session_id)

        if entry is None:
            # Create a new agent for this session
            agent = _build_agent(
                quiet=True,
                platform="iii",
                use_tools=use_tools,
            )

            # Apply per-session configuration
            if user_id:
                agent.user_id = user_id
            if system:
                agent.ephemeral_system_prompt = system

            _sessions[session_id] = _SessionEntry(agent)
            log.info("created new agent session %s", session_id[:8])
        else:
            agent = entry.agent
            entry.last_used = time.time()
            log.info("reusing agent session %s (turn %d)",
                      session_id[:8],
                      len(getattr(agent, "messages", []) or []) // 2 + 1)

    result = agent.run_conversation(prompt)
    return {
        "response": result.get("final_response", ""),
        "tokens": result.get("usage", {}),
        "model": agent.model,
    }


def prune_idle_sessions() -> int:
    """Remove sessions that have been idle longer than _SESSION_TTL.

    Returns the number of pruned sessions.
    """
    now = time.time()
    stale = []
    with _session_lock:
        for sid, entry in list(_sessions.items()):
            if now - entry.last_used > _SESSION_TTL:
                stale.append(sid)
        for sid in stale:
            del _sessions[sid]
    if stale:
        log.info("pruned %d idle agent sessions", len(stale))
    return len(stale)


# ── Streaming agent runner (conversational style) ──────────────────────

def run_session_streaming(
    prompt: str,
    session_id: str,
    *,
    on_sentence: Callable[[str, int], None] | None = None,
    on_tool_start: Callable[[str], None] | None = None,
    user_id: str | None = None,
    system: str | None = None,
    min_chars: int = 15,
) -> dict:
    """Run a conversational turn with streaming sentence-level callbacks.

    Instead of returning only the final response, this calls *on_sentence*
    as each complete thought/sentence finishes streaming from the LLM.
    The caller (usually the iii worker's event loop) delivers these to
    the user's chat in real time via cross-worker invocations (e.g.
    ``telegram::send-message``).

    Args:
        prompt: User message.
        session_id: Session identifier (caches the agent for multi-turn).
        on_sentence: Called with (sentence_text, seq_number) from the
                     executor thread for each completed thought.
        on_tool_start: Called with (tool_name) when a tool call begins.
        user_id: Optional user identity for memory.
        system: Optional system prompt override.
        min_chars: Min chars before emitting a sentence (anti-fragment).

    Returns:
        Same dict as run_session — ``response``, ``tokens``, ``model``.
    """
    os.environ["HERMES_YOLO_MODE"] = "1"
    os.environ["HERMES_ACCEPT_HOOKS"] = "1"

    with _session_lock:
        entry = _sessions.get(session_id)

        if entry is None:
            agent = _build_agent(
                quiet=True,
                platform="iii",
                use_tools=True,
            )
            if user_id:
                agent.user_id = user_id
            if system:
                agent.ephemeral_system_prompt = system

            _sessions[session_id] = _SessionEntry(agent)
            log.info("created new streaming session %s", session_id[:8])
        else:
            agent = entry.agent
            entry.last_used = time.time()
            log.info("reusing streaming session %s", session_id[:8])

    # Apply conversational pacing overlay for streaming mode
    _append_or_set_ephemeral(
        agent,
        (
            "\n\n[Streaming Conversational Mode]\n"
            "You are speaking in a live conversation, not writing a document.\n"
            "Keep each response short — 1 to 3 sentences.\n"
            "After your response, invite the user to continue with a question,\n"
            "a prompt, or an open-ended invitation.\n"
            "Structure your responses conversationally:\n"
            "  • Preview what you're going to cover.\n"
            "  • Explain clearly in plain, direct language.\n"
            "  • End with a \"landing point\" — a summary, a question, or a\n"
            "    check-in (\"Does that make sense?\", \"Thoughts?\").\n"
            "Do NOT dump everything at once. Pace yourself like a thoughtful\n"
            "conversational partner — one idea at a time.\n"
            "Use second-person (\"you\") and rhetorical questions to keep it\n"
            "dialogic. This is a conversation, not a report.\n"
            "When you need to look something up, say so briefly then do it."
        ),
    )

    # Wire up streaming callbacks
    from workers.hermes_iii_worker.sentence_buffer import SentenceBuffer

    feed, flush = SentenceBuffer.build_callback(
        on_sentence=on_sentence,
        min_chars=min_chars,
    )
    agent.stream_delta_callback = feed

    if on_tool_start:
        agent.tool_gen_callback = on_tool_start

    result = agent.run_conversation(prompt)
    flush()  # emit any remaining buffered text

    return {
        "response": result.get("final_response", ""),
        "tokens": result.get("usage", {}),
        "model": agent.model,
    }


# ── Helpers ──────────────────────────────────────────────────────────────


def _append_or_set_ephemeral(agent: Any, text: str) -> None:
    """Append *text* to the agent's ephemeral_system_prompt (or set it)."""
    existing = getattr(agent, "ephemeral_system_prompt", None)
    if existing:
        agent.ephemeral_system_prompt = f"{existing}\n\n{text}"
    else:
        agent.ephemeral_system_prompt = text
