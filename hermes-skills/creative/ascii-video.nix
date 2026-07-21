# ascii-video.nix — Auto-converted from Hermes skill
# Category: creative
# Original: ascii-video

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.ascii-video;
in
{
  options.hermes.skills.ascii-video = {
    enable = mkEnableOption "ASCII video: convert video/audio to colored ASCII MP4/GIF.";
  };

  config = mkIf cfg.enable {
    hermes.skills.ascii-video = {
      enable = true;
  description = "ASCII video: convert video/audio to colored ASCII MP4/GIF.";
  triggers = [
  "ascii-video"
  "ascii video"
];
  type = "workflow";
  steps = [
  ''
    **INPUT** — Load/decode source material (video frames, audio samples, images, or nothing)
  ''
  ''
    **ANALYZE** — Extract per-frame features (audio bands, video luminance/edges, motion vectors)
  ''
  ''
    **SCENE_FN** — Scene function renders to pixel canvas (`uint8 H,W,3`). Composes multiple character grids via `_render_vf()` + pixel blend modes. See `references/composition.md`
  ''
  ''
    **TONEMAP** — Percentile-based adaptive brightness normalization. See `references/composition.md` § Adaptive Tonemap
  ''
  ''
    **SHADE** — Post-processing via `ShaderChain` + `FeedbackBuffer`. See `references/shaders.md`
  ''
  ''
    **ENCODE** — Pipe raw RGB frames to ffmpeg for H.264/GIF encoding
  ''
  ''
    **Hardware detection + quality profile** — `references/optimization.md`
  ''
  "**Input loader** — mode-dependent; `references/inputs.md`"
  ''
    **Feature analyzer** — audio FFT, video luminance, or synthetic
  ''
  ''
    **Grid + renderer** — multi-density grids with bitmap cache; `references/architecture.md`
  ''
  ''
    **Character palettes** — multiple per project; `references/architecture.md` § Palettes
  ''
  ''
    **Color system** — HSV + discrete RGB + harmony generation; `references/architecture.md` § Color
  ''
  ''
    **Scene functions** — each returns `canvas (uint8 H,W,3)`; `references/scenes.md`
  ''
  ''
    **Tonemap** — adaptive brightness normalization; `references/composition.md`
  ''
  ''
    **Shader pipeline** — `ShaderChain` + `FeedbackBuffer`; `references/shaders.md`
  ''
  ''
    **Scene table + dispatcher** — time → scene function + config; `references/scenes.md`
  ''
  ''
    **Parallel encoder** — N-worker clip rendering with ffmpeg pipes
  ''
  "**Main** — orchestrate full pipeline"
  ''
    Pick a domain unrelated to the visual goal (weather systems, microbiology, architecture, fluid dynamics, textile weaving)
  ''
  ''
    List its core visual/structural elements (erosion → gradual reveal; mitosis → splitting duplication; weaving → interlocking patterns)
  ''
];
  pitfalls = [
  ''
    **Output location** — generated files may go to unexpected directories. Always check the path
  ''
  ''
    **Resource constraints** — complex renderings/animations may need significant CPU or memory- **Dependency availability** — verify the required tools (pyfiglet, ImageMagick, etc.) are installed
  ''
];
    };
  };
}
