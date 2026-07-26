"""
Dynamic curiosity computation — per-turn heuristic for follow-up question decisions.

Ported from text-csm ``realness_engine.py`` (compute_dynamic_curiosity,
DynamicCuriosityResult, CuriositySignal).

Pure heuristics, no LLM calls. Computes a curiosity score (0.0-1.0) from
9 contextual signals in the user's message:

  ambiguity       +0.15-0.25   Short or vague message
  excitement      +0.10-0.20   Exclamation marks, CAPS, excitement words
  critical_event  +0.20        Problem/crash/fix keywords
  topic_novelty   +0.10-0.30   New concepts vs known topics
  engagement_mom  +0.10-0.15   Rising engagement trend
  repeat_topic    −0.20        Continuing established topic (dampener)
  long_message    −0.10        User already elaborating (dampener)

The result produces a directive: ask one follow-up, ask only if needed,
or do NOT ask.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


# Signal vocabularies
_EXCITEMENT_WORDS = {"amazing", "incredible", "finally", "omg", "wow",
                     "works", "nailed", "perfect", "love"}
_CRITICAL_WORDS = {"crashed", "broke", "broken", "failed", "deployed",
                   "shipped", "fixed", "urgent", "down", "blocked", "stuck"}
_VAGUE_OPENERS = ("you know", "i mean", "like,", "so,", "anyway",
                  "btw,", "well,", "thing is")
_STOP_WORDS = {"the", "and", "for", "that", "with", "this", "they",
               "have", "from", "will", "been", "were", "their", "what",
               "when", "then", "also", "some", "more", "over", "into",
               "your", "about", "which", "like", "just", "very", "even"}


@dataclass
class CuriositySignal:
    """One detected signal that influences the curiosity computation."""
    name: str
    delta: float   # positive = boost, negative = dampen
    reason: str

    def to_dict(self) -> Dict:
        return {"name": self.name, "delta": round(self.delta, 2),
                "reason": self.reason}


@dataclass
class DynamicCuriosityResult:
    """Result of per-turn curiosity computation."""
    base: float
    computed: float
    signals: List[CuriositySignal] = field(default_factory=list)

    @property
    def level(self) -> str:
        if self.computed >= 0.65:
            return "high"
        if self.computed >= 0.35:
            return "moderate"
        return "low"

    def followup_directive(self) -> str:
        """Return a human-readable instruction for the system prompt."""
        if self.level == "high":
            return ("→ Ask one focused follow-up question if it would "
                    "meaningfully deepen the conversation.")
        if self.level == "moderate":
            return ("→ Ask a follow-up only if genuinely necessary to "
                    "give a complete answer.")
        return ("→ Do NOT ask a follow-up question unless the message "
                "is completely ambiguous.")

    def prompt_description(self) -> str:
        """Full description for injection into the system prompt."""
        lines = [f"Curiosity: {self.level.upper()} "
                 f"(base {self.base:.2f} → computed {self.computed:.2f})"]
        for s in self.signals:
            sign = "+" if s.delta >= 0 else ""
            lines.append(f"  {sign}{s.delta:+.2f}  [{s.name}] {s.reason}")
        lines.append(self.followup_directive())
        return "\n".join(lines)


def compute_dynamic_curiosity(
    message: str,
    history: List[Dict[str, Any]],
    base: float = 0.5,
) -> DynamicCuriosityResult:
    """Compute per-turn curiosity from contextual signals.

    Args:
        message: The user's current message
        history: Full conversation history list of {role, content} dicts
        base: Base curiosity tendency (0-1), default 0.5

    Returns:
        DynamicCuriosityResult with computed score, level, and signals
    """
    signals: List[CuriositySignal] = []
    msg_lower = message.lower().strip()

    # ── Ambiguity: short / vague message ────────────────────────────────
    if len(message.strip()) < 20:
        signals.append(CuriositySignal(
            "ambiguity", +0.25,
            "very short message — hard to respond fully without more context"
        ))
    elif len(message.strip()) < 40 or any(msg_lower.startswith(v) for v in _VAGUE_OPENERS):
        signals.append(CuriositySignal(
            "ambiguity", +0.15,
            "short or vague opener — invites clarification"
        ))

    # ── Excitement ──────────────────────────────────────────────────────
    exclamation_count = message.count("!")
    caps_words = len(re.findall(r'\b[A-Z]{2,}\b', message))
    if exclamation_count >= 2 or caps_words >= 2:
        signals.append(CuriositySignal(
            "excitement", +0.20,
            f"high energy ({exclamation_count}x'!', {caps_words} caps words)"
        ))
    elif exclamation_count == 1 or any(w in msg_lower for w in _EXCITEMENT_WORDS):
        signals.append(CuriositySignal(
            "excitement", +0.10,
            "mild excitement or enthusiasm signal"
        ))

    # ── Critical event ──────────────────────────────────────────────────
    if any(w in msg_lower for w in _CRITICAL_WORDS):
        signals.append(CuriositySignal(
            "critical_event", +0.20,
            "critical/significant event keyword detected"
        ))

    # ── Topic novelty ───────────────────────────────────────────────────
    # Extract known topics from recent user messages
    known_topics: set = set()
    for m in history[-10:]:
        if m.get("role") != "user":
            continue
        words = set(re.findall(r'\b\w{4,}\b', m.get("content", "").lower()))
        known_topics.update(words - _STOP_WORDS)

    words = set(re.findall(r'\b\w{4,}\b', msg_lower))
    if known_topics and words:
        overlap = len(words & known_topics) / max(len(words), 1)
        if overlap < 0.1:
            signals.append(CuriositySignal(
                "topic_novelty", +0.30,
                "mostly new concepts not seen before"
            ))
        elif overlap < 0.3:
            signals.append(CuriositySignal(
                "topic_novelty", +0.10,
                "some new concepts mixed with familiar ones"
            ))
    elif not known_topics:
        signals.append(CuriositySignal(
            "topic_novelty", +0.15,
            "no prior topics — first real exchange"
        ))

    # ── Engagement momentum ─────────────────────────────────────────────
    recent_msgs = [m for m in history[-6:] if m.get("role") == "user"]
    older_msgs = [m for m in history[-10:-6] if m.get("role") == "user"]
    if recent_msgs and older_msgs:
        recent_avg = sum(len(m.get("content", "")) for m in recent_msgs) / len(recent_msgs)
        older_avg = sum(len(m.get("content", "")) for m in older_msgs) / len(older_msgs)
        current_eng = min(1.0, recent_avg / 100)
        previous_eng = min(1.0, older_avg / 100)
        if current_eng > previous_eng + 0.1:
            signals.append(CuriositySignal(
                "engagement_momentum", +0.15,
                f"engagement rising ({previous_eng:.0%} → {current_eng:.0%})"
            ))
        elif current_eng > 0.6:
            signals.append(CuriositySignal(
                "engagement_high", +0.10,
                f"sustained high engagement ({current_eng:.0%})"
            ))

    # ── Repeat topic (dampener) ─────────────────────────────────────────
    user_msgs = [m["content"].lower() for m in history[-4:]
                 if isinstance(m, dict) and m.get("role") == "user"]
    if user_msgs and any(t in msg_lower for t in user_msgs[-3:]):
        signals.append(CuriositySignal(
            "repeat_topic", -0.20,
            "continuing established topic — less need to probe"
        ))

    # ── Long elaborated message (dampener) ───────────────────────────────
    if len(message) > 200:
        signals.append(CuriositySignal(
            "long_message", -0.10,
            "user is elaborating — don't interrupt with questions"
        ))

    total_delta = sum(s.delta for s in signals)
    computed = max(0.0, min(1.0, base + total_delta))

    return DynamicCuriosityResult(base=base, computed=computed, signals=signals)
