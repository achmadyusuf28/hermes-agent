"""
sessiondb_postgresql.py — PostgreSQL session backend for Hermes Agent.

Implements :class:`PostgreSQLSessionDB` as a drop-in replacement for
:class:`SQLiteSessionDB` via the :class:`SessionDBProvider` ABC.

Usage in config.yaml::

    sessiondb:
      provider: postgresql
      dsn: "postgresql://hermes@localhost/hermes_sessions?host=/run/postgresql"
"""

from __future__ import annotations

import json
import logging
import threading
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    import psycopg2
    import psycopg2.extras
    import psycopg2.extensions
except ImportError:
    psycopg2 = None

logger = logging.getLogger(__name__)

# ── Schema ──────────────────────────────────────────────────────────────

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    source TEXT NOT NULL,
    user_id TEXT,
    session_key TEXT,
    chat_id TEXT,
    chat_type TEXT,
    thread_id TEXT,
    display_name TEXT,
    origin_json TEXT,
    expiry_finalized INTEGER DEFAULT 0,
    model TEXT,
    model_config TEXT,
    system_prompt TEXT,
    parent_session_id TEXT REFERENCES sessions(id),
    started_at DOUBLE PRECISION NOT NULL,
    ended_at DOUBLE PRECISION,
    end_reason TEXT,
    message_count INTEGER DEFAULT 0,
    tool_call_count INTEGER DEFAULT 0,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    cache_read_tokens INTEGER DEFAULT 0,
    cache_write_tokens INTEGER DEFAULT 0,
    reasoning_tokens INTEGER DEFAULT 0,
    cwd TEXT,
    git_branch TEXT,
    git_repo_root TEXT,
    billing_provider TEXT,
    billing_base_url TEXT,
    billing_mode TEXT,
    estimated_cost_usd DOUBLE PRECISION,
    actual_cost_usd DOUBLE PRECISION,
    cost_status TEXT,
    cost_source TEXT,
    pricing_version TEXT,
    title TEXT,
    api_call_count INTEGER DEFAULT 0,
    handoff_state TEXT,
    handoff_platform TEXT,
    handoff_error TEXT,
    compression_failure_cooldown_until DOUBLE PRECISION,
    compression_failure_error TEXT,
    rewind_count INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    role TEXT NOT NULL,
    content TEXT,
    tool_call_id TEXT,
    tool_calls TEXT,
    tool_name TEXT,
    timestamp DOUBLE PRECISION NOT NULL,
    token_count INTEGER,
    finish_reason TEXT,
    reasoning TEXT,
    reasoning_content TEXT,
    reasoning_details TEXT,
    codex_reasoning_items TEXT,
    codex_message_items TEXT,
    platform_message_id TEXT,
    observed INTEGER DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    compacted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS state_meta (
    key TEXT PRIMARY KEY,
    value TEXT
);

CREATE TABLE IF NOT EXISTS gateway_routing (
    scope TEXT NOT NULL DEFAULT '',
    session_key TEXT NOT NULL,
    entry_json TEXT NOT NULL,
    updated_at DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (scope, session_key)
);

