"""
Confidence-gated circuit breaker — heuristic detection of LLM self-reported
confidence levels and iteration budget penalty.

The model is instructed (via <uncertainty> guidance) to self-identify its
confidence in four tiers: HIGH, MEDIUM, LOW, UNCERTAIN. This module scans
the response text for those signals and applies iteration-budget penalties
so a low-confidence model stops calling tools and just responds.

Heuristic-only, no LLM calls. Synchronous, sub-millisecond.
"""

from __future__ import annotations

import re
from typing import Dict, Optional


# Confidence markers — ordered from strongest signal to weakest
_HIGH_MARKERS = re.compile(
    r"(?:^|\b)(?:I'm\s+)?(?:certain|confident|sure)\b",
    re.IGNORECASE,
)
_MEDIUM_MARKERS = re.compile(
    r"\b(?:I\s+think|I\s+believe|likely|probably|should\s+be|reasoned\b)",
    re.IGNORECASE,
)
_LOW_MARKERS = re.compile(
    r"\b(?:speculative|not\s+sure|could\s+be\s+wrong|may\s+not\s+be|"
    r"this\s+is\s+my\s+best\s+guess|hard\s+to\s+say|not\s+certain|"
    r"without\s+more\s+info|i'd\s+need\s+to\s+check)",
    re.IGNORECASE,
)
_UNCERTAIN_MARKERS = re.compile(
    r"\b(?:I\s+don't\s+know|I\s+don't\s+have|I'm\s+not\s+sure|"
    r"I'm\s+uncertain|genuinely\s+don't\s+know|"
    r"uncertain\b|cannot\s+determine|can't\s+determine|"
    r"not\s+enough\s+information|beyond\s+my\s+knowledge)",
    re.IGNORECASE,
)


def detect_confidence(text: str) -> str:
    """Scan response text for confidence signals.

    Returns one of ``"high"``, ``"medium"``, ``"low"``, or ``"uncertain"``.
    Checks strongest signals first (uncertain → low → high → medium).
    Falls back to ``"high"`` when no explicit signal is found (default
    assumption — most responses have no confidence annotation).

    The priority order is deliberate: UNCERTAIN is the strongest signal
    (explicit admission), followed by LOW (speculative language), HIGH
    (explicit certainty), then MEDIUM (weakest signal — "I think" is
    conversational filler as often as a deliberate confidence marker).
    """
    if not text or not text.strip():
        return "high"

    # Check strongest signals first
    if _UNCERTAIN_MARKERS.search(text):
        return "uncertain"

    if _LOW_MARKERS.search(text):
        return "low"

    if _HIGH_MARKERS.search(text):
        return "high"

    if _MEDIUM_MARKERS.search(text):
        return "medium"

    return "high"


def confidence_penalty(level: str) -> int:
    """Return the iteration-budget penalty for a confidence level.

    * ``"high"`` — 0 (no penalty, full budget)
    * ``"medium"`` — 0 (no penalty, still engaging)
    * ``"low"`` — 1 (consume one extra iteration)
    * ``"uncertain"`` — 2 (consume two extra iterations)
    """
    return {"high": 0, "medium": 0, "low": 1, "uncertain": 2}.get(level, 0)
