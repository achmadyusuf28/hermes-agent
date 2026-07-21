# hermes-cron-automation.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: hermes-cron-automation

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.hermes-cron-automation;
in
{
  options.hermes.skills.hermes-cron-automation = {
    enable = mkEnableOption "Set up and manage Hermes cron jobs — LLM-driven vs no_agent script jobs, script placement constraints (Python-only on NixOS, ~/.hermes/scripts/), lifecycle management, and debugging.";
  };

  config = mkIf cfg.enable {
    hermes.skills.hermes-cron-automation = {
      enable = true;
  description = "Set up and manage Hermes cron jobs — LLM-driven vs no_agent script jobs, script placement constraints (Python-only on NixOS, ~/.hermes/scripts/), lifecycle management, and debugging.";
  triggers = [
  "cron job"
  "schedule task"
  "automation"
  "background job"
  "daily task"
  "periodic check"
  "tool-radar"
  "watchdog script"
];
  type = "workflow";
  steps = [
  ''
    Cron runner executes `~/.hermes/scripts/tool-radar.py` (wrapper) ✅
  ''
  ''
    Wrapper calls `/run/current-system/sw/bin/tool-radar` (absolute path) ✅
  ''
  ''
    That binary calls `subprocess.run(["manifest-login"], ...)` (bare name) ❌
  ''
];
  pitfalls = [
  ''
    **no_agent script extension: must be `.py` not `.sh`** — bash is not on the cron runner's PATH. Always use Python.
  ''
  ''
    **Every subprocess call needs absolute paths** — bare command names (e.g. `["manifest-login"]`) fail inside cron scripts. Use `/run/current-system/sw/bin/<name>`.
  ''
  ''
    **`sys.executable` returns empty string in cron** — don't rely on it for subprocess calls. Use absolute paths or `exec()` in-process.
  ''
  ''
    **Symlinks outside `~/.hermes/scripts/` are blocked** — cron validates that the script resolves within the scripts directory.
  ''
  ''
    **`no_agent` jobs produce no output when stdout is empty** — the tick succeeds silently. Use this for the watchdog pattern. If you want a notification every time, add a print.
  ''
  ''
    **Timed-out scripts (30s+)** are killed with an error. Keep scripts simple and fast.
  ''
  ''
    **`last_status: error` does NOT auto-retry** — you must investigate manually. Use `cronjob action=run job_id=<id>` to test.
  ''
  ''
    **Hash-based state works per-collection** — if monitoring multiple collections, use separate state file keys per source to avoid accidental cross-contamination.
  ''
  ''
    **First run of any hash-based watchdog flags everything** — that's expected. Second run onward is quiet unless something changes.
  ''
];
    };
  };
}
