# delegation-worker.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: delegation-worker

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.delegation-worker;
in
{
  options.hermes.skills.delegation-worker = {
    enable = mkEnableOption "Subagent protocol for structured delegation: read _brief.json, write _progress.jsonl as you work, check _correction.json mid-flight, write _result.json on completion.";
  };

  config = mkIf cfg.enable {
    hermes.skills.delegation-worker = {
      enable = true;
  description = "Subagent protocol for structured delegation: read _brief.json, write _progress.jsonl as you work, check _correction.json mid-flight, write _result.json on completion.";
  triggers = [
  "_brief.json"
  "_result.json"
  "subagent protocol"
  "structured delegation"
  "TASK_DIR"
  "delegation protocol"
  "forced artifact completion"
];
  type = "workflow";
  steps = [
  "Read the correction message"
  "Write a `correction_ack` progress entry"
  "Adjust your approach"
];
  pitfalls = [
  ''
    **TASK_DIR not set** — the `TASK_DIR` environment variable is how the subagent finds its workspace. If it's missing or empty, the protocol can't start. The parent must always set this before spawning the subagent.
  ''
  ''
    **Write progress every ~5 calls, not at the end** — if you batch all progress writes to the end, the parent has no visibility into your progress mid-flight. The protocol requires intermediate progress entries.
  ''
  ''
    **Correction file requires polling** — the subagent checks `_correction.json` after each work step but there's no push notification. The parent should not expect real-time responsiveness.
  ''
  ''
    **`_result.json` is the completion gate** — if you don't write `_result.json`, your task is incomplete. The parent checks for this file. A result with `verdict: "BLOCKED"` is valid — better than no result.
  ''
  ''
    **f-string vs plain string for PROTOCOL_CORE** — the parent's protocol template must use a plain triple-quoted string (`"""..."""`), NOT an f-string. Using `f"""...{TASK_DIR}..."""` causes `NameError: name 'TASK_DIR' is not defined` at module import time.
  ''
  ''
    **Canonical JSON matters for KV cache** — write compact JSON with `sort_keys=True` to preserve the byte-stable prefix for the inference engine's disk cache. Non-canonical JSON causes cosmetic cache misses.
  ''
  ''
    **Subagent sessions are not durable** — if the parent session is closed or Hermes restarts before the subagent finishes, its work is discarded. For long-running tasks, use `cronjob` instead of `delegate_task`.
  ''
  ''
    **`/stop` cancels all running subagents** — issuing `/stop` in the parent session terminates all background subagents without writing `_result.json`.
  ''
];
    };
  };
}
