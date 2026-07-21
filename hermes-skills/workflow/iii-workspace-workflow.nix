# iii-workspace-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: iii-workspace-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.iii-workspace-workflow;
in
{
  options.hermes.skills.iii-workspace-workflow = {
    enable = mkEnableOption "Use iii engine (dashboard engine on port 49134) as a persistent workspace backbone — state store for context, NixOS management, stream events, and durable queues.";
  };

  config = mkIf cfg.enable {
    hermes.skills.iii-workspace-workflow = {
      enable = true;
  description = "Use iii engine (dashboard engine on port 49134) as a persistent workspace backbone — state store for context, NixOS management, stream events, and durable queues.";
  triggers = [
  "use iii state"
  "what are we working on"
  "check nixos"
  "workspace context"
  "iii queue"
  "iii durable"
];
  type = "workflow";
  steps = [
  ''
    Front-facing agent decomposes user intent → decides which worker(s) to call
  ''
  ''
    Agent calls worker via `invokefunction` — the worker's task context includes gateway info
  ''
  ''
    Worker executes and optionally sends result **directly** via the gateway's registered function (e.g. `telegram::send-message`)
  ''
  "Agent may also receive the result back and synthesize it"
  ''
    **Extra latency** — orchestration adds function registry fetch, tool definition injection, up to 5 LLM iterations
  ''
  ''
    **Wrong answers** — conflicting system prompts (front-facing prompt vs orchestration tool guide)
  ''
  ''
    **Hallucination** — LLM tries to use tools that can't answer the question
  ''
  "Handler enters executor thread (runs LLM agent)"
  "Agent produces a sentence/result → fires a Python callback"
  ''
    Callback schedules an ``invokefunction`` on the event loop via
  ''
  "Coroutine sends ``invokefunction`` for a delivery function"
  "Main listener loop (``async for raw in ws``) receives the"
  ''
    Callback thread's ``future.result(timeout)`` returns — the delivery is
  ''
  "task created → stream::set (symphony-task-events)"
  "stream trigger fires → symphony::pick"
  ''
    symphony::pick calls tasks::update(workflow_state="in_progress")
  ''
  ''
    tasks::update publishes to symphony-task-events (state_changed)
  ''
  "stream trigger fires → symphony::pick AGAIN ← CASCADE"
  ''
    Fetches live function registry via `engine::functions::list` (~47 functions)
  ''
  ''
    Converts each to an OpenAI-compatible tool definition, renaming `::` → `__` (LLMs struggle with `::`)
  ''
];
  pitfalls = [
  ''
    **`state::get` returns raw values** — no `{"value": ...}` envelope. Check `isinstance(result, dict)` before doing key lookups. Substring matching on strings (`"error" in result` when result is a string) returns false positives.
  ''
  ''
    **`state::list` returns full objects, not key wrappers** — entries have `id`/`title`, not `key`. Handlers using `.get("key", "")` silently skip everything.
  ''
  ''
    **`iii trigger` errors go to stderr** — engine routing failures write to stderr, not stdout. Always check both streams.
  ''
  ''
    **`iii trigger` default timeout is 30s** — always set `--timeout-ms 120000` for LLM function calls.
  ''
  ''
    **HTTP response bodies swallowed on v0.20.0** — the engine returns `{}` regardless of the invocation result. Use WebSocket `invokefunction` when response data matters.
  ''
  ''
    **Ad-hoc WebSocket clients don't receive results** — only permanent workers (with `registerfunction` + persistent listener) get results routed back.
  ''
  ''
    **Concurrent invocation routing limitation** — parallel `invokefunction` calls over the same connection may lose results. Serialize or add timeout+retry.
  ''
  ''
    **Long-running cross-worker calls may drop results** — calls to a different worker process taking >5s may lose results. Use `iii trigger` CLI subprocess workaround (+200ms overhead).
  ''
  ''
    **`systemctl` blocked from gateway** — intercepted inside Hermes Gateway sessions. Use `delegate_task(background=True)` or external shell.
  ''
  ''
    **Nix-only for system changes** — ALL system changes go through the flake and rebuild, never ad-hoc shell. This is not optional.
  ''
  ''
    **Cannot trigger-return from python worker while also calling another function** — the block inside `PENDING_INVOCATIONS` pattern requires both the send and the listener loop to be active. If your listener loop is blocked (e.g., in a tight function handler), cross-worker calls time out.
  ''
  ''
    **Stream trigger payload is nested** — access payload at `data.get("event", {}).get("data", {})`, not `data.get("event", {})`.
  ''
  ''
    **Self-cascade guard needed** — if a stream trigger handler's side effect publishes to the same stream, use an in-memory `PROCESSING_TASKS` set with `try/finally` to prevent loops.
  ''
  ''
    **AGENTS.md path discipline** — always use absolute paths for local-only artifacts in AGENTS.md, and include a disclaimer that peers won't have them.
  ''
  ''
    **Don't force `tools=True` on every message** — triggers orchestration loop overhead unnecessarily. Let the front-facing agent use its fast path for normal Q&A.
  ''
];
    };
  };
}
