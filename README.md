# HypeTek CPU Power Control

A lightweight Windows GUI for managing CPU-related Windows power policy settings and saving them as one-click profiles.

**Version:** 0.1.5-power-schemes (test build)  
**Author:** HypeTek

## What it does

- Maximum processor frequency in MHz (`PROCFREQMAX`)
- Minimum processor state (`PROCTHROTTLEMIN`)
- Maximum processor state (`PROCTHROTTLEMAX`)
- Processor performance boost mode (`PERFBOOSTMODE`)
- System cooling policy (`SYSCOOLPOL`)
- Energy Performance Preference / EPP (`PERFEPP`)
- Separate AC and battery/DC values
- Create, rename, edit, duplicate and delete profiles
- Save the current Windows values as a new profile
- One-click profile buttons
- Restore the values from immediately before the last profile application
- Shows equivalent `powercfg` commands for transparency
- Detects whether each Windows power setting can be read on the current platform
- Lists all installed Windows power schemes, including user-created schemes, and switches them from the GUI

## Quick start (Deutsch)

1. ZIP entpacken.
2. `Start-CPU-Power-Control.cmd` doppelklicken. Der Starter verwendet im Hintergrund `Start-CPU-Power-Control.vbs`, damit kein PowerShell-/Konsolenfenster offen bleibt.
3. UAC-Abfrage bestätigen. Danach sollte nur das WPF-App-Fenster sichtbar sein.
4. Beim ersten Start den Sicherheits-/Kompatibilitätshinweis lesen.
5. Beispielprofile **nicht blind übernehmen** – Werte an die eigene CPU anpassen.

Die eigentlichen Profile werden unter

`%APPDATA%\HypeTek\CPUPowerControl\profiles.json`

gespeichert.

## Compatibility

### PowerShell requirement

- **PowerShell 7 is not required.**
- The normal launcher deliberately uses the built-in **Windows PowerShell 5.1** (`powershell.exe`) for maximum Windows 10/11 compatibility.
- Version 0.1.2 fixes a UTF-8-without-BOM source encoding problem that could make Windows PowerShell 5.1 report misleading parser errors such as missing quotes/braces.
- `Test-Syntax.cmd` can be used to parse-check all PowerShell source files with the PowerShell version installed on the PC.


- Windows 10 desktop editions
- Windows 11 desktop editions
- Primarily tested/designed for x64 Windows
- Intel and AMD CPUs are supported in principle **when Windows, the CPU and platform firmware expose and honor the corresponding power policy setting**.

A setting being readable by Windows does **not** guarantee that every CPU/firmware combination will obey it. Modern hybrid CPUs, OEM Dynamic Tuning frameworks and vendor utilities may override or ignore some limits.

### Windows documentation basis

The project uses documented Windows processor power policy settings, including `PROCFREQMAX`, `PROCTHROTTLEMIN`, `PROCTHROTTLEMAX` and `PERFBOOSTMODE`. The application writes through the Windows Power Policy API and then re-activates the current power scheme.

## Safety / disclaimer

**Use at your own risk.**

HypeTek CPU Power Control changes Windows power-management policy values. It does **not** change CPU core voltage, BIOS/UEFI settings or traditional overclocking parameters.

Nevertheless, unsuitable settings can cause:

- reduced performance
- unusual clock behavior
- increased power consumption or temperatures
- instability on some systems
- conflicts with OEM/vendor power-management software

The software is provided without warranty; HypeTek is not responsible for damage, data loss, instability or other consequences resulting from its use.

## Maximum frequency and `0`

The GUI accepts `0` for maximum frequency to represent the platform/default state commonly used by Windows power schemes (effectively no additional MHz cap). Explicit limits may be entered from 100 to 64000 MHz.

## Boost mode values

- `0` Disabled
- `1` Enabled
- `2` Aggressive
- `3` Efficient enabled
- `4` Efficient aggressive

Not every mode behaves differently on every CPU. The platform ultimately decides what is supported.

## Repository structure

```text
HypeTek-CPU-Power-Control/
├─ CPU-Power-Control.ps1
├─ Start-CPU-Power-Control.cmd
├─ Start-CPU-Power-Control.vbs
├─ src/
│  ├─ Main.ps1
│  ├─ MainWindow.xaml
│  ├─ PowerCfg.ps1
│  └─ ProfileManager.ps1
├─ examples/
│  └─ profiles.example.json
├─ README.md
├─ CHANGELOG.md
├─ SECURITY.md
├─ LICENSE
└─ .gitignore
```

## Current limitations of v0.1.5-power-schemes

- First public test build; not yet tested across many CPU generations.
- Hybrid-core-specific frequency controls (`PROCFREQMAX1` etc.) are not yet exposed separately.
- No vendor-specific Intel XTU / AMD Ryzen Master controls.
- No voltage control by design.
- No temperature monitoring yet.
- CPU profiles are applied to whichever Windows power scheme is active at the moment they are clicked. Windows power schemes can now be switched separately from the GUI.

## Planned next steps

- Wider Intel/AMD compatibility testing
- Better hybrid P-core/E-core awareness
- Import/export profiles
- Optional portable profile storage
- Diagnostic export for GitHub issues
- Signed release / packaged executable after the script build is stable

## License

MIT. See `LICENSE`.

## Startup troubleshooting (0.1.2-ps51-fix)
If the program cannot start, it now shows the actual exception instead of silently closing.
A log is written to:

`%LOCALAPPDATA%\HypeTek\CPUPowerControl\logs\startup.log`

For troubleshooting you can also start `Start-Debug.cmd`.


## v0.1.3 Live-Ausführung

Der Bereich **Erweiterte Informationen** trennt nun die Editor-Vorschau vom tatsächlichen Anwenden eines Profils. Beim Klick auf einen Profilbutton protokolliert die App die Power-Policy-API-Schreibvorgänge und zeigt dazu die äquivalenten `powercfg`-Befehle.


## v0.1.4 Single-Window-Start

Der normale Starter startet Windows PowerShell 5.1 jetzt versteckt und fordert die Administratorrechte direkt über einen kleinen VBScript-Launcher an. Nach der UAC-Abfrage bleibt nur die WPF-Anwendung sichtbar. `Start-Debug.cmd` öffnet absichtlich weiterhin ein Konsolenfenster und ist nur für Fehlersuche gedacht.


## v0.1.5 Windows-Energiepläne

Die Anwendung listet nun die unter Windows gespeicherten Energiepläne über die integrierte `powercfg /list`-Schnittstelle auf. Das umfasst auch selbst angelegte oder von OEM-Software hinzugefügte Pläne, sofern Windows sie in der normalen Energieplanliste führt. Der ausgewählte Plan wird über die Windows Power Policy API aktiviert; im Live-Protokoll erscheint zusätzlich der äquivalente `powercfg /setactive <GUID>`-Befehl.

Die HypeTek-CPU-Profile und die Windows-Energiepläne bleiben bewusst getrennt: Ein CPU-Profil verändert die CPU-Werte des aktuell aktiven Windows-Energieplans.
