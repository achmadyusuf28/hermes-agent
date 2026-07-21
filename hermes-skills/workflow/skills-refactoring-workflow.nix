# skills-refactoring-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: skills-refactoring-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.skills-refactoring-workflow;
in
{
  options.hermes.skills.skills-refactoring-workflow = {
    enable = mkEnableOption "Systematic approach to refactoring the Hermes skills library — splitting grab-bag skills, consolidating duplicates, creating new skills from extracted content, and verifying cross-references.";
  };

  config = mkIf cfg.enable {
    hermes.skills.skills-refactoring-workflow = {
      enable = true;
  description = "Systematic approach to refactoring the Hermes skills library — splitting grab-bag skills, consolidating duplicates, creating new skills from extracted content, and verifying cross-references.";
  triggers = [
  "refactor skills"
  "reorganize skills"
  "clean up skills"
  "skills need consolidation"
  "skill split"
  "monolithic skill"
  "bloated skill"
  "grab-bag"
  "skill hygiene"
  "skill triage"
  "skill benchmark"
  "quality scan"
  "which skills need optimization"
  "skills optimization"
  "SkillsBench"
];
  type = "workflow";
  steps = [
  ''
    **Read all candidates in parallel** — batch `skill_view()` calls to understand each skill's content and find insertion points
  ''
  ''
    **Identify gaps** — for each skill, determine what's missing (triggers, pitfalls, verification, or a combination)
  ''
  ''
    **Patch in parallel batches** — group independent skills into the same tool call. The `patch` tool works well for inserting sections before the last heading (`## Related Skills`, `## Reference Files`, `## Tips`, etc.)
  ''
  ''
    **Rename non-standard headings** — if a skill has `## Pitfalls` → rename to `## Common Pitfalls`. The scanner is strict about this
  ''
  ''
    **Verify** — rerun `python3 ~/.hermes/scripts/skill-triage.py` and check the skills moved from OPTIMIZE → CRYSTALLIZE (or REWRITE if they need more)
  ''
  ''
    **Capture findings** — any gotchas discovered about the scanner itself (like the naming convention) should go back into this skill's reference files
  ''
  "Remove the sections that were extracted into new skills"
  ''
    Add cross-references in both the body text and `related_skills` YAML
  ''
  ''
    Keep the core identity/topic that justified the skill's original purpose
  ''
  ''
    Ensure the canonical skill has the most complete/current version
  ''
  ''
    Add a "Canonical Home" banner at the top of the canonical skill
  ''
  ''
    In each other skill, replace the duplicate section with a short cross-reference
  ''
  "Add related_skills YAML entries"
  ''
    Check current usage: `memory(action='add', ...)` will report full
  ''
  ''
    Consolidate: replace long entries with shorter versions, remove stale ones
  ''
  ''
    Batch operations: use `operations` array for atomic add+remove in one call
  ''
];
  pitfalls = [
  ''
    **Don't delete skills when splitting** — keep the original focused, don't delete and recreate. Deleting breaks context from cron jobs and other skills that reference the old name.
  ''
  ''
    **Create before edit** — always create new skills before editing existing ones so new cross-references resolve immediately.
  ''
  ''
    **related_skills must be valid skill names** — only skill names from `skills_list`, not category names or tags.
  ''
  ''
    **Frontmatter YAML must be valid** — broken frontmatter (e.g., missing `---` closing) makes the skill unloadable. The skill_manage patch warns about this.
  ''
  ''
    **Frontmatter patch can silently drop lines between boundaries** — when using `skill_manage(action='patch')` to replace a multi-line span of YAML frontmatter, any YAML key between the `old_string` start and end is **dropped** if it's explicitly not included in the old_string. Example: if the frontmatter is `name:\ntitle:\ndescription:\ncategory:`, and you match `old_string="description:\ncategory:"`, the `title:` line disappears. **Fix:** match exact adjacent lines (one-to-one), not ranges that skip intermediate keys. When adding a new key like `triggers:`, insert it immediately after `description:` by matching just those two adjacent lines.
  ''
  ''
    **`title:` YAML key is non-standard** — the standard YAML frontmatter for skills uses `name:` as the primary identifier. Some skills also have a `title:` for display purposes. The triage scanner may or may not parse `title:` correctly. Avoid adding `title:` to skills that don't already have it unless you verify the scanner still works. Prefer `name:` as the single canonical identifier.
  ''
  ''
    **Triage reports deleted skills as u:2 ghosts** — the triage scanner's usage counts come from the session DB (substring search in past conversations). If a skill was mentioned in old sessions and later deleted, it still appears in the triage output as "used" (u:2 or u:1) even though it doesn't exist on disk. **Diagnosis:** `skill_view(name)` returns 404. **Action:** ignore — they're ghosts. No need to optimize something that doesn't exist.
  ''
  ''
    **Batch score thresholds for triage-driven work** — Skills that get `## Common Pitfalls` + `## Verification` added (and already had triggers) land at **9/13** consistently. Skills that already had one and get the other reach **11/13**. Those starting at 5-6/13 typically need all three (triggers, pitfalls, verification) to reach the crystallize bucket. Plan patches accordingly.
  ''
  ''
    **Escape-drift in patch** — when patching content with quotes, the skill_manage patch may reject escaped quotes. Read the exact file content with `skill_view` first, then use the unescaped version.
  ''
  ''
    **Use `absorbed_into` on delete** — when deleting a skill that was split, pass `absorbed_into=<umbrella>` to declare consolidation intent (vs. pruning). This helps the curator maintain downstream references.
  ''
  ''
    **YAML frontmatter refs are invisible to content search** — `related_skills` YAML entries won't show up in content search tools. To verify stale cross-references, check each skill individually with `skill_view`.
  ''
  ''
    **Cross-reference stale refs appear in body text too** — inline markdown like "see the `nixos-hermes-config` skill" can survive past the target skill's deletion. After deleting/renaming a skill, search for its old name across all `SKILL.md` files to catch body-text references.
  ''
  ''
    **Memory fills up during refactoring** — each new skill creation, cross-ref fix, and finding produces a memory entry. Batch consolidate at the end rather than adding many small entries.
  ''
];
    };
  };
}
