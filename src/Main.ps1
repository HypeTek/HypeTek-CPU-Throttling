Set-StrictMode -Version Latest
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Initialize-AppData

$settings = Get-AppSettings
if (-not $settings.DisclaimerAccepted) {
    $text = @"
HypeTek CPU Power Control verändert Windows-Energieverwaltungsparameter des aktuell aktiven Energieplans.

Es verändert keine CPU-Spannungen und keine BIOS-/UEFI-Overclocking-Einstellungen. Falsche oder unpassende Werte können jedoch Leistung, Temperatur, Energieverbrauch oder Stabilität beeinflussen. Manche CPUs/Firmwares ignorieren einzelne Windows-Limits.

Unterstützt: Windows 10/11, primär x64. Intel und AMD, sofern die jeweilige Einstellung von Windows/Plattform bereitgestellt wird.

Nutzung auf eigene Gefahr.

Fortfahren?
"@
    $answer = [System.Windows.MessageBox]::Show($text, 'HypeTek CPU Power Control – Hinweis', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }
    $settings.DisclaimerAccepted = $true
    Save-AppSettings -Settings $settings
}

$xamlPath = Join-Path $PSScriptRoot 'MainWindow.xaml'
[xml]$xaml = Get-Content $xamlPath -Raw -Encoding UTF8
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$names = @(
    'btnRefresh','btnAbout','txtCpu','txtOs','txtScheme','cmbPowerSchemes','btnApplyPowerScheme','txtCurrentValues','txtSupport','btnNew','btnFromCurrent','btnRestore','wrpProfiles',
    'txtProfileName','chkApplyDC','numMaxFreqAC','numMaxFreqDC','numMinStateAC','numMinStateDC','numMaxStateAC','numMaxStateDC',
    'cmbBoostAC','cmbBoostDC','cmbCoolingAC','cmbCoolingDC','numEppAC','numEppDC','btnSaveProfile','btnApplyEditor','txtExecutionLog','txtCommandPreview','txtStatus'
)
$ui = @{}
foreach ($name in $names) { $ui[$name] = $window.FindName($name) }

$boostItems = @(
    [pscustomobject]@{ Label='0 – Aus'; Value=0 },
    [pscustomobject]@{ Label='1 – Ein'; Value=1 },
    [pscustomobject]@{ Label='2 – Aggressiv'; Value=2 },
    [pscustomobject]@{ Label='3 – Effizient aktiviert'; Value=3 },
    [pscustomobject]@{ Label='4 – Effizient aggressiv'; Value=4 }
)
$coolingItems = @(
    [pscustomobject]@{ Label='0 – Passiv'; Value=0 },
    [pscustomobject]@{ Label='1 – Aktiv'; Value=1 }
)
foreach ($combo in @($ui.cmbBoostAC,$ui.cmbBoostDC)) {
    $combo.ItemsSource = $boostItems
    $combo.DisplayMemberPath = 'Label'
    $combo.SelectedValuePath = 'Value'
}
foreach ($combo in @($ui.cmbCoolingAC,$ui.cmbCoolingDC)) {
    $combo.ItemsSource = $coolingItems
    $combo.DisplayMemberPath = 'Label'
    $combo.SelectedValuePath = 'Value'
}

$script:Profiles = @(Get-Profiles)
$script:SelectedProfileId = $null
$script:LastSnapshot = $null
$script:CurrentState = $null
$script:PowerSchemes = @()

function Set-Status([string]$Text, [bool]$Error = $false) {
    $ui.txtStatus.Text = $Text
    $brush = if ($Error) { [System.Windows.Media.Brushes]::LightCoral } else { [System.Windows.Media.Brushes]::LightGreen }
    $ui.txtStatus.Foreground = $brush
}

function Add-ExecutionLog([string]$Text, [bool]$Clear = $false) {
    if ($Clear) { $ui.txtExecutionLog.Clear() }
    $stamp = Get-Date -Format 'HH:mm:ss.fff'
    $lines = @([string]$Text -split '\r?\n')
    foreach ($line in $lines) {
        $ui.txtExecutionLog.AppendText("[$stamp] $line$([Environment]::NewLine)")
    }
    $ui.txtExecutionLog.ScrollToEnd()
}

