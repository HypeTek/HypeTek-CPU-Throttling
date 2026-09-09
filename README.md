# HypeTek CPU Throttling

Windows GUI for controlling documented CPU-related Windows power-policy settings with reusable one-click profiles.

**Version:** 0.2.0  
**Author:** HypeTek

## Quick start

1. Download and fully extract the Windows release ZIP.
2. Double-click **`HypeTek-CPU-Throttling.exe`** in the top-level folder.
3. Confirm the Windows UAC prompt.
4. On first start, confirm the safety notice.
5. Adjust the example profiles for your own CPU before relying on them.

The release package is intentionally simple:

```text
HypeTek-CPU-Throttling-v0.2.0/
├─ HypeTek-CPU-Throttling.exe
├─ README.md
└─ app/
   ├─ CPU-Throttling.ps1
   ├─ Start-CPU-Throttling.cmd
   ├─ resources/
   ├─ src/
   └─ ...
```

## Highlights

- Rebranded from **HypeTek CPU Power Control** to **HypeTek CPU Throttling**
- Native Windows **EXE** as the recommended launcher
- UAC elevation handled by the EXE
- No visible PowerShell console during normal EXE startup
- Main window is brought to the foreground on startup
- Live CPU load and dynamic clock estimate
- Visible active Windows frequency limit
- Automatic matching of saved profiles to currently read Windows values
- Create, edit, duplicate, delete, import and export profiles
- Diagnostic text export
- HypeTek cyberpunk default wallpaper plus custom backgrounds
- Fill / Fit / Stretch background modes and adjustable dimming
- Optional yellow editor warning can be disabled in **Einstellungen**
- Existing v0.1.x profiles/settings remain compatible

## What it controls

The application changes documented Windows processor power-policy values in the currently active Windows energy plan:

- Maximum processor frequency (`PROCFREQMAX`)
- Minimum processor state (`PROCTHROTTLEMIN`)
- Maximum processor state (`PROCTHROTTLEMAX`)
- Processor performance boost mode (`PERFBOOSTMODE`)
- System cooling policy (`SYSCOOLPOL`)
- Energy Performance Preference / EPP (`PERFEPP`)
- Separate AC and battery/DC values
- Installed Windows power-scheme selection

It does **not** change CPU voltage, BIOS/UEFI settings or traditional overclocking controls.

### No manual Windows setting unlock required

You do **not** need to unhide the advanced MHz option in the classic Windows power-options dialog before using the app. HypeTek CPU Throttling reads and writes the Windows power-policy setting directly. If `Freq ✓` is shown in the compatibility panel, the frequency limit is available to the app even when Windows hides the setting from its own GUI.

## Live telemetry

The top panel refreshes approximately once per second and shows:

- CPU load from low-overhead Windows `GetSystemTimes` deltas
- current clock derived from Windows `% Processor Performance × base clock`
- the currently configured Windows maximum-frequency limit

CPU temperature is intentionally **not** shown. Reliable CPU-package/core temperatures on Windows generally require an additional hardware-monitoring source such as LibreHardwareMonitor or HWiNFO. Generic ACPI thermal-zone values are not treated as CPU-package temperature.

The live clock is an operating-system estimate and can differ slightly from Task Manager or dedicated monitoring tools because sampling methods and timestamps differ.

## Einstellungen / appearance

Use **Einstellungen** to configure:

- bundled HypeTek standard wallpaper
- custom wallpaper
- Fill / Fit / Stretch mode
- background dimming
- visibility of the yellow editor warning

**Standarddesign** resets only wallpaper, image mode and dimming. It does not modify CPU profiles or Windows power settings.

## Profile management

Profiles can be created, captured from current Windows values, edited, duplicated, deleted, imported from JSON and exported to JSON. A profile whose stored values match the currently read Windows values is highlighted and shown as the active HypeTek profile.

## Data compatibility

To avoid losing existing profiles during the rebrand, v0.2.0 intentionally keeps the existing runtime paths:

```text
%APPDATA%\CPUPowerControl\profiles.json
%APPDATA%\CPUPowerControl\settings.json
%LOCALAPPDATA%\CPUPowerControl\logs\startup.log
```

No destructive migration is performed.

## Requirements

- Windows 10 or Windows 11
- Administrator rights for power-policy changes
- Windows PowerShell 5.1 components included with Windows
- .NET Framework / WPF components included with Windows
- Intel or AMD CPU; individual settings depend on Windows, CPU, firmware and OEM support

## Safety

Use at your own risk. Valid Windows power-policy values can still reduce performance, increase temperatures or power use, behave differently across CPUs, or be overridden by OEM/vendor power-management software.

## License

MIT License — Copyright © 2026 HypeTek
