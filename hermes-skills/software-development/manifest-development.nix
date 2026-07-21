# manifest-development.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: manifest-development

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.manifest-development;
in
{
  options.hermes.skills.manifest-development = {
    enable = mkEnableOption "Fork, patch, build, deploy, and configure Manifest — the open-source LLM provider router. Covers the codebase structure, custom provider features (entity→DTO→service→proxy flow), Docker deployment patterns, parallel instances, and admin API usage. For developers extending Manifest's routing or provider system.";
  };

  config = mkIf cfg.enable {
    hermes.skills.manifest-development = {
      enable = true;
  description = "Fork, patch, build, deploy, and configure Manifest — the open-source LLM provider router. Covers the codebase structure, custom provider features (entity→DTO→service→proxy flow), Docker deployment patterns, parallel instances, and admin API usage. For developers extending Manifest's routing or provider system.";
  triggers = [
  "fork manifest"
  "patch manifest"
  "custom provider manifest"
  "manifest development"
  "add model headers to manifest"
  "deploy manifest instance"
  "parallel manifest deployment"
  "reset manifest password"
  "forgot manifest admin password"
  "better auth password recovery"
];
  type = "workflow";
  steps = [
  ''
    **Entity** — Add the field to the `CustomProviderModel` interface in `custom-provider.entity.ts`
  ''
  ''
    **DTO** — Add validation decorator in `custom-provider.dto.ts` (import new decorators from `class-validator` if needed)
  ''
  ''
    **Service** — The `enrichCustomProviderModels` method auto-passes through unknown fields from the API payload. If your field needs special handling, add it there.
  ''
  ''
    **Proxy flow** — In `proxy-fallback.service.ts`, after `resolveForwardEndpoint()` resolves the `customProvider` and `forwardModel`:
  ''
  ''
    Create a separate directory with its own `docker-compose.yml`
  ''
  "Use a different port (e.g. `2100` instead of `2099`)"
  "Set `PORT` env var in the new compose file"
  "Use separate postgres volume and DB"
  "Tag the compose project with a unique `name:` field"
];
  pitfalls = [
  ''
    **Port binding on container create**: If port 2099 is occupied when `docker compose up -d` creates the container, the container starts without port binding. Run `docker compose rm -f -s <service>` then `docker compose up -d` to recreate.
  ''
  ''
    **Container auto-restart**: Check for standalone containers that Docker or systemd auto-restarts. Use `docker rm -f <name>` to permanently stop them.
  ''
  ''
    **Empty DB after migration**: The compose-file postgres uses a named volume. The old standalone container may have used a bundled internal DB. After switching from standalone to compose, run setup again (data won't carry over unless migration-managed).
  ''
  ''
    **Model ID format**: When accessing custom provider models via the proxy, use `custom:<provider-uuid>/<model_name>` as the model ID. The `forwardModel` is just `<model_name>` (prefix stripped by `rawModelName()`).
  ''
  ''
    **Setup status caching**: The setup endpoint caches state. If you manipulate the DB directly, restart the container to clear the cache.
  ''
  ''
    **Read-only container**: The container runs with `read_only: true`. Debugging with shell tools is limited — use `node -e` to inspect files.
  ''
];
    };
  };
}
