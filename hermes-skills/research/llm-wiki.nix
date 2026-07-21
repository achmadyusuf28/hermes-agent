# llm-wiki.nix — Auto-converted from Hermes skill
# Category: research
# Original: llm-wiki

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.llm-wiki;
in
{
  options.hermes.skills.llm-wiki = {
    enable = mkEnableOption "Karpathy's LLM Wiki: build/query interlinked markdown KB.";
  };

  config = mkIf cfg.enable {
    hermes.skills.llm-wiki = {
      enable = true;
  description = "Karpathy's LLM Wiki: build/query interlinked markdown KB.";
  triggers = [
  "llm-wiki"
  "llm wiki"
];
  type = "workflow";
  steps = [
  ''
    Determine the wiki path (from `$WIKI_PATH` env var, or ask the user; default `~/wiki`)
  ''
  "Create the directory structure above"
  "Ask the user what domain the wiki covers — be specific"
  ''
    Write `SCHEMA.md` customized to the domain (see template below)
  ''
  "Write initial `index.md` with sectioned header"
  "Write initial `log.md` with creation entry"
  ''
    Confirm the wiki is ready and suggest first sources to ingest
  ''
  ''
    Check the dates — newer sources generally supersede older ones
  ''
  ''
    If genuinely contradictory, note both positions with dates and sources
  ''
  ''
    Mark the contradiction in frontmatter: `contradictions: [page-name]`
  ''
  "Flag for user review in the lint report"
  "Read all sources first"
  "Identify all entities and concepts across all sources"
  ''
    Check existing pages for all of them (one search pass, not N)
  ''
  "Create/update pages in one pass (avoids redundant updates)"
  "Update index.md once at the end"
  "Write a single log entry covering the batch"
  "Create `_archive/` directory if it doesn't exist"
  ''
    Move the page to `_archive/` with its original path (e.g., `_archive/entities/old-page.md`)
  ''
  "Remove from `index.md`"
];
  pitfalls = [
  ''
    **Never modify files in `raw/`** — sources are immutable. Corrections go in wiki pages.
  ''
  ''
    **Always orient first** — read SCHEMA + index + recent log before any operation in a new session.
  ''
  ''
    **Always update index.md and log.md** — skipping this makes the wiki degrade. These are the
  ''
  ''
    **Don't create pages for passing mentions** — follow the Page Thresholds in SCHEMA.md. A name
  ''
  ''
    **Don't create pages without cross-references** — isolated pages are invisible. Every page must
  ''
  ''
    **Frontmatter is required** — it enables search, filtering, and staleness detection.
  ''
  ''
    **Tags must come from the taxonomy** — freeform tags decay into noise. Add new tags to SCHEMA.md
  ''
  ''
    **Keep pages scannable** — a wiki page should be readable in 30 seconds. Split pages over
  ''
  ''
    **Ask before mass-updating** — if an ingest would touch 10+ existing pages, confirm
  ''
  ''
    **Rotate the log** — when log.md exceeds 500 entries, rename it `log-YYYY.md` and start fresh.
  ''
  ''
    **Handle contradictions explicitly** — don't silently overwrite. Note both claims with dates,
  ''
];
    };
  };
}