function Get-EquivalentCommandForSetting {
    param(
        [Parameter(Mandatory)][string]$Setting,
        [Parameter(Mandatory)][ValidateSet('AC','DC')][string]$Source,
        [Parameter(Mandatory)][uint32]$Value,
        [Parameter(Mandatory)][Guid]$SchemeGuid
    )
    $aliases = @{
        MaxFrequency = 'PROCFREQMAX'
        MinState = 'PROCTHROTTLEMIN'
        MaxState = 'PROCTHROTTLEMAX'
        BoostMode = 'PERFBOOSTMODE'
        CoolingPolicy = 'SYSCOOLPOL'
        Epp = 'PERFEPP'
    }
    $verb = if ($Source -eq 'AC') { '/setacvalueindex' } else { '/setdcvalueindex' }
    return "powercfg $verb $SchemeGuid SUB_PROCESSOR $($aliases[$Setting]) $Value"
}

function Get-IntFromBox($Box, [string]$Label, [int64]$Min, [int64]$Max, [bool]$AllowZero=$false) {
    [int64]$value = 0
    if (-not [int64]::TryParse($Box.Text.Trim(), [ref]$value)) { throw "$Label muss eine ganze Zahl sein." }
    if ($AllowZero -and $value -eq 0) { return 0 }
    if ($value -lt $Min -or $value -gt $Max) { throw "$Label muss zwischen $Min und $Max liegen." }
    return $value
}

function Get-EditorProfile {
    $name = $ui.txtProfileName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { throw 'Bitte einen Profilnamen eingeben.' }

    $acMin = Get-IntFromBox $ui.numMinStateAC 'Min. CPU-State AC' 0 100
    $acMax = Get-IntFromBox $ui.numMaxStateAC 'Max. CPU-State AC' 0 100
    $dcMin = Get-IntFromBox $ui.numMinStateDC 'Min. CPU-State DC' 0 100
    $dcMax = Get-IntFromBox $ui.numMaxStateDC 'Max. CPU-State DC' 0 100
    if ($acMin -gt $acMax) { throw 'AC: Min. CPU-State darf nicht größer als Max. CPU-State sein.' }
    if ($dcMin -gt $dcMax) { throw 'DC: Min. CPU-State darf nicht größer als Max. CPU-State sein.' }

    [pscustomobject]@{
        Id = if ($script:SelectedProfileId) { $script:SelectedProfileId } else { [guid]::NewGuid().ToString() }
        Name = $name
        ApplyDC = [bool]$ui.chkApplyDC.IsChecked
        AC = [pscustomobject]@{
            MaxFrequency = Get-IntFromBox $ui.numMaxFreqAC 'Max. Frequenz AC' 100 64000 $true
            MinState = $acMin
            MaxState = $acMax
            BoostMode = [int]$ui.cmbBoostAC.SelectedValue
            CoolingPolicy = [int]$ui.cmbCoolingAC.SelectedValue
            Epp = Get-IntFromBox $ui.numEppAC 'EPP AC' 0 100
        }
        DC = [pscustomobject]@{
            MaxFrequency = Get-IntFromBox $ui.numMaxFreqDC 'Max. Frequenz DC' 100 64000 $true
            MinState = $dcMin
            MaxState = $dcMax
            BoostMode = [int]$ui.cmbBoostDC.SelectedValue
            CoolingPolicy = [int]$ui.cmbCoolingDC.SelectedValue
            Epp = Get-IntFromBox $ui.numEppDC 'EPP DC' 0 100
        }
    }
}

function Set-EditorFromProfile($Profile) {
    $script:SelectedProfileId = $Profile.Id
    $ui.txtProfileName.Text = $Profile.Name
    $ui.chkApplyDC.IsChecked = [bool]$Profile.ApplyDC
    $ui.numMaxFreqAC.Text = [string]$Profile.AC.MaxFrequency
    $ui.numMinStateAC.Text = [string]$Profile.AC.MinState
    $ui.numMaxStateAC.Text = [string]$Profile.AC.MaxState
    $ui.cmbBoostAC.SelectedValue = [int]$Profile.AC.BoostMode
    $ui.cmbCoolingAC.SelectedValue = [int]$Profile.AC.CoolingPolicy
    $ui.numEppAC.Text = [string]$Profile.AC.Epp
    $ui.numMaxFreqDC.Text = [string]$Profile.DC.MaxFrequency
    $ui.numMinStateDC.Text = [string]$Profile.DC.MinState
    $ui.numMaxStateDC.Text = [string]$Profile.DC.MaxState
    $ui.cmbBoostDC.SelectedValue = [int]$Profile.DC.BoostMode
    $ui.cmbCoolingDC.SelectedValue = [int]$Profile.DC.CoolingPolicy
    $ui.numEppDC.Text = [string]$Profile.DC.Epp
    Update-CommandPreview
}

