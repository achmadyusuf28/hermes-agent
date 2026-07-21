# ocr-and-documents.nix — Auto-converted from Hermes skill
# Category: productivity
# Original: ocr-and-documents

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.ocr-and-documents;
in
{
  options.hermes.skills.ocr-and-documents = {
    enable = mkEnableOption "Extract text from PDFs/scans (pymupdf, marker-pdf).";
  };

  config = mkIf cfg.enable {
    hermes.skills.ocr-and-documents = {
      enable = true;
  description = "Extract text from PDFs/scans (pymupdf, marker-pdf).";
  triggers = [
  "ocr-and-documents"
  "ocr and documents"
];
  type = "tool";
  verify = ''
  # 1. [ ] Execute the command/tool with test input- [ ] Verify the output matches expected format- [ ] Check that the tool handles authentication/connection errors gracefully
# 2. Execute the command/tool with test input- [ ] Verify the output matches expected format- [ ] Check that the tool handles authentication/connection errors gracefully
  '';
  pitfalls = [
  ''
    **Auth token freshness** — OAuth tokens expire. Re-authenticate before long sessions- **Schema drift** — external API schemas change. Verify the tool's expected format matches current reality
  ''
  ''
    **Rate limiting** — batch operations may hit API rate limits. Add delays between requests
  ''
];
    };
  };
}
