# humanizer.nix — Auto-converted from Hermes skill
# Category: creative
# Original: humanizer

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.humanizer;
in
{
  options.hermes.skills.humanizer = {
    enable = mkEnableOption "Humanize text: strip AI-isms and add real voice.";
  };

  config = mkIf cfg.enable {
    hermes.skills.humanizer = {
      enable = true;
  description = "Humanize text: strip AI-isms and add real voice.";
  triggers = [
  "humanizer"
];
  type = "workflow";
  steps = [
  ''
    **Inline** — user pastes the text directly into the message. Work on it in-place, reply with the rewrite.
  ''
  ''
    **File** — user points at a file. Use `read_file` to load it, then `patch` or `write_file` to apply edits. For markdown docs in a repo, a targeted `patch` per section is cleaner than rewriting the whole file.
  ''
  ''
    **Voice calibration sample** — user provides an additional sample of their own writing (inline or by file path) and asks you to match it. Read the sample first, then rewrite. See the Voice Calibration section below.
  ''
  ''
    **Identify AI patterns** — scan for the 29 patterns listed below.
  ''
  ''
    **Rewrite problematic sections** — replace AI-isms with natural alternatives.
  ''
  "**Preserve meaning** — keep the core message intact."
  ''
    **Maintain voice** — match the intended tone (formal, casual, technical, etc.). If a voice sample was provided, match it specifically.
  ''
  ''
    **Add soul** — don't just remove bad patterns, inject actual personality. See PERSONALITY AND SOUL below.
  ''
  ''
    **Do a final anti-AI pass** — ask yourself: "What makes the below so obviously AI generated?" Answer briefly with any remaining tells, then revise one more time.
  ''
  "**Read the sample first.** Note:"
  ''
    **Match their voice in the rewrite.** Don't just remove AI patterns — replace them with patterns from the sample. If they write short sentences, don't produce long ones. If they use "stuff" and "things," don't upgrade to "elements" and "components."
  ''
  ''
    **When no sample is provided,** fall back to the default behavior (natural, varied, opinionated voice from the PERSONALITY AND SOUL section below).
  ''
  ''
    Read the input text carefully (use `read_file` if it's a file).
  ''
  "Identify all instances of the patterns above."
  "Rewrite each problematic section."
  "Ensure the revised text:"
  "Present a draft humanized version."
  ''
    Prompt yourself: "What makes the below so obviously AI generated?"
  ''
  "Answer briefly with the remaining tells (if any)."
  "Prompt yourself: \"Now make it not obviously AI generated.\""
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
