"""
Task management handlers — tasks::* CRUD on iii-state.

Ported from the original hermes-worker.py. Tasks are stored durably in
iii-state under ``scope=tasks``. This module provides the full CRUD lifecycle
plus workflow-state triggers for the Symphony pipeline.
"""
from __future__ import annotations

import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any

log = logging.getLogger(__name__)

# ── iii-state helpers ───────────────────────────────────────────────────

# Workflow states that should trigger symphony reconciliation
TRIGGER_STATES = {"todo", "in_progress", "rework", "plan_approved", "done"}

PENDING_INVOCATIONS: dict[str, Any] = {}


def _is_symphony_state(state: str) -> bool:
    """Check if a workflow state is relevant to the symphony pipeline."""
    pipeline_states = {
        "todo", "in_progress", "rework", "plan_approved",
        "pending_approval", "plan_revise", "plan_rejected",
        "gathering", "planning", "review", "completed",
    }
    return state in pipeline_states


async def _notify_symphony(ws, task_id: str, workflow_state: str, title: str) -> None:
    """Invoke symphony::pick directly via the engine to trigger task processing.

    Falls back gracefully if the function is not registered.
    """
    import asyncio
    inv_id = str(uuid.uuid4())
    future = asyncio.get_event_loop().create_future()
    PENDING_INVOCATIONS[inv_id] = future
    await ws.send(json.dumps({
        "type": "invokefunction",
        "function_id": "symphony::pick",
        "invocation_id": inv_id,
        "data": {
            "event": "reconciled",
            "task_id": task_id,
            "workflow_state": workflow_state,
            "title": (title or "")[:100],
            "timestamp": _iso_now(),
        },
    }))
    # Fire-and-forget: don't wait for result (avoid blocking the task update)
    PENDING_INVOCATIONS.pop(inv_id, None)


async def _cascade_dependents(ws, completed_task_id: str) -> int:
    """Check if any tasks depend on this one, and auto-start them.

    Looks for tasks in 'todo' state whose 'depends_on' list includes
    completed_task_id. If found, sets them to 'in_progress'.
    Returns the number of tasks cascaded.
    """
    import asyncio
    # Fetch all tasks in todo/pending_approval states
    result = await _state_list(ws, "tasks")
    entries = result if isinstance(result, list) else []
    cascaded = 0
    for entry in entries:
        task = None
        if isinstance(entry, dict):
            if "title" in entry or "id" in entry:
                task = entry
            else:
                key_str = entry.get("key", "")
                if key_str:
                    task = await _state_get(ws, "tasks", key_str)
        else:
            task = await _state_get(ws, "tasks", str(entry))

        if not task or not isinstance(task, dict):
            continue

        deps = task.get("depends_on", [])
        if not isinstance(deps, list):
            deps = []
        if completed_task_id not in deps:
            continue

        wf = task.get("workflow_state", "")
        if wf in ("todo", "pending_approval"):
            task["workflow_state"] = "in_progress"
            task["updated_at"] = _iso_now()
            await _state_set(ws, "tasks", task["id"], task)
            await _notify_symphony(ws, task["id"], "in_progress", task.get("title", ""))
            cascaded += 1
            log.info("cascade: task %s (%s) auto-started (depends on %s)",
                     task["id"][:16], task.get("title", "")[:40], completed_task_id[:16])
    return cascaded


async def _state_set(ws, scope: str, key: str, value: dict) -> dict:
    """Invoke state::set on the iii engine and wait for the result."""
    import asyncio
    inv_id = str(uuid.uuid4())
    future = asyncio.get_event_loop().create_future()
    PENDING_INVOCATIONS[inv_id] = future
    await ws.send(json.dumps({
        "type": "invokefunction",
        "function_id": "state::set",
        "invocation_id": inv_id,
        "data": {"scope": scope, "key": key, "value": value},
    }))
    try:
        result = await asyncio.wait_for(future, timeout=30)
        return result or {"stored": True, "scope": scope, "key": key}
    except asyncio.TimeoutError:
        log.warning("state::set timed out for %s/%s", scope, key)
        return {"stored": False, "error": "timeout"}
    finally:
        PENDING_INVOCATIONS.pop(inv_id, None)


