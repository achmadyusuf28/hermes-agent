# findmy.nix — Auto-converted from Hermes skill
# Category: apple
# Original: findmy

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.findmy;
in
{
  options.hermes.skills.findmy = {
    enable = mkEnableOption "Track Apple devices/AirTags via FindMy.app on macOS.";
  };

  config = mkIf cfg.enable {
    hermes.skills.findmy = {
      enable = true;
  description = "Track Apple devices/AirTags via FindMy.app on macOS.";
  type = "workflow";
  steps = [
  ''
    Keep FindMy app in the foreground when tracking AirTags (updates stop when minimized)
  ''
  ''
    Use `vision_analyze` to read screenshot content — don't try to parse pixels
  ''
  ''
    For ongoing tracking, use a cronjob to periodically capture and log locations
  ''
  "Respect privacy — only track devices/items the user owns"
];
  pitfalls = [
  ''
    **Authentication state** — session cookies and API tokens expire. Verify auth before each session
  ''
  ''
    **Endpoint reachability** — check that the target service is running (`curl http://127.0.0.1:PORT/health`)- **Version mismatch** — API versions may differ between the tool's expectations and the running service
  ''
];
    };
  };
}
