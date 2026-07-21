# honcho-setup.nix — Auto-converted from Hermes skill
# Category: integrations
# Original: honcho-setup

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.honcho-setup;
in
{
  options.hermes.skills.honcho-setup = {
    enable = mkEnableOption "Configure and manage Honcho (Plastic Labs cognitive database) on NixOS — env var architecture, LLM/embedding routing, Docker lifecycle, and API usage.";
  };

  config = mkIf cfg.enable {
    hermes.skills.honcho-setup = {
      enable = true;
  description = "Configure and manage Honcho (Plastic Labs cognitive database) on NixOS — env var architecture, LLM/embedding routing, Docker lifecycle, and API usage.";
  triggers = [
  "honcho"
  "honcho setup"
  "honcho config"
  "honcho model"
  "honcho env"
  "cognitive database"
];
  type = "workflow";
  steps = [
  "Update `LLM_OPENAI_BASE_URL` and `LLM_OPENAI_API_KEY`"
  ''
    Set all subsystem `MODEL_CONFIG__MODEL` to an Ollama-served model
  ''
  ''
    The embedding config is independent (see below) — no need to change it unless you want a different embedding model
  ''
  ''
    Set `structured_output_mode=json_object` so Honcho uses prompt-level JSON instruction
  ''
  ''
    Set `thinking_budget_tokens=0` to prevent Gemma 4's `<|think|>` mode from conflicting with Ollama's grammar formatting
  ''
  ''
    The Modelfile's `SYSTEM` prompt reinforces the correct `{"content": "..."}` object format — it's a base layer of instruction beneath whatever Honcho's subsystem prompt adds
  ''
  ''
    Ollama defers grammar/format enforcement until it sees `</think>` — if thinking is off, the end-of-thought token is never emitted and grammar constraints are dropped
  ''
  ''
    Deep reasoning during background operations (deriver, summary, dream) burns tokens and adds latency
  ''
];
  pitfalls = [
  ''
    **Model name mismatch**: Subsystems default to `gpt-5.4-mini`. If you change `LLM_OPENAI_BASE_URL` to Ollama but forget to override `MODEL_CONFIG__MODEL`, Ollama gets a request for `gpt-5.4-mini` and returns 404. Fix: set model per subsystem.
  ''
  ''
    **Embedding key fallback**: `EMBEDDING_MODEL_CONFIG` falls back to `LLM_OPENAI_API_KEY` if no explicit key is set. When routing embeddings through Ollama, this is fine (Ollama ignores the key).
  ''
  ''
    **`--network=host` requirement**: Honcho cannot reach host-loopback PostgreSQL from a bridge network. `host.docker.internal` only reaches `0.0.0.0` services. Don't waste time debugging — Honcho needs `--network=host`.
  ''
  ''
    **Env file not re-read on restart**: The `honcho.env` file is read at container startup by the `openai` Python SDK + Pydantic settings. Changes take effect only after `docker restart honcho`. A simple `docker kill`+`docker start` also works but is less clean.
  ''
  ''
    **Deriver enabled**: When `DERIVER_ENABLED=true` (default), Honcho asynchronously processes representations in the background. For testing, disable it with `DERIVER_ENABLED=false` to avoid confusing async behavior.
  ''
  ''
    **Container image version**: Migration files in `volumes` are version-specific. If the container image updates (e.g. `ghcr.io/plastic-labs/honcho:latest` has a new hash), the migration files may become incompatible. Pin to a tag like `ghcr.io/plastic-labs/honcho:vX.Y.Z` for stability.
  ''
  ''
    **`__` delimiter confusion**: The env var separator is two underscores `__`. A single underscore is part of the field name. e.g. `DERIVER_MODEL_CONFIG__MODEL` = `DeriverSettings().MODEL_CONFIG.model`, where `MODEL_CONFIG` uses `_` and the separator to `model` is `__`.
  ''
  ''
    **`DERIVER_ENABLED` hardcoded in Nix infrastructure.nix**: Even if `honcho.env` sets `DERIVER_ENABLED=true`, the Nix container definition in `infrastructure.nix` hardcodes `DERIVER_ENABLED = "false"` in the `environment` block. Docker merges `--env` flags **after** `--env-file`, so the Nix hardcoded value wins. To actually enable the deriver, you must change the Nix config AND rebuild (`nix-rebuild`) or override it. The env file alone cannot override this.
  ''
  ''
    **DeepSeek multi-provider naming**: `deepseek-v4-flash` is offered by both the `deepseek` provider and `openrouter`. The CLI rejects `manifest tiers-set ... deepseek-v4-flash -p deepseek` with "multiple providers". Fix: use `deepseek/deepseek-v4-flash -p openrouter` instead (the openrouter-prefixed variant resolves the ambiguity).
  ''
];
    };
  };
}
