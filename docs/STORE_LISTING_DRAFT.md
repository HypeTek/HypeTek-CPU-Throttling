# Microsoft Store listing draft — HypeTek CPU Throttling

> Draft for Partner Center. Final text can be adjusted after the packaged build passes real-hardware and WACK testing.

## German

### Product name
HypeTek CPU Throttling

### Short description
Windows-GUI zum Verwalten unterstützter CPU-Energieparameter und wiederverwendbarer Leistungsprofile.

### Description
HypeTek CPU Throttling ist eine Windows-Oberfläche zum Lesen und Anpassen dokumentierter CPU-bezogener Energieverwaltungswerte des aktuell aktiven Windows-Energieplans.

Die App kann unter anderem maximale CPU-Frequenz, minimalen und maximalen Prozessorzustand, Turbo-/Boost-Verhalten, Kühlrichtlinie und Energy Performance Preference (EPP) verwalten, sofern Windows, CPU, Firmware und OEM diese Einstellungen bereitstellen.

Eigene Profile lassen sich speichern und mit einem Klick anwenden. Zusätzlich zeigt die App Live-Werte für CPU-Auslastung und Takt, erkennt passende Profile und unterstützt Import, Export und Diagnoseausgaben.

Die Anwendung verändert keine CPU-Spannungen und keine BIOS-/UEFI-Overclocking-Einstellungen.

### Feature bullets
- CPU-Energieparameter für AC und Akku/DC verwalten
- Maximale CPU-Frequenz und Prozessorzustände einstellen
- Turbo-/Boost-Modus, Kühlrichtlinie und EPP verwalten
- Eigene Leistungsprofile erstellen, speichern und anwenden
- Installierte Windows-Energiepläne auswählen
- Live-Anzeige für CPU-Auslastung und Takt
- Profile importieren und exportieren
- Diagnoseinformationen als Textdatei exportieren
- HypeTek-Oberfläche mit anpassbarem Hintergrund

### Notes / compatibility
Windows 10 und Windows 11, primär x64. Einzelne Optionen sind abhängig von Windows-Version, CPU, Firmware und OEM-Unterstützung.

## English

### Product name
HypeTek CPU Throttling

### Short description
Windows GUI for managing supported CPU power-policy settings and reusable performance profiles.

### Description
HypeTek CPU Throttling is a Windows desktop interface for reading and adjusting documented CPU-related power-management values in the currently active Windows power plan.

Depending on support from Windows, the CPU, firmware and OEM implementation, the app can manage maximum processor frequency, minimum and maximum processor state, turbo/boost behavior, cooling policy and Energy Performance Preference (EPP).

Reusable profiles can be created, stored and applied with one click. The app also provides live CPU load and clock information, detects matching profiles, and supports profile import/export and diagnostic exports.

The application does not modify CPU voltages or BIOS/UEFI overclocking settings.

### Feature bullets
- Manage CPU power-policy values for AC and battery/DC
- Configure maximum CPU frequency and processor states
- Manage turbo/boost mode, cooling policy and EPP
- Create, save and apply reusable performance profiles
- Select installed Windows power plans
- Live CPU load and clock display
- Import and export profiles
- Export diagnostic information
- Customizable HypeTek interface and background

### Notes / compatibility
Windows 10 and Windows 11, primarily x64. Individual options depend on Windows version, CPU, firmware and OEM support.

## Screenshot plan

Recommended captures after MSIX validation:

1. Main window with live telemetry and profile overview.
2. Profile editor showing frequency, processor-state, boost, cooling and EPP controls.
3. Appearance/settings dialog with the HypeTek wallpaper visible.
4. Main window after a profile has been applied, showing matching active values.

Do not include personal paths, usernames, serial numbers, machine names or unrelated desktop content in Store screenshots.

## Certification note draft

HypeTek CPU Throttling modifies documented Windows power-policy values for the active power scheme. It does not modify CPU voltage or BIOS/UEFI settings. The Microsoft Store build is packaged as a Win32 desktop application and runs without requesting elevation. A real-hardware permission test confirmed that all currently supported power-policy writes and activation of the current power scheme succeed from a non-elevated Windows PowerShell 5.1 session on the tested system. Hardware and firmware may ignore unsupported settings; the application detects availability where possible.
