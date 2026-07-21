# nixos-declarative-manifesto.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-declarative-manifesto

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-declarative-manifesto;
in
{
  options.hermes.skills.nixos-declarative-manifesto = {
    enable = mkEnableOption "Apply the Declarative, Reproducible, Reliable (DRR) NixOS philosophy to any project under /mnt/data/workspace/ — MANIFESTO.md anchor, nix-init-project scaffolder, and cross-layer consistency.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-declarative-manifesto = {
      enable = true;
  description = "Apply the Declarative, Reproducible, Reliable (DRR) NixOS philosophy to any project under /mnt/data/workspace/ — MANIFESTO.md anchor, nix-init-project scaffolder, and cross-layer consistency.";
  triggers = [
  "start new project"
  "project setup scaffold"
  "declarative"
  "reproducible"
  "reliable"
  "manifesto"
  "project flake"
  "devShell"
  "nix-init-project"
  "nix flake new"
  "project structure"
  "nixos-rebuild"
  "rebuild nixos"
  "nixos-rebuild switch"
];
  type = "workflow";
  steps = [
  ''
    **Symlink MANIFESTO.md**: `ln -sf /mnt/data/workspace/soup-nix/MANIFESTO.md ./MANIFESTO.md`
  ''
  ''
    **Add flake.nix**: Use the templates in nix-init-project or write your own
  ''
  ''
    **Lock deps**: Commit `flake.lock`, pin Docker digests, hash Python deps
  ''
  "**Check against the pillars**:"
];
    };
  };
}
