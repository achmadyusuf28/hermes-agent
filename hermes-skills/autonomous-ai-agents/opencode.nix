# opencode.nix — Auto-converted from Hermes skill
# Category: autonomous-ai-agents
# Original: opencode

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.opencode;
in
{
  options.hermes.skills.opencode = {
    enable = mkEnableOption "Delegate coding to OpenCode CLI (features, PR review).";
  };

  config = mkIf cfg.enable {
    hermes.skills.opencode = {
      enable = true;
  description = "Delegate coding to OpenCode CLI (features, PR review).";
  type = "workflow";
  steps = [
  "Verify tool readiness:"
  ''
    For bounded tasks, use `opencode run '...'` (no pty needed).
  ''
  ''
    For iterative tasks, start `opencode` with `background=true, pty=true`.
  ''
  "Monitor long tasks with `process(action=\"poll\"|\"log\")`."
  ''
    If OpenCode asks for input, respond via `process(action="submit", ...)`.
  ''
  ''
    Exit with `process(action="write", data="\x03")` or `process(action="kill")`.
  ''
  ''
    Summarize file changes, test results, and next steps back to user.
  ''
  ''
    Prefer `opencode run` for one-shot automation — it's simpler and doesn't need pty.
  ''
  ''
    Use interactive background mode only when iteration is needed.
  ''
  "Always scope OpenCode sessions to a single repo/workdir."
  ''
    For long tasks, provide progress updates from `process` logs.
  ''
  ''
    Report concrete outcomes (files changed, tests, remaining risks).
  ''
  ''
    Exit interactive sessions with Ctrl+C or kill, never `/exit`.
  ''
];
  pitfalls = [
  ''
    Interactive `opencode` (TUI) sessions require `pty=true`. The `opencode run` command does NOT need pty.
  ''
  ''
    `/exit` is NOT a valid command — it opens an agent selector. Use Ctrl+C to exit the TUI.
  ''
  ''
    PATH mismatch can select the wrong OpenCode binary/model config.
  ''
  "If OpenCode appears stuck, inspect logs before killing:"
  "`process(action=\"log\", session_id=\"<id>\")`"
  ''
    Avoid sharing one working directory across parallel OpenCode sessions.
  ''
  ''
    Enter may need to be pressed twice to submit in the TUI (once to finalize text, once to send).
  ''
];
    };
  };
}
