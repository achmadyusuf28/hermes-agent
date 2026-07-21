# youtube-content.nix — Auto-converted from Hermes skill
# Category: media
# Original: youtube-content

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.youtube-content;
in
{
  options.hermes.skills.youtube-content = {
    enable = mkEnableOption "YouTube transcripts to summaries, threads, blogs.";
  };

  config = mkIf cfg.enable {
    hermes.skills.youtube-content = {
      enable = true;
  description = "YouTube transcripts to summaries, threads, blogs.";
  triggers = [
  "youtube-content"
  "youtube content"
];
  type = "workflow";
  steps = [
  ''
    **Fetch** the transcript using the helper script with `--text-only --timestamps` via `uv run python3`.
  ''
  ''
    **Validate**: confirm the output is non-empty and in the expected language. If empty, retry without `--language` to get any available transcript. If still empty, tell the user the video likely has transcripts disabled.
  ''
  ''
    **Chunk if needed**: if the transcript exceeds ~50K characters, split into overlapping chunks (~40K with 2K overlap) and summarize each chunk before merging.
  ''
  ''
    **Transform** into the requested output format. If the user did not specify a format, default to a summary.
  ''
  ''
    **Verify**: re-read the transformed output to check for coherence, correct timestamps, and completeness before presenting.
  ''
];
  pitfalls = [
  ''
    **File format mismatch** — verify the output format is compatible with the intended use
  ''
  ''
    **API key requirements** — some media APIs require authentication. Check credentials first- **Size limits** — large media files may exceed tool or platform limits. Test with representative sizes
  ''
];
    };
  };
}
