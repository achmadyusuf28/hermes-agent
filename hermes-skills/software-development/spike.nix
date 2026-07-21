# spike.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: spike

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.spike;
in
{
  options.hermes.skills.spike = {
    enable = mkEnableOption "Throwaway experiments to validate an idea before build.";
  };

  config = mkIf cfg.enable {
    hermes.skills.spike = {
      enable = true;
  description = "Throwaway experiments to validate an idea before build.";
  triggers = [
  "spike"
];
  type = "workflow";
  steps = [
  ''
    **Brief it.** 2-3 sentences: what this spike is, why it matters, key risk.
  ''
  "**Surface competing approaches** if there's real choice:"
  ''
    **Pick one.** State why. If 2+ are credible, build quick variants within the spike.
  ''
  ''
    **Skip research** for pure logic with no external dependencies.
  ''
  ''
    A runnable CLI that takes input and prints observable output
  ''
  "A minimal HTML page that demonstrates the behavior"
  "A small web server with one endpoint"
  ''
    A unit test that exercises the question with recognizable assertions
  ''
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
