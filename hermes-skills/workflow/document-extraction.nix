# document-extraction.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: document-extraction

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.document-extraction;
in
{
  options.hermes.skills.document-extraction = {
    enable = mkEnableOption "Extract text from documents (PDF, DOCX, XLSX, images, HTML) via the `document-extract` CLI tool.";
  };

  config = mkIf cfg.enable {
    hermes.skills.document-extraction = {
      enable = true;
  description = "Extract text from documents (PDF, DOCX, XLSX, images, HTML) via the `document-extract` CLI tool.";
  triggers = [
  "extract PDF"
  "read document"
  "parse PDF"
  "convert document"
  "PDF to text"
  "docx to markdown"
  "send me a file"
  "prolin guide"
];
  type = "workflow";
  steps = [
  ''
    **Find the file** — either user-provided path or `~/.hermes/cache/documents/`
  ''
  ''
    **Run `document-extract <file> -o <output>.txt`** — single command, done
  ''
  "**Analyze** the extracted text (APIs, configs, patterns)"
  "**Cross-reference** against codebase with `grep -r`"
];
  pitfalls = [
  ''
    **Scanned PDFs** need Tesseract for OCR — `which tesseract` to check
  ''
  ''
    **ONNX Runtime warning** about `/sys/class/drm/card0` is harmless
  ''
  "**Large PDFs** >100MB may need chunking"
  ''
    **The CLI tool auto-sets `LD_PRELOAD`** for libstdc++ on NixOS — if it fails with a library error, check that `libstdc++.so.6` is findable in the Nix store
  ''
  ''
    **`document-extract` depends on the Hermes venv** — if the venv is broken or missing, the CLI will fail with a Python module not found error. Run `hermes install` or check the venv path.
  ''
  ''
    **Excel files with merged cells or formulas** — markitdown extracts cell values, not computed results. For formula-heavy sheets, open in LibreOffice or save as CSV first.
  ''
];
    };
  };
}
