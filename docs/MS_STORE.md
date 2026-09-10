# Microsoft Store / MSIX workstream

Status: experimental branch `feature/ms-store-msix`. The stable v0.2.0 release on `main` is intentionally untouched.

## Goal

Build a Microsoft Store candidate without requiring an elevated process at runtime. The current production EXE uses `requireAdministrator`; this branch adds a separate Store manifest using `asInvoker` and a dedicated MSIX build.

Microsoft's current MSIX guidance says packaged desktop apps can run as full-trust/medium-integrity desktop processes, and packaged Win32 apps declare `runFullTrust`. Microsoft also warns that apps requiring elevation for functionality are not accepted through the normal Store certification path. For that reason this experiment deliberately does **not** declare `allowElevation`.

Official references:

- https://learn.microsoft.com/windows/apps/package-and-deploy/packaging/
- https://learn.microsoft.com/windows/msix/desktop/desktop-to-uwp-prepare
- https://learn.microsoft.com/windows/msix/desktop/desktop-to-uwp-manual-conversion
- https://learn.microsoft.com/windows/apps/package-and-deploy/choose-distribution-path
- https://learn.microsoft.com/windows/msix/package/create-certificate-package-signing
- https://learn.microsoft.com/windows/uwp/debug-test-perf/windows-app-certification-kit

## What this branch adds

- `src/app.store.manifest` — native EXE manifest with `asInvoker`.
- `store/AppxManifest.xml` — development MSIX manifest for a packaged Win32 desktop app.
- `src/StoreRuntimeCompat.ps1` — Store-specific runtime compatibility helpers loaded before `Main.ps1`.
- `tools/Test-StandardUser-PowerWrite.ps1` — safe permission probe that writes the already configured values back to the active power scheme while running non-elevated.
- `tools/Run-WackLocal.ps1` — local Windows App Certification Kit runner for the installed Store-test package; creates a timestamped certification report under the user's Documents folder.
- `store/Install-StoreTest.ps1` — development-only helper that replaces a previous Store-test package, refreshes the temporary CI certificate trust, and installs the current MSIX.
- `.github/workflows/build-store-msix.yml` — builds a separate x64 Store-test EXE, stages the existing app files, creates an MSIX, signs it with an ephemeral development certificate, and uploads the MSIX + public certificate + test helpers as a CI artifact.
- `Test-Syntax.ps1` additionally validates the Store runtime function contract and WACK helper syntax so missing runtime helpers and helper-script parser errors are caught by CI.

## Important: development identity

`store/AppxManifest.xml` currently uses:

- Identity Name: `HypeTek.CPUThrottling.Dev`
- Publisher: `CN=HypeTek Development`

These values are only for sideload testing. Before a real Store submission, reserve the app name in Partner Center and replace the identity fields with the exact values assigned by Microsoft.

The temporary development certificate is self-signed. Windows App Installer requires it to be trusted in the **Local Computer / Trusted People** certificate store before the test MSIX can be installed. That one-time test setup requires administrator rights; the installed Store-test application itself runs non-elevated. A real Microsoft Store package is re-signed by Microsoft and does not need this development-certificate step.

## Real-hardware permission result

On 2026-09-11 the standard-user write probe was run from a **non-elevated** Windows PowerShell 5.1 session (`Elevated token: False`) against the active Balanced scheme (`381b4222-f694-41f0-9685-ff5bb260df2e`).

All supported writes succeeded without elevation:

- MinState AC/DC: `WRITE OK`
- MaxState AC/DC: `WRITE OK`
- MaxFrequency AC/DC: `WRITE OK`
- BoostMode AC/DC: `WRITE OK`
- CoolingPolicy AC/DC: `WRITE OK`
- Epp AC/DC: `WRITE OK`
- Apply active scheme: `OK`

Result: `PASS: Supported power-setting writes succeeded without elevation.`

This demonstrates that the tested Windows power-policy write path does not require administrator rights on the tested hardware.

## Packaged MSIX real-hardware result

The development MSIX from build run #22 installed successfully on Windows 11 x64 and launched normally from the Start menu without an application UAC prompt.

The initial packaged test exposed a missing runtime compatibility helper (`Get-ActivePowerScheme`). The Store branch now loads `StoreRuntimeCompat.ps1` before `Main.ps1` and CI validates the Store runtime contract from source. The corrected package was then retested successfully.

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

## Current Store CI

`Build Store Test MSIX` run #26 completed successfully on commit `c6a7dd797279a4ab4a91701a69b026ccb308527c` after the WACK helper and updated Store documentation were added. The workflow passed PowerShell 5.1 parser/runtime checks, non-elevated manifest validation, x64 EXE build, MSIX packaging, development signing, signature verification and artifact upload.

Run #26 artifact digest: `sha256:3dc64cf72c0a06354d023861e1f725cfc59aaad8745f83167fbc45e44d6679ae`.

## Windows App Certification Kit

Microsoft recommends running the Windows App Certification Kit before Store submission. The kit must run in the context of an active user session; therefore the final certification test is intentionally a local real-machine gate instead of being treated as a hosted CI substitute.

The Store artifact includes `Run-WackLocal.ps1`. With the current MSIX installed, open **Windows PowerShell 5.1 as Administrator** and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Run-WackLocal.ps1
```

The helper:

1. locates `appcert.exe`,
2. finds the installed `HypeTek.CPUThrottling.Dev` package,
3. resets WACK state,
4. runs the certification workflow against the installed package, and
5. writes a timestamped XML report under `Documents\HypeTek\CPU-Throttling\WACK`.

If `appcert.exe` is missing, install the current Windows SDK / Windows App Certification Kit first.

## Validation sequence

1. Install the latest Store-test artifact with `Install-StoreTest.ps1` as administrator.
2. Launch HypeTek CPU Throttling normally from Start and verify there is no application UAC prompt.
3. Verify GUI, telemetry, profile switching, editor apply and Windows energy-plan switching.
4. Reconfirm restart persistence and profile import/export.
5. Close the application.
6. Open Windows PowerShell 5.1 as Administrator and run `Run-WackLocal.ps1` from the extracted artifact folder.
7. Review the generated WACK XML/HTML report and fix any failing tests before Store submission.
8. Reserve the app name in Partner Center, replace the development identity with Microsoft's assigned identity/publisher values, finalize listing assets, rebuild and rerun WACK on the final candidate.

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
- [x] Source-aware CI runtime-contract test added for required power helpers.
- [x] Profile apply/editor apply retested successfully in the fixed MSIX.
- [x] Windows energy-plan interaction retested successfully in the fixed MSIX.
- [x] Tested CPU power/profile changes work without application UAC.
- [x] Local WACK runner added to the Store artifact.
- [x] Latest Store CI artifact (run #26) builds and signs successfully.
- [ ] Restart persistence and import/export explicitly reconfirmed in the packaged app.
- [ ] Windows App Certification Kit passes on the packaged build.
- [ ] Partner Center developer account ready.
- [ ] App name reserved and official Store identity copied into manifest.
- [ ] Final Store icons/screenshots/listing text prepared.
- [ ] Final candidate rebuilt with Store-assigned identity and revalidated.
- [ ] Store submission passes certification.
