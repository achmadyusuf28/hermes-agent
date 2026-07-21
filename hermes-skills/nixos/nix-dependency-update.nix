# nix-dependency-update.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nix-dependency-update

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nix-dependency-update;
in
{
  options.hermes.skills.nix-dependency-update = {
    enable = mkEnableOption "Update pinned dependency versions in Nix derivations — bump version strings, prefetch hashes, patch .nix files, and verify no stale references remain.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nix-dependency-update = {
      enable = true;
  description = "Update pinned dependency versions in Nix derivations — bump version strings, prefetch hashes, patch .nix files, and verify no stale references remain.";
  triggers = [
  "bump [package] from [v] to [v]"
  "update pinned version"
  "new release of [tool]"
  "upgrade nix dependency"
  "prefetch-url"
];
  type = "workflow";
  pitfalls = [
  ''
    **`hash` vs `sha256` attribute — different formats accepted.** `fetchurl`'s `hash` attribute expects SRI format (`sha256-<base64>`, 44 chars). The `sha256` attribute expects Nix base32 format (52 chars) — which is what `nix-prefetch-url` outputs by default. Using a base32 hash in the `hash` attribute produces: `error: invalid SRI hash '...', length N != expected length 32`. Fix: use `sha256` for base32, or `hash` for SRI.
  ''
  ''
    **`nix-prefetch-url` outputs base32 by default, NOT SRI.** The raw output string is a 52-character Nix base32 hash (e.g. `0pm2l28v24kgy9vyi6a1xqm79ykald9hcvf4vwbigy2xq34nrr9v`). To get SRI format, pass `--hash sha256` or convert via `nix hash convert`. Do NOT assume the default output is SRI.
  ''
  ''
    **Stale comments are invisible in diffs.** `grep` the old string — don't assume comments were updated just because the version variable was.
  ''
  ''
    **Multiple derivations in one file.** Each one may need a separate prefetch. Confirm you got hashes for ALL sources before patching.
  ''
  ''
    **Version appearing in unrelated places.** The old version string can appear in file paths, options, or credential tokens. Verify each match before patching.
  ''
  ''
    **File permissions block flake evaluation.** Source files imported via `./relative-path` in a flake must be readable by the user running `nix eval` / `nixos-rebuild`. Files with `600` permissions owned by another user will produce `error: opening file '...': Permission denied`. Fix: `chmod 644` on sourced files (`.nix`, `.yaml`, `.md`, etc.) in the flake directory.
  ''
];
    };
  };
}
