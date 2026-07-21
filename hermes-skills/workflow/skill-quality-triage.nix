# skill-quality-triage.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: skill-quality-triage

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.skill-quality-triage;
in
{
  options.hermes.skills.skill-quality-triage = {
    enable = mkEnableOption "Periodic quality scanning and triage of the Hermes skills library — 6-point quality gate, automated scoring, structured report, cron-ready.";
  };

  config = mkIf cfg.enable {
    hermes.skills.skill-quality-triage = {
      enable = true;
  description = "Periodic quality scanning and triage of the Hermes skills library — 6-point quality gate, automated scoring, structured report, cron-ready.";
  triggers = [
  "run skill triage"
  "tool radar"
  "quality scan skills"
  "audit skills"
  "check skill health"
  "which skills need work"
  "update my skills library"
  "REWRITE skills"
  "skill maintenance"
  "score my skills"
];
  type = "meta";
  pitfalls = [
  ''
    **Script not on PATH** — The script lives under the skill directory, not `~/.hermes/scripts/`. When referencing from cron, use `scripts/<category>/<name>/scripts/skill-triage.py` or the absolute path.
  ''
  ''
    **Python not on PATH on NixOS** — Must use `nix-shell -p python3 --run "..."` from the terminal. The `execute_code` tool bypasses this (its own interpreter).
  ''
  ''
    **sync-conflict files skew freshness scores** — These are garbage files from syncthing/rclone. Run `scripts/cleanup-sync-conflicts.sh --force` before the scan, or use the combined cron one-liner in the Pre-flight section above.
  ''
  ''
    **Tier thresholds are heuristics** — A 9/13 skill might be perfectly adequate for its niche. The score guides priority, not replacement decisions.
  ''
  ''
    **Description check is rough** — 200-char threshold catches genuinely over-long descriptions but also flags long compound descriptions that may be fine. Read the actual description before trimming.
  ''
];
    };
  };
}
