# Changelog

## 0.1.7-ui-fix - 2026-09-07

- Profil-Editor responsiver gemacht
- Checkbox "Akkubetrieb (DC) mit anwenden" in eine eigene Zeile verschoben, damit der Text auch bei kleineren Fensterbreiten vollständig sichtbar bleibt
- Tooltip für die DC-Profiloption ergänzt
- Versionsanzeige auf v0.1.7-ui-fix aktualisiert

## 0.1.6-storage-cleanup - 2026-09-07

- Profilpfad auf `%APPDATA%\CPUPowerControl\profiles.json` bereinigt
- Startup-Logpfad auf `%LOCALAPPDATA%\CPUPowerControl\logs\startup.log` bereinigt
- internen Power-API-Namespace auf den neutralen Namen `CpuPowerControl.PowerApi` umgestellt
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
- neuer `Start-CPU-Power-Control.vbs`-Launcher fordert UAC an und startet PowerShell 5.1 versteckt
- `Start-CPU-Power-Control.cmd` ist jetzt nur noch ein kurzer Wrapper zum versteckten Launcher
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
