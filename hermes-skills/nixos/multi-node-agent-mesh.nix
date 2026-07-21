# multi-node-agent-mesh.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: multi-node-agent-mesh

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.multi-node-agent-mesh;
in
{
  options.hermes.skills.multi-node-agent-mesh = {
    enable = mkEnableOption ">-";
  };

  config = mkIf cfg.enable {
    hermes.skills.multi-node-agent-mesh = {
      enable = true;
  description = ">-";
  triggers = [
  "distribute hermes"
  "multiple machines"
  "multi-node agent"
  "hermes mesh"
  "agent across machines"
  "distributed agent infrastructure"
  "share GPU inference across machines"
  "multi-machine Hermes"
  "Wireguard mesh"
  "ZeroTier mesh"
  "agent session migration"
  "split-brain agent session"
  "cross-node tool execution"
  "heterogeneous machines agent"
  "3070 ti local inference LAN"
  "backbone on always-on machine"
  "honcho clustering"
  "manifest active active"
  "PG streaming replication"
  "bismuth hermes"
];
  type = "workflow";
  steps = [
  "Enable syncthing on both nodes (no peer ID yet), rebuild"
  ''
    Get each node's device ID from `~/.config/syncthing/config.xml`:
  ''
  ''
    Set `peerDeviceId` + `peerName` on each node pointing at the other, rebuild
  ''
  ''
    Restart syncthing on both nodes — they connect over ZeroTier/Tailscale/LAN
  ''
];
  pitfalls = [
  ''
    **`path:` URI required as non-owner** — use `--flake "path:/path/to/flake#hostname"` to bypass git ownership checks- **Transient unit blocks rebuild** — `sudo systemctl stop nixos-rebuild-switch-to-configuration.service; sudo systemctl reset-failed; sudo systemctl daemon-reload`- **Shell redirects in ExecStart need `bash -c`** — systemd's ExecStart does NOT parse `>`, `|`, `||`, `&&`
  ''
  ''
    **Nix store staleness** — files referenced via `./path` are copied into the store at build time. Rebuild to pick up changes
  ''
];
    };
  };
}
