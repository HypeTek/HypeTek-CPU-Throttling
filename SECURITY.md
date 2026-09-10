# Security

HypeTek CPU Throttling requires administrator rights because changing Windows power-policy values is a privileged operation.

The application changes documented Windows power-management settings. It does not intentionally modify CPU voltage, BIOS/UEFI settings or firmware.

The native EXE is currently not digitally code-signed. Windows SmartScreen may therefore show an unknown-publisher warning.

The native launcher does not bypass AppLocker, WDAC or comparable enterprise application-control policies.

Runtime data is stored below `%APPDATA%\HypeTek\CPU-Throttling` and logs below `%LOCALAPPDATA%\HypeTek\CPU-Throttling`. Older pre-release profile/settings data is imported non-destructively on first start when needed.

If you discover a security issue, avoid publishing credentials, private hostnames or other sensitive diagnostics in a public issue.
