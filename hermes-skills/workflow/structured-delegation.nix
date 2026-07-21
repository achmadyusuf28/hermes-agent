# structured-delegation.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: structured-delegation

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.structured-delegation;
in
{
  options.hermes.skills.structured-delegation = {
    enable = mkEnableOption "Structured brief/progress/result protocol for subagent task delegation. File-based IPC (JSON/JSONL on disk) that replaces fire-and-forget subagent spawning with observable, course-correctable work. Use when spawning a subagent for any non-trivial investigation, research, or audit task — write the brief, spawn the worker, read live progress, inject mid-flight corrections, consume structured results at the end.";
  };

  config = mkIf cfg.enable {
    hermes.skills.structured-delegation = {
      enable = true;
  description = "Structured brief/progress/result protocol for subagent task delegation. File-based IPC (JSON/JSONL on disk) that replaces fire-and-forget subagent spawning with observable, course-correctable work. Use when spawning a subagent for any non-trivial investigation, research, or audit task — write the brief, spawn the worker, read live progress, inject mid-flight corrections, consume structured results at the end.";
  triggers = [
  ''
    Structured brief/progress/result protocol for subagent task delegation. File-based IPC (JSON/JSONL on disk) that replaces fire-and-forget subagent spawning with observable, course-correctable work. Use when spawning a subagent for any non-trivial investigation, research, or audit task
  ''
  "structured delegation"
];
  type = "workflow";
  steps = [
  ''
    **Read `TASK_DIR/_brief.json`** on start — this is the single source of truth
  ''
  ''
    **Write progress after meaningful steps** — every 3-5 tool calls, or when a finding/dead-end/shift occurs
  ''
  ''
    **Check `_correction.json` after each step** — if `seq` is higher than last_seen, read and re-plan
  ''
  ''
    **Write `_state.json` after checkpoints** — for crash recovery
  ''
  ''
    **Write `_result.json` on completion** — verdict-first with structured evidence
  ''
  ''
    **On unrecoverable error:** write result with `verdict: "BLOCKED"` and the error detail. Do not crash silently.
  ''
  ''
    **Do NOT delete the workspace dir** — cleanup is handled externally
  ''
  ''
    **Write the brief** to `~/.hermes/workspace/<task-id>/_brief.json`
  ''
  ''
    **Call `delegate_task`** with `TASK_DIR: <path>` in the context string
  ''
  ''
    The subagent's system prompt auto-detects `TASK_DIR:` and injects full protocol instructions
  ''
  ''
    **Optionally load the `delegation-worker` skill** in the subagent for richer reference material
  ''
  ''
    **Poll progress** by reading `_progress.jsonl` while the subagent runs
  ''
  ''
    **Inject corrections** via `_correction.json` if the subagent is going the wrong way
  ''
  ''
    **Read `_result.json`** on completion; the subagent's final summary is still returned
  ''
  ''
    **Write the brief** to `~/.hermes/workspace/<task-id>/_brief.json`
  ''
  "**Spawn a background terminal process** with `TASK_DIR` set"
  ''
    **Poll progress** via `process(action='poll')` or `notify_on_complete`
  ''
  "**Read `_result.json`** when the process finishes"
  ''
    `PROTOCOL_CORE` is a module-level constant in `tools/delegate_tool.py` (~3.7KB) with a literal `{TASK_DIR}` placeholder in 7 positions
  ''
  ''
    At prompt-build time, `_build_child_system_prompt` does one string replace: `PROTOCOL_CORE.replace("{TASK_DIR}", task_dir)`
  ''
];
  pitfalls = [
  ''
    **Premature completion** — don't declare done until the entire workflow has been verified end-to-end- **State leakage** — across steps, ensure intermediate state doesn't contaminate later phases
  ''
  ''
    **Missing edge cases** — always test with empty inputs, error states, and concurrent access
  ''
];
    };
  };
}
