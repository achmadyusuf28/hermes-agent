"""
Hermes Delegation Protocol — Phase 0

A structured, file-based protocol for parent-to-subagent communication.
Designed for background terminal workers that cannot access Hermes tools.

Protocol flow:
  1. Parent writes  _brief.json     (task spec)
  2. Worker reads   _brief.json     (understands the task)
  3. Worker appends _progress.jsonl (live updates while working)
  4. Parent writes  _correction.json(mid-flight course correction, optional)
  5. Worker writes  _result.json    (final deliverable)

Directory:  ~/.hermes/workspace/<task_id>/
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import asdict, dataclass, field
from typing import Literal, Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

WORKSPACE_DIR = os.path.expanduser("~/.hermes/workspace")

# File names
BRIEF_FILE = "_brief.json"
PROGRESS_FILE = "_progress.jsonl"
RESULT_FILE = "_result.json"
CORRECTION_FILE = "_correction.json"
STATE_FILE = "_state.json"

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

Verdict = Literal["FOUND", "NOT_FOUND", "INCONCLUSIVE", "BLOCKED"]
"""Outcome of the delegation task."""

ProgressType = Literal["finding", "dead_end", "shift", "checkpoint", "blocked", "correction_ack", "error"]
"""Type of progress event."""


@dataclass
class Evidence:
    """A piece of file-attributed evidence."""

    path: str
    """Absolute or relative file path."""
    detail: str = ""
    """Short excerpt, line reference, or description of what was found, 
    e.g. 'line 14: inputs.soup-nix.url = ...'."""


# ---------------------------------------------------------------------------
# Brief  — parent writes before spawning
# ---------------------------------------------------------------------------


@dataclass
class BriefEnvironment:
    """Snapshot of the parent's working context."""

    cwd: str
    """Working directory the worker should use."""
    last_error: Optional[str] = None
    """The most recent error message, if relevant."""
    files_touched: Optional[list[str]] = None
    """Files the parent has already examined."""


@dataclass
class DelegationBrief:
    """The task brief. Parent writes this; worker reads it on startup.

    Only `task_id`, `intent`, `acceptance`, and `environment.cwd` are
    required. Everything else is optional context the parent can supply
    to accelerate the worker's orientation.
    """

    task_id: str
    """Semantic task identifier, e.g. 'debug-nix-hermes-attribute'."""

    intent: str
    """One-line statement of what the parent is trying to achieve."""

    acceptance: str
    """Concrete description of what 'done' looks like."""

    environment: BriefEnvironment
    """Snapshot of the parent's working environment."""

    # ── Optional context ────────────────────────────────────────────────

    open_questions: Optional[list[str]] = None
    """Specific questions the parent needs answered."""

    hypothesis: Optional[str] = None
    """What the parent suspects the answer might be."""

    eliminated_paths: Optional[list[str]] = None
    """What the parent has already ruled out."""

    constraints: Optional[list[str]] = None
    """Guardrails — things the worker must NOT do."""


# ---------------------------------------------------------------------------
# Progress  — worker appends during work
# ---------------------------------------------------------------------------


@dataclass
class ProgressEntry:
    """A single progress event written by the worker."""

    ts: float
    """Unix timestamp of the event."""
    type: ProgressType
    """Category of event."""
    detail: str
    """Human-readable description of what happened."""
    evidence: Optional[list[Evidence]] = None
    """Optional file-attributed proof."""


# ---------------------------------------------------------------------------
# Correction  — parent writes mid-flight
# ---------------------------------------------------------------------------


@dataclass
class Correction:
    """Mid-flight course correction from parent to worker."""

    seq: int
    """Monotonically increasing sequence number. Worker skips if seq <= last seen."""
    message: str
    """The correction or new direction."""
    new_hypothesis: Optional[str] = None
    """Updated hypothesis, if the parent has one."""


# ---------------------------------------------------------------------------
# Result  — worker writes on completion
# ---------------------------------------------------------------------------


@dataclass
class DelegationResult:
    """Structured result written by the worker on completion."""

    task_id: str
    """Must match the `task_id` from the brief."""
    verdict: Verdict
    """Outcome of the task."""
    confidence: float
    """The worker's confidence in the result (0.0 — 1.0)."""
    evidence: list[Evidence]
    """All evidence supporting the verdict."""

    remaining_uncertainty: Optional[str] = None
    """What is still unknown or unverified."""
    recommendation: Optional[str] = None
    """Suggested next action, if any."""
    files_touched: Optional[list[str]] = None
    """Files the worker read or wrote."""


# ---------------------------------------------------------------------------
# Task directory helpers
# ---------------------------------------------------------------------------


def _ensure_dir(task_dir: str) -> str:
    os.makedirs(task_dir, exist_ok=True)
    return task_dir


