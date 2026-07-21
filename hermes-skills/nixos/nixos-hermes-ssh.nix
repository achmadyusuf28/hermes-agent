# nixos-hermes-ssh.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-hermes-ssh

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-hermes-ssh;
in
{
  options.hermes.skills.nixos-hermes-ssh = {
    enable = mkEnableOption "Declarative SSH authentication for the Hermes user on NixOS — known hosts, tmpfiles keys, git push via SSH, and Git identity setup.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-hermes-ssh = {
      enable = true;
  description = "Declarative SSH authentication for the Hermes user on NixOS — known hosts, tmpfiles keys, git push via SSH, and Git identity setup.";
  triggers = [
  "ssh auth hermes"
  "github auth hermes"
  "git push hermes"
  "declarative ssh"
  "knownHosts"
  "tmpfiles ssh"
  "ssh key hermes"
  "hermes git identity"
  "ssh known hosts github"
];
  type = "tool";
  verify = ''
  ```bash
  '';
  pitfalls = [
  ''
    **Private key is NOT in the Nix store** — `id_ed25519` must be generated once manually. If the file doesn't exist, git operations will fail with permission denied. Generate it with `ssh-keygen -t ed25519` before first use.
  ''
  ''
    **`ssh-keyscan` output changes over time** — GitHub's host key rotates rarely but can change. If SSH starts warning about host key mismatch, re-run `ssh-keyscan -t ed25519 github.com` and update the Nix config.
  ''
  ''
    **`tmpfiles` `d` line creates but doesn't clean** — the `d` directive in tmpfiles creates the `.ssh` directory with the right permissions but does NOT clean existing files. If you need to replace a file (like the public key), use `f+` instead.
  ''
  ''
    **Shared repo permissions** — repos at `/mnt/data/workspace/` owned by `soup:users` may have `.git/objects/xx/` directories with 2755 (no group-write). Git operations that create new objects fail. Fix with `sudo chmod -R g+w /path/to/repo/.git` once.
  ''
  ''
    **Git identity is repo-local** — `git config user.email` and `user.name` are set per-repo, not globally. If you clone a new repo, the identity doesn't carry over.
  ''
  ''
    **`ssh -T git@github.com` succeeds but `git push` still fails** — the SSH auth works but the remote URL may still be HTTPS. Check with `git remote -v` and update to `git@github.com:` if needed.
  ''
  ''
    **NixOS rebuild can reset tmpfiles** — if the `tmpfiles` rules change, the `.ssh` directory permissions may be reset. Verify with `stat -c '%a' ~/.ssh` after a rebuild.
  ''
];
    };
  };
}
