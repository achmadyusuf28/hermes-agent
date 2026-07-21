# nixos-shared-workspace.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-shared-workspace

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-shared-workspace;
in
{
  options.hermes.skills.nixos-shared-workspace = {
    enable = mkEnableOption "Configure NixOS for multi-user collaborative development — shared group-writable workspace, cross-user git repos, permission stack for soup/hermes or any user pair.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-shared-workspace = {
      enable = true;
  description = "Configure NixOS for multi-user collaborative development — shared group-writable workspace, cross-user git repos, permission stack for soup/hermes or any user pair.";
  triggers = [
  "Configure NixOS for multi-user collaborative development"
  "nixos shared workspace"
];
  type = "tool";
  verify = ''
  After activation, test from each user's shell:

```bash
  '';
  pitfalls = [
  ''
    **`environment.interactiveShellInit` type**: It's `types.lines` (concatenated strings). Setting it in `configuration.nix` adds to any value set by other modules. If another module already sets it, both values appear.
  ''
  ''
    **Non-interactive shells**: System services, `nix-daemon`, and `#!` scripts don't read `/etc/bashrc`. For build systems that spawn subprocesses, the parent shell's umask is inherited — run builds from an interactive shell with umask 002.
  ''
  ''
    **ACL mount option**: Not needed on modern kernels (5.15+ ext4 defaults to ACL). The setgid + umask approach avoids ACL dependency entirely.
  ''
  ''
    **`z` vs `Z` in tmpfiles**: `z` sets permissions without following symlinks; `Z` is recursive (sets on everything below). Use `z` for the top-level dir, then `Z` only if you want to recursively fix an existing tree.
  ''
  ''
    **`nix flake check` may fail** as hermes if soup-owned files are `644` — that's the old permission problem. After activation, new files will be group-readable. Run the one-time fix above for existing files.
  ''
];
    };
  };
}
