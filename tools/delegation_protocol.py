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

Artifact lines (inspired by Fable Method):
  - The worker's final summary MUST start with an artifact line
  - RESULT:    task completed, _result.json written
  - BLOCKED:   task hit a blocker
  - PENDING:   task completed but a follow-up needs user authorization

Fable Method patterns integrated:
  - Artifact gates: forced lines in final summary (RESULT/BLOCKED/PENDING)
  - TWINS check: cross-search for duplicate findings (optional in result)
  - Adversarial judge: second pass that attempts to refute a result
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import asdict, dataclass, field
from typing import Any, Literal, Optional

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
JUDGE_FILE = "_judge.json"

# Artifact line prefixes (inspired by Fable Method's INTENT/AUTH/TWINS/PENDING)
# The subagent's final summary MUST start with one of these.
ARTIFACT_RESULT = "RESULT:"
"""Task completed successfully; _result.json was written."""
ARTIFACT_BLOCKED = "BLOCKED:"
"""Task hit an unrecoverable blocker."""
ARTIFACT_PENDING = "PENDING:"
"""Task completed but a follow-up action needs user authorization."""

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


@dataclass
class TwinCheck:
    """TWINS check record — inspired by Fable Method's twin check.

    A bug or pattern found in one place must be searched for across the
    whole project. This dataclass captures what was searched and what was
    found.
    """

    pattern: str
    """The exact pattern, construct, or expression that was searched for."""

    sites_found: list[str]
    """List of file paths (with line numbers) where the pattern was found,
    or empty list if none."""

    action_taken: str = "listed"
    """What the worker did with the twin sites. One of: 'listed', 'fixed', 
    'reported', 'none_needed'."""


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
    """Structured result written by the worker on completion.

    Includes Fable Method-inspired fields:
    - `twin_check`: records cross-search for duplicate findings
    - `pending_action`: records a follow-up that needs user authorization
    """

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

    # Fable Method-inspired extensions
    twin_check: Optional[TwinCheck] = None
    """TWINS check — did the worker search for identical patterns elsewhere?"""
    pending_action: Optional[str] = None
    """PENDING action — a follow-up that needs user authorization before it
    can be taken (e.g., deploy, push, restart, send). Corresponds to the
    PENDING artifact line in the summary."""


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
        twin = None
        if "twin_check" in data and data["twin_check"]:
            tc = data["twin_check"]
            twin = TwinCheck(
                pattern=tc["pattern"],
                sites_found=tc["sites_found"],
                action_taken=tc.get("action_taken", "listed"),
            )
        return DelegationResult(
            task_id=task_id,
            verdict=data["verdict"],
            confidence=data["confidence"],
            evidence=ev_list,
            remaining_uncertainty=data.get("remaining_uncertainty"),
            recommendation=data.get("recommendation"),
            files_touched=data.get("files_touched"),
            twin_check=twin,
            pending_action=data.get("pending_action"),
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


# ---------------------------------------------------------------------------
# Artifact line helpers  (inspired by Fable Method)
# ---------------------------------------------------------------------------


def validate_artifact_line(summary_text: str) -> tuple[str, str]:
    """Validate that a summary starts with a valid artifact line.

    Returns (prefix, rest_of_summary). Raises ValueError if no artifact
    line is found.
    """
    first_line = summary_text.strip().split("\n")[0]
    for prefix in (ARTIFACT_RESULT, ARTIFACT_BLOCKED, ARTIFACT_PENDING):
        if first_line.startswith(prefix):
            return prefix, summary_text[len(prefix):].strip()
    raise ValueError(
        f"Summary must start with one of: "
        f"{ARTIFACT_RESULT}, {ARTIFACT_BLOCKED}, or {ARTIFACT_PENDING}. "
        f"First line was: {first_line[:100]!r}"
    )


def format_artifact_line(prefix: str, task_dir_path: str, extra: str = "") -> str:
    """Format an artifact line for the subagent's final summary.

    Args:
        prefix: One of ARTIFACT_RESULT, ARTIFACT_BLOCKED, ARTIFACT_PENDING
        task_dir_path: Path to the task directory
        extra: Optional extra info (e.g. reason for BLOCKED, action for PENDING)

    Returns:
        The formatted artifact line, e.g.
        "RESULT: /home/hermes/.hermes/workspace/debug-x/_result.json"
        "BLOCKED: missing credentials"
        "PENDING: deploy to prod — awaiting your authorization"
    """
    if prefix == ARTIFACT_RESULT:
        return f"{prefix} {os.path.join(task_dir_path, RESULT_FILE)}"
    elif prefix == ARTIFACT_BLOCKED:
        return f"{prefix} {extra}" if extra else f"{prefix} unknown"
    elif prefix == ARTIFACT_PENDING:
        return f"{prefix} {extra} — awaiting your authorization" if extra else f"{prefix} unknown"
    return f"{prefix} {task_dir_path}"


# ---------------------------------------------------------------------------
# Adversarial Judge  (inspired by Fable Method's fable-judge)
# ---------------------------------------------------------------------------


@dataclass
class JudgeReport:
    """Report from an adversarial judge reviewing a completed task.

    The judge reads the worker's _result.json and tries to refute the
    findings. This catches verification theater: claims that sound right
    but aren't actually true.
    """

    task_id: str
    """Task being judged."""
    verdict: Literal["VERIFIED", "VERIFIED_WITH_CAVEATS", "REFUTED"]
    """Judge's overall verdict."""
    claims_checked: int
    """Number of claims in the original result that were checked."""
    claims_refuted: int
    """Number of claims that were successfully refuted."""
    refutations: list[str]
    """Specific refutations, one per refuted claim."""
    caveats: list[str]
    """Issues found that don't refute the work but should be noted."""
    recommendation: Optional[str] = None
    """What to do next if REFUTED or VERIFIED_WITH_CAVEATS."""


def judge_result(task_dir: str) -> Optional[JudgeReport]:
    """Read a judge report from disk, if one exists."""
    path = os.path.join(task_dir, JUDGE_FILE)
    if not os.path.exists(path):
        return None
    with open(path) as f:
        data = json.load(f)
    return JudgeReport(
        task_id=data["task_id"],
        verdict=data["verdict"],
        claims_checked=data["claims_checked"],
        claims_refuted=data["claims_refuted"],
        refutations=data.get("refutations", []),
        caveats=data.get("caveats", []),
        recommendation=data.get("recommendation"),
    )


def write_judge_report(task_dir: str, report: JudgeReport) -> str:
    """Write a judge report to disk. Returns the file path."""
    _ensure_dir(task_dir)
    path = os.path.join(task_dir, JUDGE_FILE)
    with open(path, "w") as f:
        json.dump(asdict(report), f, indent=2, default=str)
    return path


# ---------------------------------------------------------------------------
# Adversarial Judge — convenience helpers  (inspired by Fable Method)
# ---------------------------------------------------------------------------


def judge_goal(task_dir: str) -> str:
    """Generate the goal string for a judge subagent.

    The judge reads the worker's _result.json and tries to refute every
    claim. Use after the worker completes::

        result = read_result(td)
        if result:
            delegate_task(
                goal=judge_goal(td),
                context=judge_context(td),
            )

    Returns:
        Goal string for delegate_task.
    """
    result_path = os.path.join(task_dir, RESULT_FILE)
    judge_path = os.path.join(task_dir, JUDGE_FILE)
    return (
        f"Read the result at {result_path} and try to refute EVERY claim in it.\n\n"
        "You are an adversarial judge. Your stance is: a report is a set of claims, "
        "not evidence. Nothing is believed that was not observed.\n\n"
        "For each claim in the result:\n"
        "  1. Re-run the verification (read the file, check the output)\n"
        "  2. If it holds up, note it as VERIFIED\n"
        "  3. If it\'s wrong, incomplete, or unverifiable, record it as REFUTED\n\n"
        f"Write your verdict to {judge_path} with this structure:\n"
        "  - verdict: VERIFIED | VERIFIED_WITH_CAVEATS | REFUTED\n"
        "  - claims_checked: <int>\n"
        "  - claims_refuted: <int>\n"
        "  - refutations: [<string>, ...]\n"
        "  - caveats: [<string>, ...]\n"
        "  - recommendation: <string or null>\n\n"
        "Be harsh but honest. A REFUTED verdict with evidence is more valuable "
        "than a VERIFIED verdict with nothing checked."
    )


def judge_context(task_dir: str) -> str:
    """Generate the context string for a judge subagent.

    Args:
        task_dir: The task directory path.

    Returns:
        Context string for delegate_task.
    """
    return f"TASK_DIR: {task_dir}\nRole: adversarial judge"
