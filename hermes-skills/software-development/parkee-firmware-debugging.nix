# parkee-firmware-debugging.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: parkee-firmware-debugging

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.parkee-firmware-debugging;
in
{
  options.hermes.skills.parkee-firmware-debugging = {
    enable = mkEnableOption "Systematic debugging of PARKEE reader firmware (C ARM) on PAX terminals — APDU flow, NFC timing, lost contact, cross-codebase comparison.";
  };

  config = mkIf cfg.enable {
    hermes.skills.parkee-firmware-debugging = {
      enable = true;
  description = "Systematic debugging of PARKEE reader firmware (C ARM) on PAX terminals — APDU flow, NFC timing, lost contact, cross-codebase comparison.";
  type = "workflow";
  steps = [
  "— Extract Logs"
  "— Filter by Build Hash"
  "— Build Boundary Check"
  "— Cross-gate Comparison"
  "— Category Breakdown"
  "— FWT Distribution"
  "— SW1-SW2 Response Categorization"
  "— SAM Error Frame Detection"
  "— False Positive Scrub"
  "— Export to Excel"
  "— Produce Verdict"
];
    };
  };
}
