# nixos-postgresql.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-postgresql

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-postgresql;
in
{
  options.hermes.skills.nixos-postgresql = {
    enable = mkEnableOption "Manage PostgreSQL on NixOS in the Hermes mesh cluster — role-based config (server=primary, laptop/replica), pg_hba store-path puzzle, cross-host migration with minimal downtime, Honcho/Manifest connection setup, streaming replication. Covers the read-only pg_hba.conf workaround, SSH tunnel pattern for cross-host PG access, and embedding dimension matching between Honcho container and stored vectors.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-postgresql = {
      enable = true;
  description = "Manage PostgreSQL on NixOS in the Hermes mesh cluster — role-based config (server=primary, laptop/replica), pg_hba store-path puzzle, cross-host migration with minimal downtime, Honcho/Manifest connection setup, streaming replication. Covers the read-only pg_hba.conf workaround, SSH tunnel pattern for cross-host PG access, and embedding dimension matching between Honcho container and stored vectors.";
  triggers = [
  "postgresql migration"
  "move postgres"
  "pg dump restore"
  "pg_hba.conf"
  "nixos postgresql"
  "postgres primary"
  "postgres replica"
  "streaming replication"
  "honcho database"
  "manifest database"
  "EMBEDDING_VECTOR_DIMENSIONS"
  "vector dimension mismatch"
  "honcho embedding"
  "zero downtime database migration"
];
  type = "workflow";
  steps = [
  ''
    Update `authentication = lib.mkAfter '''host all all 172.30.0.0/16 trust''';` in the shared module
  ''
  "Sync to the remote node"
  "Run `nixos-rebuild switch` on the remote"
  "Kill the tunnel, switch to direct `172.30.85.237:5432`"
  ''
    Rebuild NixOS with correct `authentication = lib.mkAfter '''...127.0.0.2...'''` rules
  ''
  "`ALTER SYSTEM RESET hba_file;` on the running PG"
  ''
    `SELECT pg_reload_conf();` — if hba_file stays at the old custom path, restart PG
  ''
  "Verify: `SHOW hba_file;` → `/nix/store/<hash>-pg_hba.conf`"
  ''
    Verify: `SELECT count(*) FROM pg_hba_file_rules WHERE address = '127.0.0.2';` → > 0
  ''
  "Clean up: `rm /var/lib/postgresql/15/pg_hba.custom.conf`"
  "**Prepare target** (zero downtime)"
  "**Preliminary dump** (zero downtime — source still serving)"
  "**Transfer to target** (zero downtime)"
  ''
    **Preload data on target** (zero downtime — source still serving)
  ''
  "**Fast cutover** (downtime ~5-15 seconds)"
  "**Verify**"
];
    };
  };
}
