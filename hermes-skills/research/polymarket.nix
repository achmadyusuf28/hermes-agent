# polymarket.nix — Auto-converted from Hermes skill
# Category: research
# Original: polymarket

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.polymarket;
in
{
  options.hermes.skills.polymarket = {
    enable = mkEnableOption "Query Polymarket: markets, prices, orderbooks, history.";
  };

  config = mkIf cfg.enable {
    hermes.skills.polymarket = {
      enable = true;
  description = "Query Polymarket: markets, prices, orderbooks, history.";
  type = "workflow";
  steps = [
  ''
    **Gamma API** at `gamma-api.polymarket.com` — Discovery, search, browsing
  ''
  ''
    **CLOB API** at `clob.polymarket.com` — Real-time prices, orderbooks, history
  ''
  ''
    **Data API** at `data-api.polymarket.com` — Trades, open interest
  ''
  ''
    **Search** using the Gamma API public-search endpoint with their query
  ''
  ''
    **Parse** the response — extract events and their nested markets
  ''
  ''
    **Present** market question, current prices as percentages, and volume
  ''
  ''
    **Deep dive** if asked — use clobTokenIds for orderbook, conditionId for history
  ''
];
  pitfalls = [
  ''
    **Authentication state** — session cookies and API tokens expire. Verify auth before each session
  ''
  ''
    **Endpoint reachability** — check that the target service is running (`curl http://127.0.0.1:PORT/health`)- **Version mismatch** — API versions may differ between the tool's expectations and the running service
  ''
];
    };
  };
}
