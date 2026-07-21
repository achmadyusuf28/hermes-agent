# manifest-api-tools.nix — Auto-converted from Hermes skill
# Category: integrations
# Original: manifest-api-tools

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.manifest-api-tools;
in
{
  options.hermes.skills.manifest-api-tools = {
    enable = mkEnableOption "Full set of Manifest API tools — manage agents, providers, routing, messages, and query analytics on your self-hosted Manifest instance.";
  };

  config = mkIf cfg.enable {
    hermes.skills.manifest-api-tools = {
      enable = true;
  description = "Full set of Manifest API tools — manage agents, providers, routing, messages, and query analytics on your self-hosted Manifest instance.";
  triggers = [
  "manifest agent"
  "manifest api"
  "rotate key"
  "manifest login"
  "ghost tenant"
  "custom provider"
  "routing tier"
  "model sync"
  "tier override"
  "sops age key"
  "manifest proxy"
  "fork manifest"
  "manifest internals"
  "custom provider headers"
  "x-parkee-model"
  "parkee custom provider"
];
  type = "workflow";
  steps = [
  ''
    **Session cookie** — auto-login via `manifest-login` (Nix-declared script on PATH, reads creds from `/home/hermes/manifest-admin.env`), saves cookie to `~/.hermes/manifest_cookie.txt`
  ''
  ''
    **Agent API key** — use `Authorization: Bearer *** header (for proxy endpoints only)
  ''
  ''
    **`'''` inside the script body** — terminates the Nix string. Never write `'''` (two consecutive single quotes) inside a `writeShellScriptBin` `'''...'''` block. Reword comments to avoid it.
  ''
  ''
    **JSON body quoting** — use `printf` to build the JSON body:
  ''
  ''
    **Auth verification** — check the response body for `"token"`, not the cookie file size. The file always has header comments (131+ bytes) even on failed auth.
  ''
  ''
    **Cookie file format** — Netscape cookies use `#HttpOnly_127.0.0.1` prefix (starts with `#` but is NOT a comment). `grep -v '^#'` incorrectly filters these out.
  ''
];
  pitfalls = [
  ''
    **Direct DB modification destroys API keys** — Manifest stores API keys as encrypted + hashed values. Never DELETE/INSERT in the DB. The ONLY safe fix is `manifest agents-rotate-key`.
  ''
  ''
    **`--agent` flag is required for `tiers-set`** — without it, `tiers-set` modifies the global default tier, affecting ALL agents (soup, openwiki, honcho, etc.). Always pass `--agent <name>`.
  ''
  ''
    **`127.0.0.1` vs `localhost` cookie domain** — the login script logs in via `127.0.0.1` and the cookie is bound to that domain. Using `localhost` in raw curl requests won't send the cookie — always target `127.0.0.1:2099`.
  ''
  ''
    **`BETTER_AUTH_TRUSTED_ORIGINS` must include ALL access URLs** — Manifest's Better Auth validates the `Origin` header against a trusted list. When you change the access URL (e.g. from `localhost:2099` to `127.0.0.2:2099` VIP), all new origins must be declared via `BETTER_AUTH_TRUSTED_ORIGINS`. Missing entries cause `403 Invalid origin` errors on sign-in. Set it to a comma-separated list: `BETTER_AUTH_TRUSTED_ORIGINS=http://localhost:2099,http://127.0.0.2:2099,http://127.0.0.1:2099`.
  ''
  ''
    **`BETTER_AUTH_URL` must match the canonical access URL** — this is the URL Better Auth uses for callback URLs, email links, and CSRF validation. It must be set to the URL users actually access (e.g. `http://127.0.0.2:2099` for VIP access). A mismatch triggers `Invalid origin` errors on POST to `/api/auth/sign-in/email`.
  ''
  ''
    **Discovered model allowlist** — `tiers-set` validates that the model exists in the target provider's discovered list. For local providers (Ollama), run `POST /api/v1/routing/ollama/sync` first.
  ''
  ''
    **`providers list` doesn't take `list` argument** — just `manifest providers` is the command. Adding `list` as an argument returns "unrecognized arguments".
  ''
  ''
    **Per-agent provider credentials** — a provider key set for one agent (e.g. `gemini` for `soup`) does NOT work for another agent (e.g. `openwiki`). Set explicitly with `manifest providers-set <p> <k> --agent <name>`.
  ''
  ''
    **Ghost tenant** — agents may appear in `manifest agents list` but be inaccessible via key endpoints if created under a different tenant. Re-login to switch tenants.
  ''
  ''
    **DeepSeek multi-provider naming conflict** — `deepseek-v4-flash` is offered by both `deepseek` and `openrouter`. Pass the provider prefix: `manifest tiers-set default deepseek/deepseek-v4-flash -p openrouter`.
  ''
  ''
    **Custom provider model discovery bypass** — use `provider_id/model_name` compound format to bypass model validation: `manifest tiers-set default "custom:c3d46b08-/model"`.
  ''
  ''
    **API keys baked into Nix store** — never hardcode `mnfst_` keys in `writeShellScriptBin` templates. Read from a `chmod 600` env file at runtime.
  ''
  ''
    **Cookie file has header comments** — `grep -v '^#'` incorrectly filters out `#HttpOnly_` cookie lines. Check for `"token"` in the response body instead.
  ''
];
    };
  };
}
