#!/usr/bin/env python3
"""
skill-to-nix.py — Convert Hermes markdown skills to Nix module files.

Reads all SKILL.md files from ~/.hermes/skills/ and generates NixOS module
files compatible with the hermes.skills option type, writing them to the
output directory (default: ./hermes-skills/).

Usage:
    python3 skill-to-nix.py [--output ./my-flake/modules/hermes/skills/] [--dry-run]

Inferring skill type:
  - tool:     contains code blocks with shell commands or tool invocations
  - workflow: contains numbered steps ("1. ...", "2. ...") or "## Steps" sections
  - knowledge: no commands, no steps — conceptual/descriptive content
  - meta:     references triage, quality checks, or self-evaluation
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# YAML frontmatter parsing (no dependency on PyYAML)
# ---------------------------------------------------------------------------

def parse_frontmatter(content: str) -> Tuple[Optional[Dict[str, Any]], str]:
    """Parse YAML-like frontmatter from a markdown file.

    Returns (frontmatter_dict, body_text). Returns ({}, content) if no
    frontmatter is found.
    """
    lines = content.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, content

    # Find closing ---
    end_idx = -1
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break

    if end_idx == -1:
        return {}, content

    fm_lines = lines[1:end_idx]
    body = "\n".join(lines[end_idx + 1:])

    # Simple YAML parser for common patterns
    result = {}
    current_key = None
    current_list = None
    current_dict = None

    for line in fm_lines:
        stripped = line.strip()

        # Comment
        if stripped.startswith("#"):
            continue

        # List item
        if stripped.startswith("- "):
            value = stripped[2:].strip().strip('"').strip("'")
            if current_list is not None:
                current_list.append(value)
            elif current_dict is not None:
                # Inline dict item like: tags: [a, b]
                pass
            continue

        # Key: value
        match = re.match(r'^(\w[\w_-]*)\s*:\s*(.*)', stripped)
        if match:
            key = match.group(1)
            value = match.group(2).strip()

            if key in ("metadata",):
                # Start nested dict
                current_dict = {}
                result[key] = current_dict
                continue

            if value == "":
                # Start a list
                current_list = []
                result[key] = current_list
                continue

            # Parse value
            if value.lower() == "true":
                result[key] = True
            elif value.lower() == "false":
                result[key] = False
            elif value.startswith("[") and value.endswith("]"):
                # Inline list
                items = []
                inner = value[1:-1]
                for item in re.findall(r"""["']([^"']*)["']|(\w+)""", inner):
                    items.append(item[0] or item[1])
                result[key] = items
            elif value.startswith('"') and value.endswith('"'):
                result[key] = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                result[key] = value[1:-1]
            else:
                result[key] = value

            current_key = key
            current_list = None
            continue

        # Indented key under metadata
        if stripped and current_dict is not None:
            indent_match = re.match(r'^(\s+)(\w[\w_-]*)\s*:\s*(.*)', line)
            if indent_match:
                sub_key = indent_match.group(2)
                sub_value = indent_match.group(3).strip()
                if sub_value.startswith("["):
                    items = []
                    inner = sub_value[1:-1]
                    for item in re.findall(r"""["']([^"']*)["']|(\w+)""", inner):
                        items.append(item[0] or item[1])
                    current_dict[sub_key] = items
                elif sub_value:
                    current_dict[sub_key] = sub_value.strip('"').strip("'")

    return result, body


# ---------------------------------------------------------------------------
# Type inference
# ---------------------------------------------------------------------------

def infer_type(name: str, body: str, frontmatter: Dict, category: str) -> str:
    """Infer the skill type from content patterns."""
    body_lower = body.lower()
    name_lower = name.lower()

    # Meta skills
    if any(t in name_lower for t in ("triage", "quality", "benchmark", "audit", "evaluat")):
        return "meta"
    if cat_matches_category(category, "meta"):
        return "meta"

    # Workflow skills
    if cat_matches_category(category, "workflow"):
        return "workflow"
    if re.search(r"^\d+\.\s+", body, re.MULTILINE):
        return "workflow"
    if "## Steps" in body or "## Workflow" in body or "## Core loop" in body:
        return "workflow"
    if frontmatter.get("category") == "workflow":
        return "workflow"

    # Tool skills — have commands/packages/API calls
    prereqs = frontmatter.get("prerequisites")
    if isinstance(prereqs, dict):
        commands = prereqs.get("commands", [])
        if isinstance(commands, list) and len(commands) > 0:
            return "tool"
    if cat_matches_category(category, ("tool", "github", "mlops", "database", "devops", "social-media")):
        return "tool"

    # Heuristic: code blocks with shell commands
    code_blocks = re.findall(r"```(?:bash|sh|shell|zsh)\n(.*?)```", body, re.DOTALL)
    if code_blocks:
        # Check if code blocks contain CLI commands or tool invocations
        for block in code_blocks:
            if re.search(r"(apt|pip|npm|curl|git |ssh|nix |systemctl|docker|kubectl|gh |npx)", block):
                return "tool"

    # Knowledge skills (default for descriptive content)
    if cat_matches_category(category, ("knowledge", "concept", "reference", "research")):
        return "knowledge"

    return "knowledge"


def cat_matches_category(name: str, targets: Tuple[str, ...]) -> bool:
    """Check if a name or category matches any target."""
    if isinstance(targets, str):
        return name and name.lower() == targets.lower()
    return any(cat_matches_category(name, t) for t in targets)


def infer_category_from_path(path: Path) -> str:
    """Extract category from the directory path."""
    parts = path.parts
    # Path: .../skills/<category>/<skill-name>/SKILL.md
    try:
        idx = parts.index("skills")
        if idx + 1 < len(parts):
            return parts[idx + 1]
    except ValueError:
        pass
    return "uncategorized"


# ---------------------------------------------------------------------------
# Section extraction
# ---------------------------------------------------------------------------

def extract_section(body: str, *headings: str) -> Optional[str]:
    """Extract a section's content by heading name."""
    for heading in headings:
        # Match ## Heading or ### Heading
        pattern = re.compile(
            r'^##+\s+' + re.escape(heading) + r'\s*\n(.*?)(?=^#|\Z)',
            re.MULTILINE | re.DOTALL
        )
        match = pattern.search(body)
        if match:
            return match.group(1).strip()
    return None


