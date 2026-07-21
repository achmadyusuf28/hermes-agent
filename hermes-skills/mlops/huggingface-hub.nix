# huggingface-hub.nix — Auto-converted from Hermes skill
# Category: mlops
# Original: huggingface-hub

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.huggingface-hub;
in
{
  options.hermes.skills.huggingface-hub = {
    enable = mkEnableOption "HuggingFace hf CLI: search/download/upload models, datasets.";
  };

  config = mkIf cfg.enable {
    hermes.skills.huggingface-hub = {
      enable = true;
  description = "HuggingFace hf CLI: search/download/upload models, datasets.";
  triggers = [
  "huggingface-hub"
  "huggingface hub"
];
  type = "tool";
  verify = ''
  # 1. [ ] Run a quick test with a minimal model or dataset- [ ] Verify the expected output format (JSON, file, API response)- [ ] Confirm resource usage stays within expected bounds
# 2. Run a quick test with a minimal model or dataset- [ ] Verify the expected output format (JSON, file, API response)- [ ] Confirm resource usage stays within expected bounds
  '';
  pitfalls = [
  ''
    **HuggingFace rate limits** — unauthenticated downloads are rate-limited. Log in via `huggingface-cli login`- **CUDA/GPU availability** — verify `nvidia-smi` or `ollama list` shows expected hardware before running inference- **Disk space** — model weights can be 10-100+ GB. Check available space before downloading- **Template mismatches** — different model architectures use different chat templates. Verify the template matches
  ''
];
  example = ''
  *   **Installation:** `curl -LsSf https://hf.co/cli/install.sh | bash -s`
*   **Help:** Use `hf --help` to view all available functions and real-world examples.
*   **Authentication:** Recommended via `HF_TOKEN` environment variable or the `--token` flag.

---
  '';
    };
  };
}
