# multi-repo-workspace-setup.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: multi-repo-workspace-setup

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.multi-repo-workspace-setup;
in
{
  options.hermes.skills.multi-repo-workspace-setup = {
    enable = mkEnableOption "Clone, organize, and document a multi-repo project ecosystem — directory structure conventions, centralized OpenWiki documentation, branch-state registry for cross-branch awareness, and proposing conventions before inventing names.";
  };

  config = mkIf cfg.enable {
    hermes.skills.multi-repo-workspace-setup = {
      enable = true;
  description = "Clone, organize, and document a multi-repo project ecosystem — directory structure conventions, centralized OpenWiki documentation, branch-state registry for cross-branch awareness, and proposing conventions before inventing names.";
  triggers = [
  "clone my repos"
  "set up the project"
  "workspace structure"
  "organize projects"
  "wiki setup"
  "cross-project docs"
  "where do my repos live"
  "multi-repo"
];
  type = "workflow";
  steps = [
  "Get the Repo List"
  "Propose a Directory Structure"
  "Clone Repos"
  "Verify Clones"
  "Inventory Existing In-Repo Documentation"
  "Set Up Centralized Wiki"
  "Branch-State Registry for Cross-Branch Docs"
  "Create Wiki Landing Pages"
];
  pitfalls = [
  ''
    **Assuming you know the layout.** You don't. The user's mental model of their projects is what matters — always propose before building.
  ''
  ''
    **Type-squatting their naming.** "Frontnend" → "frontend" (typo), naming their bridge network "parkee-net" without asking. These erode trust. Propose, don't invent.
  ''
  ''
    **Cloning into your own home dir.** The repos should live somewhere accessible to both you and the user (e.g., `/mnt/data/parkee/` shared location).
  ''
  ''
    **Repo size surprises.** Toolchain repos can be 23k+ files. Account for clone time. Shallow clones (`--depth 1`) are fine for workspace setup.
  ''
  ''
    **Branch naming conventions differ.** Some repos use `main`, others `master`. Note this in the verification step.
  ''
  ''
    **Over-documenting upfront.** Wiki pages should be lightweight at first — filled in as the user works through actual problems, not pre-written in bulk.
  ''
  ''
    **Documentation that outpaces reality.** Wiki pages for in-flight refactors get stale fast if the branch-state registry isn't maintained. Let the user drive updates.
  ''
  ''
    **Making assumptions about in-repo docs.** Some repos (parkee-ws has `openspec/`, parkee-webhook has `bruno/` and `dahua/`) already have existing docs or tools. Check for them before creating wiki pages that duplicate content.
  ''
];
    };
  };
}