def extract_list_items(section_text: str) -> List[str]:
    """Extract bullet or numbered list items from section text."""
    if not section_text:
        return []
    items = []
    for line in section_text.split("\n"):
        stripped = line.strip()
        # Bullet items
        match = re.match(r'^[-*]\s+(.*)', stripped)
        if match:
            items.append(match.group(1).strip())
        # Checklist items
        match = re.match(r'^- \[[ x]\]\s+(.*)', stripped)
        if match:
            items.append(match.group(1).strip())
        # Numbered items
        match = re.match(r'^\d+[.)]\s+(.*)', stripped)
        if match:
            items.append(match.group(1).strip())
    return items


def extract_triggers(frontmatter: Dict, body: str) -> List[str]:
    """Extract trigger keywords from frontmatter or body."""
    triggers = frontmatter.get("triggers", [])
    if isinstance(triggers, list) and triggers:
        # Deduplicate
        seen = set()
        unique = []
        for t in triggers:
            t_clean = t.strip().strip('"').strip("'")
            if t_clean and t_clean.lower() not in seen:
                seen.add(t_clean.lower())
                unique.append(t_clean)
        return unique[:20]  # cap at 20
    return []


def extract_pitfalls(body: str) -> List[str]:
    """Extract pitfalls from Common Pitfalls section."""
    section = extract_section(body, "Common Pitfalls", "Pitfalls", "Gotchas")
    if section:
        return extract_list_items(section)
    return []


def extract_verification(body: str) -> Optional[str]:
    """Extract verification steps/checklist."""
    section = extract_section(body, "Verification Checklist", "Verification", "Verifying", "Testing")
    if section:
        items = extract_list_items(section)
        if items:
            return "\n".join(f"# {i+1}. {item}" for i, item in enumerate(items))
        return section
    return None


def extract_example(body: str) -> Optional[str]:
    """Extract the first example from Usage/Example sections."""
    section = extract_section(body, "Example", "Usage", "Quick Start", "Getting Started")
    if section:
        # Return first code block
        code_match = re.search(r"```(?:bash|sh|python|nix|shell)\n(.*?)```", section, re.DOTALL)
        if code_match:
            return code_match.group(1).strip()
        return section[:500]
    return None


# ---------------------------------------------------------------------------
# Nix generation
# ---------------------------------------------------------------------------

def to_nix_identifier(name: str) -> str:
    """Convert a skill name to a valid Nix identifier."""
    # slugify: lowercase, replace spaces/special chars with hyphens
    name = name.lower().strip()
    name = re.sub(r'[^a-z0-9_-]', '-', name)
    name = re.sub(r'-+', '-', name)
    name = name.strip('-')
    if not name:
        name = "unnamed"
    return name


def nix_string(value: str) -> str:
    """Escape a string for Nix double-quoted string."""
    if not value:
        return '""'
    # Escape for double-quoted strings
    escaped = (value
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("${", "\\${")
        .replace("\n", "\\n")
    )
    return f'"{escaped}"'

