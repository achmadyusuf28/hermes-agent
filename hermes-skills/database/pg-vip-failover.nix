# pg-vip-failover.nix — Auto-converted from Hermes skill
# Category: database
# Original: pg-vip-failover

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.pg-vip-failover;
in
{
  options.hermes.skills.pg-vip-failover = {
    enable = mkEnableOption "Auto-failover for PostgreSQL with DNAT VIP + external arbitrator. Two-node primary/standby with split-brain prevention. Priority-based node ring — extendable to N nodes.";
  };

  config = mkIf cfg.enable {
    hermes.skills.pg-vip-failover = {
      enable = true;
  description = "Auto-failover for PostgreSQL with DNAT VIP + external arbitrator. Two-node primary/standby with split-brain prevention. Priority-based node ring — extendable to N nodes.";
  triggers = [
  "postgresql failover"
  "pg auto failover"
  "database high availability"
  "postgres ha"
  "primary standby automatic failover"
  "pg watchdog"
  "split brain prevention"
  "database arbitrator"
  "postgres vip"
];
  type = "workflow";
  steps = [
  "Can I reach the arbitrator?"
  "Read the lease (who's the declared primary?)."
  "Am I the declared primary?"
  ''
    Create the container with `--restart no` so it exists but stays stopped:
  ''
  ''
    The watchdog starts it on promotion (node becomes primary) and stops it on demotion:
  ''
  ''
    On the primary/always-on node, the container runs with `--restart unless-stopped` — no watchdog management needed.
  ''
  ''
    The standby node runs with non-critical features disabled (e.g., `DERIVER_ENABLED=false` on Honcho) since it may lack GPU embeddings.
  ''
  "Add to `VIP_PORTS` in the watchdog script"
  "Add MASQUERADE rule in `pg-failover.nix`"
  "Add firewall rule in `infrastructure.nix`"
  ''
    Deploy the container on the primary node, pointing at `127.0.0.2:<port>`
  ''
  ''
    Run watchdog `--apply` on both nodes — it sets up DNAT for the new port
  ''
  ''
    Point all Hermes config files at `127.0.0.2:<port>` on both nodes
  ''
  ''
    Add a static DNAT rule in `pg-failover.nix` — always to `127.0.0.1:<port>`, not managed by watchdog
  ''
  "Add MASQUERADE rule (for the replica's DNAT as backup)"
  "Add firewall rule in `infrastructure.nix`"
  ''
    Deploy the container on both nodes, pointing at `127.0.0.2:<port>`
  ''
  "`nix flake check` on hermes-nix"
  ''
    Rebuild soup (laptop): `nix flake lock --update-input hermes-nix && sudo nixos-rebuild switch`
  ''
  ''
    Rebuild bismuth (desktop, 24/7): push to GitHub, then via SSH: `nix flake update hermes-nix` → build toplevel → activate
  ''
];
  pitfalls = [
  ''
    **Backup before destructive operations** — always take a backup or snapshot before DROP/TRUNCATE/DELETE
  ''
  ''
    **Transaction timeout** — long-running migrations may hit `lock_timeout` or `statement_timeout`- **Connection pool exhaustion** — many concurrent clients can exhaust PG connection limits
  ''
];
    };
  };
}
