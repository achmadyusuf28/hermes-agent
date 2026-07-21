# symphony-workers.nix — Auto-converted from Hermes skill
# Category: .archive
# Original: symphony-workers

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.symphony-workers;
in
{
  options.hermes.skills.symphony-workers = {
    enable = mkEnableOption "Reference for all Symphony pipeline workers — merged orchestrator (gather/plan/dispatch), approval gate, and judge. Updated for Phase 2 consolidation.";
  };

  config = mkIf cfg.enable {
    hermes.skills.symphony-workers = {
      enable = true;
  description = "Reference for all Symphony pipeline workers — merged orchestrator (gather/plan/dispatch), approval gate, and judge. Updated for Phase 2 consolidation.";
  triggers = [
  "symphony worker"
  "gatherer worker"
  "planner worker"
  "approval worker"
  "dispatcher worker"
  "judges worker"
  "symphony::pick"
  "rework loop"
  "sub-task execution"
  "symphony pipeline"
  "_symphony_pipeline"
  "execute-subtask"
  "publishevent"
  "auto-approval"
  "_should_auto_approve"
  "_checkpoint"
  "_retry_with_backoff"
  "_cascade_dependenrelated_skills:"
  "iii-workspace-workflow"
  "iii-engine-fundamentals"
];
  type = "knowledge";
  knowledge = ''
  # Symphony Workers Reference

> **🚫 DEPRECATED** — The symphony pipeline (orchestrator, approval gate, judges) has been fully removed from the system and replaced by `harness` + `console` workers. All systemd services stopped, Nix definitions removed. See `iii-engine-fundamentals` → `references/harness-deployment.md` for the live ecosystem setup.

## Architecture (Post-Phase 2): Merged Worker

**Phase 2 consolidated gatherer, planner, and dispatcher into a single process.** The gather/plan/dispatch logic lives in `_symphony_pipeline.py` and is called directly by `symphony-worker.py` — no cross-worker CLI subprocess, no separate systemd services.

| Worker | Systemd Service | Functions | Source |
|---|---|---|---|
| **Orchestrator (merged)** | `iii-symphony-worker` | `symphony::pick`, `symphony::reconcile`, `symphony::health` | `symphony-worker.py` + `_symphony_pipeline.py` |
| **Approval Gate** | `iii-approval-worker` | `approval::submit`, `approval::health` | `approval-worker.py` |
| **Judge + Merger** | `iii-judges-worker` | `judges::judge`, `judges::health` | `judges-worker.py` |

**Removed:** `iii-gatherer-worker`, `iii-planner-worker`, `iii-dispatcher-worker` — logic merged in-process.

All workers share:
- `workspaceModule` PYTHONPATH for workspace mirror/worktree management
- `pkgs.git` in PATH
- `SYMPHONY_WORKSPACE_ROOT` env var

### Pipeline Module (`_symphony_pipeline.py`)

The shared module at `modules/agents/hermes/workers/_symphony_pipeline.py` provides:

| Function | Role |
|---|---|
| `do_gather(ws, data)` | Repo analysis, mirror/worktree, LLM questioning, report storage |
| `do_plan(ws, data)` | Fetches gather report, LLM decomposition, validation, state storage |
| `do_dispatch(ws, data)` | Fetches plan, resolves deps, batched OpenCode execution, results aggregation |
| `call_hermes(ws, prompt, ...)` | LLM access via `hermes::ask` with retry + backoff |
| `_retry_with_backoff(fn, ...)` | Exponential backoff (3 attempts, 2s-30s jitter) |
| `_checkpoint(ws, task_id, phase, data)` | Phase-level state persistence for crash recovery |
| `_run_with_timeout(coro, timeout)` | Per-sub-task timeout enforcement |
| `iii_call(ws, fn_id, data)` | WebSocket engine invocation. **Must be patched to `trigger_iii_function` in `symphony-worker.py`** — the module's own `iii_call._pending` dict is never checked by the listen loop, causing all `hermes::ask` calls to silently time out. See `symphony-pipeline` skill for the fix. |

**Key design:** No CLI subprocess. `PYTHONPATH` must include `''${./workers}`. File uses underscores (iii engine convention). Must be git-committed (Nix flake source filter).

### Phase 3 Reliability

All in `_symphony_pipeline.py` + `modules/system/reliability.nix`:

| Feature | Code | What it does |
|---|---|---|
| Retry with backoff | `_retry_with_backoff()` | 3 attempts, 2x exp backoff + jitter, skips fatal errors |
| Checkpointing | `_checkpoint()` / `_load_checkpoint()` | Stores phase progress in state — crash restores |
| Per-task timeout | `_run_with_timeout()` | asyncio.wait_for with runner_config.timeout (default 300s) |
| Graceful degradation | `execute_batch()` | Failed sub-tasks = "failed" status, batch continues |
| Nix hardening | `reliability.nix` | Service presets, resource limits, health checks, OnFailure |

---

### Stream Trigger

The orchestrator is triggered by `invokefunction` to `symphony::pick` sent from `_notify_symphony()` in `tasks.py` whenever `tasks::update` changes `workflow_state` to a trigger state. **Not** via `publishevent` — the iii engine v0.20.0 does not support that message type. A 30s reconciliation cron is the safety net.

**Pitfall:** `symphony::pick` must be registered before `_notify_symphony` fires, or the engine silently drops the invocation. The reconciliation cron catches missed tasks within 30s.

---

## 1. Gatherer (merged → `_symphony_pipeline.py`)

Now `do_gather(ws, data)` inside the symphony worker. No separate systemd service.

### Architecture

```
do_gather receives {repo_name, repo_url, description, chat_id}
  │
  1. WorkspaceManager.ensure_mirror(repo_url)
  2. WorkspaceManager.create_task_workspace()
  3. hermes::ask × 2 (overview + task-specific)
  │
  4. If unclear_aspects: ask_user(chat_id, question, options) via Telegram
  │
  5. Build structured report
  6. state::set scope=symphony key=gather:<task_id>
  7. _checkpoint(ws, task_id, "gather_report_stored", ...)
  8. WorkspaceManager.remove_task_workspace()
```

### Key Design Decisions

- **Two-phase LLM analysis** — broad overview then task-specific
- **Max 3 questions, 10-minute timeout**

- **Report stored in state** — not workpad
- **Checkpoint after worktree creation and after analysis**

### Critical Pattern: No Bare File Paths to LLM

```python
snapshot = {"directory_tree": [], "files": {}, ...}
# Read file content, limit to 100 lines / 4000 chars per file
# Build prompt from snapshot content, NOT from path
```

### Source
- `_symphony_pipeline.py` — `do_gather()` (lines ~295-410)

---

## 2. Planner (merged → `_symphony_pipeline.py`)

Now `do_plan(ws, data)` inside the symphony worker.

### Architecture

```
do_plan receives {task_id, description, repo_name, repo_url, branch}
  │
  1. state::get gather:<task_id> → gather report
  2. Build planning prompt
  3. hermes::ask → LLM produces JSON (with _retry_with_backoff)
  4. Validate sub-tasks, inject repo/branch, add standard criteria
  5. state::set plan:<task_id> (status=plan_ready)
  6. _checkpoint(ws, task_id, "plan_stored", ...)
```

### LLM Prompt Design

- System prompt defines exact JSON schema for each sub-task
- Temperature 0.3, 240s timeout, retried on failure
- Injects `diff_scope` if missing from code sub-tasks

### Source
- `_symphony_pipeline.py` — `do_plan()` (lines ~550-680)

---

## 3. Approval Gate Worker (`iii-approval-worker`)

*Unchanged by Phase 2 — still a standalone worker.*

### Architecture

```
Main task (workflow_state="todo")
  ├── GATHER → PLAN → pending_approval
  ├── Human: ✅ Approve / 🔁 Revise / ❌ Reject / ⌛ Timeout (30min)
  │   • Approve → plan_approved → refinement (no re-gather/re-plan)
  │   • Revise → plan_revise → planner re-runs with feedback
  │   • Reject → plan_rejected (terminal)
  └── Review feedback loop:
      review → human types feedback → rework → agent re-runs → review
```

### Key States

| State | Next |
|---|---|
| `plan_ready` | Human approves, revises, or cancels |
| `plan_approved` | Dispatcher executes |
| `plan_revise` | Planner re-runs |
| `plan_rejected` | Terminal |
| `rework_needed` | Re-dispatch failed sub-tasks |

**Principle:** human touches outcome twice — authoring and final review.

### Source
- `workers/approval-worker.py`

---

## 4. Dispatcher (merged → `_symphony_pipeline.py`)

Now `do_dispatch(ws, data)` inside the symphony worker.

### Architecture

```
do_dispatch receives plan_approved plan
  │
  1. Fetch plan from state (with retry on miss)
  2. Kahn topological sort → parallel batches
  3. For each batch:
     ── OpenCode subprocess in git worktree
     ── Per-sub-task timeout from runner_config (default 300s)
     ── _checkpoint after each batch for crash recovery
  4. Aggregate — graceful degradation: partial = "partial" status
  5. Store results, _checkpoint_clear
```

### Sub-task Routing

| Type | Runner |
|---|---|
| `code` | `opencode run` in git worktree |
| `gather` | `hermes::delegate` |
| `research`/`analysis` | `hermes::delegate` or `hermes::ask` |

### Known Concurrency Issues (mitigated)

- **OpenCode SQLite crash** → separate `asyncio.Lock()` per OpenCode process

- **Per-repo mirror lock** — prevents TOCTOU races on `git clone --mirror`

### Config

| Env Var | Default |
|---|---|
| `SYMPHONY_MAX_CONCURRENT_AGENTS` | `8` |
| `SYMPHONY_WORKSPACE_ROOT` | `/symphony-workspaces` |

### Source
- `_symphony_pipeline.py` — `do_dispatch()` (lines ~730-850)

---

## 5. Judge + Merger Worker (`iii-judges-worker`)

*Unchanged by Phase 2 — still a standalone worker.*

Runs verification criteria (grep, grep_absent, compile, lint, diff_scope, diff_size, test, llm_synthesis) against sub-task results. Aggregates diffs, flags failures for rework (max 3 cycles).

### Workspace: Bare Mirror + Git Worktree

| Stage | Action |
|---|---|
| Mirror creation | `git clone --mirror <url>` |
| Worktree | `git worktree add --detach <path> <branch>` |
| Changes | `git diff HEAD` + `git ls-files --others` |
| Verification | Async criteria runner (manifest.py) |
| Cleanup | `git worktree remove --force` + rmdir |

**Bare mirror gotcha:** branches at `refs/heads/*`, NOT `refs/remotes/origin/*`.

### Source
- `workers/judges-worker.py`
  '';
  pitfalls = [
  ''
    **`path:` URI required as non-owner** — use `--flake "path:/path/to/flake#hostname"` to bypass git ownership checks- **Transient unit blocks rebuild** — `sudo systemctl stop nixos-rebuild-switch-to-configuration.service; sudo systemctl reset-failed; sudo systemctl daemon-reload`- **Shell redirects in ExecStart need `bash -c`** — systemd's ExecStart does NOT parse `>`, `|`, `||`, `&&`
  ''
  ''
    **Nix store staleness** — files referenced via `./path` are copied into the store at build time. Rebuild to pick up changes
  ''
];
    };
  };
}