function New-EditorProfile {
    $script:SelectedProfileId = $null
    $ui.txtProfileName.Text = 'Neues Profil'
    $ui.chkApplyDC.IsChecked = $false
    $ui.numMaxFreqAC.Text='3900'; $ui.numMinStateAC.Text='5'; $ui.numMaxStateAC.Text='100'; $ui.cmbBoostAC.SelectedValue=1; $ui.cmbCoolingAC.SelectedValue=1; $ui.numEppAC.Text='25'
    $ui.numMaxFreqDC.Text='3200'; $ui.numMinStateDC.Text='5'; $ui.numMaxStateDC.Text='90'; $ui.cmbBoostDC.SelectedValue=0; $ui.cmbCoolingDC.SelectedValue=1; $ui.numEppDC.Text='60'
    Update-CommandPreview
}

function Get-ValueOrDefault($Value, $Default) {
    if ($null -eq $Value) { return $Default }
    return $Value
}

function Convert-StateToProfile($State, [string]$Name='Aktueller Zustand') {
    [pscustomobject]@{
        Id = [guid]::NewGuid().ToString(); Name=$Name; ApplyDC=$true
        AC = [pscustomobject]@{
            MaxFrequency=[int64](Get-ValueOrDefault $State.AC.MaxFrequency 0); MinState=[int64](Get-ValueOrDefault $State.AC.MinState 5); MaxState=[int64](Get-ValueOrDefault $State.AC.MaxState 100)
            BoostMode=[int](Get-ValueOrDefault $State.AC.BoostMode 1); CoolingPolicy=[int](Get-ValueOrDefault $State.AC.CoolingPolicy 1); Epp=[int](Get-ValueOrDefault $State.AC.Epp 50)
        }
        DC = [pscustomobject]@{
            MaxFrequency=[int64](Get-ValueOrDefault $State.DC.MaxFrequency 0); MinState=[int64](Get-ValueOrDefault $State.DC.MinState 5); MaxState=[int64](Get-ValueOrDefault $State.DC.MaxState 100)
            BoostMode=[int](Get-ValueOrDefault $State.DC.BoostMode 1); CoolingPolicy=[int](Get-ValueOrDefault $State.DC.CoolingPolicy 1); Epp=[int](Get-ValueOrDefault $State.DC.Epp 50)
        }
    }
}

function Invoke-ApplyProfile($Profile, [bool]$TakeSnapshot=$true) {
    try {
        Add-ExecutionLog "=== Profil '$($Profile.Name)' ===" $true
        Add-ExecutionLog 'Lese aktuellen Energieplan und unterstützte Einstellungen ...'

        if ($TakeSnapshot) {
            $stateBefore = Get-SystemPowerState
            $script:LastSnapshot = Convert-StateToProfile $stateBefore 'Vorheriger Zustand'
            $ui.btnRestore.IsEnabled = $true
            Add-ExecutionLog 'Snapshot der vorherigen Werte erstellt.'
        }

        $state = Get-SystemPowerState
        $scheme = $state.SchemeGuid
        Add-ExecutionLog "Aktiver Energieplan: $($state.SchemeName) ($scheme)"

        $map = @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')
        $skipped = New-Object 'System.Collections.Generic.List[string]'
        foreach ($key in $map) {
            if ($state.Support.$key) {
                [uint32]$value = [uint32]$Profile.AC.$key
                Add-ExecutionLog "WRITE API  AC  $key = $value"
                Set-PowerSettingValue -Setting $key -Source AC -Value $value -SchemeGuid $scheme
                Add-ExecutionLog ("  -> " + (Get-EquivalentCommandForSetting -Setting $key -Source AC -Value $value -SchemeGuid $scheme))
            }
            else {
                $skipped.Add("$key/AC")
                Add-ExecutionLog "SKIP       AC  $key (nicht unterstützt)"
            }
        }
        if ($Profile.ApplyDC) {
            foreach ($key in $map) {
                if ($state.Support.$key) {
                    [uint32]$value = [uint32]$Profile.DC.$key
                    Add-ExecutionLog "WRITE API  DC  $key = $value"
                    Set-PowerSettingValue -Setting $key -Source DC -Value $value -SchemeGuid $scheme
                    Add-ExecutionLog ("  -> " + (Get-EquivalentCommandForSetting -Setting $key -Source DC -Value $value -SchemeGuid $scheme))
                }
                else {
                    $skipped.Add("$key/DC")
                    Add-ExecutionLog "SKIP       DC  $key (nicht unterstützt)"
                }
            }
        }
        else {
            Add-ExecutionLog 'DC/Akkubetrieb: laut Profil nicht anwenden.'
        }

        Add-ExecutionLog 'APPLY      PowerSetActiveScheme'
        Apply-ActiveScheme -SchemeGuid $scheme
        Add-ExecutionLog "  -> powercfg /setactive $scheme"

        Refresh-State
        $suffix = if ($skipped.Count) { " Übersprungen: $($skipped -join ', ')." } else { '' }
        Add-ExecutionLog "FERTIG     Profil '$($Profile.Name)' angewendet.$suffix"
        Set-Status "Profil '$($Profile.Name)' angewendet.$suffix"
    }
    catch {
        Add-ExecutionLog "FEHLER     $($_.Exception.Message)"
        Set-Status "Fehler beim Anwenden: $($_.Exception.Message)" $true
        [System.Windows.MessageBox]::Show($_.Exception.Message, 'Fehler', 'OK', 'Error') | Out-Null
    }
}

