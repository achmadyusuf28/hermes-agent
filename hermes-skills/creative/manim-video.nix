# manim-video.nix — Auto-converted from Hermes skill
# Category: creative
# Original: manim-video

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.manim-video;
in
{
  options.hermes.skills.manim-video = {
    enable = mkEnableOption "Manim CE animations: 3Blue1Brown math/algo videos.";
  };

  config = mkIf cfg.enable {
    hermes.skills.manim-video = {
      enable = true;
  description = "Manim CE animations: 3Blue1Brown math/algo videos.";
  triggers = [
  "manim-video"
  "manim video"
];
  type = "workflow";
  steps = [
  ''
    **PLAN** — Write `plan.md` with narrative arc, scene list, visual elements, color palette, voiceover script
  ''
  ''
    **CODE** — Write `script.py` with one class per scene, each independently renderable
  ''
  ''
    **RENDER** — `manim -ql script.py Scene1 Scene2 ...` for draft, `-qh` for production
  ''
  "**STITCH** — ffmpeg concat of scene clips into `final.mp4`"
  ''
    **AUDIO** (optional) — Add voiceover and/or background music via ffmpeg. See `references/rendering.md`
  ''
  ''
    **REVIEW** — Render preview stills, verify against plan, adjust
  ''
  ''
    List what's "standard" about how this topic is visualized (left-to-right, 2D, discrete steps, formal notation)
  ''
  "Pick the most fundamental assumption"
  ''
    Reverse it (right-to-left derivation, 3D embedding of a 2D concept, continuous morphing instead of steps, zero notation)
  ''
  ''
    Explore what the reversal reveals that the standard approach hides
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
