# workspace-profiles.nix — Auto-converted from Hermes skill
# Category: hermes
# Original: workspace-profiles

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.workspace-profiles;
in
{
  options.hermes.skills.workspace-profiles = {
    enable = mkEnableOption "Extensible context profile system for Hermes Agent — auto-detect running services, read project frontmatter, inject infrastructure guidance into the stable prompt tier, and pre-load workspace skills.";
  };

  config = mkIf cfg.enable {
    hermes.skills.workspace-profiles = {
      enable = true;
  description = "Extensible context profile system for Hermes Agent — auto-detect running services, read project frontmatter, inject infrastructure guidance into the stable prompt tier, and pre-load workspace skills.";
  triggers = [
  "workspace profile"
  "context profile"
  "infrastructure detection"
  "auto skills"
  "service probe"
  "service discovery"
  "project frontmatter"
  ".hermes.md profile"
  "hermes.auto_skills"
  "workspace_system_blocks"
  "workspace_auto_skills"
  "parse_project_frontmatter"
  "register_profile"
  "infrastructure profile"
  "iii dashboard detection"
];
  type = "workflow";
  steps = [
  ''
    **Frontmatter-declared profile** (`.hermes.md` → `AGENTS.md` → `CLAUDE.md` `hermes.profile` key) — explicit wins over automatic
  ''
  ''
    **Probe-based detection** — checks registered ServiceProbes (port scans) and FileProbes (file existence) in order
  ''
  "Falls back to `general` — no infra blocks injected"
  ''
    **Infrastructure guidance** — "The following services have been detected:" with probe results
  ''
  "**Workspace snapshot** — git branch, root, dirty state"
];
  pitfalls = [
  ''
    **Profile detection order matters** — profiles are checked in registration order. The first probe match wins. If two profiles probe for the same service, the earlier-registered one takes priority.
  ''
  ''
    **Service probes use 500ms TCP timeout** — if a service is present but the port check times out (slow service, firewall), the probe reports "not detected." This is a false negative, not a service issue.
  ''
  ''
    **Frontmatter-declared profile overrides auto-detection** — if `.hermes.md` has `hermes.profile: infrastructure`, auto-detection is completely bypassed. Explicit wins even if probes mismatch.
  ''
  ''
    **`auto_skills` from frontmatter takes priority over profile defaults** — if both frontmatter and profile define auto_skills, the frontmatter list is used as-is (not merged). List both frontmatter and profile skills if you need both.
  ''
  ''
    **FileProbe walks to git root** — it resolves the project root via git, which requires the directory to be inside a git repo. Non-git directories won't match.
  ''
  ''
    **Profile system requires a code patch to `prompt_builder.py`** — the `workspace_system_blocks()` call must be wired into `build_system_prompt_parts()` in `system_prompt.py`. Without this patch, profile detection doesn't run.
  ''
  ''
    **No side effects from probes** — probes are read-only by design. If you need to mutate state based on detection (e.g., auto-start a service), that's a separate concern.
  ''
];
    };
  };
}
