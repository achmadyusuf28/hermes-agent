# imessage.nix — Auto-converted from Hermes skill
# Category: apple
# Original: imessage

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.imessage;
in
{
  options.hermes.skills.imessage = {
    enable = mkEnableOption "Send and receive iMessages/SMS via the imsg CLI on macOS.";
  };

  config = mkIf cfg.enable {
    hermes.skills.imessage = {
      enable = true;
  description = "Send and receive iMessages/SMS via the imsg CLI on macOS.";
  type = "workflow";
  steps = [
  ''
    **Always confirm recipient and message content** before sending
  ''
  ''
    **Never send to unknown numbers** without explicit user approval
  ''
  "**Verify file paths** exist before attaching"
  "**Don't spam** — rate-limit yourself"
];
  pitfalls = [
  ''
    **Premature completion** — don't declare done until the entire workflow has been verified end-to-end- **State leakage** — across steps, ensure intermediate state doesn't contaminate later phases
  ''
  ''
    **Missing edge cases** — always test with empty inputs, error states, and concurrent access
  ''
];
    };
  };
}
