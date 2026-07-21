# nixos-gpu-services.nix — Auto-converted from Hermes skill
# Category: nixos
# Original: nixos-gpu-services

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.nixos-gpu-services;
in
{
  options.hermes.skills.nixos-gpu-services = {
    enable = mkEnableOption "Configure GPU-accelerated services on NixOS — detect NVIDIA hardware, select CUDA package variants, troubleshoot GPU inference (Ollama, vLLM), and avoid the role-vs-hardware conflation pitfall.";
  };

  config = mkIf cfg.enable {
    hermes.skills.nixos-gpu-services = {
      enable = true;
  description = "Configure GPU-accelerated services on NixOS — detect NVIDIA hardware, select CUDA package variants, troubleshoot GPU inference (Ollama, vLLM), and avoid the role-vs-hardware conflation pitfall.";
  triggers = [
  "Ollama running on CPU despite NVIDIA GPU"
  "CUDA package not being selected on NixOS"
  "Role-based package selection ignoring GPU presence"
  "Configuring ML inference services on NixOS"
  "GPU not used for inference despite working NVIDIA setup"
];
  type = "workflow";
  steps = [
  ''
    **`ollama ps` / service status** — check the PROCESSOR column (100% CPU = no GPU)
  ''
  ''
    **`nvidia-smi`** — verify GPU is present, not memory-full, and the process isn't listed
  ''
  ''
    **`cat /etc/systemd/system/<service>.service | grep ExecStart`** — check which store path the service unit points to
  ''
  ''
    **`nix-store -q --references <store-path>`** — look for `cuda_cudart`, `libcublas` in the references to confirm it's a CUDA build
  ''
  ''
    **Find the Nix module** — check the package selection logic. Look for `if role == "server"` or similar role-based gating
  ''
  ''
    **Check `nix-store -q --references` on both** — compare the CUDA vs non-CUDA store paths for the same package version
  ''
];
  pitfalls = [
  ''
    **DynamicUser + systemd**: Ollama's systemd unit uses `DynamicUser=true` — this restricts device access. Verify `DeviceAllow` directives include NVIDIA devices (`char-nvidia-*`, `char-nvidia-uvm`). The service also needs `SupplementaryGroups=render` for GPU access.
  ''
  ''
    **Stale store paths in systemd units**: After a rebuild, if the flake input or module didn't change, the service unit may still reference the old (non-CUDA) store path. Always verify `ExecStart` after a rebuild.
  ''
  ''
    **Conflating role with hardware**: A "laptop" with an NVIDIA GPU should get CUDA packages. A "server" without one shouldn't. Role and hardware capability are orthogonal axes.
  ''
  ''
    **Multiple Ollama binaries**: `which ollama` may resolve to a different store path than the one the systemd service uses. Always check the service unit directly.
  ''
  ''
    **Bind address blocks container access**: When Docker containers on the same host (Honcho, Manifest) need to reach Ollama via `localhost:11434`, Ollama must listen on `0.0.0.0` not a specific interface IP. Binding to a ZeroTier or LAN IP accepts connections from that IP only — loopback (`127.0.0.1`, `127.0.0.2`) is a *different* address and will be rejected. The NixOS firewall still protects the port from external access; `0.0.0.0` only enables local container→Ollama communication via the kernel's loopback.
  ''
  ''
    **`literalExpression` required for `defaultText`**: When a module option's `default` is a dynamic expression (e.g., `cfg.role == "server"`), always set `defaultText = literalExpression "..."`. Without it, the `nixos-option` help output renders the raw thunk instead of the readable description — confusing for users inspecting the option.
  ''
];
    };
  };
}
