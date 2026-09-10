# HypeTek CPU Throttling v0.2.0

First stable release of **HypeTek CPU Throttling**.

## Highlights

- Native `HypeTek-CPU-Throttling.exe` launcher with UAC elevation and HypeTek icon
- PowerShell/WPF core runs without a visible console during normal startup
- Main window is brought to the foreground after launch
- Live CPU utilization and dynamic clock estimate
- Active MHz limit and matching-profile detection
- Profile create/edit/duplicate/delete/import/export
- Diagnostic export
- HypeTek cyberpunk default appearance and configurable wallpapers
- Optional editor warning in Settings
- CPU temperature intentionally omitted unless a reliable external sensor provider is integrated
- No manual unhide of the Windows `PROCFREQMAX` GUI setting is required

## Data storage

```text
%APPDATA%\HypeTek\CPU-Throttling\profiles.json
%APPDATA%\HypeTek\CPU-Throttling\settings.json
%LOCALAPPDATA%\HypeTek\CPU-Throttling\logs\startup.log
```

Older pre-release profile, settings and appearance data is imported non-destructively on first start when the new files do not yet exist.

## Release package

```text
HypeTek-CPU-Throttling-v0.2.0/
├─ HypeTek-CPU-Throttling.exe
├─ README.md
└─ app/
   └─ application core / resources / troubleshooting files
```

## Requirements

Windows 10/11. Administrator rights are required to change Windows power-policy values.

## SmartScreen

The executable is not digitally code-signed, so Windows may show an unknown-publisher or SmartScreen warning on some systems.

## License

MIT License — Copyright © 2026 HypeTek
