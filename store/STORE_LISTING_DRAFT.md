# Microsoft Store listing draft

Status: draft for Partner Center. Do not submit until the non-elevated real-hardware tests in `docs/MS_STORE.md` pass and the official Partner Center identity is applied.

Microsoft currently requires at least a description and one screenshot for an MSIX Store listing; four or more screenshots are recommended. A privacy-policy URL is required if the app collects or transmits personal information.

## de-DE

### Produktname

HypeTek CPU Throttling

### Kurzbeschreibung

Windows-Tool zum Verwalten von CPU-Energieeinstellungen und wiederverwendbaren Leistungsprofilen – mit Live-Auslastung, Taktanzeige und separaten Netz-/Akkuprofilen.

### Beschreibung

HypeTek CPU Throttling bietet eine übersichtliche Windows-Oberfläche für dokumentierte CPU-bezogene Einstellungen der Windows-Energieverwaltung.

Erstelle eigene Profile und wechsle mit wenigen Klicks zwischen unterschiedlichen Leistungs-, Temperatur- und Energiespar-Konfigurationen. Die App liest die vom System unterstützten Einstellungen aus und zeigt übersichtlich an, welche Optionen auf dem jeweiligen PC verfügbar sind.

Unterstützt werden unter anderem maximale Prozessorfrequenz, minimaler und maximaler Prozessorzustand, Processor Performance Boost Mode, System Cooling Policy und Energy Performance Preference (EPP). Netzbetrieb (AC) und Akkubetrieb (DC) können getrennt konfiguriert werden.

Die integrierte Live-Anzeige zeigt CPU-Auslastung und einen aus Windows-Leistungsdaten abgeleiteten aktuellen Takt. Profile können erstellt, aus aktuellen Systemwerten übernommen, bearbeitet, dupliziert, importiert und exportiert werden.

HypeTek CPU Throttling verändert keine CPU-Spannungen und keine BIOS-/UEFI-Overclocking-Einstellungen. Einzelne Windows-Energieoptionen können je nach CPU, Firmware, OEM und Treibern nicht verfügbar sein oder vom System ignoriert werden.

### Produktfeatures

CPU-Leistungsprofile mit Ein-Klick-Anwendung
Maximale CPU-Frequenz konfigurieren
Minimalen und maximalen Prozessorzustand verwalten
Turbo-/Boost-Modus konfigurieren
Energy Performance Preference (EPP)
Getrennte Werte für Netz- und Akkubetrieb
Installierte Windows-Energiepläne auswählen
Live-Anzeige für CPU-Auslastung und Takt
Profile erstellen, bearbeiten und duplizieren
Profile als JSON importieren und exportieren
Diagnoseinformationen als Textdatei exportieren
Anpassbares HypeTek Cyberpunk-Design
Windows 10 und Windows 11
Intel- und AMD-Unterstützung abhängig von Plattform und Firmware
Keine Änderung von CPU-Spannung oder BIOS-/UEFI-Overclocking

### Empfohlene Screenshots

1. Hauptfenster mit Live-Auslastung, Takt und aktivem Profil
2. Profil-Editor mit AC/DC-Einstellungen
3. Übersicht mehrerer gespeicherter Profile
4. Einstellungen / Hintergrund- und Darstellungsoptionen

### Suchbegriffe – Entwurf

CPU, Throttling, CPU Limit, Energieplan, Power Plan, CPU Frequency, CPU Boost, EPP, Prozessor, Windows Energieverwaltung

### Hinweise für Zertifizierung – Entwurf

HypeTek CPU Throttling modifies documented Windows processor power-policy settings only. It does not change CPU voltage, BIOS/UEFI settings, or perform traditional overclocking. Availability and behavior of individual settings depend on Windows, CPU, firmware, OEM and driver support.

The Store package is intended to run without elevation. Development sideload builds use a temporary self-signed certificate solely for local testing; this is not part of the final Microsoft Store distribution.

## en-US

### Product name

HypeTek CPU Throttling

### Short description

Windows utility for managing CPU power settings and reusable performance profiles, with live CPU load, clock telemetry, and separate AC/DC configuration.

### Description

HypeTek CPU Throttling provides a clear Windows interface for documented CPU-related Windows power-management settings.

Create reusable profiles and switch between performance, temperature and power-saving configurations with only a few clicks. The app reads the settings supported by the current system and shows which options are available on that PC.

Supported controls include maximum processor frequency, minimum and maximum processor state, Processor Performance Boost Mode, System Cooling Policy and Energy Performance Preference (EPP). AC and battery/DC values can be configured separately.

The built-in live panel displays CPU load and a current clock estimate derived from Windows performance data. Profiles can be created, captured from current system values, edited, duplicated, imported and exported.

HypeTek CPU Throttling does not change CPU voltage or BIOS/UEFI overclocking settings. Individual Windows power settings may be unavailable or ignored depending on the CPU, firmware, OEM configuration and drivers.

### Product features

One-click reusable CPU power profiles
Configure maximum CPU frequency
Manage minimum and maximum processor state
Configure processor boost mode
Energy Performance Preference (EPP)
Separate AC and battery/DC values
Select installed Windows power plans
Live CPU load and clock telemetry
Create, edit and duplicate profiles
Import and export profiles as JSON
Export diagnostic information to a text file
Customizable HypeTek cyberpunk appearance
Windows 10 and Windows 11
Intel and AMD support depending on platform and firmware
No CPU-voltage or BIOS/UEFI overclocking changes

### Recommended screenshots

1. Main window showing live load, clock and active profile
2. Profile editor with AC/DC settings
3. Saved profile overview
4. Appearance/settings dialog

### Search terms – draft

CPU, throttling, CPU limit, power plan, CPU frequency, CPU boost, EPP, processor, Windows power management

## Before submission

- Replace development package identity with the exact Partner Center identity.
- Complete the standard-user permission test on real hardware.
- Install and test the MSIX on Windows 10 and Windows 11.
- Capture final screenshots from the Store build.
- Decide whether a privacy-policy URL is required based on the final app behavior and Partner Center declarations.
- Run Windows App Certification Kit.
