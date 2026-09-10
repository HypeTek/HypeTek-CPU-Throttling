# Changelog

## 0.2.0 - 2026-09-10

### Final release
- Product name finalized as **HypeTek CPU Throttling** across the application, launchers and documentation.
- Runtime data moved to `%APPDATA%\HypeTek\CPU-Throttling` and logs to `%LOCALAPPDATA%\HypeTek\CPU-Throttling`.
- Older pre-release profile/settings/appearance data is imported non-destructively when the new files do not yet exist.
- Internal native power API namespace standardized on `CpuThrottling`.
- Legacy launcher filenames removed from the final release package.
- Native EXE, PowerShell fallback launchers, README and test documentation aligned to v0.2.0.
- CPU temperature remains intentionally omitted until a reliable hardware-sensor provider is available.

## 0.2.0-preview4 - 2026-09-09

### Changed
- Removed CPU temperature display entirely.
- Removed ACPI/WMI thermal-zone polling from runtime telemetry.
- Removed temperature from diagnostics export.
- Kept dynamic clock, CPU load telemetry and Preview 3 design system unchanged.
- Temperature telemetry is deliberately deferred until a reliable hardware-sensor provider is integrated.

## 0.2.0-preview3 - 2026-09-09

### Telemetry
- Live clock derives from `% Processor Performance × nominal/base clock` so Intel/AMD Turbo can be represented above 100% of base frequency
- CPU load sampling moved to low-overhead `GetSystemTimes` deltas to reduce self-induced WMI/CIM overhead
- ACPI thermal-zone polling reduced to every five seconds
- temperature label explicitly states `ACPI-Zone ≠ CPU-Package`

### Appearance
- bundled current HypeTek/Bookmarker cyberpunk default wallpaper
- high-resolution generic HypeTek header logo and matched frame
- custom wallpaper selection
- Fill / Fit / Stretch background modes
- adjustable dimming
- non-destructive `Standarddesign` reset
- old settings automatically receive appearance defaults without profile migration


## 0.2.0-preview - 2026-09-09

### Rebrand
- Product name transitioned to **HypeTek CPU Throttling**
- New HypeTek application icon and new primary launcher names
- Pre-release runtime data remained compatible during the transition

### Added
- Native `HypeTek-CPU-Throttling.exe` launcher source/build
- Live CPU load and current/max clock telemetry
- Best-effort ACPI/WMI thermal-zone temperature display
- Active saved-profile detection and matching-profile highlight
- Profile import/export as JSON
- Diagnostic text export
- New `Start-CPU-Throttling.cmd` and `.vbs` fallback launchers

### Compatibility
- Existing profiles and settings remain compatible
- Transitional launcher wrappers were retained during preview testing
- Native EXE requests administrator rights but does not bypass AppLocker/WDAC

## 0.1.7-ui-fix - 2026-09-07

- Profil-Editor responsiver gemacht
- Checkbox "Akkubetrieb (DC) mit anwenden" in eine eigene Zeile verschoben, damit der Text auch bei kleineren Fensterbreiten vollständig sichtbar bleibt
- Tooltip für die DC-Profiloption ergänzt
- Versionsanzeige auf v0.1.7-ui-fix aktualisiert

## 0.1.6-storage-cleanup - 2026-09-07

- Profilpfad in den damaligen Laufzeitdaten bereinigt
- Startup-Logpfad in den damaligen Laufzeitdaten bereinigt
- internen Power-API-Namespace vereinheitlicht
- README und Testdokumentation auf die neuen Laufzeitpfade aktualisiert
- Versionsanzeige auf v0.1.6-storage-cleanup aktualisiert

## 0.1.5-power-schemes - 2026-09-07
- Auswahl und Aktivierung aller von Windows gelisteten Energiepläne direkt in der GUI
- eigene / benutzerdefinierte Windows-Energiepläne werden ebenfalls angezeigt, sofern `powercfg /list` sie führt
- Wechsel des Windows-Energieplans wird im Live-Protokoll mit äquivalentem `powercfg /setactive` dokumentiert
- Autorenangabe und Programmdokumentation auf HypeTek vereinheitlicht
- Versionsanzeige auf v0.1.5-power-schemes aktualisiert

## 0.1.4-single-window - 2026-09-07
- normaler Start ohne dauerhaft sichtbares PowerShell-/Konsolenfenster
- neuer versteckter VBS-Launcher fordert UAC an und startet PowerShell 5.1
- CMD-Launcher ist jetzt nur noch ein kurzer Wrapper zum versteckten Launcher
- direkte interne Relaunches verwenden ebenfalls `-WindowStyle Hidden`
- `Start-Debug.cmd` bleibt absichtlich sichtbar für Fehlersuche

## 0.1.3-live-log - 2026-09-07
- Live-Ausführungsprotokoll beim Anwenden von Profilen.
- Zeigt jeden Power Policy API-Schreibvorgang und den äquivalenten `powercfg`-Befehl.
- Editor-Vorschau und tatsächliche Ausführung sind jetzt klar getrennt.
- Versionsanzeige auf v0.1.3-live-log korrigiert.

## 0.1.2-ps51-fix — 2026-09-07
- fixed Windows PowerShell 5.1 parser crash caused by UTF-8 source files without BOM
- all `.ps1` source files are now stored as UTF-8 with BOM
- XAML is also stored as UTF-8 with BOM for consistent Unicode handling
- added `Test-Syntax.cmd` / `Test-Syntax.ps1` parser self-test
- clarified that PowerShell 7 is not required

## 0.1.1-hotfix — 2026-09-07
- startup crash diagnostics added
- WPF is now explicitly launched in STA mode
- fatal startup errors are shown in a message box and logged
- added `Start-Debug.cmd`
- improved Windows PowerShell 5.1 compatibility for WPF object creation
- safer explicit WPF type conversions for dynamically created controls

## 0.1.0 — 2026-09-07
- initial test build
- WPF profile manager
- Windows power settings and named profile buttons