function Refresh-PowerSchemeList {
    try {
        $script:PowerSchemes = @(Get-PowerSchemes)
        $ui.cmbPowerSchemes.ItemsSource = $script:PowerSchemes
        $ui.cmbPowerSchemes.DisplayMemberPath = 'DisplayName'
        $ui.cmbPowerSchemes.SelectedValuePath = 'GuidText'
        if ($script:CurrentState) {
            $ui.cmbPowerSchemes.SelectedValue = $script:CurrentState.SchemeGuid.ToString()
        }
        $ui.btnApplyPowerScheme.IsEnabled = ($script:PowerSchemes.Count -gt 0)
    }
    catch {
        $ui.cmbPowerSchemes.ItemsSource = $null
        $ui.btnApplyPowerScheme.IsEnabled = $false
        Set-Status "Energiepläne konnten nicht gelesen werden: $($_.Exception.Message)" $true
    }
}

function Invoke-SwitchPowerScheme {
    try {
        $selected = $ui.cmbPowerSchemes.SelectedItem
        if (-not $selected) { throw 'Bitte einen Windows-Energieplan auswählen.' }
        [Guid]$targetGuid = $selected.Guid
        [Guid]$currentGuid = Get-ActiveSchemeGuid

        if ($targetGuid -eq $currentGuid) {
            Set-Status "Energieplan '$($selected.Name)' ist bereits aktiv."
            return
        }

        $currentName = Get-ActiveSchemeName -SchemeGuid $currentGuid
        Add-ExecutionLog '=== Windows-Energieplan wechseln ===' $true
        Add-ExecutionLog "VON        $currentName ($currentGuid)"
        Add-ExecutionLog "NACH       $($selected.Name) ($targetGuid)"
        Add-ExecutionLog 'APPLY API  PowerSetActiveScheme'
        Apply-ActiveScheme -SchemeGuid $targetGuid
        Add-ExecutionLog "  -> powercfg /setactive $targetGuid"

        Refresh-State
        Add-ExecutionLog "FERTIG     Energieplan '$($selected.Name)' aktiviert."
        Set-Status "Energieplan '$($selected.Name)' aktiviert."
    }
    catch {
        Add-ExecutionLog "FEHLER     $($_.Exception.Message)"
        Set-Status "Energieplan konnte nicht gewechselt werden: $($_.Exception.Message)" $true
        [System.Windows.MessageBox]::Show($_.Exception.Message, 'Energieplan wechseln', 'OK', 'Error') | Out-Null
    }
}

function Update-CommandPreview {
    try {
        if (-not $script:CurrentState) { return }
        $profile = Get-EditorProfile
        $ui.txtCommandPreview.Text = ((Get-EquivalentPowerCfgCommands -Profile $profile -SchemeGuid $script:CurrentState.SchemeGuid) -join [Environment]::NewLine)
    }
    catch {
        $ui.txtCommandPreview.Text = "Vorschau nicht verfügbar: $($_.Exception.Message)"
    }
}