async def _state_get(ws, scope: str, key: str) -> dict | None:
    """Invoke state::get and return the value."""
    import asyncio
    inv_id = str(uuid.uuid4())
    future = asyncio.get_event_loop().create_future()
    PENDING_INVOCATIONS[inv_id] = future
    await ws.send(json.dumps({
        "type": "invokefunction",
        "function_id": "state::get",
        "invocation_id": inv_id,
        "data": {"scope": scope, "key": key},
    }))
    try:
        result = await asyncio.wait_for(future, timeout=30)
        if isinstance(result, dict) and "error" in result and "not found" in str(result.get("error", "")).lower():
            return None
        if isinstance(result, str):
            return json.loads(result)
        return result
    except asyncio.TimeoutError:
        return None
    finally:
        PENDING_INVOCATIONS.pop(inv_id, None)


async def _state_list(ws, scope: str) -> list[dict]:
    """List all keys under a scope via state::list."""
    import asyncio
    inv_id = str(uuid.uuid4())
    future = asyncio.get_event_loop().create_future()
    PENDING_INVOCATIONS[inv_id] = future
    await ws.send(json.dumps({
        "type": "invokefunction",
        "function_id": "state::list",
        "invocation_id": inv_id,
        "data": {"scope": scope},
    }))
    try:
        result = await asyncio.wait_for(future, timeout=30)
        if isinstance(result, list):
            return result
        if isinstance(result, str):
            return json.loads(result)
        if isinstance(result, dict) and "keys" in result:
            return result["keys"]
        return []
    except (asyncio.TimeoutError, json.JSONDecodeError):
        return []
    finally:
        PENDING_INVOCATIONS.pop(inv_id, None)


# ── Task CRUD ───────────────────────────────────────────────────────────

async def handle_tasks_create(ws, data: dict) -> dict:
    """Create a new task in iii-state."""
    title = (data.get("title") or "").strip()
    if not title:
        return {"error": "title is required"}

    task_id = f"task_{uuid.uuid4().hex[:12]}"
    now = _iso_now()
    task = {
        "id": task_id,
        "title": title,
        "description": (data.get("description") or "").strip(),
        "status": data.get("status", "todo"),
        "priority": data.get("priority", "medium"),
        "assignee": data.get("assignee", ""),
        "project": data.get("project", ""),
        "tags": data.get("tags", []),
        "created_at": now,
        "updated_at": now,
        "completed_at": None,
        "workpad": [],
    }
    # Merge extra fields
    for key, val in data.items():
        if key not in task:
            task[key] = val

    await _state_set(ws, "tasks", task_id, task)
    return {"task": task}


async def handle_tasks_list(ws, data: dict) -> dict:
    """List/filter tasks from iii-state."""
    tasks = []
    entries = await _state_list(ws, "tasks")
    if isinstance(entries, list):
        for entry in entries:
            # state::list may return full task objects directly, OR
            # {key: ..., ...} key wrappers, OR plain key strings.
            if isinstance(entry, dict):
                if "title" in entry or "id" in entry:
                    # Full task object already — use directly
                    tasks.append(entry)
                else:
                    key_str = entry.get("key", "")
                    if not key_str:
                        continue
                    task_data = await _state_get(ws, "tasks", key_str)
                    if task_data and isinstance(task_data, dict) and "title" in task_data:
                        tasks.append(task_data)
            else:
                key_str = str(entry)
                if not key_str:
                    continue
                task_data = await _state_get(ws, "tasks", key_str)
                if task_data and isinstance(task_data, dict) and "title" in task_data:
                    tasks.append(task_data)

    # Filter
    status_filter = data.get("status", "")
    if status_filter:
        tasks = [t for t in tasks if t.get("status") == status_filter]
    project = data.get("project", "")
    if project:
        tasks = [t for t in tasks if t.get("project") == project]
    assignee = data.get("assignee", "")
    if assignee:
        tasks = [t for t in tasks if t.get("assignee") == assignee]

    # Sort by updated_at descending
    tasks.sort(key=lambda t: t.get("updated_at", ""), reverse=True)

    return {"tasks": tasks, "total": len(tasks)}


async def handle_tasks_get(ws, data: dict) -> dict:
    """Get a task by ID."""
    task_id = (data.get("task_id") or data.get("id") or "").strip()
    if not task_id:
        return {"error": "task_id is required"}
    task = await _state_get(ws, "tasks", task_id)
    if not task:
        return {"error": f"task {task_id} not found"}
    return {"task": task}


