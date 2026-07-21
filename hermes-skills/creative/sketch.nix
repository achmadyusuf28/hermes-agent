# sketch.nix — Auto-converted from Hermes skill
# Category: creative
# Original: sketch

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.sketch;
in
{
  options.hermes.skills.sketch = {
    enable = mkEnableOption "Throwaway HTML mockups: 2-3 design variants to compare.";
  };

  config = mkIf cfg.enable {
    hermes.skills.sketch = {
      enable = true;
  description = "Throwaway HTML mockups: 2-3 design variants to compare.";
  triggers = [
  "sketch"
];
  type = "workflow";
  steps = [
  ''
    **Feel.** "What should this feel like? Adjectives, emotions, a vibe." — *"calm, editorial, like Linear"* tells you more than *"minimal"*.
  ''
  ''
    **References.** "What apps, sites, or products capture the feel you're imagining?" — actual references beat abstract descriptions.
  ''
  ''
    **Core action.** "What's the single most important thing a user does on this screen?" — the variants should all serve this well; if they don't, they're just decoration.
  ''
  ''
    **Click a primary action** and something visible happens (state change, modal, toast, navigation feint)
  ''
  ''
    **See one meaningful state transition** (filter a list, toggle a mode, open/close a panel)
  ''
  "**Hover recognizable affordances** (buttons, rows, tabs)"
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