function Refresh-State {
    try {
        $script:CurrentState = Get-SystemPowerState
        $s = $script:CurrentState
        $ui.txtCpu.Text = "CPU: $($s.CpuName)"
        $ui.txtOs.Text = "$($s.OsName) · $($s.Architecture) · Build $($s.OsVersion)"
        $ui.txtScheme.Text = "$($s.SchemeName)`n$($s.SchemeGuid)"
        $freqText = if ($null -eq $s.AC.MaxFrequency) { 'n/a' } elseif ([int64]$s.AC.MaxFrequency -eq 0) { 'Unlimited' } else { "$($s.AC.MaxFrequency) MHz" }
        $boostText = if ($null -eq $s.AC.BoostMode) { 'n/a' } elseif ([int]$s.AC.BoostMode -eq 0) { 'Aus' } else { "Ein (Mode $($s.AC.BoostMode))" }
        $ui.txtCurrentValues.Text = "AC: $freqText · Turbo $boostText · Min/Max $($s.AC.MinState)/$($s.AC.MaxState)% · EPP $($s.AC.Epp)"
        $supportParts = @()
        foreach ($pair in @(@('MaxFrequency','Freq'),@('BoostMode','Boost'),@('MinState','Min'),@('MaxState','Max'),@('CoolingPolicy','Cooling'),@('Epp','EPP'))) {
            if ($s.Support.($pair[0])) { $supportParts += "$($pair[1]) ✓" }
            else { $supportParts += "$($pair[1]) ✗" }
        }
        $ui.txtSupport.Text = ($supportParts -join ' · ')
        Refresh-PowerSchemeList
        Update-CommandPreview
        Set-Status 'Systemwerte aktualisiert.'
    }
    catch {
        Set-Status "Systemwerte konnten nicht gelesen werden: $($_.Exception.Message)" $true
    }
}

