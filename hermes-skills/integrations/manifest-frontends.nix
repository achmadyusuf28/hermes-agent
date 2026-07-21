# manifest-frontends.nix — Auto-converted from Hermes skill
# Category: integrations
# Original: manifest-frontends

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.manifest-frontends;
in
{
  options.hermes.skills.manifest-frontends = {
    enable = mkEnableOption "Configure third-party CLI/TUI tools (OpenCode, OpenWiki, Claude Code) to route through Manifest as an OpenAI-compatible endpoint — turning them into frontends for Manifest-routed agents.";
  };

  config = mkIf cfg.enable {
    hermes.skills.manifest-frontends = {
      enable = true;
  description = "Configure third-party CLI/TUI tools (OpenCode, OpenWiki, Claude Code) to route through Manifest as an OpenAI-compatible endpoint — turning them into frontends for Manifest-routed agents.";
  triggers = [
  "manifest frontend"
  "opencode manifest"
  "TUI for hermes"
  "opencode-hermes"
  "claude-manifest"
  "openwiki manifest"
  "configure opencode"
  "openai-compatible endpoint"
  "use manifest as provider"
];
  type = "knowledge";
  knowledge = ''
  # Manifest Frontends

Wire third-party CLI/TUI tools to route through Manifest as an
OpenAI-compatible API. Every tool that accepts a base URL + API key
can become a frontend for any Manifest agent.

## Universal Pattern

```bash
BASE_URL = "http://localhost:2099/v1"    # Manifest proxy
API_KEY  = "mnfst_<agent-key>"           # Any Manifest agent
MODEL    = "default"                      # Routes to agent's default routing tier
```

## Tool Configurations

### OpenCode (TUI/CLI)

Uses `@ai-sdk/openai-compatible` npm provider adapter. Config JSON:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "manifest": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Manifest",
      "options": {
        "baseURL": "http://localhost:2099/v1",
        "apiKey": "mnfst_..."
      },
      "models": {
        "default": { "name": "Manifest Default" }
      }
    }
  },
  "model": "manifest/default"
}
```

Set via `OPENCODE_CONFIG` env var or a Nix wrapper (see reference files).

### OpenWiki (CLI Wiki)

Via env vars:

```bash
OPENWIKI_PROVIDER="openai-compatible"
OPENAI_COMPATIBLE_API_KEY="mnfst_..."
OPENAI_COMPATIBLE_BASE_URL="http://localhost:2099/v1"
OPENWIKI_MODEL_ID="default"
```

### Claude Code (CLI)

Via env vars:

```bash
ANTHROPIC_BASE_URL="http://localhost:2099"
ANTHROPIC_AUTH_TOKEN="mnfst_..."
ANTHROPIC_MODEL="default"
```

## Why Route Through Manifest

- **Agent isolation** — each tool uses its own Manifest agent (soup, opencode,
  openwiki) with separate routing tiers, cost tracking, and audit trails

- **No provider keys in tools** — tools authenticate to Manifest, which holds
  the real provider credentials
- **Single routing layer** — change model/provider for ALL tools from one place
  via `manifest tiers-set`
- **Unified monitoring** — all traffic flows through Manifest's message store
  and rate limiter

- **Fallback chains** — primary model fails, Manifest tries fallback transparently

## Available Wrappers

Based on the existing codebase (`coding-assistants.nix`):

| Command | Routes through | Use case |
|---|---|---|
| `opencode` | OpenCode's built-in providers | Pure coding |
| `opencode-manifest` | Manifest (opencode agent) | Coding via Manifest |
| `opencode-local` | Ollama (localhost:11434) | Offline |
| `opencode-hermes` | Manifest (soup/hermes agent) | TUI for Hermes |
| `claude-manifest` | Manifest (Anthropic-compatible) | Claude Code via Manifest |
| `claude-local` | Ollama (Anthropic-compatible) | Claude Code via Ollama |

## Creating a New Wrapper

Two approaches, in order of preference:

### Recommended: Runtime Key Injection (production)

Reads the API key from an external env file at runtime — keeps secrets out
of the Nix store. Auto-rebuilds the config if the key changes (hash check).

**Dual-user fallback:** On multi-user machines (e.g. `soup` = human,
`hermes` = AI agent), the wrapper checks both the current user's
`~/.hermes/.env` AND the agent user's `/home/hermes/.hermes/.env`.
This avoids a "No API key found" error when the key lives under a
different user's home.

```nix
opencode-hermes = pkgs.writeShellApplication {
  name = "opencode-hermes";
  runtimeInputs = with pkgs; [ opencode coreutils gnused ];
  text = '''
    CONFIG_DIR="$HOME/.config/.opencode-hermes"
    SETTINGS_FILE="$CONFIG_DIR/opencode.json"
    mkdir -p "$CONFIG_DIR"

    # Read API key — check user's env first, then agent user's
    HERMES_API_KEY=""
    for ENV_FILE in "$HOME/.hermes/.env" "/home/hermes/.hermes/.env"; do
      if [ -f "$ENV_FILE" ]; then
        HERMES_API_KEY=$(grep -E '^OPENAI_API_KEY=' "$ENV_FILE" \
          | sed 's/^OPENAI_API_KEY=//')
        [ -n "$HERMES_API_KEY" ] && break
      fi
    done
    if [ -z "$HERMES_API_KEY" ]; then
      echo "ERROR: No API key found in ~/.hermes/.env or /home/hermes/.hermes/.env" >&2
      echo "  Run manifest-login or copy the key into your own ~/.hermes/.env" >&2
      exit 1
    fi

    # Auto-rebuild config if key changed
    CURRENT_KEY_HASH=$(echo "$HERMES_API_KEY" | md5sum \
      | cut -d' ' -f1 || true)
    SAVED_KEY_HASH=""
    [ -f "$CONFIG_DIR/.key_hash" ] \
      && SAVED_KEY_HASH=$(cat "$CONFIG_DIR/.key_hash")

    if [ ! -f "$SETTINGS_FILE" ] \
        || [ "$CURRENT_KEY_HASH" != "$SAVED_KEY_HASH" ]; then
      cat > "$SETTINGS_FILE" <<EOF
    {
      "\$schema": "https://opencode.ai/config.json",
      "provider": {
        "manifest": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "Manifest",
          "options": {
            "baseURL": "http://localhost:2099/v1",
            "apiKey": "$HERMES_API_KEY"
          },
          "models": {
            "default": { "name": "Manifest Default" }
          }
        }
      },
      "model": "manifest/default",
      "lsp": true
    }
EOF
      echo "$CURRENT_KEY_HASH" > "$CONFIG_DIR/.key_hash"
    fi

    export OPENCODE_CONFIG="$SETTINGS_FILE"
    exec opencode "$@"
  ''';
};
```

**Benefits over hardcoded keys:**
- API key never enters the Nix store (world-readable)
- Key rotation doesn't require Nix rebuild — just update the env file
- Hash check means zero-config on key change (auto-regenerates)

### Simple: Hardcoded Key (quick prototyping)

API key ends up in the Nix store — fine for dev, avoid for production.

```nix
opencode-hermes = pkgs.writeShellApplication {
  name = "opencode-hermes";
  runtimeInputs = with pkgs; [ opencode coreutils ];
  text = '''
    CONFIG_DIR="$HOME/.config/.opencode-hermes"
    SETTINGS_FILE="$CONFIG_DIR/opencode.json"
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$SETTINGS_FILE" ]; then
      cat <<'WRAPEOF' > "$SETTINGS_FILE"
    {
      "$schema": "https://opencode.ai/config.json",
      "provider": {
        "manifest": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "Manifest",
          "options": {
            "baseURL": "http://localhost:2099/v1",
            "apiKey": "mnfst_<agent-key>"
          },
          "models": {
            "default": { "name": "Manifest Default" }
          }
        }
      },
      "model": "manifest/default"
    }
    WRAPEOF
    fi
    export OPENCODE_CONFIG="$SETTINGS_FILE"
    exec opencode "$@"
  ''';
};
```

## Multi-Interface Setup

A single Manifest agent can be accessed from multiple interfaces in parallel —
each uses its own API key and routing tier but shares the same backend:

| Interface | When | Authentication |
|---|---|---|
| **Telegram** 📱 | Mobile / anywhere | Bot token |
| **OpenCode TUI** 🖥️ | Laptop coding sessions | Manifest agent key |
| **Manifest CLI** | Quick checks | Session cookie |
| **OpenWiki** 📚 | Knowledge synthesis | Manifest agent key |

No conflicts — Telegram messages, TUI sessions, and CLI queries all
hit the same agent routing and message store independently.
  '';
  pitfalls = [
  ''
    **Authentication state** — session cookies and API tokens expire. Verify auth before each session
  ''
  ''
    **Endpoint reachability** — check that the target service is running (`curl http://127.0.0.1:PORT/health`)- **Version mismatch** — API versions may differ between the tool's expectations and the running service
  ''
];
    };
  };
}
