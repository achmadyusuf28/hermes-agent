# hf-ollama.nix — Auto-converted from Hermes skill
# Category: mlops
# Original: hf-ollama

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.hf-ollama;
in
{
  options.hermes.skills.hf-ollama = {
    enable = mkEnableOption "Download a GGUF or safetensors model from HuggingFace and import it into Ollama with auto-detected chat templates";
  };

  config = mkIf cfg.enable {
    hermes.skills.hf-ollama = {
      enable = true;
  description = "Download a GGUF or safetensors model from HuggingFace and import it into Ollama with auto-detected chat templates";
  triggers = [
  "download model"
  "ollama model"
  "hf model"
  "huggingface import"
  "gguf download"
];
  type = "workflow";
  steps = [
  ''
    **Download** — `hf download <repo> --local-dir ~/ollama-models/<name>/`
  ''
  ''
    **Convert** (if `--convert`) — Clone llama.cpp → run `convert_hf_to_gguf.py` via nix-shell → output GGUF
  ''
  ''
    **Detect** — Infer model family from repo/name (gemma/llama/qwen/mistral/etc.)
  ''
  ''
    **Generate Modelfile** — Auto-picks chat template + stop tokens + sensible defaults
  ''
  "**Import** — `ollama create <name> -f Modelfile`"
  "**Verify** — `ollama list` + quick inference smoke test"
  "**Cleanup** — Delete raw files (unless `--keep-gguf`)"
  ''
    llama.cpp is cloned to `~/.hermes/cache/llama.cpp/` (first time only)
  ''
  ''
    Conversion runs via `nix-shell` with `python3Packages.{torch,transformers,sentencepiece,protobuf,numpy}`
  ''
  "The GGUF lands in `~/ollama-models/<name>/<name>.gguf`"
  ''
    Default quantization is **Q4_K_M** (good quality/size balance)
  ''
];
  pitfalls = [
  ''
    **llama.cpp first-time clone is slow** — `--convert` clones llama.cpp to `~/.hermes/cache/llama.cpp/` on first use (~1.3GB). Subsequent runs are fast. If the clone fails, check network connectivity or manually clone to that path.
  ''
  ''
    **NixOS `libstdc++.so.6` errors with torch/transformers** — when running the conversion via nix-shell, numpy/torch may fail with `libstdc++.so.6 not found`. This is handled by the script's `LD_PRELOAD` logic, but if it fails, check `find /nix -name "libstdc++.so.6"` and set `LD_PRELOAD` manually.
  ''
  ''
    **`huggingface-hub` Python package required** — the script imports from the `huggingface-hub` library. On NixOS, this is in `modules/shell/shell.nix` under `python3Packages.huggingface-hub`. If the script fails with `ModuleNotFoundError`, check that the package is installed in the environment.
  ''
  ''
    **Ollama must be running** — `ollama create` and `ollama list` require the Ollama service to be active. Check with `systemctl status ollama-cuda` (or `ollama serve`).
  ''
  ''
    **Disk space for safetensors conversion** — a 7B model in safetensors is ~14GB. The conversion step creates an intermediate GGUF in `~/ollama-models/` which adds another ~14GB. Ensure enough free disk space.
  ''
  ''
    **`--include` glob is case-sensitive** — HF repo filenames vary. `*Q4_K_M*` won't match `*q4_k_m*`. Check the repo listing first: `huggingface-cli repo-files <repo>`.
  ''
  ''
    **Bind address for container access** — when containers on the same host need to reach Ollama via `localhost`, Ollama must listen on `0.0.0.0` not a specific IP (like a ZeroTier IP). Binding to a specific IP only accepts connections from that IP, not from loopback. On NixOS, set `services.ollama.host = \"0.0.0.0\"` for server-role nodes. The firewall still restricts external access — this only affects local container→Ollama communication.
  ''
  ''
    **Copying models between nodes is faster than re-downloading** — in multi-node setups running the same Ollama version, copy the model store directly over SSH instead of running `ollama pull` on each node. Ollama models are portable between same-version installations. The store is at `$OLLAMA_MODELS` (default `/var/lib/ollama/models` on NixOS, `~/.ollama/models/` on standalone). To copy specific models:
  ''
  ''
    **Bind address for container access** — when containers on the same host need to reach Ollama via `localhost`, Ollama must listen on `0.0.0.0` not a specific IP (like a ZeroTier IP). Binding to a specific IP only accepts connections from that IP, not from loopback. On NixOS, set `services.ollama.host = "0.0.0.0"` for server-role nodes. The firewall still restricts external access — this only affects local container->Ollama communication.
  ''
  ''
    **Copying models between nodes is faster than re-downloading** — in multi-node setups running the same Ollama version, copy the model store directly over SSH instead of running `ollama pull` on each node. Ollama models are portable between same-version installations. The store is at `$OLLAMA_MODELS` (default `/var/lib/ollama/models` on NixOS, `~/.ollama/models/` on standalone). To copy specific models:
  ''
];
  example = ''
  hf-ollama <name> <hf-repo> [options]
  '';
    };
  };
}
