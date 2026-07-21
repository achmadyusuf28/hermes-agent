# node-inspect-debugger.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: node-inspect-debugger

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.node-inspect-debugger;
in
{
  options.hermes.skills.node-inspect-debugger = {
    enable = mkEnableOption "Debug Node.js via --inspect + Chrome DevTools Protocol CLI.";
  };

  config = mkIf cfg.enable {
    hermes.skills.node-inspect-debugger = {
      enable = true;
  description = "Debug Node.js via --inspect + Chrome DevTools Protocol CLI.";
  type = "workflow";
  steps = [
  ''
    **Wrong line numbers in TS source.** Breakpoints hit the emitted JS, not the `.ts`. Either (a) break in the built `dist/*.js`, or (b) enable sourcemaps (`node --enable-source-maps`) and use `sb('src/app.tsx', N)` — but only with CDP clients that follow sourcemaps. `node inspect` CLI does not.
  ''
  ''
    **`--inspect` vs `--inspect-brk`.** `--inspect` starts the inspector but doesn't pause; your script races past your first breakpoint if you attach too late. Use `--inspect-brk` when you need to set breakpoints before any code runs.
  ''
  ''
    **Port collisions.** Default is `9229`. If multiple Node processes are inspecting, pass `--inspect=0` (random port) and read the actual URL from `/json/list`:
  ''
  ''
    **Child processes.** `--inspect` on a parent does NOT inspect its children. Use `NODE_OPTIONS='--inspect-brk' node parent.js` to propagate to every child; be aware they all need unique ports (Node auto-increments when `NODE_OPTIONS='--inspect'` is inherited).
  ''
  ''
    **Background kills.** If you `Ctrl+C` out of `node inspect` while the target is paused, the target stays paused. Either `cont` first, or `kill` the target explicitly.
  ''
  ''
    **Running `node inspect` through an agent terminal.** It's a PTY-friendly REPL. In Hermes, launch it with `terminal(pty=true)` or `background=true` + `process(action='submit', data='...')`. Non-PTY foreground mode will work for one-shot commands but not for interactive stepping.
  ''
  ''
    **Security.** `--inspect=0.0.0.0:9229` exposes arbitrary code execution. Always bind to `127.0.0.1` (the default) unless you have an isolated network.
  ''
];
  pitfalls = [
  ''
    **Wrong line numbers in TS source.** Breakpoints hit the emitted JS, not the `.ts`. Either (a) break in the built `dist/*.js`, or (b) enable sourcemaps (`node --enable-source-maps`) and use `sb('src/app.tsx', N)` — but only with CDP clients that follow sourcemaps. `node inspect` CLI does not.
  ''
  ''
    **`--inspect` vs `--inspect-brk`.** `--inspect` starts the inspector but doesn't pause; your script races past your first breakpoint if you attach too late. Use `--inspect-brk` when you need to set breakpoints before any code runs.
  ''
  ''
    **Port collisions.** Default is `9229`. If multiple Node processes are inspecting, pass `--inspect=0` (random port) and read the actual URL from `/json/list`:
  ''
  ''
    **Child processes.** `--inspect` on a parent does NOT inspect its children. Use `NODE_OPTIONS='--inspect-brk' node parent.js` to propagate to every child; be aware they all need unique ports (Node auto-increments when `NODE_OPTIONS='--inspect'` is inherited).
  ''
  ''
    **Background kills.** If you `Ctrl+C` out of `node inspect` while the target is paused, the target stays paused. Either `cont` first, or `kill` the target explicitly.
  ''
  ''
    **Running `node inspect` through an agent terminal.** It's a PTY-friendly REPL. In Hermes, launch it with `terminal(pty=true)` or `background=true` + `process(action='submit', data='...')`. Non-PTY foreground mode will work for one-shot commands but not for interactive stepping.
  ''
  ''
    **Security.** `--inspect=0.0.0.0:9229` exposes arbitrary code execution. Always bind to `127.0.0.1` (the default) unless you have an isolated network.
  ''
];
    };
  };
}
