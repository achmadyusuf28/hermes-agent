# jupyter-live-kernel.nix — Auto-converted from Hermes skill
# Category: data-science
# Original: jupyter-live-kernel

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.jupyter-live-kernel;
in
{
  options.hermes.skills.jupyter-live-kernel = {
    enable = mkEnableOption "Iterative Python via live Jupyter kernel (hamelnb).";
  };

  config = mkIf cfg.enable {
    hermes.skills.jupyter-live-kernel = {
      enable = true;
  description = "Iterative Python via live Jupyter kernel (hamelnb).";
  type = "workflow";
  steps = [
  "**uv** must be installed (check: `which uv`)"
  ''
    **JupyterLab** must be installed: `uv tool install jupyterlab`
  ''
  "A Jupyter server must be running (see Setup below)"
  ''
    **First execution after server start may timeout** — the kernel needs a moment
  ''
  ''
    **The kernel Python is JupyterLab's Python** — packages must be installed in
  ''
  ''
    **--compact flag saves significant tokens** — always use it. JSON output can
  ''
  ''
    **For pure REPL use**, create a scratch.ipynb and don't bother with cell editing.
  ''
  ''
    **Argument order matters** — subcommand flags like `--path` go BEFORE the
  ''
  ''
    **If a session doesn't exist yet**, you need to start one via the REST API
  ''
  ''
    **Errors are returned as JSON** with traceback — read the `ename` and `evalue`
  ''
  ''
    **Occasional websocket timeouts** — some operations may timeout on first try,
  ''
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
