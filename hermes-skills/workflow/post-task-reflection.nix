# post-task-reflection.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: post-task-reflection

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.post-task-reflection;
in
{
  options.hermes.skills.post-task-reflection = {
    enable = mkEnableOption "Mandatory self-reflection after any complex task — evaluate what worked, what didn't, and what to do differently. Feed findings back into skills, memory, or new skills.";
  };

  config = mkIf cfg.enable {
    hermes.skills.post-task-reflection = {
      enable = true;
  description = "Mandatory self-reflection after any complex task — evaluate what worked, what didn't, and what to do differently. Feed findings back into skills, memory, or new skills.";
  triggers = [
  "reflection"
  "retrospective"
  "after-action"
  "what did we learn"
  "self improve"
  "feedback loop"
  "postmortem"
  "skill hygiene"
  "cross-session learning"
  "pre-creation"
];
  type = "workflow";
  pitfalls = [
  ''
    **Don't reflect on every task** — run this skill only for tasks meeting the thresholds (3+ calls, user correction, first-time task, etc.). Running it for trivial one-shot lookups creates noise and wastes tokens.
  ''
  ''
    **Prefer source code changes over memory** — the system prompt source (`prompt_builder.py`) is more durable than memory entries. If the same correction keeps coming up, push it to source, not just memory.
  ''
  ''
    **Don't promise "I'll remember for next time"** — that's what skills and memory are for. If you don't write it down, you won't remember. Create/patch the skill or memory entry before declaring the task done.
  ''
  ''
    **Quality gate verification is mandatory** — after creating or updating a skill, run the 6-point pre-save quality gate (triggers, verification, fallback, freshness, self-contained, compact) from `hermes-agent-skill-authoring`. Skipping this produces substandard skills.
  ''
  ''
    **Cross-reference check is not optional** — always check if new knowledge overlaps with an existing skill that should be updated, or if a loaded skill was outdated and should be patched. Stale skills compound over time.
  ''
  ''
    **Source code changes must be committed** — if you modified `prompt_builder.py` or any tracked file in the Hermes fork, commit and push it. Uncommitted source changes don't survive across sessions if the repo is pulled on restart.
  ''
  ''
    **Session evaluations are user-facing, not the same as this reflection** — this skill is an internal self-improvement loop. Don't confuse it with offering the user an end-of-session summary. The user-facing evaluation is only offered when it serves the user (open-ended exploration, significant learnings), not for every completed task.
  ''
];
    };
  };
}
