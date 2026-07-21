# nix/agentic.nix — Agentic OS module for NixOS
#
# Defines the durable data model for an autonomic agent:
#
#   hermes.facts       — Durable agent memory (git-tracked, survives rebuilds)
#   hermes.skills      — Skills as Nix modules (typed per category)
#   hermes.invariants  — Declarative health checks for the autonomic loop
#
# All three use types.lazyAttrsOf for O(1) eval at scale (N ≥ 500 entries).
# The nullOr wrapper prevents mkIf false entries from falsely returning true
# on existence checks — a documented trap of lazyAttrsOf.
#
# Usage in a flake:
#   {
#     imports = [ inputs.hermes-agent.nixosModules.agentic ];
#     hermes.facts = {
#       user.name = "Yusuf";
#       project.parkee.repos = [ "parkee-reader-pax-2" ];
#     };
#     hermes.skills.postgresql-backup = {
#       enable = true;
#       type = "tool";
#       triggers = [ "pg_dump" ];
#       action = pkgs.writeShellScript "backup" ''
#         pg_dump -Fc mydb -f "/backup/$(date +%Y%m%d).dump"
#       '';
#     };
#     hermes.invariants.postgres-is-up = {
#       enable = true;
#       check = "pg_isready -h 127.0.0.1";
#       interval = "5min";
#     };
#   }
#
{ inputs, lib, ... }:

let
  inherit (lib) types mkOption mkIf mkEnableOption;

  # ── Skill type (tool | knowledge | workflow | meta) ───────────────────
  skillTypeEnum = types.enum [ "tool" "knowledge" "workflow" "meta" ];

  # ── Shared skill submodule (used by hermes.skills.*) ──────────────────
  skillSubmodule = types.submodule {
    options = {
      enable = mkEnableOption "this skill";

      type = mkOption {
        type = skillTypeEnum;
        description = ''
          What kind of skill this is. Determines which quality checks apply:
          - tool:      has action + verify, executable
          - knowledge: has knowledge field, no action — conceptual reference
          - workflow:  has steps, describes multi-step process
          - meta:      self-validating (triage, benchmarks)
        '';
        example = "tool";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Human-readable summary of what this skill does.";
      };

      triggers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Keywords that cause the agent to recall this skill.
          Like the triggers frontmatter in Hermes markdown skills.
        '';
        example = [ "pg_dump" "postgres backup" ];
      };

      # ── Tool-type fields ──────────────────────────────────────────────
      action = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = ''
          Executable derivation that performs the action.
          Required for type = "tool".
          Example: pkgs.writeShellScript "my-action" (builtins.readFile ./scripts/my-action.sh)
        '';
      };

      verify = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Shell command that verifies success after action.
          Exit 0 = success, non-zero = failure.
          Example: "pg_isready -h 127.0.0.1"
        '';
      };

      # ── Knowledge-type fields ─────────────────────────────────────────
      knowledge = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Conceptual content for type = "knowledge" skills.
          Prose explaining the concept, with cross-references.
        '';
      };

      coherence = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Cross-references to verify this knowledge is consistent with
          other knowledge. Used by the triage benchmark for knowledge skills.
          Example: [ "cross-ref: types.lazyAttrsOf in hermes.skills option" ]
        '';
      };

      # ── Workflow-type fields ──────────────────────────────────────────
      steps = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Ordered steps for type = "workflow" skills.
          Each step is a description of what to do.
          Example: [ "Step 1: connect to postgres" "Step 2: run pg_dump" ]
        '';
      };

      # ── All types ─────────────────────────────────────────────────────
      pitfalls = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Common mistakes, edge cases, and anti-patterns.
          Used by the triage benchmark for all skill types.
        '';
        example = [
          "Rate limiting: unauthenticated queries are heavily throttled"
          "Token expiry: long-running workflows may hit token expiration"
        ];
      };

      example = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Usage example for this skill.";
      };
    };
  };

  # ── Invariant submodule (used by hermes.invariants.*) ─────────────────
  invariantSubmodule = types.submodule {
    options = {
      enable = mkEnableOption "this invariant";

      check = mkOption {
        type = types.str;
        description = ''
          Shell command that checks the invariant. Exit 0 = healthy.
          Example: "pg_isready -h 127.0.0.1"
          Example: "curl -sf http://localhost:2099/health"
          Example: "test $(df / | tail -1 | awk '{print $5}' | tr -d %) -lt 90"
        '';
      };

      interval = mkOption {
        type = types.str;
        default = "5min";
        description = ''
          How often to run the check. Systemd OnCalendar format.
          Examples: "5min", "hourly", "daily", "*:0/5"
        '';
      };

      remediate = mkOption {
        type = types.nullOr (types.either types.package types.str);
        default = null;
        description = ''
          Script or derivation to run when the invariant fails.
          If null, the agent is asked to diagnose and propose a fix.
          If set, the fix runs automatically (for low-severity invariants).
        '';
      };

      severity = mkOption {
        type = types.enum [ "low" "medium" "high" "critical" ];
        default = "medium";
        description = ''
          Severity determines the approval gate:
          - low:       auto-remediate (no human needed)
          - medium:    remediate + notify
          - high:      human approval required
          - critical:  human approval + on-call escalation
        '';
      };

      cooldown = mkOption {
        type = types.str;
        default = "1h";
        description = ''
          Min time between remediation attempts for this invariant.
          Prevents thrashing on flapping conditions.
          Format: human duration string like "30m", "2h", "1d".
        '';
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Human-readable description of what this invariant guards.";
      };
    };
  };

