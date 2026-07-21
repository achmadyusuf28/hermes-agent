# graphify.nix — Auto-converted from Hermes skill
# Category: tools
# Original: graphify

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.graphify;
in
{
  options.hermes.skills.graphify = {
    enable = mkEnableOption "Turn any folder of code, docs, or images into a queryable knowledge graph. Query it for repo architecture, relationships, and context instead of reading raw files.";
  };

  config = mkIf cfg.enable {
    hermes.skills.graphify = {
      enable = true;
  description = "Turn any folder of code, docs, or images into a queryable knowledge graph. Query it for repo architecture, relationships, and context instead of reading raw files.";
  triggers = [
  "graphify query"
  "codebase understanding"
  "repo architecture"
  "file relationships"
];
  type = "workflow";
  steps = [
  ''
    `bash -n /run/current-system/sw/bin/graphify` — syntax check
  ''
  ''
    `python3 -c "print(repr(open('/run/current-system/sw/bin/graphify').read()))"` — inspect actual bytes
  ''
  ''
    `bash -x /run/current-system/sw/bin/graphify --help` — trace execution
  ''
];
  example = ''
  ```bash
  '';
    };
  };
}
