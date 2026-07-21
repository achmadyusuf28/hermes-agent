# nano-pdf.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: nano-pdf

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nano-pdf;
in
{
  options.hermes.skills.nano-pdf = {
    enable = mkEnableOption "Edit PDF text/typos/titles via nano-pdf CLI (NL prompts).";
  };

  config = mkIf cfg.enable {
    hermes.skills.nano-pdf = {
      enable = true;
  description = "Edit PDF text/typos/titles via nano-pdf CLI (NL prompts).";
  triggers = [
  "nano-pdf"
  "nano pdf"
];
  type = "tool";
  verify = ''
  # 1. [ ] Execute the command/tool with test input- [ ] Verify the output matches expected format- [ ] Check that the tool handles authentication/connection errors gracefully
# 2. Execute the command/tool with test input- [ ] Verify the output matches expected format- [ ] Check that the tool handles authentication/connection errors gracefully
  '';
  pitfalls = [
  ''
    **Auth token freshness** — OAuth tokens expire. Re-authenticate before long sessions- **Schema drift** — external API schemas change. Verify the tool's expected format matches current reality
  ''
  ''
    **Rate limiting** — batch operations may hit API rate limits. Add delays between requests
  ''
];
  example = ''
  nano-pdf edit <file.pdf> <page_number> "<instruction>"
  '';
    };
  };
}
