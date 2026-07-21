# task-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: task-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.task-workflow;
in
{
  options.hermes.skills.task-workflow = {
    enable = mkEnableOption "A systematic task execution methodology — classify the ask, define done, gather evidence in parallel, decide one recommendation, act surgically, verify by observation, report outcome-first with forced verifiable artifacts. Covers the fit gate (route before doing), INTENT line (spec-vs-test reconciliation), twin check (sweep for duplicate bugs after every fix), authorization gate (AUTH line for outward actions), and the 3-cycle hard bound (stop + hand back). Inspired by and adapted from the Fable Method. Use at the start of any non-trivial multi-step task.";
  };

  config = mkIf cfg.enable {
    hermes.skills.task-workflow = {
      enable = true;
  description = "A systematic task execution methodology — classify the ask, define done, gather evidence in parallel, decide one recommendation, act surgically, verify by observation, report outcome-first with forced verifiable artifacts. Covers the fit gate (route before doing), INTENT line (spec-vs-test reconciliation), twin check (sweep for duplicate bugs after every fix), authorization gate (AUTH line for outward actions), and the 3-cycle hard bound (stop + hand back). Inspired by and adapted from the Fable Method. Use at the start of any non-trivial multi-step task.";
  triggers = [
  "task execution"
  "task methodology"
  "how to approach"
  "fable method"
  "done criteria"
  "INTENT line"
  "TWINS check"
  "AUTH gate"
  "adversarial judge"
  "fit gate"
  "PENDING line"
  "3-cycle bound"
];
  type = "workflow";
  steps = [
  ''
    **Orient first.** Enumerate what exists before reading specifics. You cannot pick the right files from memory.
  ''
  ''
    **Primary sources beat memory.** Read actual code, files, output. Never invent an API signature or endpoint from recall. For library APIs, fetch current docs.
  ''
  ''
    **Parallelize independent lookups.** Web fetches, doc lookups, and reads across many files go in one batch, never sequentially.
  ''
  ''
    **Read narrow, never re-read.** Search to locate the section, then read only that section. Never re-fetch what's already in context.
  ''
  ''
    **Time-box.** One round of lookups + one follow-up covers most tasks. A third needs a stated reason. Two consecutive fruitless lookups = stop.
  ''
  ''
    **Establish intent before changing behavior.** A failing check has two culprits: the code or the check itself. Find the intended behavior (README, spec, docstring) and confirm code, check, and spec all agree. If any two disagree, that's a surprise (rule 7).
  ''
  ''
    **Surprises route the loop.** Anything that contradicts your expectation is your most important finding: state it. If it changes what done means, update Step 1. If it changes what the user is asking, go back to Step 0.
  ''
  ''
    **INTENT gate, before any behavior-changing edit.** Write: `INTENT: code does <X>; the failing check/task expects <Y>; the spec (README/docstring) says <Z>`. You must open the actual spec/docstring to fill Z. If X, Y, Z don't all agree, don't edit yet — the disagreement is the real finding. Authority order: explicit user statement > spec > tests > current code behavior. The INTENT line appears verbatim in your final report.
  ''
  ''
    **Recall gate, before first use of anything not opened this session.** An API written from memory is not evidence. Open its source now, or label it in the report as memory/unverified.
  ''
  ''
    **Smallest correct change.** Touch only what the task needs. Match existing style.
  ''
  ''
    **Precise edits over rewrites.** Rewrite a whole file only if you authored it this session or have fully read it.
  ''
  ''
    **Track multi-part work.** 3+ heterogeneous steps or 5+ similar items get a written checklist. Tick items as you go; audit against the ask before reporting.
  ''
  ''
    **Never destroy without looking.** Before deleting or overwriting, look at what's actually there.
  ''
  ''
    **Failed-edit recovery ladder.** Re-read the exact region, adjust the match, retry once. Only then widen to a larger span. Full rewrite is last and you say you fell back.
  ''
  ''
    **Standing prohibitions** unless the user explicitly says otherwise: never commit or push; never weaken a check or fabricate to make it pass; never touch secrets, credentials, or env files; never add a dependency; never delete outside the declared scope.
  ''
];
  pitfalls = [
  ''
    **Step-skipping is the #1 failure mode** — the most common mistake is jumping from Step 0 to Step 4 (acting without gathering evidence). If you don't know what files to change, you didn't do Step 2.
  ''
  ''
    **The fit gate is not optional** — running the full loop on a trivial question produces wasted work. Always ask: is this a question, task, or plan-first? If it's a question, don't execute.
  ''
  ''
    **INTENT before editing** — never make a behavior-changing edit without writing the INTENT line first. It forces you to check the spec/tests/expected behavior before touching code. Skipping it is the most common bug origin.
  ''
  ''
    **TWINS check after every fix** — a bug found in one place is presumed to recur. Always search the project for the same construct. Missing a twin is the most common regression source.
  ''
  ''
    **Authorization gate for outward actions** — push, deploy, send, or delete without the user's own words bypasses review. The user's docs/prefs are NOT authorization.
  ''
  ''
    **Plan approval ≠ execution permission** — user saying "go ahead" on a plan means the plan itself is sound, not that you can silently start the first irreversible action. Before stopping a service, deleting a container, or changing a database connection string, announce the specific action and wait for confirmation. The AUTH gate applies per-action, not just per-plan.
  ''
  ''
    **3-cycle bound — stop after 3 failures** — the same bug cannot be solved by the same approach. After 3 cycles, you're missing information. Stop and report.
  ''
  ''
    **Artifact gate before reporting** — sweep the report for INTENT, AUTH, TWINS, PENDING lines. A missing line means you skipped that step.
  ''
  ''
    **Delegation doesn't skip these steps** — subagents get auto-injected TWINS and the completion gate, but NOT the adversarial judge. For consequential work, spawn the judge manually.
  ''
  ''
    **Step 6: don't narrate the loop** — never report step numbers or scaffolding. The user sees results, not process.
  ''
];
    };
  };
}
