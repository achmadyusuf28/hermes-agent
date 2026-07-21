# powerpoint.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: powerpoint

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.powerpoint;
in
{
  options.hermes.skills.powerpoint = {
    enable = mkEnableOption "Create, read, edit .pptx decks, slides, notes, templates.";
  };

  config = mkIf cfg.enable {
    hermes.skills.powerpoint = {
      enable = true;
  description = "Create, read, edit .pptx decks, slides, notes, templates.";
  type = "workflow";
  steps = [
  "Analyze template with `thumbnail.py`"
  "Unpack → manipulate slides → edit content → clean → pack"
  "/path/to/slide-01.jpg (Expected: [brief description])"
  "/path/to/slide-02.jpg (Expected: [brief description])"
  "Generate slides → Convert to images → Inspect"
  ''
    **List issues found** (if none found, look again more critically)
  ''
  "Fix issues"
  ''
    **Re-verify affected slides** — one fix often creates another problem
  ''
  "Repeat until a full pass reveals no new issues"
];
  pitfalls = [
  ''
    **Auth token freshness** — OAuth tokens expire. Re-authenticate before long sessions- **Schema drift** — external API schemas change. Verify the tool's expected format matches current reality
  ''
  ''
    **Rate limiting** — batch operations may hit API rate limits. Add delays between requests
  ''
];
    };
  };
}
