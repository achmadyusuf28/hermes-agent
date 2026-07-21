# hermes-environment.nix — Auto-converted from Hermes skill
# Category: hermes
# Original: hermes-environment

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.hermes-environment;
in
{
  options.hermes.skills.hermes-environment = {
    enable = mkEnableOption "Introspecting and reasoning about the live Hermes Agent environment — ports, services, config, and process layout.";
  };

  config = mkIf cfg.enable {
    hermes.skills.hermes-environment = {
      enable = true;
  description = "Introspecting and reasoning about the live Hermes Agent environment — ports, services, config, and process layout.";
  triggers = [
  "what port is X running on"
  "what's your dashboard port"
  "where is the Hermes web UI"
  "what services are running"
  "what does the Hermes config say about X"
  "how are LLM calls routed"
  "token tracking"
  "token usage"
  "LLM proxy"
  "manifest"
  "cost monitoring"
  "prompt compression"
  "system prompt"
  "prompt assembly"
  "system_prompt.py"
  "prompt_builder.py"
  "how is your system prompt composed"
  "what layers are in your system prompt"
  "SOUL.md identity"
  "prompt tiers"
];
  type = "workflow";
  steps = [
  ''
    **Verify architecture claims with live data before presenting them.** Never recite the known-port-map or architecture diagram as gospel — this skill itself was wrong about the Telegram path until verified. The authoritative source is always:
  ''
  "Check ~/.hermes/config.yaml for declared config:"
  "Check live listening sockets (authoritative):"
  "Match port to process:"
  "Cross-reference with env vars visible to the agent process:"
  "byteplus (subscription) → `deepseek-v4-flash`"
  "deepseek (API key) → `deepseek-v4-flash`"
  "openrouter (API key) → `deepseek/deepseek-v4-flash`"
  ''
    **Try the API first** — for Manifest, the OpenAI-compatible `/v1/chat/completions` is the only public endpoint. There is no management API.
  ''
  ''
    **Dashboard login** — requires browser interaction (NextAuth SPA login). Credentials work via the web UI only.
  ''
  ''
    **PostgreSQL direct** — fallback when API and dashboard are unavailable. Manifest stores all config in its local PostgreSQL. The connection is at `127.0.0.1:5432`, database `manifest`, user `manifest`, no password required for localhost. See `references/manifest-routing-discovery.md` for full schema and queries.
  ''
  ''
    **Identify the actual model in use** — through your provider/proxy routing config (see Manifest section above). Don't assume. Verify whether it's Flash, Pro, or standard tier.
  ''
  ''
    **Fetch pricing pages** — use `web_extract` for static docs, `browser_navigate` for SPA pages (pricing pages are often SPA-rendered). Both DeepSeek (`api-docs.deepseek.com/quick_start/pricing/`) and MiMo (`mimo.mi.com/docs/en-US/price/pay-as-you-go`) are SPAs.
  ''
  ''
    **Compare same tier** — DeepSeek V4 Flash ≈ MiMo V2.5 (identical pricing). DeepSeek V4 Pro ≈ MiMo V2.5 Pro (identical pricing). Match model quality tiers, not just names.
  ''
  ''
    **Account for proxy routing** — the user may route through a subscription provider (byteplus, OpenRouter) rather than direct API. Subscription costs differ from per-token pricing. Check the primary route provider, not just the model name.
  ''
  ''
    **Save as reference** — provider pricing changes. Note the date of comparison and the source URLs so it's clear when it's stale.
  ''
];
  pitfalls = [
  ''
    Port 5173 is Opik UI, not Hermes dashboard. Easy to confuse since both are web UIs.
  ''
  ''
    The Hermes dashboard runs on port **9119** via `hermes dashboard` subcommand — it's **not** the same as the iii engine on port 3111. Port 3111 serves the iii engine HTTP API (JSON function calls, triggers, live registry), not a web UI.
  ''
  ''
    The hermes process in ps aux shows the full env, including companion service URLs — useful shortcut when you need OPIK or Honcho addresses.
  ''
  ''
    Manifest's harness dashboard at `localhost:2099` requires web login — there is no API-based token query I can call programmatically.
  ''
  ''
    **NixOS site-packages are ephemeral.** The workspace_profile module (`agent/workspace_profile.py`) and all three patches to coding_context.py, prompt_builder.py, and system_prompt.py live inside the Hermes venv at `~/.hermes-agent-venv/lib/python3.13/site-packages/agent/`. A package reinstall (pip upgrade, uv sync, NixOS rebuild) will restore the originals. After such an event, the agent loses infrastructure auto-detection until patches are re-applied. Check for this by running `python3 -c "from agent.workspace_profile import get_registry; print('OK')"` from the venv.
  ''
];
    };
  };
}
