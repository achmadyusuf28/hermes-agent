# openwiki.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: openwiki

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.openwiki;
in
{
  options.hermes.skills.openwiki = {
    enable = mkEnableOption "Personal brain wiki and code documentation — local CLI for agent knowledge synthesis.";
  };

  config = mkIf cfg.enable {
    hermes.skills.openwiki = {
      enable = true;
  description = "Personal brain wiki and code documentation — local CLI for agent knowledge synthesis.";
  triggers = [
  "openwiki"
  "personal wiki"
  "agent wiki"
  "update wiki"
  "second brain"
  "knowledge base"
];
  type = "workflow";
  steps = [
  "Choose provider (OpenAI, Anthropic, OpenRouter, etc.)"
  "Set API key"
  ''
    Configure connectors (local git repos, Notion, Gmail, X, Web Search, Hacker News)
  ''
  ''
    **Identify the repo** from the tag — locate it at `/mnt/data/parkee/`
  ''
  ''
    **Check `active-work.md`** (in wiki/) for the project's current branch state
  ''
  "**Read the wiki page** for project context"
  ''
    **If the user included a branch name**, use the "in-progress" version block for architecture/code references, the "stable" block only for context on what hasn't changed
  ''
  ''
    **If no branch is mentioned** but `active-work.md` shows the project is on a non-main branch, still note it — the user is on `refactor-apdu-v2` even if they didn't say so
  ''
];
  pitfalls = [
  ''
    **`openwiki personal --init` walks through interactive setup** — it's not a silent command. It will prompt for provider selection, API key, and connector configuration. Run it in a terminal where you can interact.
  ''
  ''
    **Reading large wiki files with `read_file`** — the default limit is 500 lines. A file of 3420+ lines needs chunked reads (`offset=1, limit=2000` + subsequent chunks), and reassembling in `execute_code` can corrupt line-number prefixes. Prefer `terminal` with `wc -l` to check size first.
  ''
  ''
    **OpenWiki through Manifest** — the `OPENWIKI_PROVIDER` env vars must be set before every invocation. They're not persistent across shell sessions. Wrap in a script or add to `.profile`.
  ''
  ''
    **Wiki topics go under `topics/` subdirectory** — writing a `.md` file directly to `~/.openwiki/wiki/` (not `~/openwiki/wiki/topics/`) won't be auto-discovered. Always use `~/.openwiki/wiki/topics/<topic>.md`.
  ''
  ''
    **AGENTS.md/CLAUDE.md with local-only references** — when the wiki generates AGENTS.md files with wiki reference sections, those references point to local wiki paths. Peers who clone the repo won't have access. Use absolute paths and include a disclaimer.
  ''
  ''
    **Project tag convention is user-managed** — `[pax]`, `[parkee-agent]` tags at the start of messages signal which project you're working on. The agent reads them, but the user must remember to include them. If the user forgets, the agent falls back to general knowledge.
  ''
  ''
    **`active-work.md` is manually updated** — branch tracking is not automated. Only the user knows when a refactor is truly done. The agent should read `active-work.md` before answering cross-branch questions but never auto-update it.
  ''
];
  example = ''
  openwiki personal --init                  # Initialize personal brain
openwiki personal --update                # Refresh from configured sources
openwiki code --init                      # Init repo docs (AGENTS.md/CLAUDE.md)
openwiki code --update                    # Update repo docs
openwiki -p "Your question"               # One-shot query (non-interactive)
openwiki ingest all                       # Run all connector ingestion
openwiki auth <provider>                  # Authenticate a connector (gmail, notion, slack, x)
openwiki cron list                        # List scheduled connector updates
  '';
    };
  };
}
