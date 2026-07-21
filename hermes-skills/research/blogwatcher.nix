# blogwatcher.nix — Auto-converted from Hermes skill
# Category: research
# Original: blogwatcher

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.blogwatcher;
in
{
  options.hermes.skills.blogwatcher = {
    enable = mkEnableOption "Monitor blogs and RSS/Atom feeds via blogwatcher-cli tool.";
  };

  config = mkIf cfg.enable {
    hermes.skills.blogwatcher = {
      enable = true;
  description = "Monitor blogs and RSS/Atom feeds via blogwatcher-cli tool.";
  type = "tool";
  verify = ''
  # 1. [ ] Run through the workflow with a test repo- [ ] Verify the expected output matches (gh CLI output, API response)- [ ] Check edge cases: no changes, empty state, permission errors
# 2. Run through the workflow with a test repo- [ ] Verify the expected output matches (gh CLI output, API response)- [ ] Check edge cases: no changes, empty state, permission errors
  '';
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
