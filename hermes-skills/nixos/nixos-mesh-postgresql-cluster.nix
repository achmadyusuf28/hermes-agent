# nixos-mesh-postgresql-cluster.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-mesh-postgresql-cluster

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-mesh-postgresql-cluster;
in
{
  options.hermes.skills.nixos-mesh-postgresql-cluster = {
    enable = mkEnableOption "Orchestrate the full lifecycle of a multi-node PostgreSQL cluster on NixOS — primary migration, streaming replication setup, failover test, and role-based service dispatch (server=primary, laptop=standby, replica=streaming). Covers the end-to-end process from initial dump/restore to production failover verification.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-mesh-postgresql-cluster = {
      enable = true;
  description = "Orchestrate the full lifecycle of a multi-node PostgreSQL cluster on NixOS — primary migration, streaming replication setup, failover test, and role-based service dispatch (server=primary, laptop=standby, replica=streaming). Covers the end-to-end process from initial dump/restore to production failover verification.";
  triggers = [
  "postgresql cluster"
  "move postgres to another host"
  "pg migration between nodes"
  "postgresql failover"
  "setup streaming replication"
  "postgres role-based nixos"
  "mesh database migration"
  "pg primary handoff"
];
  type = "workflow";
  steps = [
  "Verify PG version match on both nodes (pin `postgresql_15`)"
  "Set up SSH tunnel for interim connectivity"
  "Preliminary dump → transfer → preload on target"
  ''
    **Cutover**: stop services → final dump → restore → recreate containers with new DATABASE_URL
  ''
  ''
    **On primary**: create `replicator` role, add auth rule for mesh subnet
  ''
  ''
    **On standby**: stop PG, wipe data dir, run `pg_basebackup` from primary
  ''
  ''
    Create `standby.signal` and `postgresql.auto.conf` with `primary_conninfo`
  ''
  "Start standby PG"
  ''
    Verify: `pg_is_in_recovery = t` on standby, `state = streaming` on primary
  ''
  "Stop primary PG (simulate failure)"
  "Promote standby: `pg_ctl promote -D <data_dir>`"
  ''
    Verify: `pg_is_in_recovery = f` on promoted node, data intact
  ''
  ''
    Point services (Honcho/Manifest) at promoted node with recreated containers
  ''
  ''
    Fix table ownership on promoted node (same GRANT/ALTER pattern)
  ''
  ''
    Recover original primary: start PG → it's now a divergent primary
  ''
  ''
    Re-establish replication: `pg_basebackup` from the surviving primary → set up replication in the original direction
  ''
  ''
    Write a plan listing exactly which services will be affected
  ''
  "Get explicit user approval"
  ''
    Announce each irreversible step (stop PG, promote, create containers) before executing
  ''
  ''
    Write a plan listing exactly which services will be removed/added (docker-honcho, docker-qdrant, docker-redis, hermes-gateway are all gated behind `role == "server"`)
  ''
];
    };
  };
}
