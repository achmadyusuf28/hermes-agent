# notion.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: notion

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.notion;
in
{
  options.hermes.skills.notion = {
    enable = mkEnableOption "Notion API + ntn CLI: pages, databases, markdown, Workers.";
  };

  config = mkIf cfg.enable {
    hermes.skills.notion = {
      enable = true;
  description = "Notion API + ntn CLI: pages, databases, markdown, Workers.";
  type = "workflow";
  steps = [
  "Create an integration at https://notion.so/my-integrations"
  "Copy the API key (starts with `ntn_` or `secret_`)"
  "Store in `${HERMES_HOME:-~/.hermes}/.env`:"
  ''
    **Share target pages/databases with the integration** in Notion: page menu `...` → `Connect to` → your integration name. Without this, the API returns 404 for that page even though it exists.
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