function Find-ProfileById([string]$Id) {
    return ($script:Profiles | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
}

function Render-Profiles {
    $ui.wrpProfiles.Children.Clear()
    foreach ($profile in $script:Profiles) {
        $button = New-Object System.Windows.Controls.Button
        $button.Width = 190; $button.Height = 82; $button.Tag = $profile.Id
        $panel = New-Object System.Windows.Controls.StackPanel
        $title = New-Object System.Windows.Controls.TextBlock; $title.Text=$profile.Name; $title.FontWeight=[System.Windows.FontWeights]::SemiBold; $title.FontSize=14; $title.TextWrapping=[System.Windows.TextWrapping]::Wrap
        $sub = New-Object System.Windows.Controls.TextBlock; $sub.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#CBD5E1'); $sub.Margin=[System.Windows.Thickness]::new(0,5,0,0)
        $freq = if ([int64]$profile.AC.MaxFrequency -eq 0) { 'Unlimited' } else { "$($profile.AC.MaxFrequency) MHz" }
        $boost = if ([int]$profile.AC.BoostMode -eq 0) { 'Turbo OFF' } else { 'Turbo ON' }
        $sub.Text = "$freq · $boost"
        [void]$panel.Children.Add($title); [void]$panel.Children.Add($sub); $button.Content=$panel
        $button.Add_Click({ param($sender,$eventArgs) $p = Find-ProfileById ([string]$sender.Tag); if ($p) { Invoke-ApplyProfile $p } })

        $menu = New-Object System.Windows.Controls.ContextMenu
        foreach ($entry in @(@('Bearbeiten','edit'),@('Duplizieren','dup'),@('Löschen','delete'))) {
            $item = New-Object System.Windows.Controls.MenuItem; $item.Header=$entry[0]; $item.Tag="$($profile.Id)|$($entry[1])"
            $item.Add_Click({
                param($sender,$eventArgs)
                $parts = [string]$sender.Tag -split '\|',2; $p = Find-ProfileById $parts[0]; if (-not $p) { return }
                switch ($parts[1]) {
                    'edit' { Set-EditorFromProfile $p; Set-Status "Profil '$($p.Name)' im Editor geöffnet." }
                    'dup' {
                        $copy = [pscustomobject]@{ Id=[guid]::NewGuid().ToString(); Name="$($p.Name) – Kopie"; ApplyDC=[bool]$p.ApplyDC; AC=$p.AC; DC=$p.DC }
                        $script:Profiles += $copy; Save-Profiles $script:Profiles; Render-Profiles; Set-EditorFromProfile $copy
                    }
                    'delete' {
                        $ans=[System.Windows.MessageBox]::Show("Profil '$($p.Name)' wirklich löschen?",'Profil löschen','YesNo','Question')
                        if ($ans -eq 'Yes') { $script:Profiles=@($script:Profiles | Where-Object {$_.Id -ne $p.Id}); Save-Profiles $script:Profiles; Render-Profiles; New-EditorProfile }
                    }
                }
            })
            [void]$menu.Items.Add($item)
        }
        $button.ContextMenu=$menu
        [void]$ui.wrpProfiles.Children.Add($button)
    }
}

$ui.btnRefresh.Add_Click({ Refresh-State })
$ui.btnApplyPowerScheme.Add_Click({ Invoke-SwitchPowerScheme })
$ui.btnNew.Add_Click({ New-EditorProfile; Set-Status 'Neues Profil im Editor.' })
$ui.btnFromCurrent.Add_Click({
    try { $p=Convert-StateToProfile (Get-SystemPowerState) 'Mein aktuelles Profil'; $script:SelectedProfileId=$null; Set-EditorFromProfile $p; $script:SelectedProfileId=$null; Set-Status 'Aktuelle Werte in den Editor übernommen.' }
    catch { Set-Status $_.Exception.Message $true }
})
$ui.btnRestore.Add_Click({ if ($script:LastSnapshot) { Invoke-ApplyProfile $script:LastSnapshot $false } })
$ui.btnSaveProfile.Add_Click({
    try {
        $p=Get-EditorProfile
        $existing=Find-ProfileById $p.Id
        if ($existing) {
            $script:Profiles=@($script:Profiles | ForEach-Object { if ($_.Id -eq $p.Id) { $p } else { $_ } })
        } else { $script:Profiles += $p; $script:SelectedProfileId=$p.Id }
        Save-Profiles $script:Profiles; Render-Profiles; Set-Status "Profil '$($p.Name)' gespeichert."
    } catch { Set-Status $_.Exception.Message $true; [System.Windows.MessageBox]::Show($_.Exception.Message,'Ungültige Werte','OK','Warning') | Out-Null }
})
$ui.btnApplyEditor.Add_Click({ try { Invoke-ApplyProfile (Get-EditorProfile) } catch { Set-Status $_.Exception.Message $true } })
$ui.btnAbout.Add_Click({
    $msg=@"
HypeTek CPU Power Control v0.1.5-power-schemes
by HypeTek

Kompatibilität
• Windows 10 / Windows 11
• primär x64
• Intel und AMD grundsätzlich möglich
• einzelne Optionen nur, wenn Windows/CPU/Firmware sie bereitstellen bzw. beachten

Die App kann installierte Windows-Energiepläne wechseln und CPU-Energieverwaltungswerte im jeweils aktiven Energieplan ändern. Keine CPU-Spannungen, keine BIOS-/UEFI-Parameter, kein klassisches Overclocking.

Wichtig: Auch gültige Windows-Werte können auf einzelnen Plattformen ignoriert werden oder zu ungewohntem Takt-/Temperaturverhalten führen. Nutzung auf eigene Gefahr.

Profile: $script:ProfilesPath
"@
    [System.Windows.MessageBox]::Show($msg,'Info / Kompatibilität','OK','Information') | Out-Null
})

foreach ($control in @($ui.txtProfileName,$ui.chkApplyDC,$ui.numMaxFreqAC,$ui.numMaxFreqDC,$ui.numMinStateAC,$ui.numMinStateDC,$ui.numMaxStateAC,$ui.numMaxStateDC,$ui.cmbBoostAC,$ui.cmbBoostDC,$ui.cmbCoolingAC,$ui.cmbCoolingDC,$ui.numEppAC,$ui.numEppDC)) {
    if ($control -is [System.Windows.Controls.TextBox]) { $control.Add_TextChanged({ Update-CommandPreview }) }
    elseif ($control -is [System.Windows.Controls.ComboBox]) { $control.Add_SelectionChanged({ Update-CommandPreview }) }
    elseif ($control -is [System.Windows.Controls.CheckBox]) { $control.Add_Click({ Update-CommandPreview }) }
}

$ui.txtExecutionLog.Text = "Noch keine Profiländerung in dieser Sitzung ausgeführt.$([Environment]::NewLine)"
New-EditorProfile
Render-Profiles
Refresh-State
[void]$window.ShowDialog()
