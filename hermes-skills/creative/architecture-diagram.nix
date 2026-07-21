# architecture-diagram.nix — Auto-converted from Hermes skill
# Category: creative
# Original: architecture-diagram

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.architecture-diagram;
in
{
  options.hermes.skills.architecture-diagram = {
    enable = mkEnableOption "Dark-themed SVG architecture/cloud/infra diagrams as HTML.";
  };

  config = mkIf cfg.enable {
    hermes.skills.architecture-diagram = {
      enable = true;
  description = "Dark-themed SVG architecture/cloud/infra diagrams as HTML.";
  triggers = [
  "architecture-diagram"
  "architecture diagram"
];
  type = "workflow";
  steps = [
  ''
    User describes their system architecture (components, connections, technologies)
  ''
  "Generate the HTML file following the design system below"
  ''
    Save with `write_file` to a `.html` file (e.g. `~/architecture-diagram.html`)
  ''
  "User opens in any browser — works offline, no dependencies"
  "Draw an opaque background rect (`#0f172a`)"
  "Draw the semi-transparent styled rect on top"
  "**Header:** Title with a pulsing dot indicator and subtitle"
  ''
    **Main SVG:** The diagram contained within a rounded border card
  ''
  ''
    **Summary Cards:** A grid of three cards below the diagram for high-level details
  ''
  "**Footer:** Minimal metadata"
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
