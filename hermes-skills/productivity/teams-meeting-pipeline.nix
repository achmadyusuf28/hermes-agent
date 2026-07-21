# teams-meeting-pipeline.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: teams-meeting-pipeline

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.teams-meeting-pipeline;
in
{
  options.hermes.skills.teams-meeting-pipeline = {
    enable = mkEnableOption "Operate the Teams meeting summary pipeline via Hermes CLI — summarize meetings, inspect pipeline status, replay jobs, manage Microsoft Graph subscriptions.";
  };

  config = mkIf cfg.enable {
    hermes.skills.teams-meeting-pipeline = {
      enable = true;
  description = "Operate the Teams meeting summary pipeline via Hermes CLI — summarize meetings, inspect pipeline status, replay jobs, manage Microsoft Graph subscriptions.";
  triggers = [
  "Operate the Teams meeting summary pipeline via Hermes CLI"
  "teams meeting pipeline"
];
  type = "workflow";
  steps = [
  ''
    Run `hermes teams-pipeline subscriptions` — if it's empty or all entries show `expirationDateTime` in the past, that's the cause.
  ''
  "Recreate with `subscribe` as shown above."
  ''
    **Set up automated renewal immediately** via `hermes cron add`, a systemd timer, or plain crontab. The operator runbook at `/docs/guides/operate-teams-meeting-pipeline#automating-subscription-renewal-required-for-production` has all three options. 12-hour interval is safe (6x headroom against the 72h limit).
  ''
];
  pitfalls = [
  ''
    **Auth token freshness** — OAuth tokens expire. Re-authenticate before long sessions- **Schema drift** — external API schemas change. Verify the tool's expected format matches current reality
  ''
  ''
    **Rate limiting** — batch operations may hit API rate limits. Add delays between requests
  ''
];
    };
  };
}
