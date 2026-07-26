"""
Tone detection — heuristic language/formality/energy classifier.

Ported from text-csm ``realness_engine.py`` (detect_tone, ToneProfile,
ToneHistory). Pure heuristics, no LLM calls — runs synchronously in
sub-millisecond time.

Integration:
  1. Call ``detect_tone()`` per user turn, passing the message and an
     optional ``ToneHistory`` instance for a language prior on ambiguous
     messages.
  2. Call ``tone.mirror_instruction()`` to get a system-prompt-ready
     instruction string.
  3. Record the tone with ``tone_history.record()`` and inject the
     instruction into the volatile prompt tier.
"""

from __future__ import annotations

import re
from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

# ── Vocabulary ────────────────────────────────────────────────────────────────
# Indonesian casual/slang markers
_ID_SLANG = {
    "lu", "lo", "gw", "gue", "gak", "gk", "nggak", "ngga", "ga", "tau",
    "nih", "sih", "deh", "dong", "lah", "kalo", "trus", "terus", "udah",
    "udh", "blm", "aja", "emg", "emang", "beneran", "gan", "cuy", "sob",
    "woy", "gimana", "kenapa", "ngapain", "apaan", "anjir", "anjay",
    "mantap", "mantep", "ngerti", "nemu", "yuk", "yg", "dgn", "utk",
}
# English internet slang / leet markers
_EN_SLANG = {
    "ngl", "imo", "tbh", "idk", "idc", "lol", "lmao", "lmfao", "omg",
    "wtf", "bruh", "fr", "frfr", "nah", "yea", "rn", "smh", "fwiw",
    "afaik", "iirc", "hmu", "wdym", "istg", "lowkey", "highkey", "bet",
    "sus", "slay", "cap", "bussin", "fam", "yo", "sup", "wassup",
}
# Short non-stop-word abbreviations that signal leet/slang
_ABBREV_SLANG = {
    "gk", "gw", "lu", "lo", "fr", "rn", "imo", "tbh", "idk", "ngl",
    "smh", "omg", "wtf", "btw", "lol", "xd", "hm", "gg", "wp", "ez",
    "nvm", "imo", "fyi", "eta", "asap",
}
# Common stop words — short but NOT slang
_STOP_WORDS = {
    "i", "a", "in", "of", "to", "is", "it", "my", "me", "we", "an",
    "at", "be", "do", "go", "he", "if", "no", "on", "or", "so", "up",
    "us", "am", "as", "by", "hi", "ok", "the", "and", "for", "not",
    "but", "you", "can", "are", "was", "has", "had", "did", "his",
    "her", "its", "our", "who", "all", "one", "how", "why", "the",
    "its", "too", "yes", "yet", "now", "new", "old", "let",
}
# Formal Indonesian markers (if present, shift toward formal)
_ID_FORMAL = {"saya", "anda", "bapak", "ibu", "mohon", "silakan", "dengan hormat"}


# =========================================================================
# Data classes
# =========================================================================


@dataclass
class ToneProfile:
    """Detected tone/register of a single user message."""

    language: str         # "en", "id", "mixed", "unknown"
    formality: str        # "formal", "casual", "slang"
    energy: str           # "low", "medium", "high"
    has_leet: bool        # abbreviations, missing vowels, numerals in words
    script_hints: List[str] = field(default_factory=list)  # raw markers found

    def mirror_instruction(self) -> str:
        """Return a concrete instruction for the LLM to mirror this tone.

        Injected into the system prompt each turn.
        """
        lang_map = {
            "id": "Indonesian", "en": "English", "mixed": "mixed Indonesian/English"
        }
        lang = lang_map.get(self.language, "the same language as the user")

        parts = [f"Respond in {lang}."]

        if self.formality == "slang" or self.has_leet:
            parts.append(
                "User is writing in casual slang/leet. Match their register: "
                "be informal, short, use the same vocabulary style. "
                "Do NOT use formal pronouns or polite filler phrases."
            )
        elif self.formality == "casual":
            parts.append(
                "User is writing casually. Stay relaxed and conversational — "
                "no stiff phrasing."
            )
        else:
            parts.append("User is writing formally. Match their register.")

        if self.energy == "low":
            parts.append("Low energy message — keep the response brief and low-key.")
        elif self.energy == "high":
            parts.append("High energy message — match the enthusiasm.")

        return " ".join(parts)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "language": self.language,
            "formality": self.formality,
            "energy": self.energy,
            "has_leet": self.has_leet,
            "script_hints": self.script_hints,
        }


