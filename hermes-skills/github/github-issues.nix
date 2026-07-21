# github-issues.nix — Auto-converted from Hermes skill
# Category: github
# Original: github-issues

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.github-issues;
in
{
  options.hermes.skills.github-issues = {
    enable = mkEnableOption "Create, triage, label, assign GitHub issues via gh or REST.";
  };

  config = mkIf cfg.enable {
    hermes.skills.github-issues = {
      enable = true;
  description = "Create, triage, label, assign GitHub issues via gh or REST.";
  triggers = [
  "github-issues"
  "github issues"
];
  type = "workflow";
  steps = [
  "Navigate to /settings while logged out"
  "Get redirected to /login?next=/settings"
  "Log in"
  "Actual: redirected to /dashboard (should go to /settings)"
  "<step>"
  "<step>"
  "**List untriaged issues:**"
  ''
    **Read and categorize** each issue (view details, understand the bug/feature)
  ''
  "**Apply labels and priority** (see Managing Issues above)"
  "**Assign** if the owner is clear"
  "**Comment with triage notes** if needed"
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
