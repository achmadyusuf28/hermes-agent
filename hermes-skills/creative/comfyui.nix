# comfyui.nix — Auto-converted from Hermes skill
# Category: creative
# Original: comfyui

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.comfyui;
in
{
  options.hermes.skills.comfyui = {
    enable = mkEnableOption "Generate images, video, and audio with ComfyUI — install, launch, manage nodes/models, run workflows with parameter injection. Uses the official comfy-cli for lifecycle and direct REST/WebSocket API for execution.";
  };

  config = mkIf cfg.enable {
    hermes.skills.comfyui = {
      enable = true;
  description = "Generate images, video, and audio with ComfyUI — install, launch, manage nodes/models, run workflows with parameter injection. Uses the official comfy-cli for lifecycle and direct REST/WebSocket API for execution.";
  type = "workflow";
  steps = [
  "Sign up at https://comfy.org/cloud"
  "Generate an API key at https://platform.comfy.org/login"
  "Set the key:"
  "Run workflows:"
  ''
    **API format required** — every script and the `/api/prompt` endpoint expect
  ''
  ''
    **Server must be running** — all execution requires a live server.
  ''
  ''
    **Model names are exact** — case-sensitive, includes file extension.
  ''
  ''
    **Missing custom nodes** — "class_type not found" means a required node
  ''
  ''
    **Working directory** — `comfy-cli` auto-detects the ComfyUI workspace.
  ''
  ''
    **Cloud free-tier API limits** — `/api/prompt`, `/api/view`, `/api/upload/*`,
  ''
  ''
    **Timeout for video/audio workflows** — auto-detected when an output node
  ''
  ''
    **Path traversal in output filenames** — server-supplied filenames are
  ''
  ''
    **Workflow JSON is arbitrary code** — custom nodes run Python, so
  ''
  ''
    **Auto-randomized seed** — pass `seed: -1` in `--args` (or use
  ''
  ''
    **`tracking` prompt** — first run of `comfy` may prompt for analytics.
  ''
];
  pitfalls = [
  ''
    **API format required** — every script and the `/api/prompt` endpoint expect
  ''
  ''
    **Server must be running** — all execution requires a live server.
  ''
  ''
    **Model names are exact** — case-sensitive, includes file extension.
  ''
  ''
    **Missing custom nodes** — "class_type not found" means a required node
  ''
  ''
    **Working directory** — `comfy-cli` auto-detects the ComfyUI workspace.
  ''
  ''
    **Cloud free-tier API limits** — `/api/prompt`, `/api/view`, `/api/upload/*`,
  ''
  ''
    **Timeout for video/audio workflows** — auto-detected when an output node
  ''
  ''
    **Path traversal in output filenames** — server-supplied filenames are
  ''
  ''
    **Workflow JSON is arbitrary code** — custom nodes run Python, so
  ''
  ''
    **Auto-randomized seed** — pass `seed: -1` in `--args` (or use
  ''
  ''
    **`tracking` prompt** — first run of `comfy` may prompt for analytics.
  ''
];
    };
  };
}
