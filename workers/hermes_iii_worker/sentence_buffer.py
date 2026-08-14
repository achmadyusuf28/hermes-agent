"""
Sentence buffer — accumulates stream deltas and emits at sentence boundaries.

Designed to run inside AIAgent.stream_delta_callback (called from the
executor thread during run_conversation). Calls on_sentence(text, seq)
at each detected sentence/thought boundary.
"""
from __future__ import annotations

import re
from typing import Callable

# Sentence-ending patterns — period, exclamation, question mark,
# or double newline (paragraph break)
_SENTENCE_END = re.compile(r"[.!?\u3002\uff01\uff1f][\s\n]|[\n\u3000]{2,}")


class SentenceBuffer:
    """Accumulates raw stream tokens, fires callbacks at sentence boundaries.

    Args:
        on_sentence: Called with (clean_sentence_text, sequence_number)
                     for each completed sentence.
        on_flush:    Called with (remaining_text, sequence_number) on flush.
        min_chars:   Minimum characters before emitting a sentence
                     (avoids tiny fragments like "Ok." as standalone messages).
    """

    def __init__(
        self,
        on_sentence: Callable[[str, int], None] | None = None,
        on_flush: Callable[[str, int], None] | None = None,
        min_chars: int = 15,
    ) -> None:
        self._buffer = ""
        self._seq = 0
        self.on_sentence = on_sentence
        self.on_flush = on_flush
        self.min_chars = min_chars

    def feed(self, token: str) -> None:
        """Feed a stream delta token. Fires on_sentence at boundaries."""
        self._buffer += token

        # Scan for sentence boundaries
        while True:
            m = _SENTENCE_END.search(self._buffer)
            if not m:
                break
            end = m.end()
            sentence = self._buffer[:end].strip()
            self._buffer = self._buffer[end:]

            if sentence and len(sentence) >= self.min_chars:
                self._seq += 1
                if self.on_sentence:
                    try:
                        self.on_sentence(sentence, self._seq)
                    except Exception:
                        pass

    def flush(self) -> None:
        """Emit any remaining buffered text."""
        remaining = self._buffer.strip()
        if remaining:
            self._seq += 1
            if self.on_flush:
                try:
                    self.on_flush(remaining, self._seq)
                except Exception:
                    pass
            elif self.on_sentence:
                try:
                    self.on_sentence(remaining, self._seq)
                except Exception:
                    pass
        self._buffer = ""

    @property
    def sequence(self) -> int:
        return self._seq

    # ── Convenience: build the streaming callback tuple ────────────────

    @classmethod
    def build_callback(
        cls,
        on_sentence: Callable[[str, int], None],
        min_chars: int = 15,
    ) -> tuple[Callable[[str], None], Callable[[], None]]:
        """Return (feed_fn, flush_fn) callbacks for the given on_sentence handler.

        Use as::

            feed, flush = SentenceBuffer.build_callback(publish_sentence)
            agent.stream_delta_callback = feed
            result = agent.run_conversation(prompt)
            flush()
        """
        buf = cls(on_sentence=on_sentence, min_chars=min_chars)
        return buf.feed, buf.flush


class TurnBuffer:
    """Accumulates sentences into conversational turns before emitting.

    Instead of firing every sentence boundary as a separate message, this
    groups sentences into "turns" — coherent thought units that the user can
    digest and respond to. Turns are emitted when:

    * Max *max_sentences* sentences accumulated, OR
    * A sentence ends with ``?`` (question = opens the floor)

    The ``on_turn`` callback receives the combined text once per turn.

    Args:
        on_turn: Called with (combined_text, turn_number) for each turn.
        max_sentences: Max sentences before auto-emitting (default 2).

    Usage::

        def send_turn(text, num):
            _send_message(text)

        buf = TurnBuffer(on_turn=send_turn)
        buf.accumulate("First sentence.")
        buf.accumulate("Second sentence.")  # → auto-emit
        buf.accumulate("What do you think?")  # → auto-emit (question)
        buf.flush()  # emit any remaining
    """

    def __init__(
        self,
        on_turn: Callable[[str, int], None] | None = None,
        max_sentences: int = 2,
    ) -> None:
        self._buffer: list[str] = []
        self._turn_seq = 0
        self.on_turn = on_turn
        self.max_sentences = max_sentences

    def accumulate(self, text: str, seq: int) -> None:  # noqa: ARG002  — accept same signature as on_sentence
        """Feed a completed sentence. Emits a turn on boundaries."""
        text = text.strip()
        if not text:
            return
        self._buffer.append(text)

        # Question-ending sentences open the floor → emit immediately
        if text.endswith("?"):
            self._emit()
            return

        # Max sentences reached → emit
        if len(self._buffer) >= self.max_sentences:
            self._emit()

    def flush(self) -> None:
        """Emit any remaining buffered sentences."""
        if self._buffer:
            self._emit()

    def _emit(self) -> None:
        """Combine buffered sentences and fire the callback."""
        if not self._buffer:
            return
        combined = " ".join(self._buffer)
        self._buffer.clear()
        self._turn_seq += 1
        if self.on_turn:
            try:
                self.on_turn(combined, self._turn_seq)
            except Exception:
                pass

    @property
    def turn_number(self) -> int:
        return self._turn_seq
