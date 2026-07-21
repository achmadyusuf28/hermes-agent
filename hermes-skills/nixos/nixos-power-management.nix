# nixos-power-management.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-power-management

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-power-management;
in
{
  options.hermes.skills.nixos-power-management = {
    enable = mkEnableOption "Configure and troubleshoot NixOS power state transitions — hibernate, suspend, resume, and the system services (keyring, D-Bus, display manager, NVIDIA) that break or need re-initialization after state changes.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-power-management = {
      enable = true;
  description = "Configure and troubleshoot NixOS power state transitions — hibernate, suspend, resume, and the system services (keyring, D-Bus, display manager, NVIDIA) that break or need re-initialization after state changes.";
  triggers = [
  "hibernate"
  "suspend"
  "resume"
  "power management"
  "logind"
  "sleep"
  "lid close"
  "suspend-then-hibernate"
  "gnome-keyring"
  "post-resume"
  "session loss after sleep"
  "keyring hibernate"
  "D-Bus after resume"
  "browser session lost hibernate"
  "nvidia power management"
];
  type = "tool";
  verify = ''
  # 1. [ ] `sudo nixos-rebuild dry-build --flake "path:<path>"` succeeds- [ ] Apply the change and verify with `systemctl status` or `curl` health check- [ ] Confirm config survives `nixos-rebuild switch` without regressions
# 2. `sudo nixos-rebuild dry-build --flake "path:<path>"` succeeds- [ ] Apply the change and verify with `systemctl status` or `curl` health check- [ ] Confirm config survives `nixos-rebuild switch` without regressions
  '';
  pitfalls = [
  ''
    **Don't use `swaylock` instead of PAM-based lock** — swaylock doesn't trigger `pam_gnome_keyring.so`, so the keyring stays locked even after the user types their password
  ''
  ''
    **Don't use `User=` without setting `DBUS_SESSION_BUS_ADDRESS`** — the D-Bus environment is not inherited from the user's session
  ''
  ''
    **Don't forget the UID** — `id -u <username>` before hardcoding `/run/user/<UID>/bus`
  ''
  ''
    **Post-resume hooks run as root by default** — always set `User=` to the real user for any command that needs D-Bus access
  ''
  ''
    **Hypridle's `after_sleep_cmd` only fires on RAM sleep**, not on hibernate → use systemd `post-resume.target` for hibernate recovery
  ''
];
    };
  };
}
