# agent-session-visualization.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: agent-session-visualization

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.agent-session-visualization;
in
{
  options.hermes.skills.agent-session-visualization = {
    enable = mkEnableOption "Visualize coding-agent sessions as 3D codebase traces — export Hermes sessions to mindwalk's trace format, run the mindwalk viewer, and interpret the visual output (touch heatmaps, playback, friction signals).";
  };

  config = mkIf cfg.enable {
    hermes.skills.agent-session-visualization = {
      enable = true;
  description = "Visualize coding-agent sessions as 3D codebase traces — export Hermes sessions to mindwalk's trace format, run the mindwalk viewer, and interpret the visual output (touch heatmaps, playback, friction signals).";
  triggers = [
  "session visualization"
  "mindwalk"
  "visualize session"
  "session trace"
  "3D codebase map"
  "agent observability"
  "session replay"
];
  type = "workflow";
  steps = [
  "**Group membership** — add `soup` to the `hermes` group:"
  ''
    **Home dir traversable** — `0750` on `/home/hermes/` and `~/.hermes/`:
  ''
  ''
    **Output dir setgid** — `2775` so both users can write, new files inherit `hermes` group:
  ''
];
  pitfalls = [
  ''
    **Duplicate tool results**: Every `tool_call_id` appears **exactly 2 times** in messages where `role='tool'`. When processing messages in order with a `pending_tool_calls` dict, the first occurrence pops the pending call and creates a correct event. The second occurrence finds `None` — if unhandled, `inp` defaults to `{}` and the event gets no file targets, no command, no summary. **Fix:** `if pending is None: continue` to skip the duplicate. See `references/hermes-db-quirks.md` for full details.
  ''
  ''
    **Export before serve**: `mindwalk serve` discovers `.trace.json` files in the Hermes dir. Run `hermes-mindwalk-export` first to populate the directory. The server scans on page load with a 5s cache TTL.
  ''
  ''
    **Large sessions**: A session with 5000+ events can take 5-10s to export. Use `--limit` or `--recent` for quick iteration.
  ''
  ''
    **Big state.db**: With 100+ sessions, the full export takes 30-60s. The `--recent` flag filters to last 24h using `started_at >= NOW - 86400` at the SQL level.
  ''
  ''
    **No `is_error` column**: The messages table in state.db does not have an `is_error` flag. Error detection relies on parsing the JSON `content` for `"exit_code": N` where N > 0. Plain-text tool summaries starting with `[terminal] ran` are not errors.
  ''
  "**`.trace.json` extension pitfalls**: Two things to know:"
  ''
    `filepath.Ext(".trace.json")` returns `.json` (Go only returns the last dot extension). The `scanSessions` function in the fork has a patch to check `ext == ".json" && strings.HasSuffix(path, ".trace.json")`. If you merge from upstream, re-apply this patch.
  ''
  ''
    The Hermes adapter (`internal/adapter/hermes/`) uses its own `ListSessions()` which globs `*.trace.json` directly — no extension trickery needed.
  ''
  ''
    **Port conflicts**: The default `mindwalk serve` uses a random port. Use `--port N` for a specific range. Kill stale processes with `lsof -ti :<port> | xargs kill`. A stale process exits with `bind: address already in use`.
  ''
  ''
    **Session key format**: The API uses hash-based keys (`hermes-f915ac5dbef166ad1377e55b`), not raw session IDs. Get the key from the `GET /api/sessions` response. You can also open by file path: `mindwalk open ~/.hermes/mindwalk/<session>.trace.json`.
  ''
  ''
    **CWD detection from messages**: The `sessions.cwd` column is set at session start and records where the user actually was. **Trust it.** Only override when the stored CWD is empty, `/`, or has more than 50K immediate children (signals a container-root or giant mount point). Auto-detection (scanning `terminal.workdir` params, counting workspace path mentions) is a fallback, not a replacement. Overriding a valid `/home/hermes` CWD with a guessed `/mnt/data/workspace` produces a 14M-file citymap that can't render. See `references/citymap-builder-patches.md` for the Go-side fix.
  ''
  ''
    **Citymap too large to render tree**: When the citymap builder walks CWD, it starts with `git ls-files -co --exclude-standard` (if a git repo) and falls back to `filepath.WalkDir`. The walker only skips `.git`, `node_modules`, `.venv`, `dist`, `build`. Directories like `.cache/`, `.local/`, `.npm/`, `.hermes/`, and Python virtualenvs are walked in full. With CWD=`/home/hermes/` this produces **149,573 files** and **21,161 directories** — the treemap layout assigns every file a rectangle, but 150K sub-pixel buildings never render (terrain visible, tree invisible). **Fix:** patch `internal/citymap/builder.go` to add a `shouldSkipDir` helper that skips `".cache", ".local", ".npm", ".hermes", ".graphify", "__pycache__", ".mypy_cache", ".pytest_cache", ".ruff_cache"` plus any dir ending in `venv`, `env`, `-env`, or `_env`. See `references/citymap-builder-patches.md` for the full Go patch.
  ''
  ''
    **Git info from subdirectories**: When CWD is a container directory (e.g. `/mnt/data/workspace/`) rather than a git repo itself, scan one level deep with `git -C <subdir> rev-parse --show-toplevel`. This finds the actual project repo(s) the session worked in.
  ''
  ''
    **Path normalization — allow ../ paths and filter noise**: Files outside the CWD (e.g. `/home/hermes/.ollama/Modelfiles/` from CWD `/mnt/data/workspace/`) resolve to `../../../home/hermes/...`. The `normalize_path` function should allow up to 3 levels of `..` traversal — mindwalk handles `../` in paths fine. Deeper than 3 is probably system noise. Also **filter network-path noise**: paths starting with a digit (`8000/health`) are curl/fetch URL fragments, not files — reject them. Paths containing `:` before `/` (relative URLs like `localhost:8000/v1/models`) are also noise — reject those too. Without this filter, every `curl -s http://localhost:8000/health` call produces bogus targets like `8000/health`, `localhost:8000/v1/models`, `application/json`, and `HTTP/1.1`.
  ''
  ''
    **Script file permissions**: The export script must be world-readable (`755`), not just executable (`711`). Python needs to read its own source code at startup. If the script is `-rwx--x--x`, you'll get `PermissionError` when Python tries to `open()` its own file. Fix: `chmod 755 /path/to/hermes-mindwalk-export`. This happens when the file was created by a different user with a restrictive umask.
  ''
  ''
    **Action classification**: The `action_for()` function maps Hermes tools to mindwalk actions. Key refinements discovered in practice:\n  - Terminal commands matching verify patterns (`pytest`, `make test`, `cargo test`, `npx jest`, `npm run build`, `go build ./...`) are classified as `verify`, not `exec`.\n  - `vision_analyze` is in `READ_TOOLS` — it reads image files, so events get `read` action.\n  - Commands starting with `cat`, `head`, `tail`, `ls`, `echo` produce output but are still `exec` operations — however they get classified as `read` by regex matching on the command text. This is a heuristic trade-off.
  ''
  ''
    **Nix `'''` string escaping**: In Nix indented strings (`''' ... '''`), `''${...}` is NOT interpolated — only `'''''${...}` triggers interpolation. If you write `"''${../../relative/path}"` inside a `text = ''' ... '''` block, bash receives the literal `''${../../relative/path}` and tries to expand it as a malformed variable name (fails silently). Use absolute paths or use `'''''${...}'''` syntax for Nix string interpolation.
  ''
  ''
    **SQL WHERE before ORDER BY**: The `--recent` and `--limit` flags append conditions to the SQL query. Build all `WHERE` conditions *before* appending `ORDER BY` and `LIMIT`. Appending `AND started_at >= ...` after `ORDER BY` produces a syntax error. Pattern: collect conditions in a list, join with `AND`, then interpolate into the query template with `ORDER BY` already in place.
  ''
];
    };
  };
}
