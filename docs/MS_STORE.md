# Microsoft Store / MSIX workstream

Status: experimental branch `feature/ms-store-msix`. The stable v0.2.0 release on `main` is intentionally untouched.

## Goal

Build a Microsoft Store candidate without requiring an elevated process at runtime. The production EXE on `main` uses `requireAdministrator`; this branch adds a separate Store path using `asInvoker`, packaged Win32/full-trust execution and MSIX.

The Store test package deliberately does **not** declare `allowElevation`.

Official references:

- https://learn.microsoft.com/windows/apps/package-and-deploy/packaging/
- https://learn.microsoft.com/windows/msix/desktop/desktop-to-uwp-prepare
- https://learn.microsoft.com/windows/msix/desktop/desktop-to-uwp-manual-conversion
- https://learn.microsoft.com/windows/apps/package-and-deploy/choose-distribution-path
- https://learn.microsoft.com/windows/msix/package/create-certificate-package-signing
- https://learn.microsoft.com/windows/uwp/debug-test-perf/windows-app-certification-kit
- https://learn.microsoft.com/windows/win32/hidpi/setting-the-default-dpi-awareness-for-a-process

## What this branch adds

- `src/app.store.manifest` — non-elevated native EXE manifest with DPI awareness.
- `store/AppxManifest.xml` — development MSIX manifest for a packaged Win32 desktop app.
- `src/StoreRuntimeCompat.ps1` — Store-specific runtime compatibility helpers loaded before `Main.ps1`.
- `tools/Test-StandardUser-PowerWrite.ps1` — safe non-elevated permission probe.
- `tools/Run-WackLocal.ps1` — local Windows App Certification Kit runner.
- `tools/Test-DpiAwareness.ps1` — runtime probe for the actual main-window DPI context.
- `store/Install-StoreTest.ps1` — development sideload installer/helper.
- `.github/workflows/build-store-msix.yml` — builds, validates, packages, signs and uploads the Store-test MSIX.
- CI extraction of the compiled EXE manifest with `mt.exe` to prove `asInvoker` and `PerMonitorV2` are embedded in the final binary.

## Development identity

`store/AppxManifest.xml` still uses development-only values:

- Identity Name: `HypeTek.CPUThrottling.Dev`
- Publisher: `CN=HypeTek Development`

Before a real Store submission, reserve the app name in Partner Center and replace these with Microsoft's assigned Store identity/publisher values.

The test certificate is self-signed and is trusted only for sideload testing. The installed Store-test application itself runs non-elevated.

## Real-hardware permission result

On 2026-09-11 the standard-user power-write probe was run from a **non-elevated** Windows PowerShell 5.1 session (`Elevated token: False`) against the active Balanced power scheme.

All supported writes succeeded without elevation:

- MinState AC/DC: `WRITE OK`
- MaxState AC/DC: `WRITE OK`
- MaxFrequency AC/DC: `WRITE OK`
- BoostMode AC/DC: `WRITE OK`
- CoolingPolicy AC/DC: `WRITE OK`
- Epp AC/DC: `WRITE OK`
- Apply active scheme: `OK`

Result: `PASS: Supported power-setting writes succeeded without elevation.`

## Packaged MSIX real-hardware result

The development MSIX installs successfully on Windows 11 x64 and launches normally from Start without an application UAC prompt.

The initial packaged test exposed a missing runtime helper (`Get-ActivePowerScheme`). `StoreRuntimeCompat.ps1` now supplies the Store runtime compatibility layer before `Main.ps1`, and CI validates the required function contract.

Confirmed working in the packaged application:

- normal Start-menu launch without application elevation
- full GUI and live telemetry
- existing profile loading
- profile apply
- editor apply
- Windows energy-plan interaction
- supported CPU power settings without UAC
- Store runtime helper loading

Restart persistence and profile import/export remain explicit checklist items until separately reconfirmed for the packaged build.

## DPI / WACK findings

