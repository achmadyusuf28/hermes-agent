# python-debugpy.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: python-debugpy

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.python-debugpy;
in
{
  options.hermes.skills.python-debugpy = {
    enable = mkEnableOption "Debug Python: pdb REPL + debugpy remote (DAP).";
  };

  config = mkIf cfg.enable {
    hermes.skills.python-debugpy = {
      enable = true;
  description = "Debug Python: pdb REPL + debugpy remote (DAP).";
  type = "workflow";
  steps = [
  ''
    **pdb under pytest-xdist silently does nothing.** You won't see the prompt, the test just hangs. Always use `-p no:xdist` or `-n 0`.
  ''
  ''
    **`breakpoint()` in CI / non-TTY contexts hangs the process.** Safe locally; never commit it. Add a pre-commit grep as a safety net.
  ''
  ''
    **`PYTHONBREAKPOINT=0`** disables all `breakpoint()` calls. Check the env if your breakpoint isn't hitting:
  ''
  ''
    **`debugpy.listen` blocks only if you also call `wait_for_client()`.** Without it, execution continues and your first breakpoint may fire before the client is attached.
  ''
  ''
    **Attach to PID fails on hardened kernels.** `ptrace_scope=1` (Ubuntu default) allows only same-user ptrace of child processes. Workaround: `echo 0 > /proc/sys/kernel/yama/ptrace_scope` (needs root) or launch under `debugpy` from the start.
  ''
  ''
    **Threads.** `pdb` only debugs the current thread. For multithreaded code, use `debugpy` (thread-aware DAP) or set `threading.settrace()` per thread.
  ''
  ''
    **asyncio.** `pdb` works in coroutines but `await` inside pdb requires Python 3.13+ or `await` from `interact` mode on older versions. For 3.11/3.12, use `asyncio.run_coroutine_threadsafe` tricks or `!stmt`-based awaits via `asyncio.ensure_future`.
  ''
  ''
    **`scripts/run_tests.sh` strips credentials and sets `HOME=<tmpdir>`.** If your bug depends on user config or real API keys, it won't reproduce under the wrapper. Debug with raw `pytest` first to repro, then re-confirm under the wrapper.
  ''
  ''
    **Forking / multiprocessing.** pdb does not follow forks. Each child needs its own `breakpoint()` or `set_trace()`. For Hermes subagents, debug one process at a time.
  ''
];
  pitfalls = [
  ''
    **pdb under pytest-xdist silently does nothing.** You won't see the prompt, the test just hangs. Always use `-p no:xdist` or `-n 0`.
  ''
  ''
    **`breakpoint()` in CI / non-TTY contexts hangs the process.** Safe locally; never commit it. Add a pre-commit grep as a safety net.
  ''
  ''
    **`PYTHONBREAKPOINT=0`** disables all `breakpoint()` calls. Check the env if your breakpoint isn't hitting:
  ''
  ''
    **`debugpy.listen` blocks only if you also call `wait_for_client()`.** Without it, execution continues and your first breakpoint may fire before the client is attached.
  ''
  ''
    **Attach to PID fails on hardened kernels.** `ptrace_scope=1` (Ubuntu default) allows only same-user ptrace of child processes. Workaround: `echo 0 > /proc/sys/kernel/yama/ptrace_scope` (needs root) or launch under `debugpy` from the start.
  ''
  ''
    **Threads.** `pdb` only debugs the current thread. For multithreaded code, use `debugpy` (thread-aware DAP) or set `threading.settrace()` per thread.
  ''
  ''
    **asyncio.** `pdb` works in coroutines but `await` inside pdb requires Python 3.13+ or `await` from `interact` mode on older versions. For 3.11/3.12, use `asyncio.run_coroutine_threadsafe` tricks or `!stmt`-based awaits via `asyncio.ensure_future`.
  ''
  ''
    **`scripts/run_tests.sh` strips credentials and sets `HOME=<tmpdir>`.** If your bug depends on user config or real API keys, it won't reproduce under the wrapper. Debug with raw `pytest` first to repro, then re-confirm under the wrapper.
  ''
  ''
    **Forking / multiprocessing.** pdb does not follow forks. Each child needs its own `breakpoint()` or `set_trace()`. For Hermes subagents, debug one process at a time.
  ''
];
    };
  };
}
