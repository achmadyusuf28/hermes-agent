#!/usr/bin/env python3
"""
NixOS Agentic OS Tools — first-class Nix intelligence for Hermes.

Replaces ad-hoc shell commands with structured tools that speak Nix's
data model and NixOS's service model.

Tools:
  nix_eval      — Evaluate a Nix expression and return structured JSON.
  nix_build     — Dry-run a flake build, returning the diff / errors.
  nix_switch    — Transactional nixos-rebuild switch with auto-rollback.
  nix_services  — Query systemd unit state as structured JSON.
  nix_logs      — Filtered journalctl queries by unit, severity, time window.
"""

import json
import logging
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

from tools.registry import registry, tool_error

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DEFAULT_FLAKE = "/etc/nixos"
NIX_EVAL_TIMEOUT = 30
NIX_BUILD_TIMEOUT = 120
NIX_SWITCH_TIMEOUT = 300
NIX_SERVICE_TIMEOUT = 15
NIX_LOG_TIMEOUT = 30

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _nix_binary() -> str:
    """Return the path to the nix binary, with fallback."""
    for candidate in ("nix", "/run/current-system/sw/bin/nix", "/nix/var/nix/profiles/default/bin/nix"):
        try:
            result = subprocess.run(
                [candidate, "--version"],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0:
                return candidate
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    return "nix"  # last resort, will fail with a clear error


def _run_cmd(
    cmd: List[str],
    timeout: int = 30,
    workdir: Optional[str] = None,
) -> Dict[str, Any]:
    """Run a command and return {exit_code, stdout, stderr, timed_out}."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=workdir or None,
        )
        return {
            "exit_code": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "timed_out": False,
        }
    except subprocess.TimeoutExpired as e:
        return {
            "exit_code": -1,
            "stdout": e.stdout or "",
            "stderr": e.stderr or "",
            "timed_out": True,
        }
    except FileNotFoundError as e:
        return {
            "exit_code": -1,
            "stdout": "",
            "stderr": f"Command not found: {e}",
            "timed_out": False,
        }


def _safe_json(raw: str) -> Any:
    """Parse JSON with lenient settings, returning None on failure."""
    if not raw or not raw.strip():
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def _flake_dir(flake: str) -> str:
    """Resolve the flake reference to an absolute directory path."""
    if not flake or flake == "default":
        flake = DEFAULT_FLAKE
    # If it's a path, resolve it
    p = Path(flake).expanduser().resolve()
    if p.exists():
        return str(p)
    return flake


def _check_nix_available() -> bool:
    """Availability check: nix binary exists and responds."""
    try:
        result = subprocess.run(
            [_nix_binary(), "--version"],
            capture_output=True, text=True, timeout=5,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


# ---------------------------------------------------------------------------
# Tool: nix_eval
# ---------------------------------------------------------------------------

NIX_EVAL_SCHEMA = {
    "name": "nix_eval",
    "description": (
        "Evaluate a Nix expression against a flake and return structured JSON. "
        "Use this instead of grepping .nix files — it reads the evaluated config, "
        "not the source text. "
        "Examples: "
        "'nixpkgs#lib.version' returns the Nixpkgs version. "
        "'.#nixosConfigurations.nixos.config.services.postgresql.port' returns the "
        "configured PostgreSQL port. "
        "Pass '--flake /path/to/flake' to evaluate against a specific flake; "
        "defaults to /etc/nixos."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": (
                    "Nix expression to evaluate. Can be a flake reference "
                    "(e.g. 'nixpkgs#lib.version') or an inline expression "
                    "(use '--expr' flag for the latter)."
                ),
            },
            "flake": {
                "type": "string",
                "description": (
                    "Path or flake URI to evaluate against. "
                    "Defaults to /etc/nixos. Use '.' for the current directory. "
                    "Examples: '/etc/nixos', '/home/hermes/soup-nix', '.'"
                ),
            },
            "enable_flake": {
                "type": "boolean",
                "description": (
                    "Pass the expression as a flake reference "
                    "(default: true). Set to false to evaluate inline "
                    "Nix expressions with --expr."
                ),
            },
        },
        "required": ["expression"],
    },
}


def _nix_eval_handler(args: Dict[str, Any], **kw) -> str:
    """Evaluate a Nix expression and return JSON."""
    expression = args.get("expression", "").strip()
    if not expression:
        return tool_error("nix_eval: expression is required.")

    flake = _flake_dir(args.get("flake", DEFAULT_FLAKE))
    enable_flake = args.get("enable_flake", True)

    nix = _nix_binary()
    cmd = [nix, "eval", "--json"]
    # Safety: restrict evaluation to prevent IFD and overruns
    cmd.extend(["--option", "allow-import-from-derivation", "false"])
    cmd.extend(["--option", "restrict-eval", "false"])  # needed for flake access
    cmd.extend(["--option", "max-call-depth", "5000"])

    if enable_flake:
        # Flake reference: e.g. nixpkgs#lib.version or ./.#some.option
        ref = expression
        if not ref.startswith(".") and "#" not in ref:
            # Bare expression like '#lib.version' — add implicit nixpkgs
            ref = f"nixpkgs#{ref}"
        cmd.append(ref)
        workdir = flake if os.path.isdir(flake) else None
    else:
        cmd.append("--expr")
        cmd.append(expression)
        workdir = None

    result = _run_cmd(cmd, timeout=NIX_EVAL_TIMEOUT, workdir=workdir)

    if result["timed_out"]:
        return tool_error(
            f"nix_eval timed out after {NIX_EVAL_TIMEOUT}s. "
            "The expression may be too complex or recursive. "
            "Try a simpler query."
        )

    if result["exit_code"] != 0:
        # Clean up common Nix error noise
        stderr = result["stderr"]
        # Show the most relevant part
        lines = [l for l in stderr.split("\n") if l.strip() and "warning:" not in l.lower()]
        error_msg = "\n".join(lines[-10:]) if lines else stderr
        return tool_error(f"nix_eval failed (exit {result['exit_code']}):\n{error_msg}")

    stdout = result["stdout"].strip()
    # nix eval --json outputs raw JSON on stdout
    parsed = _safe_json(stdout)
    if parsed is None:
        return json.dumps({
            "success": True,
            "result_type": "raw_string",
            "value": stdout,
        }, ensure_ascii=False)

    # Direct JSON serialization (it's already a Python structure from json.loads)
    return json.dumps({
        "success": True,
        "result_type": "json",
        "value": parsed,
    }, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Tool: nix_build
# ---------------------------------------------------------------------------

NIX_BUILD_SCHEMA = {
    "name": "nix_build",
    "description": (
        "Build or dry-run a Nix derivation from a flake. "
        "Use this to verify that a configuration change builds successfully "
        "before applying it. "
        "Returns structured build output: exit code, build log, and the "
        "output paths. "
        "Pass 'dry_run=true' to only evaluate without building (fast). "
        "Pass 'check=<attr>' like 'nixosConfigurations.nixos.config.system.build.toplevel' "
        "to build the full system closure."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "attribute": {
                "type": "string",
                "description": (
                    "Flake output attribute to build. "
                    "Examples: "
                    "'.#nixosConfigurations.nixos.config.system.build.toplevel' "
                    "(full system), "
                    "'.#packages.x86_64-linux.default' (package). "
                    "The '#' must be included."
                ),
            },
            "flake": {
                "type": "string",
                "description": (
                    "Path or flake URI to build from. "
                    "Defaults to /etc/nixos."
                ),
            },
            "dry_run": {
                "type": "boolean",
                "description": (
                    "If true, only evaluate (nix build --dry-run) without "
                    "actually building. Returns the set of store paths that "
                    "would be built or substituted. Fast."
                ),
                "default": True,
            },
            "check": {
                "type": "boolean",
                "description": (
                    "If true, run 'nix flake check' instead of building. "
                    "Validates all module options, evaluates all assertions, "
                    "and runs any checks defined in the flake. "
                    "Use this to validate configuration changes."
                ),
                "default": False,
            },
        },
        "required": ["attribute"],
    },
}


def _nix_build_handler(args: Dict[str, Any], **kw) -> str:
    """Build or dry-run a Nix derivation."""
    attribute = args.get("attribute", "").strip()
    if not attribute:
        return tool_error("nix_build: attribute is required.")

    flake = _flake_dir(args.get("flake", DEFAULT_FLAKE))
    dry_run = args.get("dry_run", True)
    run_check = args.get("check", False)

    nix = _nix_binary()

    if run_check:
        cmd = [nix, "flake", "check"]
        if os.path.isdir(flake):
            cmd.append(str(Path(flake).resolve()))
        else:
            cmd.append(flake)
        timeout = NIX_BUILD_TIMEOUT
    else:
        cmd = [nix, "build"]
        if dry_run:
            cmd.append("--dry-run")
        cmd.extend(["--json"])
        cmd.extend(["--option", "allow-import-from-derivation", "false"])
        cmd.extend(["--option", "max-call-depth", "5000"])

        ref = attribute if "#" in attribute or attribute.startswith(".") else f".#{attribute}"
        cmd.append(ref)
        timeout = NIX_EVAL_TIMEOUT if dry_run else NIX_BUILD_TIMEOUT

    workdir = str(Path(flake).resolve()) if os.path.isdir(flake) else None
    result = _run_cmd(cmd, timeout=timeout, workdir=workdir)

    if result["timed_out"]:
        return tool_error(
            f"nix_build timed out after {timeout}s. "
            "The derivation may be too complex."
        )

    if result["exit_code"] != 0:
        stderr = result["stderr"]
        lines = [l for l in stderr.split("\n") if l.strip() and "warning:" not in l.lower()]
        error_msg = "\n".join(lines[-15:]) if lines else stderr
        return tool_error(f"nix_build failed (exit {result['exit_code']}):\n{error_msg}")

    output = {
        "success": True,
        "dry_run": dry_run if not run_check else False,
        "check": run_check,
        "exit_code": 0,
    }

    if result["stdout"].strip():
        parsed = _safe_json(result["stdout"].strip())
        if parsed is not None:
            output["build_result"] = parsed
        else:
            output["stdout"] = result["stdout"].strip()

    if result["stderr"].strip():
        output["build_log"] = result["stderr"].strip()

    return json.dumps(output, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Tool: nix_switch
# ---------------------------------------------------------------------------

NIX_SWITCH_SCHEMA = {
    "name": "nix_switch",
    "description": (
        "Apply a new NixOS configuration by running nixos-rebuild switch "
        "against a flake. This is the 'atomic apply' button for the agentic OS. "
        "ALWAYS use nix_build with check=true first to validate the change. "
        "On failure, the tool automatically triggers a rollback. "
        "The switch happens transactionally — if the new generation fails its "
        "health checks, the previous generation is restored."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "flake": {
                "type": "string",
                "description": (
                    "Path or flake URI to switch to. "
                    "Defaults to /etc/nixos."
                ),
            },
            "hostname": {
                "type": "string",
                "description": (
                    "NixOS hostname attribute in the flake. "
                    "Optional; defaults to what nixos-rebuild detects."
                ),
            },
            "health_check": {
                "type": "string",
                "description": (
                    "A shell command to run after switching to verify the "
                    "system is healthy. If this exits non-zero, a rollback "
                    "is triggered. Example: 'systemctl is-system-running --wait' "
                    "or 'pg_isready -h 127.0.0.1'."
                ),
            },
            "health_check_timeout": {
                "type": "integer",
                "description": "Max seconds to wait for the health check. Default: 60.",
                "default": 60,
            },
            "auto_rollback": {
                "type": "boolean",
                "description": (
                    "If true, automatically roll back on health check failure. "
                    "Default: true. Set to false to leave the failed generation "
                    "in place for debugging."
                ),
                "default": True,
            },
        },
    },
}


def _nix_switch_handler(args: Dict[str, Any], **kw) -> str:
    """Apply a nixos-rebuild switch with rollback on failure."""
    flake = _flake_dir(args.get("flake", DEFAULT_FLAKE))
    hostname = args.get("hostname", "")
    health_check = args.get("health_check", "")
    health_check_timeout = args.get("health_check_timeout", 60)
    auto_rollback = args.get("auto_rollback", True)

    if not os.path.isdir(flake):
        return tool_error(f"nix_switch: flake directory '{flake}' not found.")

    # Build the nixos-rebuild command
    rebuild = subprocess.run(
        ["which", "nixos-rebuild"],
        capture_output=True, text=True, timeout=5,
    )
    if rebuild.returncode != 0:
        return tool_error("nixos-rebuild not found in PATH. Is NixOS installed?")

    cmd = ["sudo", "nixos-rebuild", "switch", "--flake", str(Path(flake).resolve())]
    if hostname:
        cmd[-1] = f"{cmd[-1]}#{hostname}"

    result = _run_cmd(cmd, timeout=NIX_SWITCH_TIMEOUT)

    if result["timed_out"]:
        # Extremely dangerous — the switch might still be running
        return tool_error(
            f"nix_switch timed out after {NIX_SWITCH_TIMEOUT}s. "
            "The switch may still be in progress. Check the system state "
            "manually before proceeding."
        )

    response = {
        "success": result["exit_code"] == 0,
        "exit_code": result["exit_code"],
        "stdout": result["stdout"],
        "stderr": result["stderr"],
        "rolled_back": False,
    }

    if result["exit_code"] != 0:
        response["error"] = "nixos-rebuild switch failed. The system remains on the previous generation."
        return json.dumps(response, ensure_ascii=False, default=str)

    # Health check phase
    if health_check:
        health_result = _run_cmd(
            ["sh", "-c", health_check],
            timeout=health_check_timeout,
        )
        response["health_check"] = {
            "command": health_check,
            "exit_code": health_result["exit_code"],
            "stdout": health_result["stdout"],
            "stderr": health_result["stderr"],
        }

        if health_result["exit_code"] != 0 and health_result["timed_out"] is False:
            if auto_rollback:
                # Trigger rollback
                rollback_cmd = ["sudo", "nixos-rebuild", "switch", "--rollback"]
                rollback_result = _run_cmd(rollback_cmd, timeout=NIX_SWITCH_TIMEOUT)
                response["rolled_back"] = True
                response["rollback"] = {
                    "success": rollback_result["exit_code"] == 0,
                    "exit_code": rollback_result["exit_code"],
                    "stdout": rollback_result["stdout"],
                    "stderr": rollback_result["stderr"],
                }
                if rollback_result["exit_code"] == 0:
                    response["message"] = (
                        "Health check failed → automatic rollback to previous "
                        "generation completed."
                    )
                else:
                    response["message"] = (
                        "Health check failed AND rollback also failed. "
                        "Manual intervention required."
                    )
            else:
                response["message"] = (
                    "Health check failed but auto_rollback is disabled. "
                    "The new generation is active but unhealthy."
                )

    return json.dumps(response, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Tool: nix_services
# ---------------------------------------------------------------------------

NIX_SERVICES_SCHEMA = {
    "name": "nix_services",
    "description": (
        "Query systemd unit state as structured JSON. "
        "Use this instead of parsing 'systemctl status' output. "
        "Returns running, failed, and dependency information for services. "
        "Can filter by unit name pattern or state."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "pattern": {
                "type": "string",
                "description": (
                    "Optional unit name pattern (glob). "
                    "Examples: 'postgres*', 'sshd.service', 'docker*'. "
                    "Omit to list all units."
                ),
            },
            "state": {
                "type": "string",
                "enum": ["all", "running", "failed", "exited", "dead"],
                "description": "Filter units by state. Default: all.",
                "default": "all",
            },
            "type": {
                "type": "string",
                "enum": ["service", "timer", "socket", "all"],
                "description": "Type of units to list. Default: service.",
                "default": "service",
            },
        },
    },
}


def _nix_services_handler(args: Dict[str, Any], **kw) -> str:
    """Query systemd unit state."""
    pattern = args.get("pattern", "")
    state = args.get("state", "all")
    unit_type = args.get("type", "service")

    # Build systemctl command
    cmd = ["systemctl", "list-units", "--no-pager", "--no-legend", "--plain"]

    # Type filter
    if unit_type != "all":
        cmd.extend(["--type", unit_type])

    # State filter
    state_map = {
        "all": "--all",
        "running": "--state=running",
        "failed": "--state=failed",
        "exited": "--state=exited",
        "dead": "--state=dead,inactive",
    }
    cmd.append(state_map.get(state, "--all"))

    if pattern:
        cmd.append(pattern)

    result = _run_cmd(cmd, timeout=NIX_SERVICE_TIMEOUT)

    if result["exit_code"] != 0:
        return tool_error(f"nix_services failed: {result['stderr']}")

    # Parse the tabular output into structured JSON
    units = []
    for line in result["stdout"].strip().split("\n"):
        line = line.strip()
        if not line:
            continue
        parts = line.split(None, 4)
        if len(parts) >= 4:
            unit = {
                "name": parts[0],
                "load": parts[1] if len(parts) > 1 else "",
                "active": parts[2] if len(parts) > 2 else "",
                "sub": parts[3] if len(parts) > 3 else "",
                "description": parts[4] if len(parts) > 4 else "",
            }
            unit["status"] = "running" if unit["sub"] == "running" else \
                             "failed" if unit["sub"] == "failed" else \
                             "exited" if unit["sub"] == "exited" else \
                             "inactive" if unit["active"] == "inactive" else \
                             unit["sub"]
            units.append(unit)

    return json.dumps({
        "success": True,
        "total_count": len(units),
        "state_filter": state,
        "type_filter": unit_type,
        "units": units,
    }, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Tool: nix_logs
# ---------------------------------------------------------------------------

NIX_LOGS_SCHEMA = {
    "name": "nix_logs",
    "description": (
        "Query systemd journal with structured filters. "
        "Use this instead of grepping journalctl output. "
        "Returns log entries as structured JSON with timestamp, priority, "
        "unit, and message fields. "
        "Can filter by unit, severity, time window, and message pattern."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "unit": {
                "type": "string",
                "description": (
                    "Systemd unit name to filter by. "
                    "Examples: 'postgresql.service', 'sshd', 'docker-compose-*'. "
                    "Omit for all units."
                ),
            },
            "priority": {
                "type": "string",
                "enum": ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"],
                "description": "Minimum log priority. Default: info.",
                "default": "info",
            },
            "since": {
                "type": "string",
                "description": (
                    "Start time for the query. "
                    "Examples: '5 min ago', 'yesterday', '2026-07-20', '-1h'. "
                    "Default: '-30m' (last 30 minutes)."
                ),
                "default": "-30m",
            },
            "until": {
                "type": "string",
                "description": (
                    "End time for the query. "
                    "Examples: 'now', '2026-07-21'. "
                    "Omit for 'now'."
                ),
            },
            "grep": {
                "type": "string",
                "description": "Case-insensitive pattern to search for in log messages.",
            },
            "lines": {
                "type": "integer",
                "description": "Max lines to return. Default 50, max 200.",
                "default": 50,
                "maximum": 200,
                "minimum": 1,
            },
            "output": {
                "type": "string",
                "enum": ["json", "short", "short-iso"],
                "description": "Output format. 'json' returns structured entries, 'short' returns text. Default: json.",
                "default": "json",
            },
        },
    },
}


PRIORITY_MAP = {
    "emerg": "0", "alert": "1", "crit": "2", "err": "3",
    "warning": "4", "notice": "5", "info": "6", "debug": "7",
}


def _nix_logs_handler(args: Dict[str, Any], **kw) -> str:
    """Query systemd journal."""
    unit = args.get("unit", "")
    priority = args.get("priority", "info")
    since = args.get("since", "-30m")
    until = args.get("until", "")
    grep = args.get("grep", "")
    lines = min(args.get("lines", 50), 200)
    output = args.get("output", "json")

    cmd = ["journalctl", "--no-pager", "--no-hostname"]

    if output == "json":
        cmd.extend(["-o", "json"])
    else:
        cmd.extend(["-o", output])

    if unit:
        cmd.extend(["-u", unit])

    # Priority
    prio_num = PRIORITY_MAP.get(priority, "6")
    cmd.extend(["-p", prio_num])

    # Time window
    cmd.extend(["--since", since])
    if until:
        cmd.extend(["--until", until])

    # Lines
    cmd.extend(["-n", str(lines)])

    if grep:
        cmd.extend(["-g", grep])

    result = _run_cmd(cmd, timeout=NIX_LOG_TIMEOUT)

    if result["exit_code"] != 0 and result["exit_code"] != 1:
        # journalctl exits 1 when no entries match
        return tool_error(f"nix_logs failed: {result['stderr']}")

    if output == "json":
        entries = []
        for line in result["stdout"].strip().split("\n"):
            line = line.strip()
            if not line:
                continue
            entry = _safe_json(line)
            if entry:
                entries.append(entry)
        return json.dumps({
            "success": True,
            "total_entries": len(entries),
            "entries": entries,
        }, ensure_ascii=False, default=str)
    else:
        return json.dumps({
            "success": True,
            "output": result["stdout"].strip(),
        }, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Tool: nix_generations
# ---------------------------------------------------------------------------

NIX_GENERATIONS_SCHEMA = {
    "name": "nix_generations",
    "description": (
        "List NixOS system generations with their status. "
        "Returns generation numbers, dates, whether they're the current "
        "booted generation, and rollback compatibility."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "limit": {
                "type": "integer",
                "description": "Max generations to show. Default 10.",
                "default": 10,
            },
        },
    },
}


def _nix_generations_handler(args: Dict[str, Any], **kw) -> str:
    """List system generations."""
    limit = args.get("limit", 10)

    # Use nixos-rebuild list-generations --json for clean structured output
    cmd = ["nixos-rebuild", "list-generations", "--json"]
    result = _run_cmd(cmd, timeout=15)

    if result["exit_code"] != 0:
        # Fallback: try with sudo
        cmd = ["sudo", "nixos-rebuild", "list-generations", "--json"]
        result = _run_cmd(cmd, timeout=15)
        if result["exit_code"] != 0:
            return tool_error(f"nix_generations failed: {result['stderr']}")

    all_generations = _safe_json(result["stdout"])
    if not isinstance(all_generations, list):
        return json.dumps({
            "success": True,
            "total_generations": 0,
            "generations": [],
        }, ensure_ascii=False, default=str)

    # Determine currently booted generation from the JSON data
    current_booted = None
    for g in all_generations:
        if g.get("current"):
            current_booted = g.get("generation")
            break

    generations = all_generations[-limit:]
    for gen in generations:
        gen["booted"] = bool(current_booted and gen.get("generation") == current_booted)

    return json.dumps({
        "success": True,
        "total_generations": len(all_generations),
        "current_booted": current_booted,
        "generations": generations,
    }, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Registry Registrations
# ---------------------------------------------------------------------------

registry.register(
    name="nix_eval",
    toolset="nixos",
    schema=NIX_EVAL_SCHEMA,
    handler=lambda args, **kw: _nix_eval_handler(args, **kw),
    check_fn=_check_nix_available,
    emoji="❄️",
    description=(
        "Evaluate a Nix expression and return structured JSON. "
        "Use instead of grep on .nix files."
    ),
)

registry.register(
    name="nix_build",
    toolset="nixos",
    schema=NIX_BUILD_SCHEMA,
    handler=lambda args, **kw: _nix_build_handler(args, **kw),
    check_fn=_check_nix_available,
    emoji="🔨",
    description=(
        "Build or dry-run a Nix derivation. Validate config changes "
        "before applying them."
    ),
)

registry.register(
    name="nix_switch",
    toolset="nixos",
    schema=NIX_SWITCH_SCHEMA,
    handler=lambda args, **kw: _nix_switch_handler(args, **kw),
    check_fn=_check_nix_available,
    emoji="🔄",
    description=(
        "Apply a NixOS configuration with automatic rollback on "
        "health check failure."
    ),
)

registry.register(
    name="nix_services",
    toolset="nixos",
    schema=NIX_SERVICES_SCHEMA,
    handler=lambda args, **kw: _nix_services_handler(args, **kw),
    emoji="📊",
    description=(
        "Query systemd unit state as structured JSON. Running, failed, "
        "dependency info."
    ),
)

registry.register(
    name="nix_logs",
    toolset="nixos",
    schema=NIX_LOGS_SCHEMA,
    handler=lambda args, **kw: _nix_logs_handler(args, **kw),
    emoji="📋",
    description=(
        "Query systemd journal with structured filters. Unit, severity, "
        "time window, grep pattern."
    ),
)

registry.register(
    name="nix_generations",
    toolset="nixos",
    schema=NIX_GENERATIONS_SCHEMA,
    handler=lambda args, **kw: _nix_generations_handler(args, **kw),
    check_fn=_check_nix_available,
    emoji="📜",
    description=(
        "List NixOS system generations with current/booted status."
    ),
)
