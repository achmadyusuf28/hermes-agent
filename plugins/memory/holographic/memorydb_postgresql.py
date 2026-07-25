"""
memorydb_postgresql.py — PostgreSQL memory store for Holographic plugin.

Drop-in replacement for :class:`MemoryStore` (SQLite) with the same public
API, backed by PostgreSQL.  Reads the connection string from the same
``sessiondb.dsn`` config that :mod:`sessiondb_postgresql` uses, so the
mesh only needs one configured PG DSN for both session and memory data.

Usage in config.yaml::

    sessiondb:
      provider: postgresql
      dsn: "postgresql://hermes@localhost/hermes_sessions?host=/run/postgresql"

    plugins:
      hermes-memory-store:
        db_path: postgresql   # ← tells the plugin to use this module
"""

from __future__ import annotations

import logging
import re
import threading
from pathlib import Path
from typing import Any, List, Optional

try:
    import psycopg2
    import psycopg2.extras
    import psycopg2.extensions
except ImportError:
    psycopg2 = None

try:
    from plugins.memory.holographic import holographic as hrr
except ImportError:
    import holographic as hrr  # type: ignore[no-redef]

logger = logging.getLogger(__name__)

# ── Schema ─────────────────────────────────────────────────────────────

_SCHEMA = """
CREATE TABLE IF NOT EXISTS holographic_facts (
    fact_id         SERIAL PRIMARY KEY,
    content         TEXT NOT NULL UNIQUE,
    category        TEXT DEFAULT 'general',
    tags            TEXT DEFAULT '',
    trust_score     REAL DEFAULT 0.5,
    retrieval_count INTEGER DEFAULT 0,
    helpful_count   INTEGER DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hrr_vector      BYTEA,
    search_vector   TSVECTOR
);

CREATE INDEX IF NOT EXISTS idx_hf_trust    ON holographic_facts(trust_score DESC);
CREATE INDEX IF NOT EXISTS idx_hf_category ON holographic_facts(category);
CREATE INDEX IF NOT EXISTS idx_hf_search   ON holographic_facts USING GIN(search_vector);

CREATE TABLE IF NOT EXISTS holographic_entities (
    entity_id   SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    entity_type TEXT DEFAULT 'unknown',
    aliases     TEXT DEFAULT '',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_he_name ON holographic_entities(name);

CREATE TABLE IF NOT EXISTS holographic_fact_entities (
    fact_id   INTEGER REFERENCES holographic_facts(fact_id) ON DELETE CASCADE,
    entity_id INTEGER REFERENCES holographic_entities(entity_id) ON DELETE CASCADE,
    PRIMARY KEY (fact_id, entity_id)
);

CREATE TABLE IF NOT EXISTS holographic_memory_banks (
    bank_id    SERIAL PRIMARY KEY,
    bank_name  TEXT NOT NULL UNIQUE,
    vector     BYTEA NOT NULL,
    dim        INTEGER NOT NULL,
    fact_count INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Auto-maintain search_vector on insert/update
CREATE OR REPLACE FUNCTION hf_search_vector_update() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', coalesce(NEW.content, '') || ' ' || coalesce(NEW.tags, ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only create trigger if it does not already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_hf_search_vector'
    ) THEN
        CREATE TRIGGER trg_hf_search_vector
            BEFORE INSERT OR UPDATE OF content, tags
            ON holographic_facts
            FOR EACH ROW
            EXECUTE FUNCTION hf_search_vector_update();
    END IF;
END;
$$;
"""

# ── Trust constants (mirror store.py) ──────────────────────────────────

_HELPFUL_DELTA   =  0.05
_UNHELPFUL_DELTA = -0.10
_TRUST_MIN       =  0.0
_TRUST_MAX       =  1.0

