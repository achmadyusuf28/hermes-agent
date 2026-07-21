# codex.nix — Auto-converted from Hermes skill
# Category: autonomous-ai-agents
# Original: codex

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.codex;
in
{
  options.hermes.skills.codex = {
    enable = mkEnableOption "Delegate coding to OpenAI Codex CLI (features, PRs).";
  };

  config = mkIf cfg.enable {
    hermes.skills.codex = {
      enable = true;
  description = "Delegate coding to OpenAI Codex CLI (features, PRs).";
  triggers = [
  "codex"
];
  type = "workflow";
  steps = [
  ''
    **Always use `pty=true`** — Codex is an interactive terminal app and hangs without a PTY
  ''
  ''
    **Git repo required** — Codex won't run outside a git directory. Use `mktemp -d && git init` for scratch
  ''
  ''
    **Use `exec` for one-shots** — `codex exec "prompt"` runs and exits cleanly
  ''
  ''
    **`--full-auto` for building** — auto-approves changes within the sandbox
  ''
  ''
    **Background for long tasks** — use `background=true` and monitor with `process` tool
  ''
  ''
    **Don't interfere** — monitor with `poll`/`log`, be patient with long-running tasks
  ''
  ''
    **Parallel is fine** — run multiple Codex processes at once for batch work
  ''
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