in {
  flake.nixosModules.agentic = { config, lib, pkgs, ... }: {

    options.hermes = {
      facts = mkOption {
        type = types.lazyAttrsOf (types.nullOr types.anything);
        default = { };
        description = ''
          Durable agent memory stored as a Nix attribute set.
          Every value can be read by the agent via nix_eval in < 5ms
          (served from pre-computed options.json, not interpreter eval).

          Use for facts that must survive nixos-rebuild switch:
          - User preferences
          - Project context
          - Historical patterns
          - Configuration decisions

          Because this uses types.lazyAttrsOf, existence checks on keys
          disabled via lib.mkIf false will return true. The nullOr wrapper
          ensures disabled keys return null instead of crashing eval.
        '';
        example = {
          user = {
            name = "Yusuf";
            prefers-cheap-models = true;
          };
          project.parkee.repos = [ "parkee-reader-pax-2" "parkee-reader-jellies" ];
          last-config-fix = "2026-07-21: increased postgres max_connections";
        };
      };

      skills = mkOption {
        type = types.lazyAttrsOf (types.nullOr skillSubmodule);
        default = { };
        description = ''
          Skills as Nix modules. Each skill has a type (tool, knowledge,
          workflow, meta) and fields appropriate to that type.

          The module system validates per-type requirements at build time:
          - tool skills require action + verify
          - knowledge skills require knowledge + coherence
          - workflow skills require steps
          - meta skills are self-validating

          The triage benchmark (hermes.skills.skill-quality-triage) evaluates
          skills against per-type criteria and scores them 0-13.
        '';
        example = {
          postgresql-backup = {
            enable = true;
            type = "tool";
            description = "Backup all PostgreSQL databases to /backup";
            triggers = [ "pg_dump" "postgres backup" ];
            action = pkgs.writeShellScript "backup-all" ''
              for db in $(sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false"); do
                pg_dump -Fc "$db" -f "/backup/$db-$(date +%Y%m%d).dump"
              done
            '';
            verify = ''
              for f in /backup/*.dump; do
                pg_restore --list "$f" > /dev/null 2>&1 || exit 1
              done
            '';
            pitfalls = [
              "Disk full: backups accumulate, set up retention via a cron job"
              "Permission: /backup must be writable by the postgres user"
            ];
          };
          lazy-evaluation = {
            enable = true;
            type = "knowledge";
            description = "How Nix lazy evaluation works";
            triggers = [ "lazy eval" "thunks" "how does nix think" ];
            knowledge = ''
              Nix only evaluates what's needed via thunks — placeholders that
              defer execution until the "moment of need." This is why NixOS
              can manage 2,700+ configuration modules without O(N) eval cost.
              The types.attrsOf type is strict in key names (O(N)), while
              types.lazyAttrsOf is lazy in both names and values (O(1)).
            '';
            coherence = [
              "cross-ref: types.lazyAttrsOf for hermes.facts option"
              "contradicts: imperative package managers have no thunks"
            ];
          };
        };
      };

      invariants = mkOption {
        type = types.lazyAttrsOf (types.nullOr invariantSubmodule);
        default = { };
        description = ''
          Declarative health checks for the autonomic loop.
          Each invariant defines:
          - check:      shell command (exit 0 = healthy)
          - interval:   how often to check
          - remediate:  optional auto-fix script
          - severity:   approval gate (low=auto, critical=human)
          - cooldown:   min gap between remediation attempts

          The autonomic loop evaluates all enabled invariants on its
          schedule, diagnoses failures, and applies or escalates fixes.
        '';
        example = {
          postgres-is-up = {
            enable = true;
            check = "pg_isready -h 127.0.0.1";
            interval = "5min";
            severity = "high";
            description = "PostgreSQL must be accepting connections";
          };
          manifest-soup-is-healthy = {
            enable = true;
            check = "curl -sf http://127.0.0.1:2099/api/v1/health";
            interval = "1min";
            severity = "critical";
            remediate = pkgs.writeShellScript "restart-manifest" ''
              systemctl restart manifest-soup.service
            '';
            cooldown = "5min";
            description = "Manifest Soup API must respond to health checks";
          };
          disk-space = {
            enable = true;
            check = "test $(df / | tail -1 | awk '{print $5}' | tr -d %) -lt 90";
            interval = "10min";
            severity = "medium";
            description = "Root disk usage must stay below 90%";
          };
        };
      };
    };

    # ── Config assertions ───────────────────────────────────────────────
    config = {
      # At build time, validate that every enabled skill has its
      # type-required fields filled. This is the Nix equivalent of
      # the skill-triage quality gate.
      assertions =
        let
          validateSkill = name: skill: [
            {
              assertion = skill.type != "tool" || skill.action != null;
              message = ''
                hermes.skills.${name} has type "tool" but no action defined.
                Tool skills must have an action derivation.
              '';
            }
            {
              assertion = skill.type != "knowledge" || skill.knowledge != null;
              message = ''
                hermes.skills.${name} has type "knowledge" but no knowledge field.
                Knowledge skills must have conceptual content.
              '';
            }
            {
              assertion = skill.type != "workflow" || skill.steps != [ ];
              message = ''
                hermes.skills.${name} has type "workflow" but no steps.
                Workflow skills must define ordered steps.
              '';
            }
          ];
        in
        lib.flatten (
          lib.mapAttrsToList (name: skill:
            if skill.enable then validateSkill name skill else [ ]
          ) config.hermes.skills
        );

      # ── Systemd timers for enabled invariants ──────────────────────────
      # Generates systemd timers that run the check scripts at the declared
      # interval. These are the "sensors" in the MAPE-K loop.
      systemd.timers = lib.mapAttrs' (name: inv:
        lib.nameValuePair "hermes-invariant-${name}" {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = inv.interval;
            Persistent = true;
          };
        }
      ) (lib.filterAttrs (n: v: v.enable) config.hermes.invariants);

      # The matching services — each runs the check script and logs the result.
      systemd.services = lib.mapAttrs' (name: inv:
        lib.nameValuePair "hermes-invariant-${name}" {
          serviceConfig = {
            Type = "oneshot";
            User = "hermes";
            ExecStart = pkgs.writeShellScript "check-${name}" ''
              set -e
              RESULT=$(${inv.check} 2>&1) || true
              EXIT_CODE=$?
              if [ $EXIT_CODE -eq 0 ]; then
                echo "INVARIANT_OK ${name}"
              else
                echo "INVARIANT_FAIL ${name}: $RESULT"
                # Non-zero exit propagates for monitoring
                exit $EXIT_CODE
              fi
            '';
          };
        }
      ) (lib.filterAttrs (n: v: v.enable) config.hermes.invariants);
    };
  };
}