Four local WACK reports have now been reviewed. All have the same high-level result:

- Overall result: `WARNING`
- all non-DPI tests: `PASS`
- `FAIL`: none
- only warning: `DPIAwarenessValidation`

The latest report is `HypeTek-CPU-Throttling-WACK-20260911-024957.xml`.

The current Store launcher has both Microsoft-documented DPI mechanisms:

- embedded manifest: `dpiAware=true/pm`
- embedded manifest: `dpiAwareness=PerMonitorV2`
- runtime fallback before UI creation: `SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)`

CI now extracts the **compiled EXE's actual manifest resource** with `mt.exe` and fails if `asInvoker` or `PerMonitorV2` are missing. The Store build passes this check.

The latest WACK report's own static analysis also detects `user32.dll!SetProcessDpiAwarenessContext`, yet the separate `DPIAwarenessValidation` test still emits a warning saying the same binary is not DPI-aware.

### Runtime DPI proof: PASS

A real running packaged app window was inspected with `tools/Test-DpiAwareness.ps1` while the app was open from the Start menu.

Observed result:

```text
Process ID: 26612
Main HWND : 0x420E80
Context   : PerMonitorV2
PASS: The actual application window is running as PerMonitorV2 DPI-aware.
```

This gives three independent positive signals for DPI awareness:

1. the final EXE contains the `PerMonitorV2` manifest declaration,
2. the final EXE contains and WACK detects the `SetProcessDpiAwarenessContext` call,
3. Windows reports the actual running app window as `PerMonitorV2`.

Therefore the persistent local `DPIAwarenessValidation` warning is documented as a local WACK analyzer discrepancy rather than a reason to keep modifying confirmed-working DPI behavior. The final Microsoft Store certification remains the authoritative acceptance gate.

## Validation evidence retained for Store certification notes

- non-elevated power writes: PASS
- packaged application launch without UAC: PASS
- packaged profile/editor/power-plan operation: PASS
- local WACK: 0 FAIL, one persistent DPI analyzer WARNING
- embedded manifest extraction: PASS (`PerMonitorV2` present)
- runtime DPI context: PASS (`PerMonitorV2`)

If the Store certification surfaces the same DPI warning, include the above evidence and the exact local WACK report in certification/support notes instead of weakening or removing the working DPI configuration.

## Store-readiness checklist

- [x] Stable `main` branch kept separate.
- [x] Non-elevated Store EXE manifest.
- [x] Development MSIX manifest.
- [x] Dedicated CI build for MSIX.
- [x] Sideload signing for test artifacts.
- [x] Standard-user power-write permission probe.
- [x] Development-only test installer for certificate trust + MSIX install.
- [x] Standard-user permission probe passes on real target hardware.
- [x] MSIX installs and launches on a Windows 11 x64 test machine.
- [x] Missing Store runtime helpers fixed and loaded before `Main.ps1`.
- [x] Source-aware CI runtime-contract validation.
- [x] Profile apply/editor apply retested successfully in packaged app.
- [x] Windows energy-plan interaction retested successfully in packaged app.
- [x] Tested CPU power/profile changes work without application UAC.
- [x] Local WACK runner added to the Store artifact.
- [x] Four local WACK runs completed with 0 FAIL results.
- [x] DPI manifest declarations present in source.
- [x] CI verifies the final EXE's embedded DPI manifest.
- [x] Runtime `SetProcessDpiAwarenessContext` call present and detected by WACK static analysis.
- [x] Real running main window verified as `PerMonitorV2`.
- [x] Persistent local WACK DPI warning documented as an analyzer discrepancy with runtime evidence.
- [ ] Restart persistence and import/export explicitly reconfirmed in the packaged app.
- [ ] Partner Center developer account ready.
- [ ] App name reserved and official Store identity copied into manifest.
- [ ] Final Store icons/screenshots/listing text prepared.
- [ ] Final candidate rebuilt with Store-assigned identity and revalidated.
- [ ] Store submission passes certification.
