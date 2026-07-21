# parkee-iii-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: parkee-iii-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.parkee-iii-workflow;
in
{
  options.hermes.skills.parkee-iii-workflow = {
    enable = mkEnableOption "Multi-repo PARKEE development workflow via the iii engine — dynamic functions, state tracking, and parallel operations across parkee-reader-pax, parkee-reader-jellies, and shared submodules.";
  };

  config = mkIf cfg.enable {
    hermes.skills.parkee-iii-workflow = {
      enable = true;
  description = "Multi-repo PARKEE development workflow via the iii engine — dynamic functions, state tracking, and parallel operations across parkee-reader-pax, parkee-reader-jellies, and shared submodules.";
  triggers = [
  "parkee development"
  "build parkee"
  "parkee status"
  "update submodules"
  "deploy to reader"
  "bank bug"
  "deduct"
  "parkee bank"
  "parkee transaction"
  "bug fix"
  "fix bug"
  "patch firmware"
];
  type = "workflow";
  steps = [
  "Identify task type from user's message"
  ''
    Load relevant KB file(s) with `read_file(path="<absolute-path>")`
  ''
  ''
    Also read workspace AGENTS.md at `/mnt/data/projects/parkee/AGENTS.md`
  ''
  ''
    Honcho has PARKEE facts injected every session (gotchas, bank versions)
  ''
];
  pitfalls = [
  ''
    **`sudo` path on NixOS** — `sudo` is at `/run/wrappers/bin/sudo`, NOT on the default PATH in restricted shells. Always use the full path or `/run/current-system/sw/bin/sudo`.
  ''
  ''
    **Shared-repo permission denied** — repos owned by `soup:users` have per-repo `.git/objects/xx/` directories with 2755 permissions (no group-write). Git commands that create new objects fail. Workaround: apply changes via `patch`/`write_file` on source files, bypassing git. Do NOT `chmod` the object store.
  ''
  ''
    **Second-brain is local-only** — the KB at `/mnt/data/projects/parkee/second-brain/` is NOT inside any repo. Peers who clone parkee repos won't have it. AGENTS.md files referencing second-brain paths must include the disclaimer.
  ''
  ''
    **Markitdown PDF extraction on NixOS** — numpy may fail with `libstdc++.so.6 not found`. Fix with `LD_PRELOAD=$(find /nix -name "libstdc++.so.6" -print -quit)`.
  ''
  ''
    **Subagent self-reports are not durable** — self-reporting via `iii trigger tasks::update` from subagents is best-effort. If the iii engine is down when a subagent tries to report, the update is lost. The parent should verify final state after all subagents complete.
  ''
  ''
    **PAX/JELLIES submodule mismatch** — always run `git submodule status` before building. A stale or new commit in a submodule (especially `parkee-reader-exit`) changes protocol behavior silently.
  ''
  ''
    **`#ifdef PARQUE_NODISPLAY` dual-implementation** — fixes applied to IM700 branch do NOT apply to IM15 branch. Before declaring a fix done, verify in BOTH branches. See the diff command in the main skill for verification.
  ''
  ''
    **Bug investigation: description.md is not evidence** — the root cause in a Linear ticket's description.md is someone else's opinion. The raw reader log (`Send-Archive*.zip`) is the primary source of truth. Always extract and read it.
  ''
  ''
    **NixOS `sed` for multi-line edits** — `sed` with embedded `\n` does NOT work for multi-line replacements on NixOS. Use `sudo python3 -c "..."` with `content.replace()` instead.
  ''
];
    };
  };
}
