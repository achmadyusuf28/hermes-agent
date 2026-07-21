# nixos-wrapper-pattern.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-wrapper-pattern

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-wrapper-pattern;
in
{
  options.hermes.skills.nixos-wrapper-pattern = {
    enable = mkEnableOption "Create Nix wrappers for pip-installed tools, Toolbox-installed JetBrains apps, and prebuilt binaries on NixOS — writeShellScriptBin, LD_LIBRARY_PATH, sudo -u, runtime context passing, Nix string escaping, wrapper debugging.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-wrapper-pattern = {
      enable = true;
  description = "Create Nix wrappers for pip-installed tools, Toolbox-installed JetBrains apps, and prebuilt binaries on NixOS — writeShellScriptBin, LD_LIBRARY_PATH, sudo -u, runtime context passing, Nix string escaping, wrapper debugging.";
  triggers = [
  "wrapper pattern"
  "writeShellScriptBin"
  "writeShellApplication"
  "pip tool on PATH"
  "LD_LIBRARY_PATH nixos"
  "sudo -u hermes"
  "runtime context sudo"
  "HERMES_INVOCATION_DIR"
  "nix string escaping"
  "nix shell escaping"
  "hermes command not found"
  "tool not in path"
  "autoPatchelfHook"
  "prebuilt binary"
  "glibc binary nixos"
  "iii-worker"
  "libcap_ng"
  "runtime api key"
  "nix store secret"
  "env file api key"
];
  type = "workflow";
  steps = [
  ''
    **Syntax check first**: `bash -n /run/current-system/sw/bin/<tool>` — if this passes but runtime fails, issue is quoting/escaping
  ''
  ''
    **Inspect actual bytes**: `python3 -c "print(repr(open('/run/current-system/sw/bin/<tool>').read()))"` — reveals hidden characters
  ''
  ''
    **Trace execution**: `bash -x /run/current-system/sw/bin/<tool> <args>` — shows every expanded command
  ''
  ''
    **Test directly**: `bash /run/current-system/sw/bin/<tool>` — see raw bash parser errors
  ''
  ''
    **Diff against Nix source**: Compare generated script in `/run/current-system/sw/bin/` with source in `agent.nix`
  ''
  ''
    Verify tool is in venv: `ls /home/hermes/.hermes-agent-venv/bin/`
  ''
  ''
    Add wrapper in `let` block of `modules/agents/hermes/agent.nix`
  ''
  "Add to `environment.systemPackages`"
  ''
    Rebuild: `sudo -n nixos-rebuild switch --flake "path:/mnt/data/workspace/soup-nix#soup"`
  ''
  "Test with `bash -n` first, then inspect generated script"
  ''
    Create a dedicated module under `modules/development/<tool>.nix`
  ''
  ''
    Import it in `configuration.nix` under the Development section
  ''
  ''
    Use the [Toolbox Binary Wrapping Pattern](#toolbox-binary-wrapping-pattern) for binary resolution + LD_LIBRARY_PATH
  ''
  ''
    Wire Zsh integrations via `programs.zsh.interactiveShellInit`
  ''
  ''
    Rebuild and verify with `bash -n /run/current-system/sw/bin/<tool>`
  ''
];
  pitfalls = [
  ''
    **Nix `'''` string escaping: avoid `'''` (two consecutive single quotes)** — `'''` inside a Nix indented string terminates the string prematurely. Never write `'''` in your script body.
  ''
  ''
    **LD_PRELOAD must be set in bash, not Python** — setting `os.environ['LD_PRELOAD']` inside Python doesn't work. The linker resolves shared objects before Python starts. Always set it in the `writeShellScriptBin` wrapper.
  ''
  ''
    **`''${...}` in Nix `'''` strings is interpolated** — only `$VAR` (without braces) is literal. Use `'''''${VAR}` when you need shell brace expansion (`''${var:-default}`, `''${var##pattern}`).
  ''
  ''
    **`\\\"` in Nix `'''` strings produces literal backslash+quote** — it's NOT an escaped quote. Use `printf` to build JSON strings safely.
  ''
  ''
    **Python scripts must be world-readable** — mode `711` (`rwx--x--x`) lets you execute but Python can't read its own source. Use `chmod 755` or `644`.
  ''
  ''
    **`writeShellApplication` auto-adds PATH** — use this over `writeShellScriptBin` for tools that need runtime deps on PATH. `writeShellScriptBin` is for simple scripts.
  ''
  ''
    **API keys in Nix store are world-readable** — always read secrets from a `chmod 600` env file at runtime, never hardcode in the wrapper template.
  ''
  ''
    **Toolbox paths change on every update** — use pattern-matching globs in wrapper scripts, not hardcoded `ch-*` paths.
  ''
  ''
    **Prebuilt binaries need `autoPatchelfHook`** — for glibc binaries (not pip), use `autoPatchelfHook` in `buildInputs` to resolve shared library RPATHs automatically.
  ''
  ''
    **`first run` of auto-venv pip install can take 5-20 minutes** — pre-warm the venv during NixOS setup or instruct the user about the delay.
  ''
  ''
    **Wrapper script debugging** — `bash -n` for syntax, `python3 -c "print(repr(open(...).read()))"` for byte inspection, `bash -x` for trace execution.
  ''
];
    };
  };
}
