# google-workspace.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: google-workspace

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.google-workspace;
in
{
  options.hermes.skills.google-workspace = {
    enable = mkEnableOption "Google OAuth2 client credentials (downloaded from Google Cloud Console)";
  };

  config = mkIf cfg.enable {
    hermes.skills.google-workspace = {
      enable = true;
  description = "Google OAuth2 client credentials (downloaded from Google Cloud Console)";
  triggers = [
  "google-workspace"
  "google workspace"
];
  type = "workflow";
  steps = [
  ''
    **Never send email, create/delete calendar events, delete Drive files, share files, or modify Docs/Sheets without confirming with the user first.** Show what will be done (recipients, file IDs, content, share role) and ask for approval. For `drive delete`, prefer the default trash (reversible) over `--permanent`.
  ''
  ''
    **Check auth before first use** — run `setup.py --check`. If it fails, guide the user through setup.
  ''
  ''
    **Use the Gmail search syntax reference** for complex queries — load it with `skill_view("google-workspace", file_path="references/gmail-search-syntax.md")`.
  ''
  ''
    **Calendar times must include timezone** — always use ISO 8601 with offset (e.g., `2026-03-01T10:00:00-06:00`) or UTC (`Z`).
  ''
  ''
    **Respect rate limits** — avoid rapid-fire sequential API calls. Batch reads when possible.
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
  example = ''
  GAPI="python ''${HERMES_HOME:-$HOME/.hermes}/skills/productivity/google-workspace/scripts/google_api.py"
  '';
    };
  };
}
