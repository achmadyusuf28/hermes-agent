# apple-reminders.nix — Auto-converted from Hermes skill
# Category: apple
# Original: apple-reminders

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.apple-reminders;
in
{
  options.hermes.skills.apple-reminders = {
    enable = mkEnableOption "Apple Reminders via remindctl: add, list, complete.";
  };

  config = mkIf cfg.enable {
    hermes.skills.apple-reminders = {
      enable = true;
  description = "Apple Reminders via remindctl: add, list, complete.";
  type = "workflow";
  steps = [
  ''
    When user says "remind me", clarify: Apple Reminders (syncs to phone) vs agent cronjob alert
  ''
  ''
    Always confirm reminder content and due date before creating
  ''
  "Use `--json` for programmatic parsing"
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
