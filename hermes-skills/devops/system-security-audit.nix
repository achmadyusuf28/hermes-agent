# system-security-audit.nix — Auto-converted from Hermes skill
# Category: devops
# Original: system-security-audit

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.system-security-audit;
in
{
  options.hermes.skills.system-security-audit = {
    enable = mkEnableOption "Audit and secure network service exposure on a NixOS development machine with Docker containers. Enumerate listening services, identify exposed ports, check Docker network modes, and tighten bind addresses to localhost.";
  };

  config = mkIf cfg.enable {
    hermes.skills.system-security-audit = {
      enable = true;
  description = "Audit and secure network service exposure on a NixOS development machine with Docker containers. Enumerate listening services, identify exposed ports, check Docker network modes, and tighten bind addresses to localhost.";
  triggers = [
  "security audit"
  "open ports"
  "exposed services"
  "network security"
  "localhost only"
  "bind to localhost"
  "secure the machine"
  "check what's listening"
];
  type = "meta";
  pitfalls = [
  ''
    **Docker `--network=host` containers can't be converted to bridge in one step** if they depend on `localhost` to reach other host-mode containers. Create a shared bridge network first, then convert one container at a time, updating its internal hostnames to use container names instead of `localhost`.
  ''
  ''
    **Some apps hardcode `0.0.0.0`** in their config — check the app's own config file, not just the systemd or Docker invocation.
  ''
  ''
    **NixOS rebuild needed** after changing services.postgresql/redis settings — use `nixos-rebuild switch`.
  ''
  ''
    **iii engine** may bind `0.0.0.0` despite config saying `127.0.0.1` — the `web` and `harness` workers in the config override the HTTP/Stream workers' host setting. The config's `host: 127.0.0.1` on the `iii-http` and `iii-stream` workers applies only to those workers; the `web` worker binds independently to `0.0.0.0`. Port 49134 (WebSocket bridge) is set by `iii-console --bridge-port 49134` — it inherits the engine's default bind. Verify with `systemctl cat iii-console` and check the `--bridge-port` flag.
  ''
  ''
    **FastAPI processes** started from ad-hoc scripts may use `--host 0.0.0.0` — find the script that launches it and change the host flag.
  ''
  ''
    **`trustedInterfaces` placeholders** — NixOS `networking.firewall.trustedInterfaces` with a nonexistent interface name (e.g. `[ "ztxxxxxx" ]` instead of the real ZeroTier interface) generates iptables rules that have 0 matched packets — they never fire. The firewall still works for other rules, but the trusted interface exemption is a no-op. Find the real interface with `ip link | grep zt` and fix the config.
  ''
  ''
    **Docker containers revealed by PID only** — some containers use host networking and their process shows in `ss` with a PID but no obvious link to a container name. Check the process cgroup: `cat /proc/<pid>/cgroup` — if it contains `.scope` with a Docker container ID, it's a container. Map container ID to name with `docker ps --no-trunc`.
  ''
  ''
    **Systemd ExecStart does NOT use a shell** — Pipes `|`, redirects `>`, and boolean operators `||` are passed as literal arguments to the executable, not interpreted by a shell. This is a common trap in NixOS systemd service configs:
  ''
];
    };
  };
}
