# gif-search.nix — Auto-converted from Hermes skill
# Category: media
# Original: gif-search

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.gif-search;
in
{
  options.hermes.skills.gif-search = {
    enable = mkEnableOption "Search/download GIFs from Tenor via curl + jq.";
  };

  config = mkIf cfg.enable {
    hermes.skills.gif-search = {
      enable = true;
  description = "Search/download GIFs from Tenor via curl + jq.";
  triggers = [
  "gif-search"
  "gif search"
];
  type = "tool";
  verify = ''
  # 1. [ ] Run the tool with a representative input- [ ] Verify the output file exists and is non-empty- [ ] Check error handling for invalid inputs or missing dependencies
# 2. Run the tool with a representative input- [ ] Verify the output file exists and is non-empty- [ ] Check error handling for invalid inputs or missing dependencies
  '';
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
