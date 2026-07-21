# p5js.nix — Auto-converted from Hermes skill
# Category: creative
# Original: p5js

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.p5js;
in
{
  options.hermes.skills.p5js = {
    enable = mkEnableOption "p5.js sketches: gen art, shaders, interactive, 3D.";
  };

  config = mkIf cfg.enable {
    hermes.skills.p5js = {
      enable = true;
  description = "p5.js sketches: gen art, shaders, interactive, 3D.";
  triggers = [
  "p5js"
];
  type = "workflow";
  steps = [
  ''
    **CONCEPT** — Articulate the creative vision: mood, color world, motion vocabulary, what makes this unique
  ''
  ''
    **DESIGN** — Choose mode, canvas size, interaction model, color system, export format. Map concept to technical decisions
  ''
  ''
    **CODE** — Write single HTML file with inline p5.js. Structure: globals → `preload()` → `setup()` → `draw()` → helpers → classes → event handlers
  ''
  ''
    **PREVIEW** — Open in browser, verify visual quality. Test at target resolution. Check performance
  ''
  ''
    **EXPORT** — Capture output: `saveCanvas()` for PNG, `saveGif()` for GIF, `saveFrames()` + ffmpeg for MP4, Puppeteer for headless batch
  ''
  ''
    **VERIFY** — Does the output match the concept? Is it visually striking at the intended display size? Would you frame it?
  ''
  ''
    **Write the HTML file** — single self-contained file, all code inline
  ''
  ''
    **Open in browser** — `open sketch.html` (macOS) or `xdg-open sketch.html` (Linux)
  ''
  ''
    **Local assets** (fonts, images) require a server: `python3 -m http.server 8080` in the project directory, then open `http://localhost:8080/sketch.html`
  ''
  ''
    **Export PNG/GIF** — add `keyPressed()` shortcuts as shown above, tell the user which key to press
  ''
  ''
    **Headless export** — `node scripts/export-frames.js sketch.html --frames 300` for automated frame capture (sketch must use `noLoop()` + `_p5Ready`)
  ''
  ''
    **MP4 rendering** — `bash scripts/render.sh sketch.html output.mp4 --duration 30`
  ''
  ''
    **Iterative refinement** — edit the HTML file, user refreshes browser to see changes
  ''
  ''
    **Load references on demand** — use `skill_view(name="p5js", file_path="references/...")` to load specific reference files as needed during implementation
  ''
  ''
    Name two distinct visual systems (e.g., particle physics + handwriting)
  ''
  ''
    Map correspondences (particles = ink drops, forces = pen pressure, fields = letterforms)
  ''
  ''
    Blend selectively — keep mappings that produce interesting emergent visuals
  ''
  ''
    Code the blend as a unified system, not two systems side-by-side
  ''
  "Anchor on the user's concept (e.g., \"loneliness\")"
  "Generate associations at three distances:"
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
