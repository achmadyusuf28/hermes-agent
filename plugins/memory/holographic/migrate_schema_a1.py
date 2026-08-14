#!/usr/bin/env python3
"""migrate_holographic_schema_a1.py — Phase A1 additive schema migration.

Adds the Phase A1 provenance + lifecycle columns to an EXISTING
``holographic_facts`` table in PostgreSQL (the append-only raw-capture layer
of the three-layer memory design). Purely ADDITIVE — no data is dropped, no
existing column/type is changed. Idempotent: safe to run repeatedly.

New columns:
    source          TEXT    -- 'user-correction'|'session'|'self-derived'|'dogfood'|'legacy'
    session_id      TEXT    -- link to state.db session for raw capture
    importance      INTEGER -- 1..10; drives importance decay (tier judgment)
    superseded_by   INTEGER -- self-FK; logical soft-delete (append-only, recoverable)
    decay_exempt    BOOLEAN -- tier-1 (behavior-gating/preference) never decays
    last_used_at    TIMESTAMP -- bumped on recall hit to reset decay

Usage:
    python3 migrate_holographic_schema_a1.py
    python3 migrate_holographic_schema_a1.py --dry-run   # preview only, no writes
    python3 migrate_holographic_schema_a1.py --dsn postgresql://hermes@127.0.0.1/hermes_sessions

Requires psycopg2 and, on NixOS, the zlib LD_LIBRARY_PATH used by the Hermes
wrapper (else mirror it): 
  export LD_LIBRARY_PATH="/nix/store/fkcbg2c1w29jr5yp9awai9w3v1wvxdk9-zlib-1.3.2/lib"
"""

from __future__ import annotations

import argparse
import logging
import sys

log = logging.getLogger("migrate-holoa1")


def _resolve_dsn(override: str | None) -> str:
    if override:
        return override
    try:
        from hermes_cli.config import get_config_value
        dsn = get_config_value("sessiondb.dsn")
        if dsn:
            return dsn
    except Exception:  # noqa: BLE001
        pass
    raise RuntimeError("No sessiondb.dsn configured and no --dsn given")


_COLUMNS = [
    # (name, ddl, default_ddl_if_added)
    ("source",        "TEXT",                          "NULL"),
    ("session_id",    "TEXT",                          "NULL"),
    ("importance",    "INTEGER DEFAULT 5",             "DEFAULT 5"),
    ("superseded_by", "INTEGER",                       "NULL"),
    ("decay_exempt",  "BOOLEAN DEFAULT FALSE",         "DEFAULT FALSE"),
    ("last_used_at",  "TIMESTAMP",                     "NULL"),
]

# Best-effort: add a self-FK on superseded_by without failing if the table
# already contains it or if we can't create it (e.g. FK add unsupported).
_FK_SQL = """
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'holographic_facts_superseded_by_fkey'
          AND conrelid = 'holographic_facts'::regclass
    ) THEN
        ALTER TABLE holographic_facts
            ADD CONSTRAINT holographic_facts_superseded_by_fkey
            FOREIGN KEY (superseded_by) REFERENCES holographic_facts(fact_id)
            ON DELETE SET NULL;
    END IF;
EXCEPTION
    WHEN undefined_column THEN NULL;  -- superseded_by not added yet; skip FK
    WHEN duplicate_object      THEN NULL;
END $$;
"""


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true", help="preview changes without writing")
    ap.add_argument("--dsn", default=None, help="override the sessiondb.dsn connection string")
    args = ap.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(message)s")

    import psycopg2  # local import so --help works without the module

    dsn = _resolve_dsn(args.dsn)
    log.info("Connecting to: %s", (dsn.split('@')[-1] if '@' in dsn else dsn))
    conn = psycopg2.connect(dsn)
    conn.autocommit = True
    cur = conn.cursor()

    # Ensure the base table exists (first-ever run against an empty DB).
    from plugins.memory.holographic.memorydb_postgresql import _SCHEMA
    cur.execute(_SCHEMA)

    cur.execute("SELECT column_name FROM information_schema.columns "
                "WHERE table_name = 'holographic_facts'")
    existing = {row[0] for row in cur.fetchall()}
    log.info("Current columns on holographic_facts: %s",
             ", ".join(sorted(existing)) or "(none)")

    added = []
    for name, ddl, _default in _COLUMNS:
        if name in existing:
            log.info("  [skip] %-16s already present", name)
            continue
        if args.dry_run:
            log.info("  [dry ] would add %-16s %s", name, ddl)
            added.append(name)
            continue
        cur.execute(f"ALTER TABLE holographic_facts ADD COLUMN {name} {ddl}")
        added.append(name)
        log.info("  [add ] %-16s %s", name, ddl)

    if args.dry_run:
        log.info("DRY RUN — no changes written. Would add: %s", ", ".join(added) or "none")
        conn.close()
        return 0

    # Backfill source='legacy' for rows that predate provenance.
    cur.execute(
        "SELECT 1 FROM information_schema.columns "
        "WHERE table_name='holographic_facts' AND column_name='source'"
    )
    if cur.fetchone():
        cur.execute("UPDATE holographic_facts SET source = 'legacy' "
                    "WHERE source IS NULL AND superseded_by IS NULL")
        log.info("  [backfill] marked %s legacy rows source='legacy' (only NULL ones)",
                 cur.rowcount)

    # Best-effort self-FK on superseded_by (non-fatal).
    if "superseded_by" in existing or "superseded_by" in added:
        try:
            cur.execute(_FK_SQL)
            log.info("  [fk   ] superseded_by self-FK ensured")
        except Exception as e:  # noqa: BLE001
            log.warning("  [fk   ] skipped self-FK (%s)", e)

    conn.close()
    log.info("MIGRATION COMPLETE — added columns: %s", ", ".join(added) or "none (already up to date)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
