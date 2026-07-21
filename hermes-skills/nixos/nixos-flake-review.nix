# nixos-flake-review.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-flake-review

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-flake-review;
in
{
  options.hermes.skills.nixos-flake-review = {
    enable = mkEnableOption "Review a NixOS flake for best practices, deprecation warnings, structural issues, and common pitfalls. Covers the systematic inspection checklist and the path URI rebuild workaround.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-flake-review = {
      enable = true;
  description = "Review a NixOS flake for best practices, deprecation warnings, structural issues, and common pitfalls. Covers the systematic inspection checklist and the path URI rebuild workaround.";
  triggers = [
  "review this flake"
  "check my nixos config"
  "best practice improvements"
  "audit configuration.nix"
  "nixos rebuild issues"
];
  type = "workflow";
  steps = [
  "Zero evaluation warnings (or document remaining ones)"
  "Same or new store path"
  "All services come up (check with `systemctl --failed`)"
];
  pitfalls = [
  ''
    **`path:` URI required as non-owner** — use `--flake "path:/path/to/flake#hostname"` instead of `--flake "/path#hostname"` to bypass git ownership checks. The bare path syntax defaults to `git+file://` which triggers libgit2's ownership check.
  ''
  ''
    **Transient unit blocks subsequent rebuilds** — a failed `nixos-rebuild switch` can leave a lingering transient systemd unit. Recovery: `sudo systemctl stop nixos-rebuild-switch-to-configuration.service && sudo systemctl reset-failed` then retry.
  ''
  ''
    **Shell redirects in `ExecStart` need `bash -c`** — systemd's ExecStart does NOT parse `>`, `|`, `||`, `&&`. Wrap in `''${pkgs.bash}/bin/bash -c '...'` when needed.
  ''
  ''
    **"resource temporarily unavailable" during Go/CUDA compiles** — PID fork exhaustion from parallel compilation. Reduce with `--option max-jobs 1 --option cores 2`. Avoid `--refresh` (rebuilds everything cached).
  ''
  ''
    **Conflicting option definitions** — when a NixOS module sets a default and your config also sets it, use `lib.mkForce` or `lib.mkDefault`. Common candidates: `services.postgresql.settings.listen_addresses`, systemd `serviceConfig` fields.
  ''
  ''
    **Nix store path staleness** — after editing a file referenced via Nix path (`./path/to/file`), the running service still uses the old store copy. Always rebuild (`nixos-rebuild switch`) to pick up changes.
  ''
  ''
    **`allowUnfree` should be declared once** — scattering `nixpkgs.config.allowUnfree = true` across submodules leads to duplicate option definitions. Declare it once in `configuration.nix`.
  ''
  ''
    **`stateVersion` must match nixpkgs branch** — using an incorrect `stateVersion` can cause activation script inconsistencies. Match to the nixpkgs branch (e.g. `25.11` for nixos-unstable as of mid-2026).
  ''
];
    };
  };
}
