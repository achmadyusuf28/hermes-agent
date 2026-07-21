# parkee-deployment-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: parkee-deployment-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.parkee-deployment-workflow;
in
{
  options.hermes.skills.parkee-deployment-workflow = {
    enable = mkEnableOption "Creating and modifying Ansible playbooks in the parkee-deployment project — inventory conventions, location data from gsheets.csv, playbook patterns (server vs client targets), vars, and deployment pipeline.";
  };

  config = mkIf cfg.enable {
    hermes.skills.parkee-deployment-workflow = {
      enable = true;
  description = "Creating and modifying Ansible playbooks in the parkee-deployment project — inventory conventions, location data from gsheets.csv, playbook patterns (server vs client targets), vars, and deployment pipeline.";
  triggers = [
  "parkee deployment"
  "parkee ansible"
  "create playbook"
  "parkee-deployment"
  "location code"
  "gsheets.csv"
  "ansible playbook"
  "deploy to location"
  "parkee inventory"
  "merge csv"
  "merge_csv"
  "gather data"
  "general error"
  "pax15"
  "pax-logger"
  "daily cron"
  "log pipeline"
  "pay321"
  "multi location"
  "parallel ansible"
];
  type = "workflow";
  steps = [
  ''
    **Find the template** — use an existing playbook as starting point (same target type: server or client)
  ''
  ''
    **Read the example** closely — understand the host pattern, vars files, and task structure
  ''
  ''
    **Determine location scope** — if for specific locations, get location codes from gsheets.csv
  ''
  ''
    **Define what data to gather** — shell commands that run on remote machines
  ''
  ''
    **Plan output** — debug: msg, or save results via copy/fetch module
  ''
  "Read the current file completely"
  "Follow the existing task structure pattern"
  "Don't change the host pattern unless explicitly asked"
  "Use `patch` tool for targeted edits"
  ''
    **Identify target** -- which hosts (client PCs vs server) based on the data source (log files, DB, config files)
  ''
  ''
    **Write the playbook** -- shell command that extracts data, formats CSV, pulls files back to controller via `fetch`
  ''
  ''
    **Run the playbook** -- against single or multiple locations using the host-pattern conventions
  ''
  ''
    **Verify collection** -- check `reports/<subfolder>/` for the expected number of CSV files
  ''
  ''
    **Run the merge script** -- combines all CSVs with gate names, generates insights
  ''
  ''
    **Diagnose from insights** -- top offenders, zero-data gates, peak hours, significant drops -- identify next action
  ''
];
  pitfalls = [
  ''
    **Inventory is 19K+ lines** — don't `read_file` the whole thing at once; search or grep specific sections
  ''
  ''
    **gsheets.csv is 7K+ lines** — read with offset/limit or use terminal+grep for targeted queries
  ''
  ''
    **Playbooks use Bahasa Indonesia task names** — keep the naming convention when adding new tasks
  ''
  ''
    **`vars.yml` includes vault references** — passwords are in vault.yml, not plaintext in playbooks
  ''
  ''
    **NixOS paths** — on the controller machine, paths like `/run/current-system/sw/bin/` apply for sudo etc.
  ''
  ''
    **`/home/soup` is 0700 by default** — if a file at `/home/soup/...` is reported missing, the parent directory may not be traversable. Fix with `chmod +x /home/soup`, or copy/move the file to a shared location like `/mnt/data/`.
  ''
  ''
    **PAX model identifiers in issue titles** — "PAX15" refers to the PAX IM15 terminal, NOT a location code in gsheets.csv.
  ''
  ''
    **Permission mismatches on the controller** — the ansible repo may be owned by `soup:users`. Writing via `write_file` or `patch` may fail. Use `sudo tee` or `sudo python3` for scripts that write CSV output.
  ''
  ''
    **Merge script re-ingestion** — when running the merge script, exclude the output CSV from the input glob to avoid double-counting. Check for `if f != '<output>.csv'` in the glob filter.
  ''
  ''
    **CSV cell values may have leading/trailing whitespace** — gsheets.csv columns are space-padded by default (e.g. ` 074 ` instead of `074`). Always strip or use `-F','` awk patterns.
  ''
  ''
    **XLSX formula pitfall — VLOOKUP breaks COUNTIFS** — In Location Summary and Gates Summary, column A MUST hold the raw location code (hardcoded string), NOT a VLOOKUP formula. If column A resolves to a location name (e.g. "Optik Melawai Salemba"), COUNTIFS against Raw Events column A (which has raw codes) returns 0. Always: Col A = raw code, Col B = VLOOKUP for display name.
  ''
];
    };
  };
}
