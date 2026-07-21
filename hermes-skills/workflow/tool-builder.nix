# tool-builder.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: tool-builder

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.tool-builder;
in
{
  options.hermes.skills.tool-builder = {
    enable = mkEnableOption "Crystallize a skill into a usable CLI tool — scaffold, test, skillify. Propose first, build after approval.";
  };

  config = mkIf cfg.enable {
    hermes.skills.tool-builder = {
      enable = true;
  description = "Crystallize a skill into a usable CLI tool — scaffold, test, skillify. Propose first, build after approval.";
  triggers = [
  "build a tool"
  "create CLI"
  "crystallize"
  "scaffold tool"
  "make a script"
  "Nix wrapper"
  "writeShellScriptBin"
  "tool from skill"
];
  type = "workflow";
  pitfalls = [
  ''
    **Always propose before building** — this is not optional. The user requires discussion and explicit approval before any code is written, files are created, or builds are run.
  ''
  ''
    **Don't assume the primary user** — if you propose a Nix-wrapped user tool but the user corrects "you'll be the one using this", that means switch to agent-tool pattern (JSON output, scripts/ dir, no Nix wrapper). Ask explicitly during the proposal phase.
  ''
  ''
    **LD_PRELOAD must be set in the bash wrapper, not Python** — setting it via `os.environ` inside Python does NOT work for numpy or other C-extensions. The linker resolves shared objects at process startup, before any Python code runs.
  ''
  ''
    **Venv Python path is critical** — tools that need pip-installed deps (markitdown, numpy) must use `~/.hermes-agent-venv/bin/python3`, NOT the system Python. Compiled `.so` files are built against the venv's Python internals.
  ''
  ''
    **Nix build-time vs runtime confusion** — files referenced via Nix path (`./scripts/my-tool.py`) are copied into the store at build time. Editing the source does NOT update the running tool until `nixos-rebuild switch` is run.
  ''
  ''
    **`writeShellScriptBin` runs in a minimal PATH** — any subprocess calls from within the wrapper must use absolute paths. Use `''${pkgs.binary}/bin/<name>` rather than bare names.
  ''
  ''
    **Don't build what you don't need** — if the workflow is used ≤ weekly, takes ≤2 commands, or varies substantially each time, a skill is sufficient. Only crystallize daily, repetitive, 5+ step workflows.
  ''
];
    };
  };
}
