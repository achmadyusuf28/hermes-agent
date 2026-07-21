# claude-design.nix — Auto-converted from Hermes skill
# Category: creative
# Original: claude-design

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.claude-design;
in
{
  options.hermes.skills.claude-design = {
    enable = mkEnableOption "Design one-off HTML artifacts (landing, deck, prototype).";
  };

  config = mkIf cfg.enable {
    hermes.skills.claude-design = {
      enable = true;
  description = "Design one-off HTML artifacts (landing, deck, prototype).";
  triggers = [
  "claude-design"
  "claude design"
];
  type = "workflow";
  steps = [
  "brand docs"
  "existing product screenshots"
  "current repo components"
  "design tokens"
  "UI kits"
  "prior mockups"
  "reference models"
  "copy docs"
  "constraints from legal, product, or engineering"
  ''
    **Monitor** — the user is watching state change (dashboards, status pages, observability). Density, glanceable hierarchy, no marketing framing.
  ''
  ''
    **Operate** — the user is taking action on things (consoles, admin panels, queues, inboxes). Action affordances and selection state dominate.
  ''
  ''
    **Compare** — the user is weighing options against each other (pricing, plans, spec tables, search results). Aligned columns, parity of structure, one differentiator emphasized.
  ''
  ''
    **Configure** — the user is setting things up (settings, forms, wizards, onboarding). Progressive disclosure, clear save/validation states, low decoration.
  ''
  ''
    **Decide / Learn** — the user is being convinced or taught (landing pages, docs, marketing). One idea lands per section; this is the ONLY surface where a hero is usually correct.
  ''
  ''
    **Explore** — the user is browsing an open space (galleries, maps, search-and-filter, catalogs). Filters, result grids, and zoom/peek are the composition.
  ''
  ''
    **Command / Inspect** — the user is driving by keyboard or drilling into one object (command bars, inspectors, detail panes, property editors). Speed and focus over breadth.
  ''
  "**Understand the brief**"
  "**Gather context**"
  "**Commit to a surface** (see \"Surface-First\")"
  "**Define the design system for this artifact**"
];
  pitfalls = [
  ''
    Do not paste hosted tool schemas into a skill. They cause fake tool calls.
  ''
  ''
    Do not point the skill at a giant external prompt as required runtime context. That creates drift.
  ''
  ''
    Do not strip the design doctrine while removing tool plumbing.
  ''
  ''
    Do not over-ask when the user already gave enough direction.
  ''
  ''
    Do not under-ask for high-fidelity work with no brand context.
  ''
  "Do not produce generic SaaS layouts and call them designed."
  ''
    Do not claim browser verification unless it actually happened.
  ''
];
    };
  };
}
