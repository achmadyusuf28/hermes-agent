# hermes-agent.nix — Auto-converted from Hermes skill
# Category: autonomous-ai-agents
# Original: hermes-agent

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.hermes-agent;
in
{
  options.hermes.skills.hermes-agent = {
    enable = mkEnableOption "Configure, extend, or contribute to Hermes Agent.";
  };

  config = mkIf cfg.enable {
    hermes.skills.hermes-agent = {
      enable = true;
  description = "Configure, extend, or contribute to Hermes Agent.";
  type = "workflow";
  steps = [
  ''
    **Local faster-whisper** — free, no API key: `pip install faster-whisper`
  ''
  "**Groq Whisper** — free tier: set `GROQ_API_KEY`"
  "**OpenAI Whisper** — paid: set `VOICE_TOOLS_OPENAI_KEY`"
  "**Mistral Voxtral** — set `MISTRAL_API_KEY`"
  "Check `stt.enabled: true` in config.yaml"
  ''
    Verify provider: `pip install faster-whisper` or set API key
  ''
  "In gateway: `/restart`. In CLI: exit and relaunch."
  ''
    `hermes tools` — check if toolset is enabled for your platform
  ''
  "Some tools need env vars (check `.env`)"
  "`/reset` after enabling tools"
  "`hermes doctor` — check config and dependencies"
  ''
    `hermes auth` — re-authenticate OAuth providers (or `hermes auth add <provider>`)
  ''
  "Check `.env` has the right API key"
  ''
    **Copilot 403**: `gh auth login` tokens do NOT work for Copilot API. You must use the Copilot-specific OAuth device code flow via `hermes model` → GitHub Copilot.
  ''
  "`hermes skills list` — verify installed"
  "`hermes skills config` — check platform enablement"
  "Load explicitly: `/skill name` or `hermes -s name`"
  ''
    Add `CommandDef` to `COMMAND_REGISTRY` in `hermes_cli/commands.py`
  ''
  "Add handler in `cli.py` → `process_command()`"
  "(Optional) Add gateway handler in `gateway/run.py`"
];
  pitfalls = [
  ''
    **`path:` URI required as non-owner** — use `--flake "path:/path/to/flake#hostname"` to bypass git ownership checks- **Transient unit blocks rebuild** — `sudo systemctl stop nixos-rebuild-switch-to-configuration.service; sudo systemctl reset-failed; sudo systemctl daemon-reload`- **Shell redirects in ExecStart need `bash -c`** — systemd's ExecStart does NOT parse `>`, `|`, `||`, `&&`
  ''
  ''
    **Nix store staleness** — files referenced via `./path` are copied into the store at build time. Rebuild to pick up changes
  ''
];
  example = ''
  ```bash
  '';
    };
  };
}
