# pretext.nix — Auto-converted from Hermes skill
# Category: creative
# Original: pretext

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.pretext;
in
{
  options.hermes.skills.pretext = {
    enable = mkEnableOption "Use when building creative browser demos with @chenglou/pretext — DOM-free text layout for ASCII art, typographic flow around obstacles, text-as-geometry games, kinetic typography, and text-powered generative art. Produces single-file HTML demos by default.";
  };

  config = mkIf cfg.enable {
    hermes.skills.pretext = {
      enable = true;
  description = "Use when building creative browser demos with @chenglou/pretext — DOM-free text layout for ASCII art, typographic flow around obstacles, text-as-geometry games, kinetic typography, and text-powered generative art. Produces single-file HTML demos by default.";
  type = "workflow";
  steps = [
  ''
    **Pick a pattern** from the table above based on the user's brief.
  ''
  "**Start from a template**:"
  ''
    **Swap the corpus** for something intentional to the brief. Real prose, 10-100 sentences, no lorem.
  ''
  ''
    **Tune the aesthetic** — font, palette, composition, interaction. This is the work; don't skip it.
  ''
  "**Verify locally**:"
  ''
    **Check the console** — pretext will throw if `prepareWithSegments` is called with a bad font string; `Intl.Segmenter` is available in every modern browser.
  ''
  ''
    **Show the user the file path**, not just the code — they want to open it.
  ''
  ''
    **Drifting CSS/canvas font strings.** `ctx.font = "16px Inter"` measured, but CSS says `font-family: Inter, sans-serif; font-size: 16px`. Fine *if* Inter loads. If Inter 404s, CSS falls back to sans-serif and measurements drift by 5-20%. Always `preload` the font or use a web-safe family.
  ''
  ''
    **Re-preparing inside the animation loop.** Only `layout*` is cheap. Re-calling `prepare` every frame will tank perf. Keep the prepared handle in module scope.
  ''
  ''
    **Forgetting `Intl.Segmenter` for grapheme splits.** Emoji, combining marks, CJK — `"é".split("")` gives you two chars. Use `new Intl.Segmenter(undefined, { granularity: "grapheme" })` when sampling individual visible glyphs.
  ''
  ''
    **`break: 'never'` chips without `extraWidth`.** In `rich-inline`, if you use `break: 'never'` for an atomic chip/mention, you must also supply `extraWidth` for the pill padding — otherwise chip chrome overflows the container.
  ''
  ''
    **Using `@chenglou/pretext` from `unpkg` with TypeScript-only entry.** Use `esm.sh` — it compiles the TS exports to browser-ready ESM automatically. `unpkg` will 404 or serve raw TS.
  ''
  ''
    **Monospace fallbacks silently erasing the whole point.** Users seeing monospace-looking output often have a CSS `font-family` that fell through to `monospace`. Verify the actual rendered font via DevTools.
  ''
  ''
    **Skipping rows vs adjusting width** when flowing around a shape. If the corridor on this row is too narrow to fit a line, *skip the row* (`y += lineHeight; continue;`) rather than passing a tiny maxWidth to `layoutNextLineRange` — pretext will return one-grapheme lines that look broken.
  ''
  ''
    **Shipping a cold demo.** The default first-paint looks tutorial-grade. Add: vignette, subtle scanline, idle auto-motion, one carefully chosen interactive response (drag, hover, scroll, click). Without these, "cool pretext demo" lands as "intern repro of the README."
  ''
];
  pitfalls = [
  ''
    **Drifting CSS/canvas font strings.** `ctx.font = "16px Inter"` measured, but CSS says `font-family: Inter, sans-serif; font-size: 16px`. Fine *if* Inter loads. If Inter 404s, CSS falls back to sans-serif and measurements drift by 5-20%. Always `preload` the font or use a web-safe family.
  ''
  ''
    **Re-preparing inside the animation loop.** Only `layout*` is cheap. Re-calling `prepare` every frame will tank perf. Keep the prepared handle in module scope.
  ''
  ''
    **Forgetting `Intl.Segmenter` for grapheme splits.** Emoji, combining marks, CJK — `"é".split("")` gives you two chars. Use `new Intl.Segmenter(undefined, { granularity: "grapheme" })` when sampling individual visible glyphs.
  ''
  ''
    **`break: 'never'` chips without `extraWidth`.** In `rich-inline`, if you use `break: 'never'` for an atomic chip/mention, you must also supply `extraWidth` for the pill padding — otherwise chip chrome overflows the container.
  ''
  ''
    **Using `@chenglou/pretext` from `unpkg` with TypeScript-only entry.** Use `esm.sh` — it compiles the TS exports to browser-ready ESM automatically. `unpkg` will 404 or serve raw TS.
  ''
  ''
    **Monospace fallbacks silently erasing the whole point.** Users seeing monospace-looking output often have a CSS `font-family` that fell through to `monospace`. Verify the actual rendered font via DevTools.
  ''
  ''
    **Skipping rows vs adjusting width** when flowing around a shape. If the corridor on this row is too narrow to fit a line, *skip the row* (`y += lineHeight; continue;`) rather than passing a tiny maxWidth to `layoutNextLineRange` — pretext will return one-grapheme lines that look broken.
  ''
  ''
    **Shipping a cold demo.** The default first-paint looks tutorial-grade. Add: vignette, subtle scanline, idle auto-motion, one carefully chosen interactive response (drag, hover, scroll, click). Without these, "cool pretext demo" lands as "intern repro of the README."
  ''
];
    };
  };
}
