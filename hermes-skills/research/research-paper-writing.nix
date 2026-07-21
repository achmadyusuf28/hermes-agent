# research-paper-writing.nix — Auto-converted from Hermes skill
# Category: research
# Original: research-paper-writing

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.research-paper-writing;
in
{
  options.hermes.skills.research-paper-writing = {
    enable = mkEnableOption "Write ML papers for NeurIPS/ICML/ICLR: design→submit.";
  };

  config = mkIf cfg.enable {
    hermes.skills.research-paper-writing = {
      enable = true;
  description = "Write ML papers for NeurIPS/ICML/ICLR: design→submit.";
  triggers = [
  "research-paper-writing"
  "research paper writing"
];
  type = "workflow";
  steps = [
  ''
    **Be proactive.** Deliver complete drafts, not questions. Scientists are busy — produce something concrete they can react to, then iterate.
  ''
  ''
    **Never hallucinate citations.** AI-generated citations have ~40% error rate. Always fetch programmatically. Mark unverifiable citations as `[CITATION NEEDED]`.
  ''
  ''
    **Paper is a story, not a collection of experiments.** Every paper needs one clear contribution stated in a single sentence. If you can't do that, the paper isn't ready.
  ''
  ''
    **Experiments serve claims.** Every experiment must explicitly state which claim it supports. Never run experiments that don't connect to the paper's narrative.
  ''
  ''
    **Commit early, commit often.** Every completed experiment batch, every paper draft update — commit with descriptive messages. Git log is the experiment history.
  ''
  ''
    SEARCH → Query Semantic Scholar or Exa MCP with specific keywords
  ''
  ''
    VERIFY → Confirm paper exists in 2+ sources (Semantic Scholar + arXiv/CrossRef)
  ''
  ''
    RETRIEVE → Get BibTeX via DOI content negotiation (programmatically, not from memory)
  ''
  ''
    VALIDATE → Confirm the claim you're citing actually appears in the paper
  ''
  "ADD → Add verified BibTeX to bibliography"
  "Check if process is still running: ps aux | grep <pattern>"
  "Read last 30 lines of log: tail -30 <logfile>"
  "Check for completed results: ls <result_dir>"
  "If results exist, read and report: cat <result_file>"
  ''
    If all done, commit: git add -A && git commit -m "<descriptive message>" && git push
  ''
  "Report in structured format (tables with key metrics)"
  "Answer the key analytical question for this experiment"
  "Load all result files from a batch"
  "Compute per-task and aggregate metrics"
  "Generate summary tables"
];
  pitfalls = [
  ''
    **Token expiration** — GitHub tokens can expire mid-workflow. Verify `gh auth status` first- **Rate limiting** — unauthenticated requests are heavily rate-limited. Always use a token- **Git state drift** — ensure you're on the right branch and the working tree is clean before operations
  ''
];
    };
  };
}
