# pax2-build-verification.nix — Auto-converted from Hermes skill
# Category: software-development
# Original: pax2-build-verification

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.pax2-build-verification;
in
{
  options.hermes.skills.pax2-build-verification = {
    enable = mkEnableOption "Canonical build and verification for parkee-reader-pax-2 using Docker-based PAX Prolin SDK cross-compiler. Covers APDU parser fixes, FWT/FWI tuning, and field-issue debug methodology.";
  };

  config = mkIf cfg.enable {
    hermes.skills.pax2-build-verification = {
      enable = true;
  description = "Canonical build and verification for parkee-reader-pax-2 using Docker-based PAX Prolin SDK cross-compiler. Covers APDU parser fixes, FWT/FWI tuning, and field-issue debug methodology.";
  triggers = [
  "build pax-2"
  "verify pax compilation"
  "paxParque build"
  "PAX-2 build"
  "APDU parser"
  "FWT fix"
  "pax_sc_transmit"
  "PAY-321"
];
  type = "workflow";
  steps = [
  ''
    **Case 3S missing LE**: When `cmdlen == 5 + LC` (exact fit, no explicit LE
  ''
  ''
    **LE=0 → 256 must apply to ALL paths**: The blanket `if (LE==0) LE=256`
  ''
  ''
    **5-byte ambiguity**: Byte 4 is LC **or** LE depending on the instruction.
  ''
  ''
    Capture success and failure logs (from PAY-321 files or field reports).
  ''
  ''
    Find the first command where `SW1 - SW2 Response` difers between the two.
  ''
  "Compare `Final LC`, `Final LE`, and the raw hex command."
  ''
    Trace through the parser logic — the bug is ALMOST ALWAYS in how LC/LE are
  ''
  "Use Python to simulate the parser offline:"
  ''
    **Default FWI=4** (~4.8ms) instead of 100ms when ATS lacks FWI.
  ''
  ''
    **NFC mode delta** (+3640 µs) on every transmit — matches PN5180 DELTA_FWT_US.
  ''
  ''
    **HCE detection**: if ATS length ≤ 6 AND raw FWI ≤ 7, floor effective FWI to
  ''
];
  pitfalls = [
  ''
    **BCA path FWT gap** — `BCAsendContactlessAPDU` has its own hardcoded FWT=100000 and its own inline APDU parsing. It does NOT use `pax_sc_transmit()` or the dynamic FWT.
  ''
  ''
    **5-byte ambiguity** — Byte 4 is LC or LE depending on the instruction. The old code always set both to cmd[4]. Test 5-byte commands carefully after parser changes.
  ''
  ''
    **LE=0 → 256 must apply to ALL paths** — the `if (LE==0) LE=256` conversion must be OUTSIDE the if/else chain, not just in the Case 4S branch.
  ''
  ''
    **Case 3S missing LE** — when `cmdlen == 5 + LC`, must set LE=256. The `if (cmdlen > 5 + LC)` guard needs `==` too.
  ''
  ''
    **PN5180 RFC padding** — the SDK adds its own padding bytes to CTL commands. Don't pad manually.
  ''
  ''
    **PAX and Jellies SDKs are NOT interchangeable** — FWT fixes on PAX (Prolin SDK) cannot be ported to Jellies (H2 SDK), and vice versa. Verify the target SDK exports the required API before proposing a cross-port.
  ''
  ''
    **PORT_USBHOST vs PORT_USBACM — SDK constant typo that compiles fine.** When implementing COM_MODE_CDC, the `com_set_mode()` case must set `paxSerialPort = PORT_USBACM` (the CDC ACM virtual serial port). Using `PORT_USB_HOST` instead compiles cleanly (both are valid SDK port constants) but opens the wrong USB interface (host mode for external peripherals instead of CDC ACM). **Always diff against the parallel codebase** (`/mnt/data/parkee/readers/firmware/parkee-reader-pax`) when porting a feature — the old repo's `app_setting.c` line 410 uses the correct constant. A syntax-level verification script will NOT catch this.
  ''
];
    };
  };
}
