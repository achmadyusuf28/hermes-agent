# telegram-message-chunking.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: telegram-message-chunking

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.telegram-message-chunking;
in
{
  options.hermes.skills.telegram-message-chunking = {
    enable = mkEnableOption "Self-managed message splitting for Telegram's 4096 UTF-16 character limit — agent-owned chunking with clean markdown boundaries, not gateway auto-split.";
  };

  config = mkIf cfg.enable {
    hermes.skills.telegram-message-chunking = {
      enable = true;
  description = "Self-managed message splitting for Telegram's 4096 UTF-16 character limit — agent-owned chunking with clean markdown boundaries, not gateway auto-split.";
  triggers = [
  "message too long"
  "telegram 4096"
  "message splitting"
  "chunking"
  "1/3 2/3"
  "truncate message"
  "markdown broken"
];
  type = "workflow";
  steps = [
  ''
    **Cap responses at ~3,800 chars** — safe margin below 4,096 UTF-16 limit
  ''
  ''
    **If a response genuinely needs more space**, split it into multiple messages yourself — each with clean, self-contained markdown
  ''
  ''
    **No broken formatting across chunks** — each chunk must have valid, closed markdown (even code fences, complete table rows, closed headings)
  ''
  ''
    **Do NOT rely on Telegram's auto-chunking** or on the `sendRichMessage` path — both can produce broken rendering
  ''
  ''
    **On the CLI, there is no attachment channel** — the user reads your response directly in their terminal. Do NOT emit `MEDIA:/path` tags (those are only intercepted on messaging platforms). When referring to a file you created or changed, just state its absolute path.
  ''
];
  pitfalls = [
  ''
    **~3,800 char limit, not 4,096** — leave a 300-char safety margin for emoji, markdown syntax, and platform overhead. The hard limit is 4,096 UTF-16 code units, but hitting it exactly causes the gateway's auto-split to kick in.
  ''
  ''
    **Code fences must close in the same chunk** — if you split a response across messages, ensure each code block is complete. An unclosed `` ``` `` ruins formatting for everything after it.
  ''
  ''
    **Tables must be complete per chunk** — don't split a table across messages. Each chunk's markdown must be independently valid.
  ''
  ''
    **`sendRichMessage` is not a reliable alternative** — the rich message path has its own markdown rendering bugs (bold, code blocks, inline code). Self-chunking at ~3,800 chars is more reliable.
  ''
  ''
    **CLI mode has no attachment channel** — `MEDIA:/path` tags are only intercepted on messaging platforms (Telegram). On the CLI, just state the file's absolute path.
  ''
  ''
    **Natural continuity beats "(1/3)" labels** — use "Continuing:" or "Next:" instead of the robotic `(1/3)/ (2/3)/ (3/3)` suffixes the gateway adds. The user will read the chunks consecutively regardless.
  ''
  ''
    **Self-monitor response length** — if you consistently hit the limit, your responses are too long. Tighten before the platform forces truncation. Aim for 2,000-2,500 chars per message as a comfortable max.
  ''
];
    };
  };
}
