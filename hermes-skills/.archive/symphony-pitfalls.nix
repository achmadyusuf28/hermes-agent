# symphony-pitfalls.nix — Auto-converted from Hermes skill
# Category: .archive
# Original: symphony-pitfalls

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.symphony-pitfalls;
in
{
  options.hermes.skills.symphony-pitfalls = {
    enable = mkEnableOption "Consolidated error patterns, gotchas, and troubleshooting for the Symphony pipeline — state deserialization, stream events, cascade loops, worktrees, OpenCode concurrency, dashboard crashes, Nix deployment, health checks, and reliability patterns.";
  };

  config = mkIf cfg.enable {
    hermes.skills.symphony-pitfalls = {
      enable = true;
  description = "Consolidated error patterns, gotchas, and troubleshooting for the Symphony pipeline — state deserialization, stream events, cascade loops, worktrees, OpenCode concurrency, dashboard crashes, Nix deployment, health checks, and reliability patterns.";
  triggers = [
  "symphony error"
  "symphony pitfall"
  "state deserialization"
  "cascade event loop"
  "worktree failure"
  "opencode crash"
  "dashboard crash"
  "stream event missed"
  "bare mirror"
  "workflow state drift"
  "state::get trap"
  "schema migration"
  "dual state gap"
  "tags normalization"
  "get_task fails"
  "str object has no attribute get"
  "update whitelist"
  "workflow_state not persisting"
  "event field type mismatch"
  "tasks::update workflow_state"
];
  type = "workflow";
  steps = [
  ''
    **Button in `buildDetailHtml()`** (~line 575): Add inside the Actions `<div>` with `badge badge-<state>` for styling, calling a new JS function.
  ''
  ''
    **New JS function** (~line 672): Async POST to `/api/tasks/<id>/toggle` with `{ workflow_state: '<state>' }`. Include `confirm()` for destructive actions. Refresh list + detail on success.
  ''
  "`tasks::list --limit 200`"
  "Filter for tasks missing the new field"
  "Batch `tasks::update` for each orphan"
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
