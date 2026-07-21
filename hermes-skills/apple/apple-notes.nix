# apple-notes.nix — Auto-converted from Hermes skill
# Category: apple
# Original: apple-notes

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.apple-notes;
in
{
  options.hermes.skills.apple-notes = {
    enable = mkEnableOption "Manage Apple Notes via memo CLI: create, search, edit.";
  };

  config = mkIf cfg.enable {
    hermes.skills.apple-notes = {
      enable = true;
  description = "Manage Apple Notes via memo CLI: create, search, edit.";
  type = "workflow";
  steps = [
  ''
    Prefer Apple Notes when user wants cross-device sync (iPhone/iPad/Mac)
  ''
  ''
    Use the `memory` tool for agent-internal notes that don't need to sync
  ''
  ''
    Use the `obsidian` skill for Markdown-native knowledge management
  ''
];
  pitfalls = [
  ''
    **File format mismatch** — verify the output format is compatible with the intended use
  ''
  ''
    **API key requirements** — some media APIs require authentication. Check credentials first- **Size limits** — large media files may exceed tool or platform limits. Test with representative sizes
  ''
];
    };
  };
}
