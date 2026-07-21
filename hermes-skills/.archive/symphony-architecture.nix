# symphony-architecture.nix — Auto-converted from Hermes skill
# Category: .archive
# Original: symphony-architecture

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.symphony-architecture;
in
{
  options.hermes.skills.symphony-architecture = {
    enable = mkEnableOption "Architectural overview of the Symphony orchestration pipeline on iii primitives — core concepts, dispatch filter, tracker model, stream-driven dispatch, and key design decisions. Updated for Phases 2-3.";
  };

  config = mkIf cfg.enable {
    hermes.skills.symphony-architecture = {
      enable = true;
  description = "Architectural overview of the Symphony orchestration pipeline on iii primitives — core concepts, dispatch filter, tracker model, stream-driven dispatch, and key design decisions. Updated for Phases 2-3.";
  triggers = [
  "symphony architecture"
  "what is symphony"
  "symphony pipeline"
  "dispatch filter"
  "task routing"
  "stream trigger"
  "tracker model"
  "event-driven dispatch"
  "cascading dependents"
  "auto-approval"
  "refinement cycle"
  "publishevent"
  "reliability stack"
  "_retry_with_backoff"
  "checkpoint"
  "graceful degradatirelated_skills:"
  "iii-engine-fundamentals"
  "iii-workspace-workflow"
];
  type = "workflow";
  steps = [
  "Stream trigger fires → `symphony::pick` invoked"
  ''
    Check eligibility — `workflow_state` in trigger states? Concurrency slot free?
  ''
  ''
    Claim — in-memory `PROCESSING_TASKS` set prevents cascade loops
  ''
  "Route by workflow_state:"
  "Update task → publish stream event for next phase"
  "List all tasks with workflow_state in active states"
  ''
    For each: is claimed? If claimed but no active session → re-dispatch (crash recovery)
  ''
  "If moved to terminal but session still running → stop agent"
  "Clean up stale claims"
  ''
    **Well-defined, single-responsibility scope** — specific bug fix at known sites
  ''
  ''
    **Verifiable outcome** — can check success with grep/compile/test
  ''
  ''
    **Survives being done once** — agent doesn't need mid-course clarification
  ''
  ''
    Write one task with explicit instructions (exact commands + file paths)
  ''
  ''
    Exercise every component — stream trigger → pick → agent → result
  ''
  ''
    Verify edges — dedup guard, rework feedback, concurrent dispatch
  ''
  ''
    Only then increase complexity — branching logic, parallel sub-tasks, auto-judge
  ''
  "`task.auto_approve` is set explicitly → true"
  "`plan` is None or not a dict → false"
  "`priority=\"low\"` AND `≤3 sub-tasks` → true"
  "`plan.confidence >= 0.8` → true"
];
  pitfalls = [
  ''
    **`path:` URI required as non-owner** — use `--flake "path:/path/to/flake#hostname"` to bypass git ownership checks- **Transient unit blocks rebuild** — `sudo systemctl stop nixos-rebuild-switch-to-configuration.service; sudo systemctl reset-failed; sudo systemctl daemon-reload`- **Shell redirects in ExecStart need `bash -c`** — systemd's ExecStart does NOT parse `>`, `|`, `||`, `&&`
  ''
  ''
    **Nix store staleness** — files referenced via `./path` are copied into the store at build time. Rebuild to pick up changes
  ''
];
    };
  };
}
