# HypeTek CPU Throttling v0.2.0 – Test Checklist

## Start / rebrand
- `HypeTek-CPU-Throttling.exe` starts after UAC confirmation.
- No additional PowerShell console remains visible during normal EXE startup.
- Window title and header show **HypeTek CPU Throttling**.
- HypeTek icon is visible on the EXE and WPF window.

## Existing data
- Profiles are stored in `%APPDATA%\HypeTek\CPU-Throttling\profiles.json`.
- Existing pre-release profiles are imported automatically when the new profile file does not yet exist.
- Editing/saving a profile still works.
- `Start-CPU-Throttling.vbs` works as fallback.

## Live telemetry
- CPU load updates every few seconds.
- Current clock and max clock show plausible MHz values or `n/a`.
- UI remains responsive while telemetry refreshes.

## Active profile
- Apply a saved profile.
- After refresh the matching profile name appears in the live area.
- Matching profile button gets a green border.
- Manually changing Windows values should result in “Benutzerdefiniert / kein gespeichertes Profil” when no profile matches.

## Profile import/export
- Export all profiles to a JSON file.
- Import the exported file.
- Imported profiles are added with new IDs rather than overwriting existing profiles.

## Diagnostic export
- Export diagnostics to TXT.
- Verify it contains CPU/OS, energy plan, support flags, AC/DC values and live telemetry.
- It should not contain passwords or secrets.

## Power controls
- Apply a test profile.
- Verify supported values change.
- Restore “Letzte Werte”.
- Switch a Windows power plan and refresh.
- Test on battery only when using a laptop and after reviewing DC values.

## Safety
Do not use aggressive limits blindly. Test with known-safe values for the specific system.
- Temperature is intentionally not displayed; confirm no ACPI/temperature line appears in the live telemetry or diagnostics export.
