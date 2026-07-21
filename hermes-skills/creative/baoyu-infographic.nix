# baoyu-infographic.nix — Auto-converted from Hermes skill
# Category: creative
# Original: baoyu-infographic

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.baoyu-infographic;
in
{
  options.hermes.skills.baoyu-infographic = {
    enable = mkEnableOption "Infographics: 21 layouts x 21 styles (信息图, 可视化).";
  };

  config = mkIf cfg.enable {
    hermes.skills.baoyu-infographic = {
      enable = true;
  description = "Infographics: 21 layouts x 21 styles (信息图, 可视化).";
  type = "workflow";
  steps = [
  ''
    Save source content (file path or paste → `source.md` using `write_file`)
  ''
  "Analyze: topic, data type, complexity, tone, audience"
  "Detect source language and user language"
  "Extract design instructions from user input"
  "Save analysis to `analysis.md`"
  "Title and learning objectives"
  ''
    Sections with: key concept, content (verbatim), visual element, text labels
  ''
  "Data points (all statistics/quotes copied exactly)"
  "Design instructions from user"
  "Layout definition from `references/layouts/<layout>.md`"
  "Style definition from `references/styles/<style>.md`"
  "Base template from `references/base-prompt.md`"
  "Structured content from Step 2"
  "All text in confirmed language"
  ''
    **Data integrity is paramount** — never summarize, paraphrase, or alter source statistics. "73% increase" must stay "73% increase", not "significant increase".
  ''
  ''
    **Strip secrets** — always scan source content for API keys, tokens, or credentials before including in any output file.
  ''
  ''
    **One message per section** — each infographic section should convey one clear concept. Overloading sections reduces readability.
  ''
  ''
    **Style consistency** — the style definition from the references file must be applied consistently across the entire infographic. Don't mix styles.
  ''
  ''
    **image_generate aspect ratios** — the tool only supports `landscape`, `portrait`, and `square`. Custom ratios like `3:4` should map to the nearest option (portrait in that case).
  ''
];
  pitfalls = [
  ''
    **Data integrity is paramount** — never summarize, paraphrase, or alter source statistics. "73% increase" must stay "73% increase", not "significant increase".
  ''
  ''
    **Strip secrets** — always scan source content for API keys, tokens, or credentials before including in any output file.
  ''
  ''
    **One message per section** — each infographic section should convey one clear concept. Overloading sections reduces readability.
  ''
  ''
    **Style consistency** — the style definition from the references file must be applied consistently across the entire infographic. Don't mix styles.
  ''
  ''
    **image_generate aspect ratios** — the tool only supports `landscape`, `portrait`, and `square`. Custom ratios like `3:4` should map to the nearest option (portrait in that case).
  ''
];
    };
  };
}
