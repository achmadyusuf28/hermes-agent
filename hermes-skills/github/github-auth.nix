# github-auth.nix — Auto-converted from Hermes skill
# Category: github
# Original: github-auth

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.github-auth;
in
{
  options.hermes.skills.github-auth = {
    enable = mkEnableOption "GitHub auth setup: HTTPS tokens, SSH keys, gh CLI login.";
  };

  config = mkIf cfg.enable {
    hermes.skills.github-auth = {
      enable = true;
  description = "GitHub auth setup: HTTPS tokens, SSH keys, gh CLI login.";
  triggers = [
  "github-auth"
  "github auth"
];
  type = "workflow";
  steps = [
  ''
    If `gh auth status` shows authenticated → you're good, use `gh` for everything
  ''
  ''
    If `gh` is installed but not authenticated → use "gh auth" method below
  ''
  ''
    If `gh` is not installed → use "git-only" method below (no sudo needed)
  ''
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
