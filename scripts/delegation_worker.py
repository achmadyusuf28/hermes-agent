#!/usr/bin/env python3
"""
Hermes Delegation Worker — Phase 0

A template for background terminal workers that follow the Hermes Delegation
Protocol. Use this when you want automated investigation without an LLM.

Usage:
    TASK_DIR=~/.hermes/workspace/debug-nix-attribute python3 worker.py

The worker reads _brief.json, does the work, and writes _result.json with
structured findings. Progress is appended to _progress.jsonl as it works.

This is the "stateless automated worker" pattern — no LLM, no Hermes tools.
For LLM-based subagent delegation, use delegate_task + the delegation-worker skill.
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Protocol helpers (inline — no dependency on the Hermes codebase)
# ---------------------------------------------------------------------------

TASK_DIR = Path(os.environ.get("TASK_DIR", ""))
if not TASK_DIR.is_dir():
    print(f"FATAL: TASK_DIR is not a valid directory: {TASK_DIR}", file=sys.stderr)
    sys.exit(1)


def log_progress(event_type: str, detail: str, evidence: list | None = None):
    """Append a progress entry to _progress.jsonl."""
    entry = {
        "ts": time.time(),
        "type": event_type,
        "detail": detail,
    }
    if evidence:
        entry["evidence"] = evidence
    with open(TASK_DIR / "_progress.jsonl", "a") as f:
        f.write(json.dumps(entry) + "\n")


def write_result(
    verdict: str,
    confidence: float,
    evidence: list,
    *,
    remaining_uncertainty: str | None = None,
    recommendation: str | None = None,
    files_touched: list[str] | None = None,
):
    """Write the final _result.json."""
    # Read task_id from brief
    brief_path = TASK_DIR / "_brief.json"
    task_id = ""
    if brief_path.exists():
        with open(brief_path) as f:
            task_id = json.load(f).get("task_id", "")

    result = {
        "task_id": task_id,
        "verdict": verdict,
        "confidence": confidence,
        "evidence": evidence,
    }
    if remaining_uncertainty:
        result["remaining_uncertainty"] = remaining_uncertainty
    if recommendation:
        result["recommendation"] = recommendation
    if files_touched:
        result["files_touched"] = files_touched

    with open(TASK_DIR / "_result.json", "w") as f:
        json.dump(result, f, indent=2)

    print(f"\nDone — verdict: {verdict}, confidence: {confidence}")


# ---------------------------------------------------------------------------
# Work starts here
# ---------------------------------------------------------------------------

def main():
    # 1. Read the brief
    brief_path = TASK_DIR / "_brief.json"
    if not brief_path.exists():
        print(f"FATAL: _brief.json not found in {TASK_DIR}", file=sys.stderr)
        write_result("BLOCKED", 0.0, [], recommendation="Brief file not found")
        sys.exit(1)

    with open(brief_path) as f:
        brief = json.load(f)

    log_progress("checkpoint", f"Read brief: {brief.get('intent', '?')}")
    os.chdir(brief.get("environment", {}).get("cwd", "."))
    print(f"Intent: {brief['intent']}")
    print(f"Acceptance: {brief['acceptance']}")

    # 2. Do the work
    # ── TEMPLATE: Replace this section with your actual investigation ──
    #
    # Example: search for a pattern across files
    #   result = subprocess.run(
    #       ["grep", "-rn", some_pattern, "."],
    #       capture_output=True, text=True, timeout=60
    #   )
    #   log_progress("finding", f"Found matches in {len(result.stdout.splitlines())} files")
    #
    # The sections below are a working template. Customise for your task.

    log_progress("shift", "Beginning investigation", [{"path": brief_path.name, "snippet": f"intent: {brief['intent']}"}])

    # ── Example: run a command ───────────────────────────────────────────
    # Replace or extend this with the actual work the worker should do.
    try:
        # Example: check the working directory
        result = subprocess.run(
            ["pwd"],
            capture_output=True, text=True, timeout=10,
        )
        log_progress("finding", f"Working directory: {result.stdout.strip()}")

        # ── YOUR ACTUAL WORK HERE ─────────────────────────────────────────
        # Example: search for a specific pattern
        # questions = brief.get("open_questions", [])
        # for q in questions:
        #     print(f"  Investigating: {q}")
        #     # do the work...
        #     log_progress("finding", f"Answer: ...")

    except subprocess.TimeoutExpired:
        log_progress("error", "Command timed out")
        write_result("BLOCKED", 0.0, [], recommendation="Command timed out")
        return
    except Exception as e:
        log_progress("error", f"Unexpected error: {e}")
        write_result("BLOCKED", 0.0, [], recommendation=str(e))
        return

    # 3. Collect results and write the final result
    evidence = [
        {"path": "example.py", "detail": "Template result — replace with actual findings"}
    ]
    write_result(
        verdict="FOUND",
        confidence=0.8,
        evidence=evidence,
        remaining_uncertainty="Template — complete this section with actual uncertainty",
        recommendation="Review the findings and decide next steps",
        files_touched=[str(p) for p in Path.cwd().glob("*") if p.is_file()][:5],
    )


if __name__ == "__main__":
    main()
