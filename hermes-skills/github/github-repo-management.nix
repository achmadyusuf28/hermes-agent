# github-repo-management.nix — Auto-converted from Hermes skill
# Category: github
# Original: github-repo-management

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.github-repo-management;
in
{
  options.hermes.skills.github-repo-management = {
    enable = mkEnableOption "Clone/create/fork repos; manage remotes, releases.";
  };

  config = mkIf cfg.enable {
    hermes.skills.github-repo-management = {
      enable = true;
  description = "Clone/create/fork repos; manage remotes, releases.";
  triggers = [
  "github-repo-management"
  "github repo management"
];
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
