# simplify-code.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: simplify-code

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.simplify-code;
in
{
  options.hermes.skills.simplify-code = {
    enable = mkEnableOption "Parallel 3-agent cleanup of recent code changes.";
  };

  config = mkIf cfg.enable {
    hermes.skills.simplify-code = {
      enable = true;
  description = "Parallel 3-agent cleanup of recent code changes.";
  type = "workflow";
  steps = [
  ''
    **Merge** the findings into one list, deduping where reviewers overlap.
  ''
  ''
    **Discard false positives** — you have the most context; you don't have to
  ''
  ''
    **Resolve conflicts.** Reviewers can disagree (Reviewer 1: "use existing
  ''
  "**Apply in risk-tier order:**"
  ''
    **Verify** you didn't break anything: run the project's targeted tests for
  ''
  ''
    **Summarize** what you changed: a short list of applied fixes grouped by
  ''
];
  pitfalls = [
  ''
    **Don't fan out wider than ~3.** More reviewers means more cost and more
  ''
  ''
    **Give the WHOLE diff to each reviewer.** Splitting the diff across reviewers
  ''
  ''
    **Reviewers search, they don't guess.** A reuse finding with no pointer to
  ''
  ''
    **Apply ≠ rewrite.** This is cleanup of the user's recent changes, not a
  ''
  ''
    **Respect project conventions.** If the repo has AGENTS.md / CLAUDE.md /
  ''
  ''
    **Large diffs blow context.** If the diff is huge, scope it down before
  ''
  ''
    **Over-trusting dead code tools.** `knip`, `ts-prune`, and `depcheck` flag
  ''
  ''
    **Renaming without checking public contracts.** Export names, API route
  ''
  ''
    **Removing "unnecessary" error handling.** An empty catch block or ignored
  ''
];
    };
  };
}
