# nixos-background-worker.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-background-worker

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-background-worker;
in
{
  options.hermes.skills.nixos-background-worker = {
    enable = mkEnableOption "Deploy background worker processes alongside Docker containers on NixOS systemd. Covers the pattern of running queue consumers, batch processors, and sidecar workers that depend on a Docker container being up.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-background-worker = {
      enable = true;
  description = "Deploy background worker processes alongside Docker containers on NixOS systemd. Covers the pattern of running queue consumers, batch processors, and sidecar workers that depend on a Docker container being up.";
  triggers = [
  "nixos-background-worker"
  "nixos background worker"
];
  type = "workflow";
  steps = [
  ''
    **FastAPI server** — `fastapi run --host 0.0.0.0 src/main.py` (started by entrypoint)
  ''
  ''
    **Deriver** — `python -m src.deriver` (queue processor, NOT started by entrypoint)
  ''
];
  pitfalls = [
  ''
    **Never use `docker restart`** for the worker process — the container keeps running, only the worker should restart
  ''
  ''
    **`kill -TERM 1` is DANGEROUS** — `docker exec container kill -TERM 1` sends SIGTERM to the container's PID 1 (usually the main server process like FastAPI, nginx, or the entrypoint script). This kills the MAIN container process, not your worker. If the entrypoint used `exec`, PID 1 IS the main server — killing it terminates the entire container. The container's restart policy then restarts the whole container, which is a heavyweight and disruptive way to kill a worker.
  ''
  ''
    **Signal propagation with `docker exec`** — Docker does NOT reliably propagate signals from the host-side `docker exec` CLI process to the process running inside the container. When systemd sends SIGTERM to `docker exec` on the host, the inner process may keep running indefinitely. This means:
  ''
  ''
    If you rely on systemd's default stop signal (SIGTERM to the main PID), the worker might not actually shut down
  ''
  ''
    You MUST provide an explicit ExecStop that targets the worker by name inside the container
  ''
  ''
    Without a proper ExecStop, stopping/restarting the systemd service produces orphaned worker processes
  ''
  ''
    On the next `systemctl start`, a duplicate worker starts alongside the orphan → queue races, duplicate processing
  ''
  ''
    **Recommended ExecStop** — use Python to find and kill the worker by process name. The container has Python, so this is always available:
  ''
  ''
    **If the container doesn't have `pgrep`**, don't use shell-based PID discovery. Always use Python's `/proc` filesystem — it's available in any Python-capable container.
  ''
  ''
    **Duplicate workers** — if you start the worker manually (via `docker exec -d`) AND the systemd service starts it, you'll have multiple processes polling the same queue. Kill all but the newest before the service activates. Python-based cleanup:
  ''
  ''
    **Startup jitter** — background workers often have a random startup delay to prevent lockstep polling (e.g. Honcho's deriver has up to 30s jitter). Don't assume the worker is broken if the queue doesn't drain immediately after service start. Wait for the jitter window to elapse, then check logs.
  ''
  ''
    **No cron-like restart** — use `Restart=on-failure`, not `Restart=always`. If the worker exits cleanly (nothing to do), it should stay stopped.
  ''
  ''
    **Journal logging** — systemd captures the worker's stdout/stderr automatically via journald. Access with `journalctl -u my-worker.service -n 50 --since "5 minutes ago"`.
  ''
];
    };
  };
}
