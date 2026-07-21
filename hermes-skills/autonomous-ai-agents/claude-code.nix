# claude-code.nix — Auto-converted from Hermes skill
# Category: autonomous-ai-agents
# Original: claude-code

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.claude-code;
in
{
  options.hermes.skills.claude-code = {
    enable = mkEnableOption "Delegate coding to Claude Code CLI (features, PRs).";
  };

  config = mkIf cfg.enable {
    hermes.skills.claude-code = {
      enable = true;
  description = "Delegate coding to Claude Code CLI (features, PRs).";
  triggers = [
  "claude-code"
  "claude code"
];
  type = "workflow";
  steps = [
  "**CLI flags** — override everything"
  ''
    **Local project:** `.claude/settings.local.json` (personal, gitignored)
  ''
  "**Project:** `.claude/settings.json` (shared, git-tracked)"
  "**User:** `~/.claude/settings.json` (global)"
  "**Global:** `~/.claude/CLAUDE.md` — applies to all projects"
  ''
    **Project:** `./CLAUDE.md` — project-specific context (git-tracked)
  ''
  ''
    **Local:** `.claude/CLAUDE.local.md` — personal project overrides (gitignored)
  ''
  "Run all tests"
  "Build the Docker image"
  "Push to registry"
  "Update the $ARGUMENTS environment (default: staging)"
  "Use Alembic for migration generation"
  "Always create a rollback function"
  "Test migrations against a local database copy"
  "`.claude/agents/` — project-level, team-shared"
  "`--agents` CLI flag — session-specific, dynamic"
  "`~/.claude/agents/` — user-level, personal"
  ''
    **Use `--max-turns`** in print mode to prevent runaway loops. Start with 5-10 for most tasks.
  ''
  ''
    **Use `--max-budget-usd`** for cost caps. Note: minimum ~$0.05 for system prompt cache creation.
  ''
  ''
    **Use `--effort low`** for simple tasks (faster, cheaper). `high` or `max` for complex reasoning.
  ''
];
    };
  };
}
