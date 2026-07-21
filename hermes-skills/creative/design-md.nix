# design-md.nix — Auto-converted from Hermes skill
# Category: creative
# Original: design-md

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.design-md;
in
{
  options.hermes.skills.design-md = {
    enable = mkEnableOption "Author/validate/export Google's DESIGN.md token spec files.";
  };

  config = mkIf cfg.enable {
    hermes.skills.design-md = {
      enable = true;
  description = "Author/validate/export Google's DESIGN.md token spec files.";
  triggers = [
  "design-md"
  "design md"
];
  type = "workflow";
  steps = [
  "Overview (alias: Brand & Style)"
  "Colors"
  "Typography"
  "Layout (alias: Layout & Spacing)"
  "Elevation & Depth (alias: Elevation)"
  "Shapes"
  "Components"
  "Do's and Don'ts"
  ''
    **Ask the user** (or infer) the brand tone, accent color, and typography
  ''
  ''
    **Write `DESIGN.md`** in their project root using `write_file`. Always
  ''
  ''
    **Use token references** (`{colors.primary}`) in the `components:` section
  ''
  ''
    **Lint it** (see below). Fix any broken references or WCAG failures
  ''
  ''
    **If the user has an existing project**, also write Tailwind or DTCG
  ''
];
  pitfalls = [
  ''
    **Don't nest component variants.** `button-primary.hover` is wrong;
  ''
  ''
    **Hex colors must be quoted strings.** YAML will otherwise choke on `#` or
  ''
  ''
    **Negative dimensions need quotes too.** `letterSpacing: -0.02em` parses as
  ''
  ''
    **Section order is enforced.** If the user gives you prose in a random order,
  ''
  ''
    **`version: alpha` is the current spec version** (as of Apr 2026). The spec
  ''
  ''
    **Token references resolve by dotted path.** `{colors.primary}` works;
  ''
];
    };
  };
}
