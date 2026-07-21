# codebase-inspection.nix — Auto-converted from Hermes skill
# Category: github
# Original: codebase-inspection

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.codebase-inspection;
in
{
  options.hermes.skills.codebase-inspection = {
    enable = mkEnableOption "Inspect codebases w/ pygount: LOC, languages, ratios.";
  };

  config = mkIf cfg.enable {
    hermes.skills.codebase-inspection = {
      enable = true;
  description = "Inspect codebases w/ pygount: LOC, languages, ratios.";
  type = "workflow";
  steps = [
  ''
    **Always exclude .git, node_modules, venv** — without `--folders-to-skip`, pygount will crawl everything and may take minutes or hang on large dependency trees.
  ''
  ''
    **Markdown shows 0 code lines** — pygount classifies all Markdown content as comments, not code. This is expected behavior.
  ''
  ''
    **JSON files show low code counts** — pygount may count JSON lines conservatively. For accurate JSON line counts, use `wc -l` directly.
  ''
  ''
    **Large monorepos** — for very large repos, consider using `--suffix` to target specific languages rather than scanning everything.
  ''
];
  pitfalls = [
  ''
    **Always exclude .git, node_modules, venv** — without `--folders-to-skip`, pygount will crawl everything and may take minutes or hang on large dependency trees.
  ''
  ''
    **Markdown shows 0 code lines** — pygount classifies all Markdown content as comments, not code. This is expected behavior.
  ''
  ''
    **JSON files show low code counts** — pygount may count JSON lines conservatively. For accurate JSON line counts, use `wc -l` directly.
  ''
  ''
    **Large monorepos** — for very large repos, consider using `--suffix` to target specific languages rather than scanning everything.
  ''
];
    };
  };
}
