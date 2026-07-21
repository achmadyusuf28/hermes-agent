# himalaya.nix — Auto-converted from Hermes skill
# Category: email
# Original: himalaya

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.himalaya;
in
{
  options.hermes.skills.himalaya = {
    enable = mkEnableOption "Himalaya CLI: IMAP/SMTP email from terminal.";
  };

  config = mkIf cfg.enable {
    hermes.skills.himalaya = {
      enable = true;
  description = "Himalaya CLI: IMAP/SMTP email from terminal.";
  triggers = [
  "himalaya"
];
  type = "workflow";
  steps = [
  "Himalaya CLI installed (`himalaya --version` to verify)"
  "A configuration file at `~/.config/himalaya/config.toml`"
  "IMAP/SMTP credentials configured (password stored securely)"
];
  pitfalls = [
  ''
    **Credentials exposed** — never hardcode SMTP passwords or IMAP tokens in scripts or config
  ''
  ''
    **IMAP IDLE timeout** — long-running connections may be dropped by the server. Reconnect gracefully- **Rate limiting** — sending too many messages quickly may trigger spam filters or connection limits
  ''
];
    };
  };
}