def nix_multiline(value: str, indent: str = "  ") -> str:
    """Escape multiline string for Nix '' (double-single-quote) strings.
    
    Correctly handles '' → ''' (escaped single quote) and ${ → ''${
    """
    # Replace literal '' with ' (escaping inside '' string: '' → ')
    # Replace ${ with ''${ (to prevent interpolation)
    escaped = value.replace("''", "'''").replace("${", "''${")
    return f"''\n{indent}{escaped}\n{indent}''"

def nix_string_list(items: List[str]) -> str:
    """Generate Nix list of strings (short strings in double quotes, long in '')."""
    if not items:
        return "[ ]"
    parts = []
    for item in items[:20]:  # cap
        if len(item) < 60 and "\n" not in item:
            escaped = item.replace("\\", "\\\\").replace('"', '\\"')
            parts.append(f'  "{escaped}"')
        else:
            escaped = item.replace("''", "'''").replace("${", "''${")
            parts.append(f"  ''\n    {escaped}\n  ''")
    return "[\n" + "\n".join(parts) + "\n]"


def generate_nix_module(
    name: str, frontmatter: Dict, body: str, category: str
) -> Optional[str]:
    """Generate a Nix module file for a skill.

    Returns the file content as a string, or None if the skill can't be
    meaningfully converted.
    """
    # Basic info
    skill_name = to_nix_identifier(name or frontmatter.get("name", "unnamed"))
    description = frontmatter.get("description", "")
    if not description:
        # First line of body
        first_line = body.strip().split("\n")[0].strip()
        description = first_line.lstrip("#").strip()

    triggers = extract_triggers(frontmatter, body)
    skill_type = infer_type(skill_name, body, frontmatter, category)
    pitfalls = extract_pitfalls(body)
    verification = extract_verification(body)
    example = extract_example(body)

    # Fields to include based on type
    fields = []

    # Common fields
    if description:
        desc_escaped = description.replace("\\", "\\\\").replace('"', '\\"')
        fields.append(f'  description = "{desc_escaped}";')

    if triggers:
        fields.append(f'  triggers = {nix_string_list(triggers)};')

    # Type-specific fields
    if skill_type == "tool":
        # For tool skills, add a placeholder action and verification commands
        fields.append(f'  type = "tool";')
        if verification:
            fields.append(f'  verify = {nix_multiline(verification)};')

    elif skill_type == "knowledge":
        fields.append(f'  type = "knowledge";')
        # The knowledge field is the body content (stripped of sections)
        knowledge_body = strip_sections(body, [
            "Verification Checklist", "Verification", "Common Pitfalls",
            "Pitfalls", "Reference Files", "Related Skills",
        ])
        if knowledge_body and len(knowledge_body) > 50:
            fields.append(f'  knowledge = {nix_multiline(knowledge_body)};')

    elif skill_type == "workflow":
        fields.append(f'  type = "workflow";')
        # Extract steps from the body
        steps = extract_workflow_steps(body)
        if steps:
            steps_formatted = [s.strip() for s in steps if s.strip()]
            fields.append(f'  steps = {nix_string_list(steps_formatted)};')

    elif skill_type == "meta":
        fields.append(f'  type = "meta";')

    if pitfalls:
        fields.append(f'  pitfalls = {nix_string_list(pitfalls)};')

    if example:
        fields.append(f'  example = {nix_multiline(example)};')

    if not fields:
        return None

    # Generate the module file
    nix_content = f"""# {skill_name}.nix — Auto-converted from Hermes skill
# Category: {category}
# Original: {name or frontmatter.get("name", "unknown")}

{{ config, lib, pkgs, ... }}:
with lib;
let
  cfg = config.hermes.skills.{skill_name};
in
{{
  options.hermes.skills.{skill_name} = {{
    enable = mkEnableOption "{description}";
  }};

  config = mkIf cfg.enable {{
    hermes.skills.{skill_name} = {{
      enable = true;
{chr(10).join(fields)}
    }};
  }};
}}
"""
    return nix_content


def strip_sections(body: str, skip_headings: List[str]) -> str:
    """Strip specific sections from the body."""
    result = body
    for heading in skip_headings:
        result = re.sub(
            r'^##+\s+' + re.escape(heading) + r'\s*\n.*?(?=^##|\Z)',
            '',
            result,
            flags=re.MULTILINE | re.DOTALL,
        )
    # Clean up extra blank lines
    result = re.sub(r'\n{3,}', '\n\n', result)
    return result.strip()


