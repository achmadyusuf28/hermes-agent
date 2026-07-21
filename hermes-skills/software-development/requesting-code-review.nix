# requesting-code-review.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: requesting-code-review

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.requesting-code-review;
in
{
  options.hermes.skills.requesting-code-review = {
    enable = mkEnableOption "Pre-commit review: security scan, quality gates, auto-fix.";
  };

  config = mkIf cfg.enable {
    hermes.skills.requesting-code-review = {
      enable = true;
  description = "Pre-commit review: security scan, quality gates, auto-fix.";
  type = "tool";
  verify = ''
  # 1. [ ] Run through the workflow with a test repo- [ ] Verify the expected output matches (gh CLI output, API response)- [ ] Check edge cases: no changes, empty state, permission errors
# 2. Run through the workflow with a test repo- [ ] Verify the expected output matches (gh CLI output, API response)- [ ] Check edge cases: no changes, empty state, permission errors
  '';
  pitfalls = [
  ''
    **Empty diff** — check `git status`, tell user nothing to verify
  ''
  "**Not a git repo** — skip and tell user"
  ''
    **Large diff (>15k chars)** — split by file, review each separately
  ''
  ''
    **delegate_task returns non-JSON** — retry once with stricter prompt, then treat as FAIL
  ''
  ''
    **False positives** — if reviewer flags something intentional, note it in fix prompt
  ''
  ''
    **No test framework found** — skip regression check, reviewer verdict still runs
  ''
  ''
    **Lint tools not installed** — skip that check silently, don't fail
  ''
  ''
    **Auto-fix introduces new issues** — counts as a new failure, cycle continues
  ''
];
    };
  };
}
