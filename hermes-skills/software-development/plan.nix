# plan.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: plan

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.plan;
in
{
  options.hermes.skills.plan = {
    enable = mkEnableOption "Plan mode: write an actionable markdown plan to .hermes/plans/, no execution. Bite-sized tasks, exact paths, complete code.";
  };

  config = mkIf cfg.enable {
    hermes.skills.plan = {
      enable = true;
  description = "Plan mode: write an actionable markdown plan to .hermes/plans/, no execution. Bite-sized tasks, exact paths, complete code.";
  type = "workflow";
  steps = [
  "Setup/infrastructure"
  "Core functionality (TDD for each)"
  "Edge cases"
  "Integration"
  "Cleanup/documentation"
  "Write failing test"
  "Run to verify failure"
  "Write minimal code"
  "Run to verify pass"
  ''
    **Well-defined, single-responsibility scope** — one clear thing, not a bundle
  ''
  ''
    **Verifiable outcome** — you can check success with grep/compile/test
  ''
  ''
    **Survives being done once** — the agent doesn't need mid-course clarification
  ''
];
  pitfalls = [
  ''
    **HuggingFace rate limits** — unauthenticated downloads are rate-limited. Log in via `huggingface-cli login`- **CUDA/GPU availability** — verify `nvidia-smi` or `ollama list` shows expected hardware before running inference- **Disk space** — model weights can be 10-100+ GB. Check available space before downloading- **Template mismatches** — different model architectures use different chat templates. Verify the template matches
  ''
];
    };
  };
}