def extract_workflow_steps(body: str) -> List[str]:
    """Extract workflow steps from the body."""
    steps = []

    # Look for numbered items
    step_matches = re.findall(r'^\d+[.)]\s+(.*)', body, re.MULTILINE)
    if step_matches:
        return [s.strip() for s in step_matches if s.strip()]

    # Look for "### Step N" headings
    step_sections = re.findall(
        r'^###\s+Step\s+\d+[.:]?\s*(.*?)$',
        body,
        re.MULTILINE | re.IGNORECASE,
    )
    if step_sections:
        return [s.strip() for s in step_sections if s.strip()]

    # Look for explicit sections
    for section_name in ("Procedure", "Core Loop", "Process"):
        section = extract_section(body, section_name)
        if section:
            items = extract_list_items(section)
            if items:
                return items

    return []


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    import argparse

    parser = argparse.ArgumentParser(description="Convert Hermes skills to Nix modules")
    parser.add_argument("--output", "-o", default="./hermes-skills",
                        help="Output directory for Nix module files")
    parser.add_argument("--dry-run", "-n", action="store_true",
                        help="Show what would be generated without writing")
    parser.add_argument("--skills-dir",
                        default=os.path.expanduser("~/.hermes/skills"),
                        help="Path to Hermes skills directory")
    parser.add_argument("--aggregator", action="store_true", default=True,
                        help="Generate an aggregator module that imports all skills")
    args = parser.parse_args()

    skills_dir = Path(args.skills_dir).expanduser().resolve()
    output_dir = Path(args.output).expanduser().resolve()

    if not skills_dir.is_dir():
        print(f"Skills directory not found: {skills_dir}")
        sys.exit(1)

    if not args.dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)

    converted = 0
    skipped = []
    errors = []

    for cat_dir in sorted(skills_dir.iterdir()):
        if not cat_dir.is_dir():
            continue
        category = cat_dir.name
        cat_nix_dir = output_dir / category
        if not args.dry_run:
            cat_nix_dir.mkdir(parents=True, exist_ok=True)

        for skill_dir in sorted(cat_dir.iterdir()):
            path = skill_dir / "SKILL.md"
            if not path.exists():
                continue

            name = skill_dir.name
            content = path.read_text(encoding="utf-8", errors="replace")

            try:
                frontmatter, body = parse_frontmatter(content)
            except Exception as e:
                errors.append(f"{name}: frontmatter parse error: {e}")
                continue

            nix_content = generate_nix_module(
                name, frontmatter, body, category
            )

            if nix_content is None:
                skipped.append(name)
                continue

            nix_name = to_nix_identifier(name)
            out_path = cat_nix_dir / f"{nix_name}.nix"

            if args.dry_run:
                print(f"[DRY-RUN] {name} → {out_path.relative_to(output_dir)}")
                print(f"           type={infer_type(name, body, frontmatter, category)}, "
                      f"triggers={len(extract_triggers(frontmatter, body))}, "
                      f"pitfalls={len(extract_pitfalls(body))}")
            else:
                out_path.write_text(nix_content, encoding="utf-8")

            converted += 1

    # Generate aggregator module
    if args.aggregator:
        agg_path = output_dir / "default.nix"

        if args.dry_run:
            print(f"\n[DRY-RUN] Aggregator would be generated at: {agg_path}")
        else:
            output_dir.mkdir(parents=True, exist_ok=True)
            agg_lines = ["# Auto-generated aggregator — imports all skill modules",
                          "# Generated by skill-to-nix.py",
                          "{ ... }: {",
                          "  imports = ["]

            # Collect all generated .nix files
            for cat_dir in sorted(output_dir.iterdir()):
                if not cat_dir.is_dir():
                    continue
                for nix_file in sorted(cat_dir.glob("*.nix")):
                    rel = nix_file.relative_to(output_dir)
                    agg_lines.append(f"    ./{rel}")

            agg_lines.append("  ];")
            agg_lines.append("}")

            agg_path.write_text("\n".join(agg_lines) + "\n", encoding="utf-8")

    # Report
    print(f"\n{'='*50}")
    print(f"Skills found:    {converted + len(skipped) + len(errors)}")
    print(f"Converted:       {converted}")
    print(f"Skipped:         {len(skipped)}")
    print(f"Errors:          {len(errors)}")

    if skipped and not args.dry_run:
        print(f"\nSkipped ({len(skipped)}):")
        for s in skipped:
            print(f"  - {s}")

    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors:
            print(f"  - {e}")

    if not args.dry_run:
        print(f"\nOutput: {output_dir}")
        print(f"Import in your flake:")
        print(f"  imports = [ inputs.hermes-agent.nixosModules.agentic ];")
        print(f"  # Then import the generated skills:")
        print(f"  imports = [ ./hermes-skills/default.nix ];")


if __name__ == "__main__":
    main()