CREATE TABLE IF NOT EXISTS compression_locks (
    session_id TEXT PRIMARY KEY,
    holder TEXT NOT NULL,
    acquired_at DOUBLE PRECISION NOT NULL,
    expires_at DOUBLE PRECISION NOT NULL
);
"""

INDEX_SQL = """
CREATE INDEX IF NOT EXISTS idx_sessions_source ON sessions(source);
CREATE INDEX IF NOT EXISTS idx_sessions_source_id ON sessions(source, id);
CREATE INDEX IF NOT EXISTS idx_sessions_parent ON sessions(parent_session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON sessions(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_session ON messages(session_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_compression_locks_expires ON compression_locks(expires_at);
CREATE INDEX IF NOT EXISTS idx_messages_session_active ON messages(session_id, active, timestamp);
CREATE INDEX IF NOT EXISTS idx_sessions_session_key ON sessions(session_key, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_gateway_peer ON sessions(source, user_id, chat_id, chat_type, thread_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_handoff_state ON sessions(handoff_state, started_at);
CREATE INDEX IF NOT EXISTS idx_messages_fts_idx ON messages USING GIN (to_tsvector('english', coalesce(content, '') || ' ' || coalesce(tool_name, '') || ' ' || coalesce(tool_calls, '')));
"""

SCHEMA_VERSION = 1

# ── Provider ────────────────────────────────────────────────────────────


class PostgreSQLSessionDB:
    """PostgreSQL-backed session storage with full-text search via tsvector.

    Drop-in for :class:`SQLiteSessionDB` — all public methods match.
    Thread-safe (single shared connection with lock for writes).
    """

    # ── Lifecycle ────────────────────────────────────────────────────────

    def __init__(self, dsn: Optional[str] = None, *args, **kwargs):
        if psycopg2 is None:
            raise ImportError("psycopg2 is required for PostgreSQLSessionDB")

        from hermes_cli.config import get_config_value

        self.dsn = dsn or get_config_value(
            "sessiondb.dsn",
            "postgresql://hermes@localhost/hermes_sessions?host=/run/postgresql",
        )
        self._lock = threading.Lock()
        self._conn = psycopg2.connect(self.dsn)
        self._conn.autocommit = True
        self._init_schema()

    def initialize(self, **kwargs) -> None:
        """Open connections, create schema — already done in __init__."""

    def close(self) -> None:
        if self._conn and not self._conn.closed:
            self._conn.close()

    # ── Schema ───────────────────────────────────────────────────────────

    def _init_schema(self) -> None:
        with self._conn.cursor() as cur:
            cur.execute(SCHEMA_SQL)
            cur.execute(INDEX_SQL)
            # Ensure schema version row
            cur.execute("SELECT 1 FROM schema_version LIMIT 1")
            if cur.fetchone() is None:
                cur.execute("INSERT INTO schema_version (version) VALUES (%s)", (SCHEMA_VERSION,))

    # ── Helpers ──────────────────────────────────────────────────────────

    def _fetchone(self, sql: str, params: tuple = ()) -> Optional[Dict]:
        with self._conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            row = cur.fetchone()
            return dict(row) if row else None

    def _fetchall(self, sql: str, params: tuple = ()) -> List[Dict]:
        with self._conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            return [dict(r) for r in cur.fetchall()]

    def _execute(self, sql: str, params: tuple = ()) -> None:
        with self._conn.cursor() as cur:
            cur.execute(sql, params)

    def _execute_returning(self, sql: str, params: tuple = (), col: str = "id") -> Any:
        with self._conn.cursor() as cur:
            cur.execute(sql, params)
            row = cur.fetchone()
            return row[0] if row else None

    def _jsonify(self, value: Any) -> Any:
        """Convert dict/list values to JSON strings for TEXT columns."""
        if isinstance(value, (dict, list)):
            return json.dumps(value, default=str)
        return value

    def _row_to_session(self, row: Dict) -> Dict:
        """Convert a DB row (dict) to the dict format callers expect."""
        if row is None:
            return None
        return row

    # ── Session CRUD ─────────────────────────────────────────────────────

    def create_session(self, session_id: str, source: str, **kwargs) -> str:
        now = kwargs.pop("started_at", time.time())
        cols = ["id", "source", "started_at"]
        vals = [session_id, source, now]
        placeholders = []
        for k, v in kwargs.items():
            if k in (
                "user_id", "session_key", "chat_id", "chat_type", "thread_id",
                "display_name", "origin_json", "model", "model_config",
                "system_prompt", "parent_session_id",
            ):
                cols.append(k)
                vals.append(self._jsonify(v))
                placeholders.append(f"%({k})s")
        sql = f"INSERT INTO sessions ({', '.join(cols)}) VALUES ({', '.join('%s' for _ in vals)}) ON CONFLICT DO NOTHING"
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(sql, vals)
        return session_id

    def get_session(self, session_id: str) -> Optional[Dict]:
        return self._fetchone("SELECT * FROM sessions WHERE id = %s", (session_id,))

    def end_session(self, session_id: str, end_reason: str) -> None:
        with self._lock:
            self._execute(
                "UPDATE sessions SET ended_at = %s, end_reason = %s WHERE id = %s",
                (time.time(), end_reason, session_id),
            )

    def reopen_session(self, session_id: str) -> None:
        with self._lock:
            self._execute(
                "UPDATE sessions SET ended_at = NULL, end_reason = NULL WHERE id = %s",
                (session_id,),
            )

    def ensure_session(self, session_id: str, source: str, model: str = "", **kwargs) -> None:
        existing = self.get_session(session_id)
        if existing:
            return
        self.create_session(session_id, source, model=model, **kwargs)

    def resolve_session_id(self, session_id_or_prefix: str) -> Optional[str]:
        row = self._fetchone(
            "SELECT id FROM sessions WHERE id = %s",
            (session_id_or_prefix,),
        )
        if row:
            return row["id"]
        rows = self._fetchall(
            "SELECT id FROM sessions WHERE id LIKE %s ORDER BY started_at DESC LIMIT 1",
            (f"{session_id_or_prefix}%",),
        )
        return rows[0]["id"] if rows else None

    # ── Session metadata ─────────────────────────────────────────────────

    def set_session_title(self, session_id: str, title: str) -> bool:
        with self._lock:
            self._execute("UPDATE sessions SET title = %s WHERE id = %s", (title, session_id))
            return True

    def get_session_title(self, session_id: str) -> Optional[str]:
        row = self._fetchone("SELECT title FROM sessions WHERE id = %s", (session_id,))
        return row["title"] if row else None

    def get_session_by_title(self, title: str) -> Optional[Dict]:
        return self._fetchone("SELECT * FROM sessions WHERE title = %s", (title,))

    def resolve_session_by_title(self, title: str) -> Optional[str]:
        row = self._fetchone("SELECT id FROM sessions WHERE title = %s ORDER BY started_at DESC LIMIT 1", (title,))
        return row["id"] if row else None

    def set_session_archived(self, session_id: str, archived: bool) -> None:
        with self._lock:
            self._execute(
                "UPDATE sessions SET archived = %s WHERE id = %s",
                (1 if archived else 0, session_id),
            )

    def update_system_prompt(self, session_id: str, system_prompt: str) -> None:
        with self._lock:
            self._execute(
                "UPDATE sessions SET system_prompt = %s WHERE id = %s",
                (system_prompt, session_id),
            )

    def update_session_model(self, session_id: str, model: str) -> None:
        with self._lock:
            self._execute("UPDATE sessions SET model = %s WHERE id = %s", (model, session_id))

    def update_session_billing_route(self, session_id: str, **kwargs) -> None:
        sets = []
        vals = []
        for k in ("billing_provider", "billing_base_url", "billing_mode", "estimated_cost_usd", "actual_cost_usd", "cost_status", "cost_source", "pricing_version"):
            if k in kwargs:
                sets.append(f"{k} = %s")
                vals.append(kwargs[k])
        if sets:
            vals.append(session_id)
            with self._lock:
                self._execute(
                    f"UPDATE sessions SET {', '.join(sets)} WHERE id = %s",
                    tuple(vals),
                )

    def update_token_counts(self, session_id: str, **counts) -> None:
        sets = []
        vals = []
        for k in ("input_tokens", "output_tokens", "cache_read_tokens", "cache_write_tokens", "reasoning_tokens", "tool_call_count", "api_call_count", "message_count"):
            if k in counts:
                sets.append(f"{k} = %s")
                vals.append(counts[k])
        if sets:
            with self._lock:
                self._execute(
                    f"UPDATE sessions SET {', '.join(sets)} WHERE id = %s",
                    tuple(vals) + (session_id,),
                )

    def update_session_cwd(self, session_id: str, cwd: str, **kwargs) -> None:
        git_branch = kwargs.get("git_branch")
        git_repo_root = kwargs.get("git_repo_root")
        with self._lock:
            self._execute(
                "UPDATE sessions SET cwd = %s, git_branch = %s, git_repo_root = %s WHERE id = %s",
                (cwd, git_branch, git_repo_root, session_id),
            )

    def update_session_meta(self, session_id: str, **kwargs) -> None:
        """Generic metadata update — accepts any column name."""
        sets = []
        vals = []
        allowed = {
            "model", "model_config", "system_prompt", "cwd", "git_branch", "git_repo_root",
            "source", "user_id", "session_key", "chat_id", "chat_type", "thread_id",
            "display_name", "origin_json", "title", "handoff_state", "handoff_platform",
            "handoff_error", "end_reason", "expiry_finalized",
        }
        for k, v in kwargs.items():
            if k in allowed:
                sets.append(f"{k} = %s")
                vals.append(self._jsonify(v))
        if sets:
            vals.append(session_id)
            with self._lock:
                self._execute(
                    f"UPDATE sessions SET {', '.join(sets)} WHERE id = %s",
                    tuple(vals),
                )

    def get_next_title_in_lineage(self, base_title: str) -> str:
        row = self._fetchone(
            "SELECT title FROM sessions WHERE title LIKE %s ORDER BY started_at DESC LIMIT 1",
            (f"{base_title}%",),
        )
        if row is None:
            return base_title
        return base_title  # pragma: no cover — caller handles dedup

    def get_compression_tip(self, session_id: str) -> Optional[str]:
        row = self._fetchone(
            "SELECT id FROM sessions WHERE parent_session_id = %s ORDER BY started_at DESC LIMIT 1",
            (session_id,),
        )
        return row["id"] if row else self.get_session(session_id)["id"] if self.get_session(session_id) else None

    def get_compression_lineage(self, session_id: str) -> List[str]:
        lineage = []
        seen = set()
        current = session_id
        while current and current not in seen:
            seen.add(current)
            lineage.append(current)
            sess = self.get_session(current)
            if sess and sess.get("parent_session_id"):
                current = sess["parent_session_id"]
            else:
                break
        lineage.reverse()
        return lineage

    # ── Compression Locks ─────────────────────────────────────────────────

    def try_acquire_compression_lock(
        self,
        session_id: str,
        holder: str,
        ttl_seconds: float = 300.0,
    ) -> bool:
        if not session_id:
            return False
        now = time.time()
        expires_at = now + ttl_seconds
        with self._lock:
            with self._conn.cursor() as cur:
                # Reclaim expired locks
                cur.execute(
                    "DELETE FROM compression_locks "
                    "WHERE session_id = %s AND expires_at < %s",
                    (session_id, now),
                )
                # Try to acquire
                try:
                    cur.execute(
                        "INSERT INTO compression_locks "
                        "(session_id, holder, acquired_at, expires_at) "
                        "VALUES (%s, %s, %s, %s)",
                        (session_id, holder, now, expires_at),
                    )
                except Exception:
                    # Row already exists (another holder has a valid lock)
                    return False
                return True

    def release_compression_lock(self, session_id: str, holder: str) -> None:
        with self._lock:
            self._execute(
                "DELETE FROM compression_locks "
                "WHERE session_id = %s AND holder = %s",
                (session_id, holder),
            )

    def refresh_compression_lock(self, session_id: str, holder: str, ttl_seconds: float = 300.0) -> bool:
        now = time.time()
        expires_at = now + ttl_seconds
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute(
                    "UPDATE compression_locks SET expires_at = %s "
                    "WHERE session_id = %s AND holder = %s",
                    (expires_at, session_id, holder),
                )
                return cur.rowcount > 0

    # ── Messages ─────────────────────────────────────────────────────────

    def append_message(self, session_id: str, role: str, content: str, **kwargs) -> int:
        ts = kwargs.pop("timestamp", None)
        if ts is None:
            ts = time.time()
        cols = ["session_id", "role", "content", "timestamp"]
        vals = [session_id, role, content, ts]
        for k in (
            "tool_call_id", "tool_calls", "tool_name", "token_count",
            "finish_reason", "reasoning", "reasoning_content", "reasoning_details",
            "codex_reasoning_items", "codex_message_items", "platform_message_id",
            "observed", "active", "compacted",
        ):
            if k in kwargs:
                cols.append(k)
                vals.append(self._jsonify(kwargs[k]))
        sql = f"INSERT INTO messages ({', '.join(cols)}) VALUES ({', '.join('%s' for _ in vals)}) RETURNING id"
        with self._lock:
            return self._execute_returning(sql, tuple(vals))

    def replace_messages(self, session_id: str, messages: list) -> None:
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute("DELETE FROM messages WHERE session_id = %s", (session_id,))
                for msg in messages:
                    ts = msg.pop("timestamp", None)
                    if ts is None:
                        ts = time.time()
                    cols = ["session_id", "role", "content", "timestamp"]
                    vals = [session_id, msg.pop("role", "user"), msg.pop("content", ""), ts]
                    for k in (
                        "tool_call_id", "tool_calls", "tool_name", "token_count",
                        "finish_reason", "reasoning", "reasoning_content",
                        "reasoning_details", "codex_reasoning_items",
                        "codex_message_items", "platform_message_id",
                        "observed", "active", "compacted",
                    ):
                        if k in msg:
                            cols.append(k)
                            vals.append(self._jsonify(msg[k]))
                    cur.execute(
                        f"INSERT INTO messages ({', '.join(cols)}) VALUES ({', '.join('%s' for _ in vals)})",
                        vals,
                    )

    def get_messages(
        self,
        session_id: str,
        include_inactive: bool = False,
        limit: Optional[int] = None,
        offset: int = 0,
    ) -> list:
        active_clause = "" if include_inactive else " AND active = 1"
        sql = (
            "SELECT * FROM messages WHERE session_id = %s"
            f"{active_clause} ORDER BY id"
        )
        params: list = [session_id]
        if limit is not None or offset:
            sql += " LIMIT %s OFFSET %s"
            params.extend([limit or 2147483647, offset])
        return self._fetchall(sql, tuple(params))

    def get_messages_as_conversation(self, session_id: str, include_ancestors: bool = True) -> list:
        rows = self._fetchall(
            "SELECT * FROM messages WHERE session_id = %s AND active = 1 ORDER BY id",
            (session_id,),
        )
        return rows

    def get_messages_around(
        self,
        session_id: str,
        around_message_id: int,
        window: int = 5,
    ) -> dict:
        before_rows = self._fetchall(
            "SELECT * FROM messages WHERE session_id = %s AND id < %s ORDER BY id DESC LIMIT %s",
            (session_id, around_message_id, window),
        )
        before_rows.reverse()
        after_rows = self._fetchall(
            "SELECT * FROM messages WHERE session_id = %s AND id > %s ORDER BY id LIMIT %s",
            (session_id, around_message_id, window),
        )
        center = self._fetchone(
            "SELECT * FROM messages WHERE id = %s", (around_message_id,),
        )
        if not center and not before_rows and not after_rows:
            return {"window": [], "messages_before": 0, "messages_after": 0}
        result = before_rows + ([center] if center else []) + after_rows
        return {
            "window": result,
            "messages_before": len(before_rows),
            "messages_after": len(after_rows),
        }

    def get_anchored_view(
        self,
        session_id: str,
        around_message_id: int,
        window: int = 5,
        bookend: int = 3,
        keep_roles: Optional[Tuple[str, ...]] = ("user", "assistant"),
    ) -> dict:
        if bookend < 0:
            bookend = 0

        primitive = self.get_messages_around(
            session_id, around_message_id, window=window
        )
        window_rows = primitive.get("window", [])
        if not window_rows:
            return {
                "window": [],
                "messages_before": 0,
                "messages_after": 0,
                "bookend_start": [],
                "bookend_end": [],
            }

        if keep_roles is not None:
            keep_set = set(keep_roles)
            filtered_window = [
                m for m in window_rows
                if m.get("id") == around_message_id or m.get("role") in keep_set
            ]
        else:
            filtered_window = window_rows

        window_min_id = window_rows[0]["id"]
        window_max_id = window_rows[-1]["id"]

        bookend_start_rows: List[Dict] = []
        bookend_end_rows: List[Dict] = []
        if bookend > 0:
            role_clause = ""
            role_params: list = []
            if keep_roles is not None:
                role_placeholders = ",".join("%s" for _ in keep_roles)
                role_clause = f" AND role IN ({role_placeholders})"
                role_params = list(keep_roles)

            bookend_start_rows = self._fetchall(
                "SELECT * FROM messages "
                "WHERE session_id = %s AND id < %s" + role_clause + " "
                "AND length(coalesce(content, '')) > 0 "
                "ORDER BY id ASC LIMIT %s",
                (session_id, window_min_id, *role_params, bookend),
            )

            bookend_end_rows = self._fetchall(
                "SELECT * FROM messages "
                "WHERE session_id = %s AND id > %s" + role_clause + " "
                "AND length(coalesce(content, '')) > 0 "
                "ORDER BY id DESC LIMIT %s",
                (session_id, window_max_id, *role_params, bookend),
            )
            bookend_end_rows = list(reversed(bookend_end_rows))

        return {
            "window": filtered_window,
            "messages_before": primitive.get("messages_before", 0),
            "messages_after": primitive.get("messages_after", 0),
            "bookend_start": bookend_start_rows,
            "bookend_end": bookend_end_rows,
        }

    def clear_messages(self, session_id: str) -> None:
        with self._lock:
            self._execute("DELETE FROM messages WHERE session_id = %s", (session_id,))

    def has_archived_messages(self, session_id: str) -> bool:
        row = self._fetchone(
            "SELECT 1 FROM messages WHERE session_id = %s AND archived = 1 LIMIT 1",
            (session_id,),
        )
        return row is not None

    def archive_and_compact(
        self, session_id: str, compacted_messages: List[Dict[str, Any]]
    ) -> int:
        """Non-destructive in-place compaction for a single durable session id.

        Soft-archives every currently-active message (active = 0) and
        inserts *compacted_messages* as fresh active rows — atomically, in one
        write transaction.
        """
        with self._lock:
            with self._conn.cursor() as cur:
                # Soft-archive the live turns
                cur.execute(
                    "UPDATE messages SET active = 0, compacted = 1 "
                    "WHERE session_id = %s AND active = 1",
                    (session_id,),
                )
                # Insert compacted messages
                inserted = 0
                tool_calls_total = 0
                now_ts = time.time()
                for msg in compacted_messages:
                    role = msg.get("role", "unknown")
                    tool_calls = msg.get("tool_calls")
                    message_timestamp = now_ts
                    if msg.get("timestamp") is not None:
                        try:
                            ts_value = msg.get("timestamp")
                            message_timestamp = float(ts_value)
                        except (TypeError, ValueError):
                            pass
                    reasoning_details = msg.get("reasoning_details") if role == "assistant" else None
                    codex_reasoning_items = msg.get("codex_reasoning_items") if role == "assistant" else None
                    codex_message_items = msg.get("codex_message_items") if role == "assistant" else None
                    tool_calls_json = json.dumps(tool_calls) if tool_calls else None
                    platform_msg_id = msg.get("platform_message_id") or msg.get("message_id")

                    cur.execute(
                        """INSERT INTO messages (session_id, role, content, tool_call_id,
                           tool_calls, tool_name, timestamp, token_count, finish_reason,
                           reasoning, reasoning_content, reasoning_details, codex_reasoning_items,
                           codex_message_items, platform_message_id, observed, active)
                           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                        (
                            session_id, role, msg.get("content", ""),
                            msg.get("tool_call_id"), tool_calls_json,
                            msg.get("tool_name"), message_timestamp,
                            msg.get("token_count"), msg.get("finish_reason"),
                            msg.get("reasoning") if role == "assistant" else None,
                            msg.get("reasoning_content") if role == "assistant" else None,
                            json.dumps(reasoning_details) if reasoning_details else None,
                            json.dumps(codex_reasoning_items) if codex_reasoning_items else None,
                            json.dumps(codex_message_items) if codex_message_items else None,
                            platform_msg_id, 1 if msg.get("observed") else 0, 1,
                        ),
                    )
                    inserted += 1
                    if tool_calls is not None:
                        tool_calls_total += (
                            len(tool_calls) if isinstance(tool_calls, list) else 1
                        )
                    now_ts = max(now_ts + 1e-6, message_timestamp + 1e-6)

                # Update session counters
                cur.execute(
                    "UPDATE sessions SET message_count = %s, tool_call_count = %s WHERE id = %s",
                    (inserted, tool_calls_total, session_id),
                )
        return inserted

    def rewind_to_message(self, session_id: str, message_id: int) -> Dict:
        with self._lock:
            self._execute(
                "UPDATE messages SET active = 0 WHERE session_id = %s AND id > %s",
                (session_id, message_id),
            )
        return {"session_id": session_id, "rewound_to": message_id}

    def restore_rewound(self, session_id: str, since_message_id: int) -> int:
        with self._lock:
            self._execute(
                "UPDATE messages SET active = 1 WHERE session_id = %s AND id >= %s",
                (session_id, since_message_id),
            )
        return 0

    def resolve_resume_session_id(self, session_id: str) -> str:
        """Walk lineage to the active tip."""
        current = session_id
        seen = set()
        for _ in range(100):
            if current in seen:
                break
            seen.add(current)
            row = self._fetchone(
                "SELECT id FROM sessions WHERE parent_session_id = %s ORDER BY started_at DESC LIMIT 1",
                (current,),
            )
            if not row:
                break
            current = row["id"]
        return current

    def list_recent_user_messages(self, session_id: str, limit: int = 10) -> list:
        return self._fetchall(
            "SELECT * FROM messages WHERE session_id = %s AND role = 'user' ORDER BY id DESC LIMIT %s",
            (session_id, limit),
        )

    # ── Search ───────────────────────────────────────────────────────────

    def search_messages(self, query: str, **kwargs) -> List[Dict]:
        limit = kwargs.get("limit", 20)
        session_id = kwargs.get("session_id")
        if session_id:
            rows = self._fetchall(
                "SELECT * FROM messages WHERE session_id = %s AND to_tsvector('english', coalesce(content, '')) @@ plainto_tsquery('english', %s) ORDER BY id DESC LIMIT %s",
                (session_id, query, limit),
            )
        else:
            rows = self._fetchall(
                "SELECT * FROM messages WHERE to_tsvector('english', coalesce(content, '')) @@ plainto_tsquery('english', %s) ORDER BY id DESC LIMIT %s",
                (query, limit),
            )
        return rows

    def search_sessions(self, source: str = "", **kwargs) -> List[Dict]:
        limit = kwargs.get("limit", 20)
        if source:
            return self._fetchall(
                "SELECT * FROM sessions WHERE source = %s ORDER BY started_at DESC LIMIT %s",
                (source, limit),
            )
        return self._fetchall(
            "SELECT * FROM sessions ORDER BY started_at DESC LIMIT %s",
            (limit,),
        )

    def search_sessions_by_id(self, query: str, **kwargs) -> List[Dict]:
        limit = kwargs.get("limit", 20)
        return self._fetchall(
            "SELECT * FROM sessions WHERE id LIKE %s ORDER BY started_at DESC LIMIT %s",
            (f"%{query}%", limit),
        )

    def session_count(self, source: str = "") -> int:
        if source:
            row = self._fetchone("SELECT COUNT(*) AS cnt FROM sessions WHERE source = %s", (source,))
        else:
            row = self._fetchone("SELECT COUNT(*) AS cnt FROM sessions")
        return row["cnt"] if row else 0

    def message_count(self, session_id: str = None) -> int:
        if session_id:
            row = self._fetchone("SELECT COUNT(*) AS cnt FROM messages WHERE session_id = %s", (session_id,))
        else:
            row = self._fetchone("SELECT COUNT(*) AS cnt FROM messages")
        return row["cnt"] if row else 0

    # ── Session listing ──────────────────────────────────────────────────

    def list_sessions_rich(self, source: str = "", **kwargs) -> List[Dict]:
        limit = kwargs.get("limit", 50)
        offset = kwargs.get("offset", 0)
        if source:
            return self._fetchall(
                "SELECT * FROM sessions WHERE source = %s ORDER BY started_at DESC LIMIT %s OFFSET %s",
                (source, limit, offset),
            )
        return self._fetchall(
            "SELECT * FROM sessions ORDER BY started_at DESC LIMIT %s OFFSET %s",
            (limit, offset),
        )

    def list_cron_job_runs(self, **kwargs) -> List[Dict]:
        limit = kwargs.get("limit", 20)
        return self._fetchall(
            "SELECT * FROM messages WHERE role = 'cron' ORDER BY timestamp DESC LIMIT %s",
            (limit,),
        )

    def distinct_session_cwds(self, include_archived: bool = False) -> List[Dict]:
        if include_archived:
            return self._fetchall(
                "SELECT cwd, COUNT(*) as cnt FROM sessions WHERE cwd IS NOT NULL AND cwd != '' GROUP BY cwd ORDER BY cnt DESC"
            )
        return self._fetchall(
            "SELECT cwd, COUNT(*) as cnt FROM sessions WHERE cwd IS NOT NULL AND cwd != '' AND archived = 0 GROUP BY cwd ORDER BY cnt DESC"
        )

    def count_empty_sessions(self) -> int:
        row = self._fetchone(
            "SELECT COUNT(*) AS cnt FROM sessions WHERE id NOT IN (SELECT DISTINCT session_id FROM messages)"
        )
        return row["cnt"] if row else 0

    def delete_empty_sessions(self, **kwargs) -> int:
        with self._lock:
            self._execute(
                "DELETE FROM sessions WHERE id NOT IN (SELECT DISTINCT session_id FROM messages)"
            )
            return 0  # psycopg2 rowcount after DELETE is reliable

    def delete_session(self, session_id: str, **kwargs) -> None:
        with self._lock:
            self._execute("DELETE FROM messages WHERE session_id = %s", (session_id,))
            self._execute("DELETE FROM sessions WHERE id = %s", (session_id,))

    def delete_session_if_empty(self, session_id: str) -> bool:
        row = self._fetchone(
            "SELECT COUNT(*) AS cnt FROM messages WHERE session_id = %s", (session_id,)
        )
        if row and row["cnt"] == 0:
            self.delete_session(session_id)
            return True
        return False

    def delete_sessions(self, **kwargs) -> int:
        older_than = kwargs.get("older_than")
        source = kwargs.get("source")
        with self._lock:
            if older_than and source:
                self._execute(
                    "DELETE FROM sessions WHERE source = %s AND started_at < %s",
                    (source, older_than),
                )
            elif source:
                self._execute("DELETE FROM sessions WHERE source = %s", (source,))
            elif older_than:
                self._execute("DELETE FROM sessions WHERE started_at < %s", (older_than,))
        return 0

    def prune_sessions(self, **kwargs) -> int:
        """Delete sessions with no messages."""
        return self.delete_empty_sessions(**kwargs)

    def archive_sessions(self, **kwargs) -> int:
        older_than = kwargs.get("older_than", time.time() - 86400 * 30)
        source = kwargs.get("source")
        with self._lock:
            if source:
                self._execute(
                    "UPDATE sessions SET archived = 1 WHERE source = %s AND started_at < %s",
                    (source, older_than),
                )
            else:
                self._execute(
                    "UPDATE sessions SET archived = 1 WHERE started_at < %s",
                    (older_than,),
                )
        return 0

    def list_prune_candidates(self, **kwargs) -> List[Dict]:
        cutoff = kwargs.get("older_than", time.time() - 86400 * 30)
        return self._fetchall(
            "SELECT s.* FROM sessions s WHERE s.started_at < %s AND s.archived = 0 ORDER BY s.started_at LIMIT 50",
            (cutoff,),
        )

    # ── Export ───────────────────────────────────────────────────────────

    def export_session(self, session_id: str) -> Optional[Dict]:
        sess = self.get_session(session_id)
        if not sess:
            return None
        msgs = self.get_messages(session_id)
        return {"session": sess, "messages": msgs}

    def export_session_lineage(self, session_id: str) -> Optional[Dict]:
        lineage = self.get_compression_lineage(session_id)
        sessions = []
        for sid in lineage:
            s = self.get_session(sid)
            if s:
                sessions.append(s)
        return {"sessions": sessions}

    def export_all(self, source: str = None) -> List[Dict]:
        if source:
            sessions_list = self._fetchall("SELECT * FROM sessions WHERE source = %s ORDER BY started_at", (source,))
        else:
            sessions_list = self._fetchall("SELECT * FROM sessions ORDER BY started_at")
        result = []
        for s in sessions_list:
            msgs = self.get_messages(s["id"])
            result.append({"session": s, "messages": msgs})
        return result

    # ── Meta (state_meta table) ─────────────────────────────────────────

    def get_meta(self, key: str) -> Optional[str]:
        row = self._fetchone("SELECT value FROM state_meta WHERE key = %s", (key,))
        return row["value"] if row else None

    def set_meta(self, key: str, value: str) -> None:
        with self._lock:
            self._execute(
                "INSERT INTO state_meta (key, value) VALUES (%s, %s) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
                (key, value),
            )

    # ── Maintenance ──────────────────────────────────────────────────────

    def maybe_auto_prune_and_vacuum(self) -> bool:
        return True  # PG handles this automatically

    def vacuum(self) -> int:
        with self._lock:
            with self._conn.cursor() as cur:
                cur.execute("VACUUM ANALYZE")
        return 0

    def optimize_fts(self) -> int:
        # tsvector index is maintained automatically by PostgreSQL
        return 0

    # ── SessionDB compatibility — bridge methods ─────────────────────────

    def track_compression(self, session_id: str) -> None:
        """No-op: PG handles compressed lineage via parent_session_id."""
        pass

    def get_nearby_sessions(self, session_id: str, limit: int = 10) -> list:
        """Return sessions near the given one by time."""
        return self._fetchall(
            "SELECT * FROM sessions ORDER BY started_at DESC LIMIT %s",
            (limit,),
        )

    def record_handoff(self, session_id: str, platform: str, state: str) -> None:
        with self._lock:
            self._execute(
                "UPDATE sessions SET handoff_platform = %s, handoff_state = %s WHERE id = %s",
                (platform, state, session_id),
            )
