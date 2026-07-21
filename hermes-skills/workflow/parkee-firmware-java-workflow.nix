# parkee-firmware-java-workflow.nix — Auto-converted from Hermes skill
# Category: workflow
# Original: parkee-firmware-java-workflow

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hermes.skills.parkee-firmware-java-workflow;
in
{
  options.hermes.skills.parkee-firmware-java-workflow = {
    enable = mkEnableOption "Build commands, file patterns, and gotchas for PARKEE reader projects: parkee-reader-pax, parkee-reader-jellies, parkee-reader-entry (+ variants), parkee-reader-exit, parkee-reader-ui-module, parkee-reader-toolchain, and parkee-universal-card-reader-library (Java)";
  };

  config = mkIf cfg.enable {
    hermes.skills.parkee-firmware-java-workflow = {
      enable = true;
  description = "Build commands, file patterns, and gotchas for PARKEE reader projects: parkee-reader-pax, parkee-reader-jellies, parkee-reader-entry (+ variants), parkee-reader-exit, parkee-reader-ui-module, parkee-reader-toolchain, and parkee-universal-card-reader-library (Java)";
  triggers = [
  "parkee reader"
  "pax firmware"
  "jellies firmware"
  "java library"
  "parkee build"
  "card reader"
  "APDU"
  "firmware debug"
  "sendctl"
  "pax serial"
  "reader architecture"
  "parkee command"
  "EMV"
  "QRIS tap"
  "pax logger"
  "pax-logger"
  "PAY-"
];
  type = "workflow";
  steps = [
  "`processdata.h`: `#define NEW_CMD 0x00EF01xx`"
  "`command.c`: `BYTE cmd_new[] = {0xEF, 0x01, 0xx};`"
  "`command.h`: `extern BYTE cmd_new[];`"
  ''
    `parqueProtocol.c`: `case NEW_CMD:` in `pqCommandDispatcher`
  ''
  "`CommandType.java`: add enum with byte value map"
  ''
    `ParkeeReader.java`: `generateXxxCommand()`, `doXxx()`, handler in `onSucceed()`
  ''
  ''
    `PaymentReaderContract.java`: add interface method (use `default` for optional)
  ''
  ''
    **Init ordering** — the config read must happen BEFORE `open_serial()`. In `parkee-reader-pax::PaxDisplayLCD()`, `getSerialComMode()` is called as a pre-read, then `open_serial()`, then `config_file()` re-reads it. The pre-read must handle missing config.ini (return default `PORT_COM1`).
  ''
  ''
    **Missing config file** — `getSerialComMode()` checks `fopen(ini_appconfig, "r")` before calling `ini_gets()`. If the file doesn't exist yet (created by `config_file()` later), default to `PORT_COM1`.
  ''
  ''
    **Include chain** — caller must `#include "device_interface/serial.h"` for `extern int paxSerialPort`. Add explicitly in `app_setting.c`.
  ''
  ''
    **Default config template** — `config_file()` template must write `[SERIAL]\nMode = 0\n` for first-run devices.
  ''
  ''
    **Function declaration** — `getSerialComMode()` must be declared in `app_setting.h` since `parkeeMain.c` calls it.
  ''
  ''
    **Init ordering** — `config_file()` must run BEFORE `open_serial()` so the port variable is set before it's opened. In `parkee-reader-pax-2::PaxDisplayLCD()`, the call order was swapped (2026-07-10).
  ''
  ''
    **Include chain** — the file that calls `com_set_mode()` must `#include "device_interface/serial.h"` where it's declared. `app_setting.c` needs this include added explicitly since none of its existing headers transitively pull in `serial.h`.
  ''
  ''
    **API surface** → `Include/*.h` files (public function signatures, constants, error codes)
  ''
  ''
    **Call flow** → `smartcard/SmartCard.c` implementation (trace convenience layer → raw driver)
  ''
  ''
    **Protocol state machine** → `Bank/<bank>.c` reference implementations (SAM tag/purpose loop)
  ''
  ''
    **External format** → clean tables, no internal references, self-contained code examples
  ''
  ''
    Locate the issue at `/home/soup/linear-issues/YYYY-MM-DD/TEC-NNNN/`
  ''
  ''
    Read `description.md`, `comments.md`, and check `attachments/`
  ''
];
  pitfalls = [
  ''
    **Prolin SDK version mismatch** — always check which Prolin SDK version a PAX reader ships with. V2.4.x+ removed `OsPiccSetParam()` and `PCD_PARAM_ST` — no software-level RF tuning available. RF issues are hardware-only.
  ''
  ''
    **`#ifdef PARQUE_NODISPLAY` dual-implementation** — PAX-2 has two separate code paths for IM700 (no display) and IM15 (LVGL display). Fixes applied to one branch do NOT apply to the other. Always verify in BOTH blocks before declaring a fix done. Use the diff command in the PAX Gotchas section.
  ''
  ''
    **Shared-repo permission denied** — repos under `/mnt/data/projects/parkee/` have `.git/objects/xx/` with 2755 (no group-write). Git commands creating new objects fail. Apply changes via `patch`/`read_file`/`write_file` on source files, bypassing git.
  ''
  ''
    **Second-brain local-only disclaimer** — knowledge at `/mnt/data/projects/parkee/second-brain/` is not in any repo. Peers cloning repos won't have it. Always use absolute paths and include the disclaimer in AGENTS.md.
  ''
  ''
    **Field issue: description.md != evidence** — the root cause in a Linear ticket is someone else's opinion. The raw reader log in `Send-Archive*.zip` attachments is the primary source of truth. Always extract and read the log before forming a conclusion.
  ''
  ''
    **PAX build with RS-232 serial** — after the refactor, `serial_pax.c` may default to `PORT_USBDEV`. Use the runtime INI setting (Approach A in the migration checklist) or restore the `#ifdef USBDEV` switch (Approach B). Verify port selection with `scripts/verify-pax-binary.sh`.
  ''
  ''
    **Submodule commit drift** — always check `git submodule status`. A stale or new commit in `parkee-reader-exit` changes protocol behavior silently. The exit-lib handles shared commands (READER_INIT, DEDUCT, etc.).
  ''
  ''
    **5-byte APDU Case 2S detection** — when `cmdlen == 5`, the 5th byte is ALWAYS LE (response length expected), not LC (data length). Both `pax_sc_transmit()` and `pax_icc_transmit()` were fixed for this, but verify any new 5-byte command has the correct branch.
  ''
];
    };
  };
}
