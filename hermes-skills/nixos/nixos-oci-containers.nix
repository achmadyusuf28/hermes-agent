# nixos-oci-containers.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-oci-containers

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-oci-containers;
in
{
  options.hermes.skills.nixos-oci-containers = {
    enable = mkEnableOption "Manage Docker containers declaratively via NixOS virtualisation.oci-containers — adding containers, databases, images, networking, systemd lifecycle, restart-on-resume, and rebuild workflow on soup-nix.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-oci-containers = {
      enable = true;
  description = "Manage Docker containers declaratively via NixOS virtualisation.oci-containers — adding containers, databases, images, networking, systemd lifecycle, restart-on-resume, and rebuild workflow on soup-nix.";
  triggers = [
  "add a new docker container"
  "nixify a docker compose project"
  "oci-container"
  "docker container not restarti"
  "port conflict with existing container"
  "add postgres database"
  "rebuild after container change"
  "systemd docker service"
  "new container alongside existing"
  "local docker image in nix"
  "restart on resume"
  "docker network host vs bridge"
  "parallel container instances"
  "migrate database to new container"
];
  type = "workflow";
  steps = [
  "Build new image ✓"
  "Rebuild Nix ✓"
  ''
    **BUT**: if the container name didn't change, systemd re-uses the old container's `docker run` which already has the old image cached. The fix:
  ''
];
    };
  };
}
