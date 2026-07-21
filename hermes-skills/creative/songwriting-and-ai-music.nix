# songwriting-and-ai-music.nix — Auto-converted from Hermes skill
# Category: creative
# Original: songwriting-and-ai-music

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.songwriting-and-ai-music;
in
{
  options.hermes.skills.songwriting-and-ai-music = {
    enable = mkEnableOption "Songwriting craft and Suno AI music prompts.";
  };

  config = mkIf cfg.enable {
    hermes.skills.songwriting-and-ai-music = {
      enable = true;
  description = "Songwriting craft and Suno AI music prompts.";
  triggers = [
  "writing a song"
  "song lyrics"
  "music prompt"
  "suno prompt"
  "parody song"
  "adapting a song"
  "AI music generation"
];
  type = "workflow";
  steps = [
  "Write the concept/hook first — what's the emotional core?"
  ''
    If adapting, map the original structure (syllables, rhyme, stress)
  ''
  ''
    Generate raw material — brainstorm freely before structuring
  ''
  "Draft lyrics into the structure"
  "Read/sing aloud — catch stumbles, fix meter"
  ''
    Build the Suno style description — paint the dynamic journey
  ''
  "Add metatags to lyrics for performance direction"
  ''
    Generate 3-5 variations minimum — treat them like recording takes
  ''
  ''
    Pick the best, use Extend/Continue to build on promising sections
  ''
  "If something great happens by accident, keep it"
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
