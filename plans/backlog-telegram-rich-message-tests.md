# Backlog: Pre-existing telegram rich-message test failures

**Created:** 2026-08-14 (hermes, post-commmit `70e054785`)
**Status:** TODO — pre-existing, NOT introduced by recent commits
**Owner:** unassigned (pick up later)

## The problem

3 tests in `tests/gateway/test_telegram_rich_messages.py` fail:

- `test_oversized_content_skips_rich_and_chunks`
- `test_rich_limit_is_characters_not_bytes`
- `test_finalize_edit_rich_over_markdownv2_limit_not_split`

All fail at the same helper:

```
ERROR: AttributeError: 'NoneType' object has no attribute 'kwargs'
  at test file line ~834: _rich_edit_kwargs(adapter)
    call = adapter._bot.editMessageText.call_args
    return call.kwargs
```

Meaning: in these 3 oversized/limit scenarios, the adapter does NOT invoke
`editMessageText`, so the mock's `call_args` is `None`.

## Evidence it's pre-existing (not caused by `70e054785`)

Checked out `HEAD^` (parent of the `workers` commit, before any of this session's
changes) in a worktree and ran the same 3 tests — they fail **identically**.
The recent commit only altered the test's *mock wiring* (`do_api_request` →
`editMessageText` in `_make_adapter`), NOT the assertions or the adapter.
The mismatch predates all of this work.

## Root-cause hypothesis (unverified)

The adapter's rich finalize path (plugins/platforms/telegram/adapter.py,
`edit_message` / rich `editMessageText` around lines 1706-1772, 3929-4082)
does NOT call `editMessageText` when content is oversized / over the rich char
limit — it takes a fallback branch (splitting or legacy `edit_message_text`).
The tests assert that in those cases the rich `editMessageText` WAS still called
with the full `rich_message` markdown, which contradicts the actual branch taken.

Either:
- (a) the adapter is wrong to skip the rich call for oversized-but-under-limit
      content (it should still call `editMessageText` with rich_message), or
- (b) the tests encode a stale contract.

`RICH_MESSAGE_MAX_CHARS` vs `MAX_MESSAGE_LENGTH` comparison in the oversized test
suggests the test intends "content that is > MAX_MESSAGE_LENGTH but <
RICH_MESSAGE_MAX_CHARS should still go through rich editMessageText, not split."

## What I verified (so the next person doesn't re-derive)

- canonical gate: `./scripts/run_tests.sh tests/gateway/test_telegram_rich_messages.py`
  → **69 passed, 3 failed** (only these 3)
- `test_delegate.py` + tool tests: **355 passed** (my area is clean)
- `.gitignore` change: verified 5/5 (unrelated to this, but the session's commit
  `70e054785` is otherwise clean)
- repo tree is clean (`git status` = 0 dirty) after verification

## Suggested next steps

1. Read `plugins/platforms/telegram/adapter.py` around the rich finalize path
   (lines ~1700-1780 and ~3929-4090) to confirm which branch oversized content hits.
2. Decide: fix the adapter (ensure rich `editMessageText` is called for content
   within `RICH_MESSAGE_MAX_CHARS` even if > `MAX_MESSAGE_LENGTH`) OR update the
   3 test expectations to match the actual (splitting) behavior.
3. #3 (the "chars not bytes" one) is the most likely real bug — a limit measured
   in chars vs UTF-16 units mismatch on the rich path.
4. Re-run `./scripts/run_tests.sh tests/gateway/test_telegram_rich_messages.py` to green.

## Files touched this session (context, not the bug)
- `.gitignore` (line 76: `apps/*/src/**/*.js` — compiled asset exclusion)
- `tests/gateway/test_telegram_rich_messages.py` (mock wiring change only)