# Entity extraction patterns (mirror store.py)
_RE_CAPITALIZED  = re.compile(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b')
_RE_DOUBLE_QUOTE = re.compile(r'"([^"]+)"')
_RE_SINGLE_QUOTE = re.compile(r"'([^']+)'")
_RE_AKA          = re.compile(
    r'(\w+(?:\s+\w+)*)\s+(?:aka|also known as)\s+(\w+(?:\s+\w+)*)',
    re.IGNORECASE,
)


def _clamp_trust(value: float) -> float:
    return max(_TRUST_MIN, min(_TRUST_MAX, value))


def _resolve_dsn() -> Optional[str]:
    """Read sessiondb.dsn from config, or fall back to env / default."""
    try:
        from hermes_cli.config import get_config_value
        dsn = get_config_value("sessiondb.dsn")
        if dsn:
            return dsn
    except Exception:
        pass
    return None


# ── PostgreSQL Memory Store ────────────────────────────────────────────


class PostgreSQLMemoryStore:
    """PostgreSQL-backed fact store with entity resolution and trust scoring.

    Public API mirrors ``store.MemoryStore`` exactly so the rest of the
    holographic plugin (``FactRetriever``, ``HolographicMemoryProvider``)
    can use it as a drop-in replacement.

    ``_conn`` is a ``psycopg2`` connection with ``RealDictCursor`` so
    ``row["column"]`` access works identically to ``sqlite3.Row``.
    """

    def __init__(
        self,
        db_path: str | Path | None = None,
        default_trust: float = 0.5,
        hrr_dim: int = 1024,
    ) -> None:
        if psycopg2 is None:
            raise ImportError("psycopg2 is required for PostgreSQLMemoryStore")
        self.db_path = db_path
        self.default_trust = _clamp_trust(default_trust)
        self.hrr_dim = hrr_dim
        self._hrr_available = hrr._HAS_NUMPY
        self._lock = threading.RLock()

        dsn = _resolve_dsn()
        if not dsn:
            raise RuntimeError(
                "PostgreSQLMemoryStore: no sessiondb.dsn configured"
            )
        self._conn = psycopg2.connect(
            dsn,
            cursor_factory=psycopg2.extras.RealDictCursor,
        )
        self._conn.autocommit = False
        self._init_db()

    # ── Init ──────────────────────────────────────────────────────────

    def _init_db(self) -> None:
        """Create tables, indexes, triggers if they don't exist."""
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(_SCHEMA)
            self._conn.commit()
            # Ensure search_vector is up-to-date for any pre-existing rows
            # that were migrated from SQLite (no trigger would have fired)
            with self._conn.cursor() as cur:
                cur.execute(
                    "UPDATE holographic_facts "
                    "SET search_vector = to_tsvector('english', "
                    "coalesce(content, '') || ' ' || coalesce(tags, '')) "
                    "WHERE search_vector IS NULL"
                )
            self._conn.commit()

    # ── Core public API ──────────────────────────────────────────────

    def add_fact(
        self,
        content: str,
        category: str = "general",
        tags: str = "",
    ) -> int:
        """Insert a fact and return its fact_id. Deduplicates by content."""
        content = content.strip()
        if not content:
            raise ValueError("content must not be empty")

        with self._lock:
            try:
                with self._conn.cursor() as cur:
                    cur.execute(
                        """INSERT INTO holographic_facts
                           (content, category, tags, trust_score)
                           VALUES (%s, %s, %s, %s)
                           RETURNING fact_id""",
                        (content, category, tags, self.default_trust),
                    )
                    fact_id = cur.fetchone()["fact_id"]
                self._conn.commit()
            except psycopg2.errors.UniqueViolation:
                self._conn.rollback()
                with self._conn.cursor() as cur:
                    cur.execute(
                        "SELECT fact_id FROM holographic_facts WHERE content = %s",
                        (content,),
                    )
                    row = cur.fetchone()
                    return int(row["fact_id"]) if row else 0

            # Entity extraction
            for name in self._extract_entities(content):
                entity_id = self._resolve_entity(name)
                self._link_fact_entity(fact_id, entity_id)

            self._compute_hrr_vector(fact_id, content)
            self._rebuild_bank(category)
            return fact_id

    def search_facts(
        self,
        query: str,
        category: str | None = None,
        min_trust: float = 0.3,
        limit: int = 10,
    ) -> list[dict]:
        """Full-text search over facts using tsvector.

        Ordered by ts_rank, then trust_score descending.
        Uses plainto_tsquery for natural-language input.
        """
        query = query.strip()
        if not query:
            return []

        with self._lock:
            params: list = [query, min_trust]
            cat_clause = ""
            if category is not None:
                cat_clause = "AND category = %s"
                params.append(category)
            params.append(limit)

            with self._conn.cursor() as cur:
                cur.execute(
                    f"""SELECT fact_id, content, category, tags,
                               trust_score, retrieval_count, helpful_count,
                               created_at, updated_at
                        FROM holographic_facts
                        WHERE search_vector @@ plainto_tsquery('english', %s)
                          AND trust_score >= %s
                          {cat_clause}
                        ORDER BY ts_rank(search_vector, plainto_tsquery('english', %s)) DESC,
                                 trust_score DESC
                        LIMIT %s""",
                    params,
                )
                results = [dict(r) for r in cur.fetchall()]

            if results:
                ids = [r["fact_id"] for r in results]
                with self._conn.cursor() as cur:
                    cur.execute(
                        "UPDATE holographic_facts SET retrieval_count = retrieval_count + 1 "
                        "WHERE fact_id = ANY(%s)",
                        (ids,),
                    )
                self._conn.commit()

            return results

    def update_fact(
        self,
        fact_id: int,
        content: str | None = None,
        trust_delta: float | None = None,
        tags: str | None = None,
        category: str | None = None,
    ) -> bool:
        """Partially update a fact. Returns True if the row existed."""
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(
                    "SELECT fact_id, trust_score, category FROM holographic_facts WHERE fact_id = %s",
                    (fact_id,),
                )
                row = cur.fetchone()
            if row is None:
                return False

            assignments: list[str] = ["updated_at = CURRENT_TIMESTAMP"]
            params: list = []

            if content is not None:
                assignments.append("content = %s")
                params.append(content.strip())
            if tags is not None:
                assignments.append("tags = %s")
                params.append(tags)
            if category is not None:
                assignments.append("category = %s")
                params.append(category)
            if trust_delta is not None:
                new_trust = _clamp_trust(row["trust_score"] + trust_delta)
                assignments.append("trust_score = %s")
                params.append(new_trust)

            params.append(fact_id)
            with self._conn.cursor() as cur:
                cur.execute(
                    f"UPDATE holographic_facts SET {', '.join(assignments)} WHERE fact_id = %s",
                    params,
                )
            self._conn.commit()

            if content is not None:
                with self._conn.cursor() as cur:
                    cur.execute(
                        "DELETE FROM holographic_fact_entities WHERE fact_id = %s",
                        (fact_id,),
                    )
                self._conn.commit()
                for name in self._extract_entities(content):
                    entity_id = self._resolve_entity(name)
                    self._link_fact_entity(fact_id, entity_id)
                self._compute_hrr_vector(fact_id, content)

            cat = category or row["category"]
            self._rebuild_bank(cat)
            return True

    def remove_fact(self, fact_id: int) -> bool:
        """Delete a fact and its entity links. Returns True if row existed."""
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(
                    "SELECT fact_id, category FROM holographic_facts WHERE fact_id = %s",
                    (fact_id,),
                )
                row = cur.fetchone()
            if row is None:
                return False
            with self._conn.cursor() as cur:
                cur.execute(
                    "DELETE FROM holographic_fact_entities WHERE fact_id = %s",
                    (fact_id,),
                )
                cur.execute(
                    "DELETE FROM holographic_facts WHERE fact_id = %s",
                    (fact_id,),
                )
            self._conn.commit()
            self._rebuild_bank(row["category"])
            return True

    def list_facts(
        self,
        category: str | None = None,
        min_trust: float = 0.0,
        limit: int = 50,
    ) -> list[dict]:
        """Browse facts ordered by trust_score descending."""
        with self._lock:
            params: list = [min_trust]
            cat_clause = ""
            if category is not None:
                cat_clause = "AND category = %s"
                params.append(category)
            params.append(limit)
            with self._conn.cursor() as cur:
                cur.execute(
                    f"""SELECT fact_id, content, category, tags, trust_score,
                               retrieval_count, helpful_count, created_at, updated_at
                        FROM holographic_facts
                        WHERE trust_score >= %s
                          {cat_clause}
                        ORDER BY trust_score DESC
                        LIMIT %s""",
                    params,
                )
                return [dict(r) for r in cur.fetchall()]

    def record_feedback(self, fact_id: int, helpful: bool) -> dict:
        """Adjust trust score based on feedback."""
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(
                    "SELECT fact_id, trust_score, helpful_count "
                    "FROM holographic_facts WHERE fact_id = %s",
                    (fact_id,),
                )
                row = cur.fetchone()
            if row is None:
                raise KeyError(f"fact_id {fact_id} not found")

            old_trust = row["trust_score"]
            delta = _HELPFUL_DELTA if helpful else _UNHELPFUL_DELTA
            new_trust = _clamp_trust(old_trust + delta)
            helpful_inc = 1 if helpful else 0

            with self._conn.cursor() as cur:
                cur.execute(
                    "UPDATE holographic_facts "
                    "SET trust_score = %s, helpful_count = helpful_count + %s, "
                    "    updated_at = CURRENT_TIMESTAMP "
                    "WHERE fact_id = %s",
                    (new_trust, helpful_inc, fact_id),
                )
            self._conn.commit()

            return {
                "fact_id": fact_id,
                "old_trust": old_trust,
                "new_trust": new_trust,
                "helpful_count": row["helpful_count"] + helpful_inc,
            }

    # ── Entity helpers ───────────────────────────────────────────────

    def _extract_entities(self, text: str) -> list[str]:
        """Mirrors store.MemoryStore._extract_entities exactly."""
        seen: set[str] = set()
        candidates: list[str] = []

        def _add(name: str) -> None:
            stripped = name.strip()
            if stripped and stripped.lower() not in seen:
                seen.add(stripped.lower())
                candidates.append(stripped)

        for m in _RE_CAPITALIZED.finditer(text):
            _add(m.group(1))
        for m in _RE_DOUBLE_QUOTE.finditer(text):
            _add(m.group(1))
        for m in _RE_SINGLE_QUOTE.finditer(text):
            _add(m.group(1))
        for m in _RE_AKA.finditer(text):
            _add(m.group(1))
            _add(m.group(2))

        return candidates

    def _resolve_entity(self, name: str) -> int:
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(
                    "SELECT entity_id FROM holographic_entities WHERE name ILIKE %s",
                    (name,),
                )
                row = cur.fetchone()
            if row is not None:
                return int(row["entity_id"])

            with self._conn.cursor() as cur:
                cur.execute(
                    """SELECT entity_id FROM holographic_entities
                       WHERE ',' || aliases || ',' ILIKE '%,' || %s || ',%'""",
                    (name,),
                )
                row = cur.fetchone()
            if row is not None:
                return int(row["entity_id"])

            with self._conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO holographic_entities (name) VALUES (%s) RETURNING entity_id",
                    (name,),
                )
                self._conn.commit()
                return cur.fetchone()["entity_id"]

    def _link_fact_entity(self, fact_id: int, entity_id: int) -> None:
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO holographic_fact_entities (fact_id, entity_id) "
                    "VALUES (%s, %s) ON CONFLICT DO NOTHING",
                    (fact_id, entity_id),
                )
            self._conn.commit()

    # ── HRR helpers ──────────────────────────────────────────────────

    def _compute_hrr_vector(self, fact_id: int, content: str) -> None:
        with self._lock:
            if not self._hrr_available:
                return
            with self._conn.cursor() as cur:
                cur.execute(
                    """SELECT e.name FROM holographic_entities e
                       JOIN holographic_fact_entities fe ON fe.entity_id = e.entity_id
                       WHERE fe.fact_id = %s""",
                    (fact_id,),
                )
                entities = [r["name"] for r in cur.fetchall()]

            vector = hrr.encode_fact(content, entities, self.hrr_dim)
            with self._conn.cursor() as cur:
                cur.execute(
                    "UPDATE holographic_facts SET hrr_vector = %s WHERE fact_id = %s",
                    (psycopg2.Binary(hrr.phases_to_bytes(vector)), fact_id),
                )
            self._conn.commit()

    def _rebuild_bank(self, category: str) -> None:
        with self._lock:
            if not self._hrr_available:
                return
            bank_name = f"cat:{category}"
            with self._conn.cursor() as cur:
                cur.execute(
                    "SELECT hrr_vector FROM holographic_facts "
                    "WHERE category = %s AND hrr_vector IS NOT NULL",
                    (category,),
                )
                rows = cur.fetchall()

            if not rows:
                with self._conn.cursor() as cur:
                    cur.execute(
                        "DELETE FROM holographic_memory_banks WHERE bank_name = %s",
                        (bank_name,),
                    )
                self._conn.commit()
                return

            vectors = [hrr.bytes_to_phases(r["hrr_vector"]) for r in rows]
            bank_vector = hrr.bundle(*vectors)
            fact_count = len(vectors)
            hrr.snr_estimate(self.hrr_dim, fact_count)

            with self._conn.cursor() as cur:
                cur.execute(
                    """INSERT INTO holographic_memory_banks
                       (bank_name, vector, dim, fact_count, updated_at)
                       VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP)
                       ON CONFLICT (bank_name) DO UPDATE SET
                           vector = EXCLUDED.vector,
                           dim = EXCLUDED.dim,
                           fact_count = EXCLUDED.fact_count,
                           updated_at = EXCLUDED.updated_at""",
                    (bank_name, psycopg2.Binary(hrr.phases_to_bytes(bank_vector)),
                     self.hrr_dim, fact_count),
                )
            self._conn.commit()

    # ── Lifecycle ────────────────────────────────────────────────────

    def close(self) -> None:
        try:
            self._conn.close()
        except Exception:
            pass

    def __enter__(self) -> PostgreSQLMemoryStore:
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
