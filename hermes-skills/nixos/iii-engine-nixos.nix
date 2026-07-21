# iii-engine-nixos.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: iii-engine-nixos

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.iii-engine-nixos;
in
{
  options.hermes.skills.iii-engine-nixos = {
    enable = mkEnableOption "Package, configure, and extend the iii engine on NixOS — binary version updates, worker binary packaging with autoPatchelfHook, the iii worker add workaround, and engine config management.";
  };

  config = mkIf cfg.enable {
    hermes.skills.iii-engine-nixos = {
      enable = true;
  description = "Package, configure, and extend the iii engine on NixOS — binary version updates, worker binary packaging with autoPatchelfHook, the iii worker add workaround, and engine config management.";
  triggers = [
  "iii engine update"
  "iii engine version"
  "iii-worker binary"
  "iii worker add"
  "iii-config.yaml"
  "workers.iii.dev"
  "harness worker"
  "iii engine config"
  "iii-pubsub"
  "iii-cron"
  "iii worker registry"
  "install harness"
  "systemd services"
  "provider service"
  "add worker"
  "remove worker"
  "remove symphorelated_skills:"
  "nixos-hermes-service"
  "nixos-wrapper-pattern"
  "nix-dependency-update"
];
  type = "workflow";
  steps = [
  ''
    Check latest release: `curl -sL https://api.github.com/repos/iii-hq/iii/releases/latest | jq .tag_name`
  ''
  ''
    Prefetch hash: `nix-prefetch-url https://github.com/iii-hq/iii/releases/download/iii/vX.Y.Z/iii-x86_64-unknown-linux-gnu.tar.gz --type sha256`
  ''
  "Update `version` and `sha256` in the derivation"
  ''
    Also update `iii-console-bin` (musl variant, different hash):
  ''
  ''
    Run `sudo nixos-rebuild switch --flake path:/mnt/data/workspace/soup-nix`
  ''
  ''
    Copy config to writable temp: `cp /nix/store/...-config.yaml /tmp/`
  ''
  "Run: `iii --config /tmp/config.yaml worker add <name>`"
  ''
    Copy the generated `config.yaml` and `iii.lock` from the working directory back to `modules/agents/hermes/`
  ''
  "Rebuild NixOS"
  ''
    `iii-worker-manager` (built-in engine module) reads the config
  ''
  ''
    For each name entry, checks `iii.lock` for the binary metadata
  ''
  ''
    Spawns the binary as a child process with `--url ws://127.0.0.1:49134`
  ''
  ''
    The binary connects to the engine via WebSocket and registers its functions
  ''
  ''
    The engine manages lifecycle (restart on crash, stop on config change)
  ''
  ''
    **Use `sub_filter` to rewrite the embedded `__CONSOLE_CONFIG__`** so the JS talks back to the proxy port:
  ''
  ''
    **Systemd service setup** — nginx must run in `daemon off` mode with explicit pid and error log paths:
  ''
  ''
    **WebSocket upgrade** — configure the map and proxy pass for WS:
  ''
  "Copy to a writable temp location"
  "Run `iii worker add` against the temp copy"
  ''
    Merge the generated worker entries back into `modules/agents/hermes/iii-config.yaml`
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
