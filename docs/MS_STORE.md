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
- `store/Install-StoreTest.ps1` — development-only helper that trusts the temporary test certificate and installs the MSIX.
- `.github/workflows/build-store-msix.yml` — builds a separate x64 Store-test EXE, stages the existing app files, creates an MSIX, signs it with an ephemeral development certificate, and uploads the MSIX + public certificate + test installer as a CI artifact.

## Important: development identity

`store/AppxManifest.xml` currently uses:

- Identity Name: `HypeTek.CPUThrottling.Dev`
- Publisher: `CN=HypeTek Development`

These values are only for sideload testing. Before a real Store submission, reserve the app name in Partner Center and replace the identity fields with the exact values assigned by Microsoft.

The temporary development certificate is self-signed. Windows App Installer requires it to be trusted in the **Local Computer / Trusted People** certificate store before the test MSIX can be installed. That one-time test setup requires administrator rights; the installed Store-test application itself must still run non-elevated. A real Microsoft Store package is re-signed by Microsoft and does not need this development-certificate step.

## Validation sequence

1. Run `tools\Test-StandardUser-PowerWrite.ps1` from a **non-elevated** Windows PowerShell 5.1 window.
2. All supported AC/DC settings should report `WRITE OK`, and `Apply active scheme` should report `OK`.
3. Download the `HypeTek-CPU-Throttling-Store-Test` workflow artifact.
4. Extract the artifact and run `Install-StoreTest.ps1` as administrator. The elevation is only used to trust the temporary development certificate and install the test package.
5. Launch HypeTek CPU Throttling normally from the Start menu. It must not show a UAC prompt.
6. Verify GUI launch, telemetry, profile load/save, AC/DC changes, profile switching, and restart persistence without elevation.
7. After testing, uninstall the test package and remove the development certificate from Local Computer -> Trusted People.
8. Run Windows App Certification Kit before submission.

If step 1 fails with access denied on supported settings, stop: the no-elevation Store path needs redesign before submission.

## Store-readiness checklist

- [x] Stable `main` branch kept separate.
- [x] Non-elevated Store EXE manifest.
- [x] Development MSIX manifest.
- [x] Dedicated CI build for MSIX.
- [x] Sideload signing for test artifacts.
- [x] Standard-user power-write permission probe.
- [x] Development-only test installer for certificate trust + MSIX install.
- [ ] Standard-user permission probe passes on real target hardware.
- [ ] MSIX installs and runs on Windows 10/11 test machines.
- [ ] All power/profile features work without UAC.
- [ ] Partner Center developer account ready.
- [ ] App name reserved and official Store identity copied into manifest.
- [ ] Final Store icons/screenshots/listing text prepared.
- [ ] Windows App Certification Kit passes.
- [ ] Store submission passes certification.
