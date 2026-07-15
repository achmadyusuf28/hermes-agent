---
name: delegation-worker
description: "Structured delegation protocol for background workers. Load this skill when you're a subagent spawned with a TASK_DIR. It teaches you to read _brief.json, write _progress.jsonl, check _correction.json, and write _result.json."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [delegation, subagent, protocol, worker, structured]
    related_skills: [hermes-agent]
---

# Delegation Worker Protocol

You are operating in **structured delegation mode**. Follow the protocol below.

## Protocol overview

```
_parent_                          _worker_ (you)
  │                                   │
  │  writes _brief.json               │
  │ ───────────────────────────────►  │  reads brief
  │                                   │  ── works, step by step ──
  │  reads _progress.jsonl  ◄─────────│  appends progress per step
  │    (optional)                     │
  │  writes _correction.json  ──────► │  checks and adapts
  │          │                        │
  │          └── loop until done ─────│──
  │                                   │  └─ writes _result.json
  │  reads _result.json ◄────────────│  done
```

## Step-by-step

### 1. Start: read the brief

The `TASK_DIR` environment variable or context contains the path to your
workspace directory. Open `{TASK_DIR}/_brief.json` and read:

| Field | Purpose |
|---|---|
| `task_id` | Semantic ID for this work unit |
| `intent` | One-line goal — what the parent wants |
| `acceptance` | What "done" looks like, concretely |
| `environment.cwd` | Working directory to use |
| `hypothesis` (optional) | What the parent suspects |
| `open_questions` (optional) | Specific questions to answer |
| `eliminated_paths` (optional) | Already ruled out |
| `constraints` (optional) | Guardrails — things NOT to do |

**Before doing anything else**, change to `environment.cwd` and read the brief
fully. The brief is your single source of truth for this task.

### 2. Work: write progress

After every meaningful step — a finding, a dead end, a shift in focus, or
every ~5 tool calls — append a JSON line to `{TASK_DIR}/_progress.jsonl`.

Format:
```json
{"ts": 1747345678.23, "type": "finding", "detail": "Found X in file Y", "evidence": [{"path": "file.py:42", "detail": "relevant line"}]}
```

Event types:

| Type | When to use |
|---|---|
| `finding` | Discovered something useful |
| `dead_end` | A path that didn't pan out |
| `shift` | Changed focus or hypothesis |
| `checkpoint` | Major milestone reached |
| `blocked` | Hit a blocker, need intervention |
| `correction_ack` | Received and accepted a mid-flight correction |
| `error` | Something unexpected or wrong |

The `evidence` field is optional. Include file paths and snippets when you
can — the parent uses them to understand your reasoning without re-reading
everything you read.

### 3. Mid-flight: check for corrections

After each work step, check if `{TASK_DIR}/_correction.json` exists.

If it does, read it. It has:
```json
{"seq": 1, "message": "...", "new_hypothesis": "..."}
```

- If `seq > your_last_seen_seq`, the parent sent a new correction.
  Read the `message`, update your approach, and write a
  `correction_ack` progress entry.
- If `seq <= your_last_seen_seq`, you already handled this one. Skip it.

### 4. Done: write the result

When you have an answer (or hit an unrecoverable blocker), write
`{TASK_DIR}/_result.json`.

```json
{
  "task_id": "must-match-brief",
  "verdict": "FOUND",
  "confidence": 0.95,
  "evidence": [
    {"path": "file.py:42", "detail": "The function does X and Y"}
  ],
  "remaining_uncertainty": "Still unclear about Z",
  "recommendation": "Do this next",
  "files_touched": ["file.py", "config.yaml"]
}
```

Verdict options:

| Verdict | Meaning |
|---|---|
| `FOUND` | Found the answer to the parent's open question(s) |
| `NOT_FOUND` | Searched thoroughly, answer doesn't exist |
| `INCONCLUSIVE` | Unsure — evidence is ambiguous |
| `BLOCKED` | Can't proceed — missing credentials, permissions, etc. |

**Do NOT delete the workspace directory** — that's the parent's job.

### Guidelines

- **Write progress early and often.** A progress entry is cheap (one line of
  JSON) and invaluable if the parent wants to check in mid-flight.
- **Evidence is better than prose.** If you found something in a file, write
  the path and line. Don't make the parent guess where to look.
- **Blocked is not failure.** If you can't proceed, write result with
  `verdict: "BLOCKED"` and explain what's needed. That's an honest outcome.
- **Corrections are directional, not prescriptive.** The parent may say
  "try looking in modules/ai/". They're pointing, not spelling out each step.
  Use your judgment.
- **Your summary to the parent still matters.** The structured result is for
  machine parsing. Your final message (the one returned to the parent via
  delegate_task) should be a concise human-readable summary.
- **If no TASK_DIR is set**, you're in normal (unstructured) delegation mode.
  Ignore this protocol and work as normal.
