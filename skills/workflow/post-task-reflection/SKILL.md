---
name: post-task-reflection
description: "Self-reflection after complex tasks — evaluate what worked and feed findings back into skills, memory, or new skills."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [reflection, self-improvement, skills, memory, retrospective]
    related_skills: [conversational-presence, hermes-agent]
---

# Post-Task Reflection — Self-Improvement Loop

Run this after every task that meets **any** of these thresholds:
- 3+ tool calls
- User provided a correction or new preference
- Multi-phase workflow with distinct stages
- First time doing a particular type of task
- Something went wrong and needed debugging
- You learned a new path, command, pattern, or convention
- You discovered a gotcha that should be documented

The framework provides automatic background review via `background_review.py` that runs in a forked agent thread after each turn. This skill is the **manual inline complement** — run it when the auto-review might miss the full context, or when you want to act immediately rather than waiting for the background thread.

## The Reflection

### 1. Completed — what was done

One-line summary of the outcome.

### 2. Findings — what was learned

- **New commands/paths/tools** discovered during the task
- **Gotchas** hit and how they were resolved
- **Patterns** that worked well or didn't
- **User preferences** surfaced (language, style, tool preference)
- **Environment quirks** that should be remembered

### 3. Actions — what to change

For each finding, decide:

| If... | Then... |
|---|---|
| A skill had wrong info | `skill_manage(action='patch')` immediately |
| A skill was missing a step | `skill_manage(action='patch')` to add it |
| A new reusable workflow emerged | `skill_manage(action='create')` with the workflow |
| A skill was overly redundant | `skill_manage(action='delete', absorbed_into='...')` |
| A user preference surfaced | `memory(action='add', target='user')` |
| An environment fact was learned | `memory(action='add', target='memory')` |
| A correction to how you operate | `memory(action='add', target='memory')` |

**Act immediately.** Skills and memory are the only reliable cross-session state.

### 4. Cross-reference check

- Did any new knowledge overlap with an existing skill that should be updated?
- Did you load a skill that was outdated or missing steps? Patch it now.
- Is any memory entry stale (wrong path, outdated command)? Fix it.

### 5. Done criteria

- [ ] All findings triaged into skill patches, memory updates, or new skills
- [ ] No "I'll remember this next time" — it's written down
- [ ] Cross-reference check performed

## Relationship to the Framework Auto-Review

The Hermes agent automatically runs a background memory/skill review after each turn (controlled by `agent._skill_nudge_interval` in config). That review is a forked agent thread that inspects the conversation and decides what to save. This skill is for **you** — the active agent — to run inline when you want:

- **Faster action** — the background thread runs asynchronously; inline reflection takes effect immediately
- **Richer context** — you have access to files, terminal, and tools the background fork doesn't
- **Nuanced judgment** — you can decide whether a finding belongs in memory, a skill patch, or a new skill
