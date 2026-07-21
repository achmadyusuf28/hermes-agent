# heartmula.nix — Auto-converted from Hermes skill
# Category: media
# Original: heartmula

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.heartmula;
in
{
  options.hermes.skills.heartmula = {
    enable = mkEnableOption "HeartMuLa: Suno-like song generation from lyrics + tags.";
  };

  config = mkIf cfg.enable {
    hermes.skills.heartmula = {
      enable = true;
  description = "HeartMuLa: Suno-like song generation from lyrics + tags.";
  type = "workflow";
  steps = [
  ''
    **Do NOT use bf16 for HeartCodec** — degrades audio quality. Use fp32 (default).
  ''
  ''
    **Tags may be ignored** — known issue (#90). Lyrics tend to dominate; experiment with tag ordering.
  ''
  ''
    **Triton not available on macOS** — Linux/CUDA only for GPU acceleration.
  ''
  "**RTX 5080 incompatibility** reported in upstream issues."
  ''
    The dependency pin conflicts require the manual upgrades and patches described above.
  ''
];
  pitfalls = [
  ''
    **Do NOT use bf16 for HeartCodec** — degrades audio quality. Use fp32 (default).
  ''
  ''
    **Tags may be ignored** — known issue (#90). Lyrics tend to dominate; experiment with tag ordering.
  ''
  ''
    **Triton not available on macOS** — Linux/CUDA only for GPU acceleration.
  ''
  "**RTX 5080 incompatibility** reported in upstream issues."
  ''
    The dependency pin conflicts require the manual upgrades and patches described above.
  ''
];
    };
  };
}
