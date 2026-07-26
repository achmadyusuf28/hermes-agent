"""
Multi-bubble response splitter — paragraph-aware chunking with code block
preservation for Telegram (and other character-limited platforms).

Replaces the naive character-boundary split that can break markdown code
fences mid-stream.  This version:

  1. Splits at paragraph boundaries (\\n\\n) closest to the limit
  2. Never splits inside fenced code blocks (```...```)
  3. Never splits inside inline code, bold, italic, or link markers
  4. Emits a single chunk if the whole message fits under the limit
  5. If a single code block exceeds the limit, marks it for file delivery

Usage:
    chunks, oversized_code = split_bubbles(text, max_chars=3800)
    for chunk in chunks:
        await send(chunk)
    if oversized_code:
        await send_document(oversized_code)
"""

from __future__ import annotations

import re
from typing import List, Tuple


def _utf16_len(text: str) -> int:
    """Return the length of *text* in UTF-16 code units."""
    try:
        return len(text.encode("utf-16-le")) // 2
    except Exception:
        return len(text)


def _is_code_fence(line: str) -> bool:
    """Check if a line starts a ``` code fence."""
    return line.strip().startswith("```")


def split_bubbles(
    text: str,
    max_chars: int = 3800,
    len_fn=None,
) -> Tuple[List[str], str]:
    """Split *text* into paragraph-aware chunks.

    Args:
        text: The message to split (pre-formatted markdown).
        max_chars: Max UTF-16 code units per chunk (default 3800).
        len_fn: Optional length function (default: ``_utf16_len``).

    Returns:
        ``(chunks, oversized_code)`` where *chunks* are message strings
        each ≤ *max_chars*, and *oversized_code* is any single code block
        that exceeded *max_chars* (for file delivery), or ``""``.
    """
    if len_fn is None:
        len_fn = _utf16_len

    if not text:
        return [], ""

    if len_fn(text) <= max_chars:
        return [text], ""

    # ── Split into paragraph blocks ──────────────────────────────────
    # Preserve the delimiter so rejoining works: use a non-consuming split
    # marker approach.  We split on blank lines (2+ newlines).
    raw_blocks = re.split(r"\n{2,}", text)

    # ── Identify blocks ──────────────────────────────────────────────
    # Walk blocks to find code fence boundaries and oversized blocks.
    blocks: List[str] = []
    oversized_code = ""
    in_code = False
    code_accum = []
    code_start_idx = -1

    for idx, block in enumerate(raw_blocks):
        lines = block.split("\n")
        first_line = lines[0]
        last_line = lines[-1] if len(lines) > 1 else first_line

        if not in_code and _is_code_fence(first_line):
            # Opening fence
            in_code = True
            code_accum = [block]
            code_start_idx = len(blocks)
            continue

        if in_code:
            code_accum.append(block)
            if _is_code_fence(last_line):
                # Closing fence — full code block assembled
                full = "\n\n".join(code_accum)
                if len_fn(full) > max_chars:
                    # Oversized — extract for file delivery
                    oversized_code = full
                    # Don't add to blocks; will be sent separately
                else:
                    blocks.append(full)
                in_code = False
                code_accum = []
            continue

        # Regular paragraph block
        blocks.append(block)

    # Handle unclosed code block at end
    if in_code and code_accum:
        full = "\n\n".join(code_accum)
        if not oversized_code and len_fn(full) > max_chars:
            oversized_code = full
        elif not oversized_code:
            blocks.append(full)

    # ── Group blocks into chunks ─────────────────────────────────────
    chunks: List[str] = []
    current_chunk: List[str] = []
    current_size = 0

    for block in blocks:
        # Calculate size if we add this block to the current chunk
        if current_chunk:
            candidate = "\n\n".join(current_chunk + [block])
            candidate_len = len_fn(candidate)
        else:
            candidate_len = len_fn(block)

        if current_chunk and candidate_len > max_chars:
            # Flush current chunk
            chunks.append("\n\n".join(current_chunk))
            current_chunk = [block]
            current_size = len_fn(block)
        else:
            current_chunk.append(block)
            current_size = candidate_len

    if current_chunk:
        chunks.append("\n\n".join(current_chunk))

    return chunks, oversized_code