def task_dir(task_id: str) -> str:
    """Return the workspace directory for a given task_id."""
    return os.path.join(WORKSPACE_DIR, task_id)


# ---------------------------------------------------------------------------
# I/O helpers — brief
# ---------------------------------------------------------------------------


def write_brief(task_dir: str, brief: DelegationBrief) -> str:
    """Write a brief to disk. Returns the file path."""
    _ensure_dir(task_dir)
    path = os.path.join(task_dir, BRIEF_FILE)
    with open(path, "w") as f:
        json.dump(asdict(brief), f, indent=2, default=str)
    return path


def read_brief(task_dir: str) -> DelegationBrief:
    """Read a brief from disk."""
    path = os.path.join(task_dir, BRIEF_FILE)
    with open(path) as f:
        data = json.load(f)
    env = BriefEnvironment(**data["environment"])
    return DelegationBrief(
        task_id=data["task_id"],
        intent=data["intent"],
        acceptance=data["acceptance"],
        environment=env,
        open_questions=data.get("open_questions"),
        hypothesis=data.get("hypothesis"),
        eliminated_paths=data.get("eliminated_paths"),
        constraints=data.get("constraints"),
    )


# ---------------------------------------------------------------------------
# I/O helpers — progress
# ---------------------------------------------------------------------------


def append_progress(task_dir: str, entry: ProgressEntry) -> str:
    """Append a progress entry. Returns the file path."""
    _ensure_dir(task_dir)
    path = os.path.join(task_dir, PROGRESS_FILE)
    with open(path, "a") as f:
        f.write(json.dumps(asdict(entry), default=str) + "\n")
    return path


def read_progress(task_dir: str) -> list[ProgressEntry]:
    """Read all progress entries from disk."""
    path = os.path.join(task_dir, PROGRESS_FILE)
    if not os.path.exists(path):
        return []
    entries = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                data = json.loads(line)
                ev_list = (
                    [Evidence(**e) for e in data["evidence"]]
                    if data.get("evidence")
                    else None
                )
                entries.append(
                    ProgressEntry(
                        ts=data["ts"],
                        type=data["type"],
                        detail=data["detail"],
                        evidence=ev_list,
                    )
                )
    return entries


# ---------------------------------------------------------------------------
# I/O helpers — correction
# ---------------------------------------------------------------------------


def write_correction(task_dir: str, correction: Correction) -> str:
    """Write a mid-flight correction. Returns the file path."""
    _ensure_dir(task_dir)
    path = os.path.join(task_dir, CORRECTION_FILE)
    with open(path, "w") as f:
        json.dump(asdict(correction), f, indent=2, default=str)
    return path


def read_correction(task_dir: str) -> Optional[Correction]:
    """Read the latest correction, or None."""
    path = os.path.join(task_dir, CORRECTION_FILE)
    if not os.path.exists(path):
        return None
    with open(path) as f:
        data = json.load(f)
    return Correction(
        seq=data["seq"],
        message=data["message"],
        new_hypothesis=data.get("new_hypothesis"),
    )


# ---------------------------------------------------------------------------
# I/O helpers — result
# ---------------------------------------------------------------------------


def write_result(task_dir: str, result: DelegationResult) -> str:
    """Write the final result. Returns the file path."""
    _ensure_dir(task_dir)
    path = os.path.join(task_dir, RESULT_FILE)
    with open(path, "w") as f:
        json.dump(asdict(result), f, indent=2, default=str)
    return path


def read_result(task_dir: str) -> Optional[DelegationResult]:
    """Read the final result, or None if not yet written."""
    path = os.path.join(task_dir, RESULT_FILE)
    if not os.path.exists(path):
        return None
    with open(path) as f:
        data = json.load(f)
    # Flexible parsing: accept both strict protocol schema and free-form
    task_id = data.get("task_id", os.path.basename(os.path.dirname(path)))
    if "verdict" in data:
        ev_list = [Evidence(**e) for e in data["evidence"]]
        return DelegationResult(
            task_id=task_id,
            verdict=data["verdict"],
            confidence=data["confidence"],
            evidence=ev_list,
            remaining_uncertainty=data.get("remaining_uncertainty"),
            recommendation=data.get("recommendation"),
            files_touched=data.get("files_touched"),
        )
    else:
        # Free-form: wrap the whole payload as one evidence entry
        summary = data.get("summary", data.get("description", str(data)[:200]))
        return DelegationResult(
            task_id=task_id,
            verdict="FOUND",
            confidence=1.0,
            evidence=[Evidence(
                path=str(data.get("project", "unknown")),
                detail=summary,
            )],
            recommendation=data.get("conclusion", None),
            files_touched=[],
        )