async def handle_tasks_update(ws, data: dict) -> dict:
    """Update a task."""
    task_id = (data.get("task_id") or data.get("id") or "").strip()
    if not task_id:
        return {"error": "task_id is required"}

    task = await _state_get(ws, "tasks", task_id)
    if not task:
        return {"error": f"task {task_id} not found"}

    old_wf = task.get("workflow_state", "")

    # Apply updates
    for key in ("title", "description", "status", "priority", "assignee", "project", "tags", "workflow_state", "phase"):
        if key in data:
            task[key] = data[key]

    task["updated_at"] = _iso_now()
    if task.get("status") in ("done", "completed", "cancelled"):
        task["completed_at"] = _iso_now()

    await _state_set(ws, "tasks", task_id, task)

    new_wf = task.get("workflow_state", "")

    # Fire-and-forget: notify symphony for pipeline-relevant transitions
    if new_wf in TRIGGER_STATES and new_wf != old_wf:
        import asyncio
        asyncio.create_task(_notify_symphony(ws, task_id, new_wf, task.get("title", "")))

    # Cascade: when a task is done, auto-start dependents
    if new_wf == "done" and old_wf != "done":
        import asyncio
        asyncio.create_task(_cascade_dependents(ws, task_id))

    return {"task": task}


async def handle_tasks_delete(ws, data: dict) -> dict:
    """Soft-delete a task (marks as cancelled)."""
    task_id = (data.get("task_id") or data.get("id") or "").strip()
    if not task_id:
        return {"error": "task_id is required"}
    task = await _state_get(ws, "tasks", task_id)
    if not task:
        return {"error": f"task {task_id} not found"}
    task["status"] = "cancelled"
    task["updated_at"] = _iso_now()
    task["completed_at"] = _iso_now()
    await _state_set(ws, "tasks", task_id, task)
    return {"deleted": True, "task_id": task_id}


async def handle_tasks_backlog(ws, data: dict) -> dict:
    """Compact open-task summary for session context."""
    result = await handle_tasks_list(ws, {"status": ""})
    all_tasks = result.get("tasks", [])
    open_tasks = [t for t in all_tasks if t.get("status") not in ("done", "cancelled", "completed")]
    return {
        "backlog": [{"id": t["id"], "title": t["title"][:100],
                      "status": t.get("status", ""),
                      "priority": t.get("priority", "medium")}
                     for t in open_tasks],
        "total": len(open_tasks),
    }


async def handle_tasks_append_note(ws, data: dict) -> dict:
    """Append a note/workpad entry to a task."""
    task_id = (data.get("task_id") or data.get("id") or "").strip()
    note = (data.get("note") or data.get("content") or "").strip()
    if not task_id or not note:
        return {"error": "task_id and note are required"}
    task = await _state_get(ws, "tasks", task_id)
    if not task:
        return {"error": f"task {task_id} not found"}
    workpad = task.get("workpad", [])
    if not isinstance(workpad, list):
        workpad = []
    workpad.append({
        "id": f"note_{uuid.uuid4().hex[:8]}",
        "content": note,
        "created_at": _iso_now(),
    })
    task["workpad"] = workpad
    task["updated_at"] = _iso_now()
    await _state_set(ws, "tasks", task_id, task)
    return {"task": task}


async def handle_tasks_get_workpad(ws, data: dict) -> dict:
    """Read the full workpad for a task."""
    task_id = (data.get("task_id") or data.get("id") or "").strip()
    if not task_id:
        return {"error": "task_id is required"}
    task = await _state_get(ws, "tasks", task_id)
    if not task:
        return {"error": f"task {task_id} not found"}
    return {"task_id": task_id, "workpad": task.get("workpad", [])}


async def handle_tasks_check_overdue(ws, data: dict) -> dict:
    """Check for overdue tasks (daily maintenance)."""
    result = await handle_tasks_list(ws, {"status": ""})
    tasks = result.get("tasks", [])
    now = _iso_now()
    overdue = []
    for t in tasks:
        due = t.get("due_date", "")
        if due and due < now and t.get("status") not in ("done", "cancelled", "completed"):
            overdue.append({"id": t["id"], "title": t["title"], "due_date": due})
    return {"overdue": overdue, "total": len(overdue)}


# ── Router ──────────────────────────────────────────────────────────────

TASKS_DISPATCH: dict[str, Any] = {
    "tasks::create": handle_tasks_create,
    "tasks::list": handle_tasks_list,
    "tasks::get": handle_tasks_get,
    "tasks::update": handle_tasks_update,
    "tasks::delete": handle_tasks_delete,
    "tasks::backlog": handle_tasks_backlog,
    "tasks::append-note": handle_tasks_append_note,
    "tasks::get-workpad": handle_tasks_get_workpad,
    "tasks::check-overdue": handle_tasks_check_overdue,
}


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()
