# petdex.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: petdex

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.petdex;
in
{
  options.hermes.skills.petdex = {
    enable = mkEnableOption "Install and select animated petdex mascots for Hermes.";
  };

  config = mkIf cfg.enable {
    hermes.skills.petdex = {
      enable = true;
  description = "Install and select animated petdex mascots for Hermes.";
  type = "workflow";
  steps = [
  "Find a pet: `hermes pets list <query>` and note its `slug`."
  "Install + activate: `hermes pets install <slug> --select`."
  "Preview it: `hermes pets show` (Ctrl+C to stop)."
  ''
    Confirm setup: `hermes pets doctor` — shows the resolved pet, configured
  ''
];
  pitfalls = [
  ''
    A pet only shows once one is installed AND selected (`enabled: true`).
  ''
  ''
    Inside a pipe/redirect (no TTY) terminal rendering is disabled by design.
  ''
  ''
    The petdex npm CLI installs to `~/.codex/pets`; Hermes uses its own
  ''
];
    };
  };
}
