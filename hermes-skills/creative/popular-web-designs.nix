# popular-web-designs.nix — Auto-converted from Hermes skill
# Category: creative
# Original: popular-web-designs

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.popular-web-designs;
in
{
  options.hermes.skills.popular-web-designs = {
    enable = mkEnableOption "54 real design systems (Stripe, Linear, Vercel) as HTML/CSS.";
  };

  config = mkIf cfg.enable {
    hermes.skills.popular-web-designs = {
      enable = true;
  description = "54 real design systems (Stripe, Linear, Vercel) as HTML/CSS.";
  triggers = [
  "build a page that looks like"
  "make it look like stripe"
  "design like linear"
  "vercel style"
  "create a UI"
  "web design"
  "landing page"
  "dashboard design"
  "website styled like"
];
  type = "workflow";
  steps = [
  "Pick a design from the catalog below"
  ''
    Load it: `skill_view(name="popular-web-designs", file_path="templates/<site>.md")`
  ''
  ''
    Use the design tokens and component specs when generating HTML
  ''
  ''
    Pair with the `generative-widgets` skill to serve the result via cloudflared tunnel
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
