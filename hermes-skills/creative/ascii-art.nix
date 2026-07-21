# ascii-art.nix — Auto-converted from Hermes skill
# Category: creative
# Original: ascii-art

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.ascii-art;
in
{
  options.hermes.skills.ascii-art = {
    enable = mkEnableOption "ASCII art: pyfiglet, cowsay, boxes, image-to-ascii.";
  };

  config = mkIf cfg.enable {
    hermes.skills.ascii-art = {
      enable = true;
  description = "ASCII art: pyfiglet, cowsay, boxes, image-to-ascii.";
  triggers = [
  "ascii-art"
  "ascii art"
];
  type = "workflow";
  steps = [
  ''
    **Text as a banner** → pyfiglet if installed, otherwise asciified API via curl
  ''
  "**Wrap a message in fun character art** → cowsay"
  ''
    **Add decorative border/frame** → boxes (can combine with pyfiglet/asciified)
  ''
  ''
    **Art of a specific thing** (cat, rocket, dragon) → ascii.co.uk via curl + parsing
  ''
  ''
    **Convert an image to ASCII** → ascii-image-converter or jp2a
  ''
  "**QR code** → qrenco.de via curl"
  "**Weather/moon art** → wttr.in via curl"
  ''
    **Something custom/creative** → LLM generation with Unicode palette
  ''
  ''
    **Any tool not installed** → install it, or fall back to next option
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
  example = ''
  python3 -m pyfiglet "YOUR TEXT" -f slant
python3 -m pyfiglet "TEXT" -f doom -w 80    # Set width
python3 -m pyfiglet --list_fonts             # List all 571 fonts
  '';
    };
  };
}
