# symphony-pipeline.nix — Auto-converted from Hermes skill
# Category: .archive
# Original: symphony-pipeline

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.symphony-pipeline;
in
{
  options.hermes.skills.symphony-pipeline = {
    enable = mkEnableOption "Symphony task orchestration pipeline — merged gather/plan/dispatch worker";
  };

  config = mkIf cfg.enable {
    hermes.skills.symphony-pipeline = {
      enable = true;
  description = "Symphony task orchestration pipeline — merged gather/plan/dispatch worker";
  triggers = [
  "Symphony task orchestration pipeline"
  "symphony pipelills"
  "symphony-workers"
];
  type = "workflow";
  steps = [
  ''
    **Immediate triggers**: `tasks::update` fires `invokefunction` to `symphony::pick` directly → pipeline picks in <1s. **NOT** via `publishevent` (engine v0.20.0 doesn't support that message type).
  ''
  ''
    **Auto-approval**: Tasks with `priority=low` + ≤3 sub-tasks, or `confidence ≥ 0.8`, skip approval
  ''
  ''
    **Cascading dependents**: `done` tasks trigger `depends_on` dependents
  ''
  ''
    **Skip re-gather/re-plan**: Refinement reads existing plan from state
  ''
  ''
    **Verification**: Uses `PROC_SHELL` env var (defaults to `/run/current-system/sw/bin/sh`)
  ''
  ''
    **Dashboard**: WebSocket push at `/ws`, metrics 3.6ms, 🗑 Cancel Task button in detail panel with confirmation dialog. Live push status indicator (🟢/🔴) for WebSocket connection.
  ''
  ''
    **Test isolation**: Cancel stale tasks before testing pipeline flow — the single-threaded worker processes tasks sequentially
  ''
  ''
    **Exponential backoff retry** — `_retry_with_backoff(fn, max_retries=3, base_delay=1.0, max_delay=30.0)`. Used for `hermes::ask` LLM calls and plan fetching. Skips retry on fatal errors (permission, auth, not found).
  ''
  ''
    **Progress checkpointing** — `_checkpoint(ws, task_id, phase, data)` stores intermediate state in `state::set` with key `checkpoint:{task_id}`. Checkpoints at: gather_worktree, gather_analysis, gather_report_stored, plan_stored, dispatch_batch_{N}. Cleared on successful phase completion.
  ''
  ''
    **Per-sub-task timeout** — `_run_with_timeout(coro, timeout, label)` wraps each sub-task in `asyncio.wait_for`. Configurable via `runner_config.timeout` in plan (default 300s). Timed-out sub-tasks are marked `failed`, not `error`.
  ''
  ''
    **Graceful degradation** — Failed sub-tasks are collected with `status: "failed"`, not `status: "error"`. The batch continues processing remaining sub-tasks. `all_completed` is based on actual failures only. The dispatch result returns `status: "completed" | "partial"`.
  ''
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
