# airtable.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: airtable

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.airtable;
in
{
  options.hermes.skills.airtable = {
    enable = mkEnableOption "Airtable REST API via curl. Records CRUD, filters, upserts.";
  };

  config = mkIf cfg.enable {
    hermes.skills.airtable = {
      enable = true;
  description = "Airtable REST API via curl. Records CRUD, filters, upserts.";
  type = "workflow";
  steps = [
  ''
    Create a **Personal Access Token (PAT)** at https://airtable.com/create/tokens (tokens start with `pat...`).
  ''
  "Grant these scopes (minimum):"
  ''
    **Important:** in the same token UI, add each base you want to access to the token's **Access** list. PATs are scoped per-base — a valid token on the wrong base returns `403`.
  ''
  ''
    Store the token in `''${HERMES_HOME:-~/.hermes}/.env` (or via `hermes setup`):
  ''
  ''
    **Confirm auth.** `curl -s -o /dev/null -w "%{http_code}\n" https://api.airtable.com/v0/meta/bases -H "Authorization: Bearer $AIRTABLE_API_KEY"` — expect `200`.
  ''
  ''
    **Find the base.** List bases (step above) OR ask the user for the `app...` ID directly if the token lacks `schema.bases:read`.
  ''
  ''
    **Inspect the schema.** `GET /v0/meta/bases/$BASE_ID/tables` — cache the exact field names and primary-field name locally in the session before mutating anything.
  ''
  ''
    **Read before you write.** For "update X where Y", `filterByFormula` first to resolve the `rec...` ID, then `PATCH /v0/$BASE_ID/$TABLE/$RECORD_ID`. Never guess record IDs.
  ''
  ''
    **Batch writes.** Combine related creates into one 10-record POST to stay under the 5 req/sec budget.
  ''
  ''
    **Destructive ops.** Deletions can't be undone via API. If the user says "delete all Xs", echo back the filter + record count and confirm before firing.
  ''
];
  pitfalls = [
  ''
    **`filterByFormula` MUST be URL-encoded.** Field names with spaces or non-ASCII also need encoding (`{My Field}` → `%7BMy%20Field%7D`). Use Python stdlib (pattern above) — never hand-escape.
  ''
  ''
    **Empty fields are omitted from responses.** A missing `"Assignee"` key doesn't mean the field doesn't exist — it means this record's value is empty. Check the schema (step 3) before concluding a field is missing.
  ''
  ''
    **PATCH vs PUT.** `PATCH` merges supplied fields into the record. `PUT` replaces the record entirely and clears any field you didn't include. Default to `PATCH`.
  ''
  ''
    **Single-select options must exist.** Writing `"Status": "Shipping"` when `Shipping` isn't in the field's option list errors with `INVALID_MULTIPLE_CHOICE_OPTIONS` unless you pass `"typecast": true` (which auto-creates the option).
  ''
  ''
    **Per-base token scoping.** A `403` on one base while another works means the token's Access list doesn't include that base — not a scope or auth issue. Send the user to https://airtable.com/create/tokens to grant it.
  ''
  ''
    **Rate limits are per base, not per token.** 5 req/sec on `baseA` and 5 req/sec on `baseB` is fine; 6 req/sec on `baseA` alone will throttle. Monitor the `Retry-After` header on `429`.
  ''
];
    };
  };
}
