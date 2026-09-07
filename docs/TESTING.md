# v0.1.7 Test Checklist

This is the first hardware test build. Please test on one profile at a time.

## Before testing

- Note the currently active Windows power plan.
- Keep a temperature/clock monitor open if available.
- Do not combine the first test with BIOS/XTU/Ryzen Master changes.

## Basic UI

- App requests administrator rights.
- First-run warning is shown once.
- CPU, Windows version and active power scheme are displayed.
- Compatibility indicators appear for Freq / Boost / Min / Max / Cooling / EPP.
- Example profiles appear as buttons.

## Profile workflow

1. Click **Aktuelle Werte als Profil**.
2. Give it a name and save it.
3. Right-click it and choose **Bearbeiten**.
4. Change one harmless value, save again and confirm the same button updates.
5. Duplicate the profile.
6. Delete the duplicate.

## Z2 / i7-8700 reference test

For Hype's current test system, the known useful starting point is:

- AC max frequency: 3900 MHz
- AC minimum processor state: 5%
- AC maximum processor state: 100%
- Boost mode: Enabled (1)
- Cooling policy: Active (1)

EPP can be left at the currently detected value for the first functional test.

After applying, verify the frequency limit with your normal monitoring tool and run a short workload before a long gaming session.

## Restore

After applying any profile, use **Letzte Werte** and verify that the previous power values return.

## If something behaves unexpectedly

Windows Control Panel power options or `powercfg` can still be used to restore a normal power plan. Selecting another standard Windows power plan and activating it is also a useful sanity check.


## Windows-Energiepläne

1. Prüfen, ob die Auswahlliste mindestens den aktuell aktiven Windows-Energieplan zeigt.
2. Wenn mehrere Pläne vorhanden sind, einen anderen Plan auswählen und `Aktivieren` klicken.
3. Prüfen, ob der Name oben aktualisiert wird und Windows den Plan tatsächlich als aktiv meldet.
4. Einen selbst erstellten Windows-Energieplan testen, falls vorhanden.
5. Im Live-Protokoll muss `PowerSetActiveScheme` sowie der äquivalente `powercfg /setactive <GUID>`-Befehl erscheinen.


## Storage paths

- Profile storage: `%APPDATA%\CPUPowerControl\profiles.json`
- Startup log: `%LOCALAPPDATA%\CPUPowerControl\logs\startup.log`
- Verify that no vendor-specific parent directory is created for application data.
