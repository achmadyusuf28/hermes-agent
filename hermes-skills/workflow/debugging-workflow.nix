# debugging-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: debugging-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.debugging-workflow;
in
{
  options.hermes.skills.debugging-workflow = {
    enable = mkEnableOption "Systematic failure diagnosis — isolate the layer, check logs, reduce to repro, test hypothesis. Covers MCP, NixOS, iii engine, and general code debugging.";
  };

  config = mkIf cfg.enable {
    hermes.skills.debugging-workflow = {
      enable = true;
  description = "Systematic failure diagnosis — isolate the layer, check logs, reduce to repro, test hypothesis. Covers MCP, NixOS, iii engine, and general code debugging.";
  triggers = [
  "debug this"
  "something broke"
  "why is X failing"
  "error"
  "not working"
  "troubleshoot"
  "investigate"
  "diagnose"
  "hibernate"
  "suspend"
  "sleep"
  "keyring"
  "session lost"
  "logged out"
  "port audit"
  "security audit"
  "exposed port"
  "who's listening"
  "network scan"
  "0.0.0.0"
];
  type = "workflow";
  steps = [
  ''
    **What layer is it in?** — Is this a crash, a silent failure, a wrong-result, a timeout, a connectivity issue, or a permissions problem? Different layers have different debugging tools.
  ''
  ''
    **What changed last?** — Was it working before? What file was edited, what package was installed, what service was restarted?
  ''
  ''
    **What are the logs saying?** — Every component has a log source. Read it before changing anything.
  ''
  ''
    **Can I reproduce it?** — A bug you can reproduce on demand is a bug you can fix. If you can't reproduce it, you can't verify the fix.
  ''
  ''
    GNOME Keyring daemon locks on resume (no password → no decryption)
  ''
  ''
    D-Bus sockets are recreated during resume — Firefox's connection to
  ''
  ''
    Firefox can't re-establish the decryption context for the origin's storage
  ''
  ''
    Firefox resets that origin's IndexedDB/localStorage → session cookie gone →
  ''
  ''
    **Post-resume keyring re-init** — Add a `post-resume.target` one-shot that
  ''
  ''
    **Kill and restart the browser on resume** (destructive to tabs — use only if
  ''
  ''
    **Hypridle `after_sleep_cmd`** — Already often set for brightness restore;
  ''
  ''
    **Firefox `about:config` workaround** — Set `security.webauth.webauthn` and
  ''
  ''
    **Long-term** — Switch to a WhatsApp Desktop client (Ferdium, Franz, or the
  ''
  "🔴 Crash / data loss — fix immediately"
  ''
    🟡 Fragile / wrong under certain conditions — fix if precondition is common
  ''
  "🟢 Dead code / cosmetic — skip unless user specifically asks"
  ''
    Search the codebase for an existing fix pattern (e.g., same crash was fixed elsewhere with `usleep(10000)`)
  ''
  "Apply the same pattern to all unprotected sites"
  ''
    Verify with grep: `grep -n -B1 "pattern" src/path/to/file.c`
  ''
];
  pitfalls = [
  ''
    **Read error messages character by character** — most debugging time is wasted on errors that the system literally told you about. Skimmed error messages are the #1 cause of wasted debug cycles.
  ''
  ''
    **`sudo` path on NixOS** — always use `/run/wrappers/bin/sudo` or `/run/current-system/sw/bin/sudo`, never bare `sudo` in scripts or restricted shells.
  ''
  ''
    **`iii trigger` errors go to stderr** — `function_not_found`, `TIMEOUT`, and other engine errors write to stderr, not stdout. Any wrapper that only captures `stdout.strip()` will get a blank string and assume success.
  ''
  ''
    **`iii trigger` default timeout is 30s** — always set `--timeout-ms 120000` for LLM function calls. Default 30s is too short for any function that delegates to an LLM.
  ''
  ''
    **Engine restart kills all external workers** — Python SDK workers don't auto-reconnect. After engine restart, kill and restart all external workers. TypeScript workers reconnect automatically.
  ''
  ''
    **`systemctl` blocked from gateway** — the Hermes gateway intercepts `systemctl` commands. Use `delegate_task(background=True)` or an external shell to restart services.
  ''
  ''
    **Two Telegram paths, diagnose correctly** — if the bot typed but didn't deliver → check the relay. If the bot went silent mid-conversation → check the gateway (likely hung agent loop).
  ''
  ''
    **State `S` + wchan `do_epoll_wait` is normal** — an active process sleeps between events. State `D` or wchan `inode`/`pipe`/`sk_wait_data` means it's stuck. Don't restart processes that are just idle.
  ''
  ''
    **Keyring unlock ≠ browser recovery** — CLI tools recover after keyring unlock because their token is in the keyring. Browser web apps (WhatsApp Web, Telegram Web) lose their session because Firefox's IndexedDB/keyring binding breaks. Don't diagnose as keyring problem.
  ''
  ''
    **Layer order matters** — always work through the 4 questions (What layer? What changed? Logs? Reproduce?) before grabbing at fixes. Jumping to fix attempts before diagnosis is the root cause of most cascading failures.
  ''
];
    };
  };
}
