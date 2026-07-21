# nixos-secrets-management.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-secrets-management

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-secrets-management;
in
{
  options.hermes.skills.nixos-secrets-management = {
    enable = mkEnableOption "Manage secrets on NixOS using sops-nix with age encryption — generating age keys from SSH, configuring .sops.yaml, encrypting/decrypting secrets, wiring into Nix config, and git integration.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-secrets-management = {
      enable = true;
  description = "Manage secrets on NixOS using sops-nix with age encryption — generating age keys from SSH, configuring .sops.yaml, encrypting/decrypting secrets, wiring into Nix config, and git integration.";
  triggers = [
  "sops"
  "secrets management"
  "age encryption"
  "api keys nixos"
  "env files nixos"
  "scattered secrets"
  "consolidate secrets"
];
  type = "workflow";
  pitfalls = [
  ''
    **`SOPS_AGE_KEY_FILE` does not accept SSH private keys**: sops expects native age private keys. Use `ssh-to-age -private-key -i <ssh_key>` to convert, then pass the result via `SOPS_AGE_KEY`.
  ''
  ''
    **Encrypting without both recipients**: If you encrypt with only one age key, the other recipient can't decrypt. Always list all authorized keys in `.sops.yaml`.
  ''
  ''
    **Nix ''' string quoting**: Avoid inline `'''` in Nix strings — consecutive single quotes prematurely close a Nix multi-line string. Use `printf` or heredocs in wrapped scripts instead.
  ''
  ''
    **Permissions**: Encrypted files can be tracked in git. Plaintext `secrets/` directory must stay in `.gitignore`. Double-check before committing.
  ''
];
    };
  };
}
