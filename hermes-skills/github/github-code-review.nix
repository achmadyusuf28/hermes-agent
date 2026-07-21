# github-code-review.nix — Auto-converted from Hermes skill
# Category: github
# Original: github-code-review

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.github-code-review;
in
{
  options.hermes.skills.github-code-review = {
    enable = mkEnableOption "Review PRs: diffs, inline comments via gh or REST.";
  };

  config = mkIf cfg.enable {
    hermes.skills.github-code-review = {
      enable = true;
  description = "Review PRs: diffs, inline comments via gh or REST.";
  triggers = [
  "github-code-review"
  "github code review"
];
  type = "workflow";
  steps = [
  "**Get the big picture first:**"
  ''
    **Review file by file** — use `read_file` on changed files for full context, and the diff to see what changed:
  ''
  "**Check for common issues:**"
  "**Present structured feedback** to the user."
  "`git diff main...HEAD --stat` — see scope of changes"
  "`git diff main...HEAD` — read the full diff"
  ''
    For each changed file, use `read_file` if you need more context
  ''
  "Apply the checklist above"
  ''
    Present findings in the structured format (Critical / Warnings / Suggestions / Looks Good)
  ''
  ''
    If critical issues found, offer to fix them before the user pushes
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
