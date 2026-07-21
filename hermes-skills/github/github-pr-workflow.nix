# github-pr-workflow.nix — Auto-converted from Hermes skill
# Category: github
# Original: github-pr-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.github-pr-workflow;
in
{
  options.hermes.skills.github-pr-workflow = {
    enable = mkEnableOption "GitHub PR lifecycle: branch, commit, open, CI, merge.";
  };

  config = mkIf cfg.enable {
    hermes.skills.github-pr-workflow = {
      enable = true;
  description = "GitHub PR lifecycle: branch, commit, open, CI, merge.";
  triggers = [
  "github-pr-workflow"
  "github pr workflow"
];
  type = "workflow";
  steps = [
  "Check CI status → identify failures"
  "Read failure logs → understand the error"
  "Use `read_file` + `patch`/`write_file` → fix the code"
  "`git add . && git commit -m \"fix: ...\" && git push`"
  "Wait for CI → re-check status"
  ''
    Repeat if still failing (up to 3 attempts, then ask the user)
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
