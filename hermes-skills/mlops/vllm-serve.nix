# vllm-serve.nix — Auto-converted from Hermes skill
# Category: mlops
# Original: vllm-serve

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.vllm-serve;
in
{
  options.hermes.skills.vllm-serve = {
    enable = mkEnableOption "Download and serve safetensors models via vLLM with an OpenAI-compatible API endpoint";
  };

  config = mkIf cfg.enable {
    hermes.skills.vllm-serve = {
      enable = true;
  description = "Download and serve safetensors models via vLLM with an OpenAI-compatible API endpoint";
  triggers = [
  "vllm serve"
  "serve model"
  "vllm model"
  "openai compatible endpoint"
  "LLM server"
];
  type = "tool";
  verify = ''
  # 1. [ ] `vllm-serve <hf-repo>` starts without errors and shows the server listening on the configured port
# 2. `vllm-serve <hf-repo>` starts without errors and shows the server listening on the configured port
# 3. [ ] `curl http://localhost:<port>/v1/models` returns the model list
# 4. `curl http://localhost:<port>/v1/models` returns the model list
# 5. [ ] `curl -X POST http://localhost:<port>/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"<model>","messages":[{"role":"user","content":"hello"}]}'` returns a response
# 6. `curl -X POST http://localhost:<port>/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"<model>","messages":[{"role":"user","content":"hello"}]}'` returns a response
# 7. [ ] `vllm-serve --list` shows the running server
# 8. `vllm-serve --list` shows the running server
# 9. [ ] No CUDA OOM errors in the logs (check with free GPU memory)
# 10. No CUDA OOM errors in the logs (check with free GPU memory)
# 11. [ ] If running alongside Ollama: both services respond without errors
# 12. If running alongside Ollama: both services respond without errors
# 13. [ ] Honcho integration: `curl http://localhost:8001/v1/chat/completions` (or custom port) works from Honcho's configured base URL
# 14. Honcho integration: `curl http://localhost:8001/v1/chat/completions` (or custom port) works from Honcho's configured base URL
  '';
  pitfalls = [
  ''
    **vLLM needs a compatible GPU** — RTX 3070 Ti (8GB) can handle up to ~7B models with `--dtype half --gpu-memory-utilization 0.6`. Larger models will OOM.
  ''
  ''
    **Ollama conflicts** — vLLM and Ollama share the same GPU. Unload Ollama models (`ollama stop <model>`) before starting vLLM, or use `--gpu-memory-utilization 0.5` to reserve memory.
  ''
  ''
    **First download is slow** — vLLM downloads the model from HuggingFace on first use. Ensure stable internet and enough disk space (7B model = ~14GB).
  ''
  ''
    **`--enforce-eager` disables CUDA graphs** — this frees ~1-2GB GPU memory but reduces throughput by ~30%. Use only when memory-constrained.
  ''
  ''
    **vLLM service not auto-started** — `vllm-serve` runs in the foreground. For persistent serving, wrap it as a systemd service or use a terminal `background=true` session.
  ''
  ''
    **Port conflicts** — default port 8001. If already in use, use `--port 8002` or check `vllm-serve --list`.
  ''
  ''
    **NixOS `LD_LIBRARY_PATH`** — vLLM's CUDA dependencies need the Nix-provided library paths. The wrapper script handles this, but if vLLM fails to import torch, check that the venv was created correctly.
  ''
  ''
    **`--list` only shows vLLM processes started with the CLI** — manually started vLLM servers or systemd-managed ones won't appear. Use `ps aux | grep vllm` instead.
  ''
];
  example = ''
  vllm-serve <hf-repo> [options]
  '';
    };
  };
}
