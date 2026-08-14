"""
Configuration for the hermes-iii-worker.

Reads from environment variables first, falls back to Hermes config.yaml,
then to honcho.env for the Manifest API key.
"""
from __future__ import annotations

import logging
import os
from pathlib import Path

log = logging.getLogger(__name__)

# ── iii engine WebSocket ────────────────────────────────────────────────
III_WS_URL = os.environ.get("III_WS_URL", "ws://127.0.0.1:49134")

# ── Manifest LLM proxy ──────────────────────────────────────────────────
MANIFEST_URL = os.environ.get("MANIFEST_URL", "http://127.0.0.1:2099/v1/chat/completions")
MANIFEST_API_KEY = os.environ.get("MANIFEST_API_KEY", "")
MANIFEST_MODEL = os.environ.get("MANIFEST_MODEL", "")

# ── Honcho memory service ───────────────────────────────────────────────
HONCHO_URL = os.environ.get("HONCHO_URL", "http://127.0.0.1:8000")
HONCHO_WORKSPACE = os.environ.get("HONCHO_WORKSPACE", "hermes")

# ── Conversation memory limits ──────────────────────────────────────────
MAX_HISTORY_TURNS = 10
MAX_STORED_TURNS = 20

# ── Symphony workflow states that trigger dispatch ──────────────────────
TRIGGER_WORKFLOW_STATES = {"todo", "in_progress", "rework"}
TERMINAL_WORKFLOW_STATES = {"done", "cancelled", "completed", "plan_rejected", "plan_timed_out"}


def resolve_manifest_key() -> str:
    """Resolve the Manifest API key from env → config.yaml → honcho.env."""
    if MANIFEST_API_KEY:
        return MANIFEST_API_KEY

    # Try reading from Hermes config.yaml
    config_path = Path.home() / ".hermes" / "config.yaml"
    try:
        import yaml
        with open(config_path) as f:
            cfg = yaml.safe_load(f) or {}

        # Check custom_providers for mnfst_ key
        for p in cfg.get("custom_providers", []):
            key = p.get("api_key", "")
            if key.startswith("mnfst_"):
                log.info("loaded Manifest API key from config.yaml custom_providers")
                return key

        # Check provider block
        provider = cfg.get("provider", {})
        if isinstance(provider, dict):
            key = provider.get("api_key", "")
            if key:
                log.info("loaded Manifest API key from config.yaml provider block")
                return key
    except Exception as e:
        log.warning("could not read Manifest key from config.yaml: %s", e)

    # Fall back to honcho.env
    honcho_env = Path.home() / "honcho.env"
    try:
        with open(honcho_env) as f:
            for line in f:
                line = line.strip()
                if line.startswith("LLM_OPENAI_API_KEY="):
                    key = line.split("=", 1)[1].strip().strip("\"'")
                    log.info("loaded Manifest API key from honcho.env")
                    return key
    except Exception as e:
        log.warning("could not read Manifest key from honcho.env: %s", e)

    log.warning("no Manifest API key found — LLM calls will likely fail")
    return ""
