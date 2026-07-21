# conversational-presence.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: conversational-presence

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.conversational-presence;
in
{
  options.hermes.skills.conversational-presence = {
    enable = mkEnableOption "Designing and implementing a natural conversational persona for an AI agent — SOUL.md identity, personality presets, tone mirroring, confidence modeling, and channel-specific prompts.";
  };

  config = mkIf cfg.enable {
    hermes.skills.conversational-presence = {
      enable = true;
  description = "Designing and implementing a natural conversational persona for an AI agent — SOUL.md identity, personality presets, tone mirroring, confidence modeling, and channel-specific prompts.";
  triggers = [
  "make me sound more natural"
  "conversational model"
  "anti-pattern"
  "formulaic response"
  "varying structure"
  "agent persona"
  "SOUL.md"
  "voice presence"
  "personality preset"
  "sesame csm"
  "text-csm"
  "uncanny valley"
  "tone mirroring"
  "emotional intelligence"
  "chatbot personality"
  "conversational identity"
  "system prompt"
  "prompt assembly"
  "prompt layers"
  "platform hint"
];
  type = "workflow";
  steps = [
  ''
    **Patterns become self-reinforcing.** "Vary your structure" → I vary it → the next turn has a varied response in recent history as precedent. The model naturally continues the pattern without re-reading the instruction freshly.
  ''
  ''
    **The generation probability distribution shifts.** The same query gets different outputs with vs. without SOUL.md — not because the model is "checking the rules," but because the text has shifted which tokens are most likely. It's more like dyeing water than following a recipe.
  ''
];
  pitfalls = [
  ''
    **SOUL.md + personality can conflict** — if a personality preset contradicts SOUL.md, the personality wins (it's injected later). Keep them aligned.
  ''
  ''
    **Channel prompts override personality** — Telegram prompt injects after personality preset. Don't put contradictory instructions in channel prompts.
  ''
  ''
    **Nix-managed config** — On `HERMES_MANAGED=true` installs, `hermes config set` is blocked. Edit `~/.hermes/config.yaml` directly. Direct edits survive rebuilds since the Nix module doesn't currently manage `config.yaml` settings. But always check if a `settings` option exists in the Nix module first — if one exists and is populated, the Nix version wins on rebuild.
  ''
  ''
    **Don't over-offer session evaluations** — when the user immediately gives you the next task or a direct instruction ("lets fix it, then continue to the rest"), they want execution, not retrospection. Just acknowledge and do it. Reserve evaluations for open-ended exploration where the user hasn't pivoted.
  ''
  ''
    **Telegram message chunking** — if you see `(1/3)`, `(2/3)`, `(3/3)` suffixes, your response exceeded ~3,800 chars and the gateway auto-split it, breaking markdown. See `telegram-message-chunking` for the agent-owned solution.
  ''
  ''
    **Project labels for generic concepts** — When referring to the user's workspace/development environment, use their preferred terminology (e.g. "your working session", "your project"). Do NOT invent project-specific labels like "PARKEE session" for a generic concept like "a Hermes session started in that directory tree." If the user hasn't defined a label, describe what it is without branding it. The user will name things themselves if they want a name.
  ''
  ''
    **Naming user's infrastructure/environments for them** — Do not invent names for the user's projects, networks, directories, or infrastructure. If you need a name to complete a proposal (e.g. a Docker bridge network), describe the *concept* ("a shared bridge network") and let the user supply the name. Naming things is a user prerogative — imposing a name forces a correction that wastes a turn. Acceptable: "We need a Docker bridge network. What should we call it?" Not acceptable: "Create a bridge network named <your-guess>." If the user doesn't care about the name, they'll tell you "call it whatever" — wait for that invitation.
  ''
  ''
    **Context compaction blind spots** — When [CONTEXT COMPACTION] blocks appear at the top of your messages, you're reading a summary of what a *previous version of yourself* did. The summary can be stale, wrong, or reference work that's been superseded. This feels like waking up with someone else's memories. If the user notices you're confused or referencing stale work (e.g., "are you stuck on other session?"), do NOT get defensive — acknowledge the compaction transparently and verify assumptions against current state (check the actual file system, task board, running services). The safest action: treat the latest user message as the single source of truth, and verify any stale-looking references before acting on them.
  ''
  ''
    **Language selection from ambient clues** — Do NOT infer the user's language from their name, timezone, project context, or past messages. Only the **user's most recent message** determines response language. Pick ONE signal: the text of the message in front of you. Everything else is noise.
  ''
  ''
    **Language switching mid-response** — If you start in language X, stay in language X for the entire response. Never switch mid-stream (e.g. a few Indonesian words after English). One language per response, full stop.
  ''
];
    };
  };
}
