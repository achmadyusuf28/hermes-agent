# front-facing-agent-pattern.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: front-facing-agent-pattern

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.front-facing-agent-pattern;
in
{
  options.hermes.skills.front-facing-agent-pattern = {
    enable = mkEnableOption "Shell architecture for a front-facing conversational agent that delegates to specialist workers — SOUL.md hierarchy, RACI delegation model, and gateway-as-worker pattern.";
  };

  config = mkIf cfg.enable {
    hermes.skills.front-facing-agent-pattern = {
      enable = true;
  description = "Shell architecture for a front-facing conversational agent that delegates to specialist workers — SOUL.md hierarchy, RACI delegation model, and gateway-as-worker pattern.";
  triggers = [
  "front-facing agent"
  "gateway as worker"
  "delegation model"
  "RACI"
  "SOUL hierarchy"
  "FRONT_SYSTEM_PROMPT"
  "telegram relay"
  "hermes::front"
  "build a front-facing shell"
  "gateway architecture"
  "worker delegation"
];
  type = "workflow";
  steps = [
  "**Gateway connects** to `ws://localhost:49134`"
  "**Registers a function** like `telegram::send-message`"
  "**Listens for invocations** in its WS message loop"
  ''
    **Workers call it** from their handlers to push messages to the user
  ''
];
  pitfalls = [
  ''
    **`systemctl` blocked inside gateway** — any command containing `systemctl` is intercepted when running inside a Hermes Gateway session. Use `delegate_task()`, `kill -TERM $(systemctl show -P MainPID ...)`, or background terminal to restart services.
  ''
  ''
    **`hermes config set` is blocked on NixOS** — on `HERMES_MANAGED=true` installs, edit `~/.hermes/config.yaml` directly, then restart the gateway via `nixos-rebuild switch` or external shell.
  ''
  ''
    **Front-facing shell must NOT duplicate Honcho fetch** — `orchestrate()` handles Honcho context injection internally when `user_id` is provided. The handler should never fetch Honcho explicitly — it creates duplicated code and double token usage.
  ''
  ''
    **Always-on orchestration adds ~500ms overhead** — the function registry fetch adds latency on every call, even for simple Q&A. This is acceptable for user-facing chat but avoid it for programmatic hot-paths.
  ''
  ''
    **Don't force `tools=True` on every message** — the gateway should only pass `tools=True` when the user explicitly asks for delegated work. Every call triggers the orchestration loop: registry fetch, tool definition injection, up to 5 LLM iterations. For normal chat, let the agent use its default fast path.
  ''
  ''
    **Gateway-as-worker pattern requires the relay to stay connected** — if the Telegram relay disconnects from the engine, `telegram::send-message` becomes unavailable. Workers pushing results to Telegram will silently fail. Monitor relay health.
  ''
  ''
    **Conversation history grows unbounded** — the front-facing shell saves every turn to `iii-state` (scope=conversations). Without pruning at 20 turns, state size grows indefinitely. The `hermes::front` handler prunes automatically at 20, but verify this is still working after code changes.
  ''
];
    };
  };
}
