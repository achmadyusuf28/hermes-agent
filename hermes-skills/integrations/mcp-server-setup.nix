# mcp-server-setup.nix — Auto-converted from Hermes skill
# Category: integrations
# Original: mcp-server-setup

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.mcp-server-setup;
in
{
  options.hermes.skills.mcp-server-setup = {
    enable = mkEnableOption "Setting up MCP (Model Context Protocol) servers for AI tools — opencode MCP wiring, custom MCP server scripts, configuration formats, and debugging.";
  };

  config = mkIf cfg.enable {
    hermes.skills.mcp-server-setup = {
      enable = true;
  description = "Setting up MCP (Model Context Protocol) servers for AI tools — opencode MCP wiring, custom MCP server scripts, configuration formats, and debugging.";
  triggers = [
  "mcp server"
  "opencode mcp"
  "MCP integration"
  "honcho mcp"
  "graphify mcp"
  "mcp tool"
  "model context protocol"
  "connect to opencode"
  "stdio mcp"
];
  type = "workflow";
  steps = [
  "`initialize` — negotiate protocol version + capabilities"
  "`notifications/initialized` — confirm ready"
  "`tools/list` — discover available tools"
  "`tools/call` — invoke a specific tool"
];
  pitfalls = [
  ''
    **`command` must be an array** — `["/path/to/binary", "--flag"]`, not `"/path/to/binary --flag"`. OpenCode's config schema validates this strictly.
  ''
  ''
    **`enabled: true` is required** — without it the server is registered but not started.
  ''
  ''
    **`timeout` in milliseconds** — default may be too short for slow tools. Set to 20000-30000 (20-30s) for graph queries.
  ''
  ''
    **Nix-wrapped binaries work** — if the binary is a Nix wrapper (e.g., `graphify-mcp` at `/run/current-system/sw/bin/graphify-mcp`), it works fine as an MCP command since the wrapper itself isn't long-running — it just spawns the real binary.
  ''
  ''
    **stdin/stdout only** — MCP servers communicate over stdio. No HTTP, no WebSocket. Error messages go to stderr (visible in opencode logs).
  ''
  ''
    **JSON-RPC, not REST** — the protocol is strict JSON-RPC 2.0. Every request has `jsonrpc`, `id`, `method`. Every response has `jsonrpc`, `id`, `result` (or `error`).
  ''
];
    };
  };
}
