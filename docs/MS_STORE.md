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

## What this branch adds

- `src/app.store.manifest` — native EXE manifest with `asInvoker`.
- `store/AppxManifest.xml` — development MSIX manifest for a packaged Win32 desktop app.
- `tools/Test-StandardUser-PowerWrite.ps1` — safe permission probe that writes the already configured values back to the active power scheme while running non-elevated.
- `store/Install-StoreTest.ps1` — development-only helper that replaces a previous Store-test package, refreshes the temporary CI certificate trust, and installs the current MSIX.
- `.github/workflows/build-store-msix.yml` — builds a separate x64 Store-test EXE, stages the existing app files, creates an MSIX, signs it with an ephemeral development certificate, and uploads the MSIX + public certificate + test installer as a CI artifact.
- `Test-Syntax.ps1` additionally validates the runtime function contract used by the UI so missing helper functions are caught by CI instead of only on real hardware.

## Important: development identity

`store/AppxManifest.xml` currently uses:

- Identity Name: `HypeTek.CPUThrottling.Dev`
- Publisher: `CN=HypeTek Development`

These values are only for sideload testing. Before a real Store submission, reserve the app name in Partner Center and replace the identity fields with the exact values assigned by Microsoft.

The temporary development certificate is self-signed. Windows App Installer requires it to be trusted in the **Local Computer / Trusted People** certificate store before the test MSIX can be installed. That one-time test setup requires administrator rights; the installed Store-test application itself must still run non-elevated. A real Microsoft Store package is re-signed by Microsoft and does not need this development-certificate step.

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

This proves that the current documented power-policy write path does not inherently require administrator rights on the tested hardware.

## First MSIX runtime result

The development MSIX installed successfully on a Windows 11 x64 test machine and the packaged application launched far enough to load the full GUI, telemetry, current Windows power scheme, compatibility flags, profiles and user data.

Applying a profile then exposed a code-level runtime defect: `Main.ps1` called `Get-ActivePowerScheme`, but no function with that name was loaded. This was **not** an elevation or MSIX sandbox failure; the lower-level non-elevated write probe had already proved the underlying power APIs work.

The Store branch now provides the missing active-scheme object helper and CI checks the required runtime function contract. The next artifact must be retested for profile apply, editor apply, power-scheme switching and persistence.

## Validation sequence

1. Run `tools\Test-StandardUser-PowerWrite.ps1` from a **non-elevated** Windows PowerShell 5.1 window.
2. All supported AC/DC settings should report `WRITE OK`, and `Apply active scheme` should report `OK`.
3. Download the latest `HypeTek-CPU-Throttling-Store-Test` workflow artifact.
4. Extract the artifact and run `Install-StoreTest.ps1` as administrator. The helper automatically removes an older Store-test package and stale temporary CI certificate before installing this build. User profiles/settings are not removed.
5. Launch HypeTek CPU Throttling normally from the Start menu. It must not show a UAC prompt.
6. Verify GUI launch, telemetry, profile load/save, AC/DC changes, editor apply, profile switching, Windows energy-plan switching, import/export and restart persistence without elevation.
7. After testing, uninstall the test package and remove the development certificate from Local Computer -> Trusted People.
8. Run Windows App Certification Kit before submission.

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
- [x] Missing active-power-scheme runtime helper found and fixed on Store branch.
- [x] CI runtime-contract test added for required power helpers.
- [ ] Profile apply/editor apply retested successfully in the fixed MSIX.
- [ ] Windows energy-plan switching retested successfully in the fixed MSIX.
- [ ] All power/profile features work without UAC.
- [ ] Restart persistence and import/export verified in the packaged app.
- [ ] Partner Center developer account ready.
- [ ] App name reserved and official Store identity copied into manifest.
- [ ] Final Store icons/screenshots/listing text prepared.
- [ ] Windows App Certification Kit passes.
- [ ] Store submission passes certification.
