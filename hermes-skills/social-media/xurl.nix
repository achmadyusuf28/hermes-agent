# xurl.nix — Auto-converted from Hermes skill
# Category: social-media
# Original: xurl

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.xurl;
in
{
  options.hermes.skills.xurl = {
    enable = mkEnableOption "X/Twitter via xurl CLI: post, search, DM, media, v2 API.";
  };

  config = mkIf cfg.enable {
    hermes.skills.xurl = {
      enable = true;
  description = "X/Twitter via xurl CLI: post, search, DM, media, v2 API.";
  triggers = [
  "xurl"
];
  type = "workflow";
  steps = [
  ''
    Create or open an app at https://developer.x.com/en/portal/dashboard
  ''
  "Set the redirect URI to `http://localhost:8080/callback`"
  "Copy the app's Client ID and Client Secret"
  "Register the app locally (user runs this):"
  ''
    Authenticate (specify `--app` to bind the token to your app):
  ''
  "Set the app as default so all commands use it:"
  "Verify:"
  "Verify prerequisites: `xurl --help` and `xurl auth status`."
  ''
    **Check default app has credentials.** Parse the `auth status` output. The default app is marked with `▸`. If the default app shows `oauth2: (none)` but another app has a valid oauth2 user, tell the user to run `xurl auth default <that-app>` to fix it. This is the most common setup mistake — the user added an app with a custom name but never set it as default, so xurl keeps trying the empty `default` profile.
  ''
  ''
    If auth is missing entirely, stop and direct the user to the "One-Time User Setup" section — do NOT attempt to register apps or pass secrets yourself.
  ''
  ''
    Start with a cheap read (`xurl whoami`, `xurl user @handle`, `xurl search ... -n 3`) to confirm reachability.
  ''
  ''
    Confirm the target post/user and the user's intent before any write action (post, reply, like, repost, DM, follow, block, delete).
  ''
  ''
    Use JSON output directly — every response is already structured.
  ''
  "Never paste `~/.xurl` contents back into the conversation."
];
  pitfalls = [
  ''
    **Rate limiting** — write operations are aggressively rate-limited. Space out posts- **Credential scope** — ensure the API token has the necessary permissions for the operation
  ''
  ''
    **Content formatting** — platform-specific markdown/formatting may differ from standard markdown
  ''
];
    };
  };
}