@dataclass
class ToneHistory:
    """Rolling history of per-turn tone profiles.

    Enables within-session trend analysis — e.g. "user usually writes
    casual Indonesian" — which feeds back into single-message detection as a
    language prior, and into the system prompt so the LLM knows the user's
    typical register even when a short message is ambiguous.
    """

    entries: List[Dict[str, Any]] = field(default_factory=list)
    max_entries: int = 100

    def record(self, tone: ToneProfile, turn: int) -> None:
        """Append a tone snapshot for this turn."""
        self.entries.append({
            "turn": turn,
            "language": tone.language,
            "formality": tone.formality,
            "energy": tone.energy,
            "has_leet": tone.has_leet,
            "timestamp": datetime.now().isoformat(),
        })
        if len(self.entries) > self.max_entries:
            self.entries = self.entries[-self.max_entries:]

    def dominant(self, last_n: int = 10) -> Optional[Dict[str, str]]:
        """Most common language / formality / energy over last N turns.

        Returns None if no history yet.
        """
        recent = self.entries[-last_n:]
        if not recent:
            return None
        known_langs = [e["language"] for e in recent if e["language"] != "unknown"]
        lang  = Counter(known_langs).most_common(1)
        form  = Counter(e["formality"] for e in recent).most_common(1)
        enrgy = Counter(e["energy"] for e in recent).most_common(1)
        return {
            "language": lang[0][0] if lang else "unknown",
            "formality": form[0][0] if form else "casual",
            "energy": enrgy[0][0] if enrgy else "medium",
        }

    def trend_summary(self, last_n: int = 5) -> str:
        """One-liner for system prompt injection."""
        dom = self.dominant(last_n)
        if not dom:
            return ""
        return f"User typically: {dom['language']} / {dom['formality']} / {dom['energy']} energy"

    def formality_drift(self, window: int = 6) -> Optional[str]:
        """Detect if the user is becoming more or less formal recently.

        Returns ``"becoming_formal"``, ``"becoming_casual"``, or ``None``.
        """
        if len(self.entries) < window:
            return None
        _rank = {"formal": 2, "casual": 1, "slang": 0}
        first_half = self.entries[-(window):-(window // 2)]
        second_half = self.entries[-(window // 2):]
        avg_before = sum(_rank.get(e["formality"], 1) for e in first_half) / len(first_half)
        avg_after  = sum(_rank.get(e["formality"], 1) for e in second_half) / len(second_half)
        if avg_after - avg_before > 0.5:
            return "becoming_formal"
        if avg_before - avg_after > 0.5:
            return "becoming_casual"
        return None

    def to_dict(self) -> Dict[str, Any]:
        return {"entries": self.entries, "max_entries": self.max_entries}


# =========================================================================
# Detection
# =========================================================================


def _infer_language_from_history(history: List[Dict]) -> str:
    """Look at recent user messages to infer dominant language."""
    counts = {"id": 0, "en": 0}
    for msg in reversed(history[-6:]):
        if msg.get("role") != "user":
            continue
        words = set(re.findall(r"[a-zA-Z']+", msg.get("content", "").lower()))
        if words & _ID_SLANG:
            counts["id"] += 1
        if words & _EN_SLANG:
            counts["en"] += 1
    if counts["id"] > counts["en"]:
        return "id"
    if counts["en"] > counts["id"]:
        return "en"
    return "unknown"


def detect_tone(
    message: str,
    history: Optional[List[Dict]] = None,
    tone_history: Optional[ToneHistory] = None,
) -> ToneProfile:
    """Heuristic tone detection from a single message + optional context.

    Does not call an external model — runs synchronously, zero latency.
    ``tone_history`` provides a language prior when a short or ambiguous
    message has no clear language signal.
    """
    words = re.findall(r"[a-zA-Z']+", message.lower())
    word_set = set(words)

    # ── Language detection ───────────────────────────────────────────────
    id_hits = word_set & _ID_SLANG
    en_hits = word_set & _EN_SLANG
    id_form = any(f in message.lower() for f in _ID_FORMAL)
    has_nonascii = bool(re.search(r'[^\x00-\x7F]', message))

    if id_hits and en_hits:
        language = "mixed"
    elif id_hits or id_form or has_nonascii:
        language = "id"
    elif en_hits:
        language = "en"
    else:
        # Fallback 1: use rolling tone history dominant language (within-session prior)
        if tone_history:
            dom = tone_history.dominant(last_n=8)
            if dom and dom["language"] != "unknown":
                language = dom["language"]
            else:
                language = _infer_language_from_history(history) if history else "unknown"
        else:
            language = _infer_language_from_history(history) if history else "unknown"

    # ── Formality ────────────────────────────────────────────────────────
    non_stop_short = [w for w in words if len(w) <= 3 and w not in _STOP_WORDS]
    abbrev_hits = word_set & _ABBREV_SLANG

    has_leet = bool(
        id_hits
        or en_hits
        or abbrev_hits
        or re.search(r'\b\w*\d\w*\b', message)   # numbers inside words (l33t)
        or len(non_stop_short) >= 2               # multiple unexplained short words
    )

    if id_form and not id_hits:
        formality = "formal"
    elif has_leet:
        formality = "slang"
    else:
        formality = "casual"

    # ── Energy ───────────────────────────────────────────────────────────
    exclamations = message.count("!")
    caps_words = len(re.findall(r'\b[A-Z]{2,}\b', message))
    char_len = len(message.strip())

    if exclamations >= 2 or caps_words >= 2:
        energy = "high"
    elif exclamations == 1 or (id_hits and char_len < 30):
        energy = "medium"
    elif char_len < 12 and not (id_hits or en_hits):
        energy = "low"
    else:
        energy = "medium"

    script_hints = list(id_hits | en_hits)[:6]

    return ToneProfile(
        language=language,
        formality=formality,
        energy=energy,
        has_leet=has_leet,
        script_hints=script_hints,
    )
