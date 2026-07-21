# touchdesigner-mcp.nix — Auto-converted from Hermes skill
# Category: creative
# Original: touchdesigner-mcp

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.touchdesigner-mcp;
in
{
  options.hermes.skills.touchdesigner-mcp = {
    enable = mkEnableOption "Control a running TouchDesigner instance via twozero MCP — create operators, set parameters, wire connections, execute Python, build real-time visuals. 36 native tools.";
  };

  config = mkIf cfg.enable {
    hermes.skills.touchdesigner-mcp = {
      enable = true;
  description = "Control a running TouchDesigner instance via twozero MCP — create operators, set parameters, wire connections, execute Python, build real-time visuals. 36 native tools.";
  triggers = [
  "Control a running TouchDesigner instance via twozero MCP"
  "touchdesigner mcp"
];
  type = "workflow";
  steps = [
  ''
    **NEVER guess parameter names.** Call `td_get_par_info` for the op type FIRST. Your training data is wrong for TD 2025.32.
  ''
  ''
    **If `tdAttributeError` fires, STOP.** Call `td_get_operator_info` on the failing node before continuing.
  ''
  ''
    **NEVER hardcode absolute paths** in script callbacks. Use `me.parent()` / `scriptOp.parent()`.
  ''
  ''
    **Prefer native MCP tools over td_execute_python.** Use `td_create_operator`, `td_set_operator_pars`, `td_get_errors` etc. Only fall back to `td_execute_python` for complex multi-step logic.
  ''
  ''
    **Call `td_get_hints` before building.** It returns patterns specific to the op type you're working with.
  ''
  "Check if TD is running"
  "Download twozero.tox if not already cached"
  "Add `twozero_td` MCP server to Hermes config (if missing)"
  "Test the MCP connection on port 40404"
  ''
    Report what manual steps remain (drag .tox into TD, enable MCP toggle)
  ''
  ''
    **Drag `~/Downloads/twozero.tox` into the TD network editor** → click Install
  ''
  ''
    **Enable MCP:** click twozero icon → Settings → mcp → "auto start MCP" → Yes
  ''
  "**Restart Hermes session** to pick up the new MCP server"
  ''
    **Verify FPS > 0** via `td_get_perf`. If FPS=0 the recording will be empty. See pitfalls #38-39.
  ''
  ''
    **Verify shader output is not black** via `td_get_screenshot`. Black output = shader error or missing input. See pitfalls #8, #40.
  ''
  ''
    **If recording with audio:** cue audio to start first, then delay recording by 3 frames. See pitfalls #19.
  ''
  ''
    **Set output path before starting record** — setting both in the same script can race.
  ''
  ''
    **TimeSlice must stay ON** for AudioSpectrum. OFF = processes entire audio file → 24000+ samples → CHOP to TOP overflow.
  ''
  ''
    **Set Output Length manually** to 256 via `outputmenu='setmanually'` and `outlength=256`. Default outputs 22050 samples.
  ''
  ''
    **DO NOT use Lag CHOP for spectrum smoothing.** Lag CHOP operates in timeslice mode and expands 256 samples to 2400+, averaging all values to near-zero (~1e-06). The shader receives no usable data. This was the #1 audio sync failure in testing.
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
