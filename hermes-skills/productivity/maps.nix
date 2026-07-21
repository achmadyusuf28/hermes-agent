# maps.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: maps

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.maps;
in
{
  options.hermes.skills.maps = {
    enable = mkEnableOption "Geocode, POIs, routes, timezones via OpenStreetMap/OSRM.";
  };

  config = mkIf cfg.enable {
    hermes.skills.maps = {
      enable = true;
  description = "Geocode, POIs, routes, timezones via OpenStreetMap/OSRM.";
  type = "workflow";
  steps = [
  ''
    `nearby --near "Colosseum Rome" --category restaurant --radius 500`
  ''
  "Extract lat/lon from the Telegram message"
  "`nearby LAT LON cafe --radius 1500`"
  ''
    `directions "Hotel Name" --to "Conference Center" --mode walking`
  ''
  "`area \"Downtown Seattle\"` → get bounding box"
  "`bbox S W N E restaurant --limit 30`"
];
  pitfalls = [
  ''
    Nominatim ToS: max 1 req/s (handled automatically by the script)
  ''
  ''
    `nearby` requires lat/lon OR `--near "<address>"` — one of the two is needed
  ''
  "OSRM routing coverage is best for Europe and North America"
  ''
    Overpass API can be slow during peak hours; the script automatically
  ''
  ''
    `distance` and `directions` use `--to` flag for the destination (not positional)
  ''
  ''
    If a zip code alone gives ambiguous results globally, include country/state
  ''
];
    };
  };
}
