# excalidraw.nix — Auto-converted from Hermes skill
# Category: creative
# Original: excalidraw

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.excalidraw;
in
{
  options.hermes.skills.excalidraw = {
    enable = mkEnableOption "Hand-drawn Excalidraw JSON diagrams (arch, flow, seq).";
  };

  config = mkIf cfg.enable {
    hermes.skills.excalidraw = {
      enable = true;
  description = "Hand-drawn Excalidraw JSON diagrams (arch, flow, seq).";
  triggers = [
  "excalidraw"
];
  type = "workflow";
  steps = [
  "**Load this skill** (you already did)"
  ''
    **Write the elements JSON** -- an array of Excalidraw element objects
  ''
  ''
    **Save the file** using `write_file` to create a `.excalidraw` file
  ''
  ''
    **Optionally upload** for a shareable link using `scripts/upload.py` via `terminal`
  ''
];
  pitfalls = [
  ''
    **Output location** — generated files may go to unexpected directories. Always check the path
  ''
  ''
    **Resource constraints** — complex renderings/animations may need significant CPU or memory- **Dependency availability** — verify the required tools (pyfiglet, ImageMagick, etc.) are installed
  ''
];
    };
  };
}
