# arxiv.nix — Auto-converted from Hermes skill
# Category: research
# Original: arxiv

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.arxiv;
in
{
  options.hermes.skills.arxiv = {
    enable = mkEnableOption "Search arXiv papers by keyword, author, category, or ID.";
  };

  config = mkIf cfg.enable {
    hermes.skills.arxiv = {
      enable = true;
  description = "Search arXiv papers by keyword, author, category, or ID.";
  triggers = [
  "arxiv"
];
  type = "workflow";
  steps = [
  ''
    **Discover**: `python scripts/search_arxiv.py "your topic" --sort date --max 10`
  ''
  ''
    **Assess impact**: `curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID?fields=citationCount,influentialCitationCount"`
  ''
  ''
    **Read abstract**: `web_extract(urls=["https://arxiv.org/abs/ID"])`
  ''
  ''
    **Read full paper**: `web_extract(urls=["https://arxiv.org/pdf/ID"])`
  ''
  ''
    **Find related work**: `curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID/references?fields=title,citationCount&limit=20"`
  ''
  ''
    **Get recommendations**: POST to Semantic Scholar recommendations endpoint
  ''
  ''
    **Track authors**: `curl -s "https://api.semanticscholar.org/graph/v1/author/search?query=NAME"`
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
