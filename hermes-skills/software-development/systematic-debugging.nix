# systematic-debugging.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: systematic-debugging

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.systematic-debugging;
in
{
  options.hermes.skills.systematic-debugging = {
    enable = mkEnableOption "4-phase root cause debugging: understand bugs before fixing.";
  };

  config = mkIf cfg.enable {
    hermes.skills.systematic-debugging = {
      enable = true;
  description = "4-phase root cause debugging: understand bugs before fixing.";
  type = "workflow";
  steps = [
  ''
    **Failing test** at the seam that reaches the bug: unit, integration, or end-to-end.
  ''
  "**HTTP script / curl** against a running dev server."
  ''
    **CLI invocation** with fixture input, diffing stdout/stderr against expected output.
  ''
  ''
    **Headless browser script** (Playwright/Puppeteer) asserting on DOM, console, or network.
  ''
  ''
    **Replay a captured trace**: HAR, request payload, event log, queue message, or webhook body.
  ''
  ''
    **Throwaway harness** that boots the smallest useful slice of the system and calls the failing path.
  ''
  ''
    **Property / fuzz loop** when the bug is intermittent wrong output over a broad input space.
  ''
  ''
    **Bisection harness** suitable for `git bisect run` when the bug appeared between two known states.
  ''
  ''
    **Differential loop** comparing old vs new version, two configs, two providers, or two datasets.
  ''
  ''
    **Human-in-the-loop script** only as a last resort: script the human steps and capture their result so the loop stays structured.
  ''
  ''
    **Fix the outermost bug first.** Always fix the error that fires earliest in the code path. It's blocking everything downstream.
  ''
  ''
    **Re-run the tight loop after each fix.** Don't assume the cascade is done. Watch for the error message to change, not disappear.
  ''
  ''
    **One fix per iteration.** Apply exactly one fix, then re-test. If you fix three things at once and the test passes, you don't know which fix mattered — or whether two of them were wrong and the third compensated.
  ''
  ''
    **Document the chain as you go.** Each fix's output (error message before → after) becomes evidence for the next hypothesis. A shared terminal history or a running notes file helps.
  ''
  ''
    **When the test passes, the cascade is done.** When you fix the deepest bug and the tight loop goes green, stop. Don't chase hypothetical "also should fix" issues unless the test requires it.
  ''
  ''
    **Commit the regression test.** The cascade proves you found every blocking bug in the chain. The test that validates the final state exercises the full path.
  ''
  "Write a test that reproduces the bug (RED)"
  "Debug systematically to find root cause"
  "Fix the root cause (GREEN)"
  "The test proves the fix and prevents regression"
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
