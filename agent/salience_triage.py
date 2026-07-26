"""
Salience triage — classify conversation turns by memorability.

Ported from text-csm ``realness_engine.py`` (SalienceTriage, TriageResult).

Determines whether a user message is worth persisting to long-term memory:
  - SENSORY  — transient noise (acknowledgments, processing signals, check-ins).
    DROPPED from Honcho writes.
  - EPISODIC — specific events, problems, actions, changes. STORED.
  - SEMANTIC — stable facts, preferences, principles, beliefs. STORED.

Heuristic-only (keyword sets + message length), no LLM calls.
Synchronous, sub-millisecond.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import List


class MemoryType(Enum):
    SENSORY = "sensory"
    EPISODIC = "episodic"
    SEMANTIC = "semantic"


@dataclass
class TriageResult:
    """Output of salience classification for one user message."""
    memory_type: MemoryType
    priority: int         # 1–10
    entities: List[str] = field(default_factory=list)


# ── Marker vocabularies ───────────────────────────────────────────────────────

_EPISODIC_MARKERS = {
    "migrated", "moved", "switched", "installed", "setup", "configured",
    "fixed", "solved", "resolved", "broke", "crashed", "failed",
    "deployed", "shipped", "launched", "released", "completed", "finished",
    "started", "began", "tried", "discovered", "realized", "learned",
    "decided", "changed", "updated", "upgraded", "downgraded",
    "happened", "occurred", "experienced", "met", "talked", "built",
    "created", "deleted", "removed", "added", "integrated",
}

_SEMANTIC_PHRASES = [
    "i prefer", "i always", "i usually", "i typically", "i tend to",
    "i'm a ", "i am a ", "i work ", "i use ", "i do ", "i have ",
    "my setup", "my stack", "my workflow", "my approach", "my name",
    "my job", "my project", "i believe", "i know", "i like", "i love",
    "i hate", "i dislike", "i want", "i think", "i use ",
]

_CRITICAL_WORDS = {
    "urgent", "critical", "important", "asap", "emergency",
    "production", "prod", "outage", "incident", "down", "broken",
    "blocked", "stuck",
    "crashed", "crashing", "error", "errors", "issue", "issues",
    "problem", "failing", "fail", "bug", "freeze", "freezing",
}

_RESOLUTION_MARKERS = {
    "fixed", "solved", "resolved", "sorted", "works", "working",
    "figured", "done", "closed", "patched", "reverted", "workaround",
}

_TOPIC_SHIFT_SIGNALS = {"btw", "anyway", "actually", "nevermind", "forget", "different"}

# Messages consisting entirely of these patterns are SENSORY (e.g. processing
# signals, short acknowledgments, status markers)
_SENSORY_PATTERNS = [
    r"^\[?\w+\]?\s*$",                   # [checking], [searcing], checking
    r"^(on it|got it|ok|okay|sure|yes|no|done|thanks|ty)$",
    r"^\[.*?\]",                         # [checking] [searching] [building]
    r"^let me\s+(check|look|see|try|find|search)",
    r"^i'?ll\s+(check|look|see|try|find|search)",
    r"^one moment",
    r"^working on it",
]

_STOP_WORDS = {
    "the", "and", "for", "that", "with", "this", "they",
    "have", "from", "will", "been", "were", "their", "what",
    "when", "then", "also", "some", "more", "over", "into",
    "your", "about", "which", "like", "just", "very", "even",
}


def _extract_concepts(message: str) -> List[str]:
    """Extract meaningful concepts from a message for entity tracking.

    Priority order:
      1. CamelCase / PascalCase tokens  — NixOS, YouTube
      2. Quoted / backtick-enclosed terms
      3. Hyphenated compounds
      4. Individual 7+ char content words
    """
    concepts: List[str] = []

    # 1. CamelCase / PascalCase
    for m in re.finditer(
        r"\b[A-Z]{2,}[a-z]+\w*\b"
        r"|\b[A-Z][a-z]+[A-Z]\w*\b"
        r"|\b(?:[A-Z][a-z]+){2,}\b",
        message,
    ):
        concepts.append(m.group(0))

    # 2. Quoted / backtick terms
    for m in re.finditer(r'["\']([^"\']{3,40})["\']|`([^`]{3,40})`', message):
        term = (m.group(1) or m.group(2) or "").strip()
        if term and len(term) > 3:
            concepts.append(term)

    # 3. Hyphenated compounds
    for m in re.finditer(r"\b\w{3,}-\w{3,}(?:-\w{2,})?\b", message):
        concepts.append(m.group(0))

    # 4. Individual 7+ char words
    for w in re.findall(r"\b\w{7,}\b", message):
        if w.lower() not in _STOP_WORDS:
            concepts.append(w)

    # Deduplicate preserving order, lowercase
    seen: set = set()
    result: List[str] = []
    for c in concepts:
        key = c.lower().strip()
        if key and key not in seen and len(key) > 3:
            seen.add(key)
            result.append(key)
    return result[:10]


def classify(message: str) -> TriageResult:
    """Classify a user message by memorability.

    Returns a TriageResult with memory_type (SENSORY/EPISODIC/SEMANTIC)
    and a priority score (1-10).
    """
    if not message or not message.strip():
        return TriageResult(MemoryType.SENSORY, 1)

    msg_lower = message.lower().strip()
    words = set(re.findall(r"\b\w{3,}\b", msg_lower))
    char_len = len(message.strip())

    # Fast-path: detect pure SENSORY patterns (processing signals, ack, etc.)
    for pattern in _SENSORY_PATTERNS:
        if re.search(pattern, msg_lower):
            return TriageResult(MemoryType.SENSORY, 1)

    entities = _extract_concepts(message)

    has_semantic = bool(
        any(phrase in msg_lower for phrase in _SEMANTIC_PHRASES)
    )
    has_episodic = bool(words & _EPISODIC_MARKERS)
    has_critical = bool(words & _CRITICAL_WORDS)
    has_resolution = bool(words & _RESOLUTION_MARKERS)

    # Short casual messages with no episodic/semantic content are SENSORY,
    # unless they end with "?" (questions are substantive queries).
    is_short_casual = (
        char_len < 30
        and not has_episodic
        and not has_semantic
        and not has_critical
        and not msg_lower.rstrip().endswith("?")
    )

    # Memory type: most specific tier wins
    if has_semantic:
        memory_type = MemoryType.SEMANTIC
    elif has_episodic or has_critical or has_resolution:
        memory_type = MemoryType.EPISODIC
    elif char_len > 80:
        # Long messages even without explicit markers are often substantive
        memory_type = MemoryType.EPISODIC
    elif is_short_casual:
        memory_type = MemoryType.SENSORY
    else:
        memory_type = MemoryType.EPISODIC  # default to keeping it

    # Priority score
    priority = 3
    if has_critical:
        priority += 3
    if has_episodic:
        priority += 2
    if has_semantic:
        priority += 2
    if char_len > 150:
        priority += 1
    if char_len < 20 and not has_critical:
        priority = max(1, priority - 2)
    priority = min(10, priority)

    return TriageResult(memory_type=memory_type, priority=priority, entities=entities)


def is_noteworthy(user_message: str) -> bool:
    """Quick check: should this turn be written to long-term memory?

    Returns True for EPISODIC and SEMANTIC turns, False for SENSORY noise.
    """
    return classify(user_message).memory_type != MemoryType.SENSORY
