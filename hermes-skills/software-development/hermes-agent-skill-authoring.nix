# hermes-agent-skill-authoring.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: hermes-agent-skill-authoring

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.hermes-agent-skill-authoring;
in
{
  options.hermes.skills.hermes-agent-skill-authoring = {
    enable = mkEnableOption "Author in-repo SKILL.md: frontmatter, validator, structure, and writing-quality principles.";
  };

  config = mkIf cfg.enable {
    hermes.skills.hermes-agent-skill-authoring = {
      enable = true;
  description = "Author in-repo SKILL.md: frontmatter, validator, structure, and writing-quality principles.";
  type = "workflow";
  steps = [
  ''
    **User-local:** `~/.hermes/skills/<maybe-category>/<name>/SKILL.md` — personal, not shared. Created via `skill_manage(action='create')`.
  ''
  ''
    **In-repo (this skill is about this case):** `/home/bb/hermes-agent/skills/<category>/<name>/SKILL.md` — committed, shipped with the package. Use `write_file` + `git add`. `skill_manage(action='create')` does NOT target this tree.
  ''
  ''
    **Optimize for process predictability.** Ask: what behavior should change when this skill loads? If a line does not change behavior, cut it.
  ''
  ''
    **Choose the right context load.** A model-invoked Hermes skill pays for its description every turn. Keep descriptions focused on trigger classes and the skill's distinctive behavior. Put details in the body or linked references.
  ''
  ''
    **Use an information hierarchy.** Put always-needed steps in `SKILL.md`; put branch-specific or bulky reference material in `references/`, `templates/`, or `scripts/` and point to it only when needed.
  ''
  ''
    **End steps with completion criteria.** Each ordered step should say how the agent knows it is done. Good criteria are checkable and, when it matters, exhaustive: "every modified file accounted for" beats "summarize changes."
  ''
  ''
    **Co-locate rules with the concept they govern.** Avoid scattering one idea across the file. Keep definition, caveats, examples, and verification near each other.
  ''
  ''
    **Use strong leading words.** Prefer compact concepts the model already knows — e.g. "tight loop," "tracer bullet," "root cause," "regression test" — over long repeated explanations. A good leading word saves tokens and anchors behavior.
  ''
  ''
    **Prune duplication and no-ops.** Keep each meaning in one source of truth. Sentence by sentence, ask whether the sentence changes agent behavior versus the default. If not, delete it rather than polishing it.
  ''
  ''
    **Watch for premature completion.** If agents tend to rush a step, first sharpen that step's completion criterion. Split the sequence only when later steps distract from doing the current step well.
  ''
  "**Survey peers** in the target category:"
  ''
    **Check validator constraints** in `tools/skill_manager_tool.py` if unsure.
  ''
  ''
    **Draft** with `write_file` to `skills/<category>/<name>/SKILL.md`.
  ''
  "**Validate locally**:"
  "**Git add + commit** on the active branch."
  ''
    **Note:** the CURRENT session's skill loader is cached — `skill_view` / `skills_list` will not see the new skill until a new session. This is expected, not a bug.
  ''
  ''
    **Crystallize (optional)** — If the skill has a single-responsibility action with clear inputs/outputs, you can offer to crystallize it into an iii worker. Add `metadata.hermes.crystallize` to the frontmatter:
  ''
  ''
    **Using `skill_manage(action='create')` for an in-repo skill.** It writes to `~/.hermes/skills/`, not the repo tree. Use `write_file` for in-repo creation.
  ''
  ''
    **Leading whitespace before `---`.** The validator checks `content.startswith("---")`; any leading blank line or BOM fails validation.
  ''
  ''
    **Description too generic.** Peer descriptions start with "Use when ..." and describe the *trigger class*, not the one task. "Use when debugging X" > "Debug X".
  ''
];
    };
  };
}
