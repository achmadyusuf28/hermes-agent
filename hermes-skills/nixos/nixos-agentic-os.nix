# nixos-agentic-os.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-agentic-os

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-agentic-os;
in
{
  options.hermes.skills.nixos-agentic-os = {
    enable = mkEnableOption "Build an autonomic, self-healing NixOS using Hermes as the agentic core — Nix tools, skill-as-module pattern, MAPE-K loop, security boundaries.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-agentic-os = {
      enable = true;
  description = "Build an autonomic, self-healing NixOS using Hermes as the agentic core — Nix tools, skill-as-module pattern, MAPE-K loop, security boundaries.";
  triggers = [
  "agentic os"
  "autonomic nixos"
  "nixos agent"
  "self-healing infrastructure"
  "nix eval tool"
  "hermes nix tools"
  "agent manages nixos"
  "skills as nix modules"
  "diy os"
  "autonomous infrastructure"
];
  type = "workflow";
  steps = [
  ''
    **Propose** — Create an isolated git worktree, write the Nix patch
  ''
  ''
    **Verify** — `nix_build --dry-run` first; for critical changes, run a headless VM integration test via the NixOS test driver
  ''
  ''
    **Apply** — `nix_switch` with a health check; on failure, auto-rollback to the previous generation
  ''
  "Evaluate all hermes.invariants[*].check"
  "If all pass → sleep silently"
  "If one fails:"
  ''
    **No iii engine as a dependency** for the MVP loop. The autonomic loop runs inside Hermes itself (cron + tools + gateway webhooks). iii earns its place at Phase 4 for complex event routing across 50+ nodes.
  ''
  ''
    **Git worktrees, not live editing.** Agent never touches the active `/etc/nixos/`. Every change is a git patch built in a temporary worktree.
  ''
  ''
    **Boot counting over health check daemon.** systemd-boot's +3 suffix mechanism is zero-config and survives kernel panics. A user-space health check daemon is a secondary line of defense.
  ''
  ''
    **Module-level stateVersion** for safe incremental migrations:
  ''
  ''
    **Human-in-the-loop by severity, not by blanket approval.** Low-severity invariants auto-remediate; critical ones always prompt.
  ''
];
  pitfalls = [
  ''
    **`types.attrsOf` for agent memory** — This creates $O(N)$ eval bottlenecks above 500 entries. Always use `types.lazyAttrsOf` wrapped in `types.nullOr`.
  ''
  ''
    **Granting `NOPASSWD: /run/current-system/sw/bin/nixos-rebuild`** — This is root-equivalent. `nixos-rebuild` wraps shell calls (`/bin/sh -c`), accepts `--override-input` for malicious flakes, and `/run/current-system/` is a symlink. Scope by store path hash instead.
  ''
  ''
    **`nixos-rebuild switch --impure`** — The `--impure` flag bypasses sandboxing entirely. Never allow it in the agent's sudo scoping.
  ''
  ''
    **Forgetting `NixOSIntegrationTest` in CI** — A `nix_build --dry-run` pass does not mean the system boots. Run a headless VM integration test before critical switches.
  ''
  ''
    **`nix_eval` on options.json** — The pre-computed JSON snapshot is fast but may be stale if a rebuild happened since it was generated. Always check `options.json` timestamp vs last `nixos-rebuild`.
  ''
  ''
    **`allow-import-from-derivation = true`** — This lets the evaluator trigger multi-hour builds during simple config queries. Keep it `false` for agent eval paths.
  ''
  ''
    **Recursive cron loop** — The autonomic cron job that checks invariants should NOT schedule new cron jobs. It writes Nix patches for review; the apply step is separate.
  ''
];
    };
  };
}
