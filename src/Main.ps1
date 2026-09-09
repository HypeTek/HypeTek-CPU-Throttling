Set-StrictMode -Version Latest
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Initialize-AppData

$settings = Get-AppSettings
if (-not $settings.DisclaimerAccepted) {
    $text = @"
HypeTek CPU Throttling verändert Windows-Energieverwaltungsparameter des aktuell aktiven Energieplans.

Es verändert keine CPU-Spannungen und keine BIOS-/UEFI-Overclocking-Einstellungen. Falsche oder unpassende Werte können jedoch Leistung, Temperatur, Energieverbrauch oder Stabilität beeinflussen. Manche CPUs/Firmwares ignorieren einzelne Windows-Limits.

Unterstützt: Windows 10/11, primär x64. Intel und AMD, sofern die jeweilige Einstellung von Windows/Plattform bereitgestellt wird.

Nutzung auf eigene Gefahr.

Fortfahren?
"@
    $answer = [System.Windows.MessageBox]::Show($text, 'HypeTek CPU Throttling – Hinweis', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }
    $settings.DisclaimerAccepted = $true
    Save-AppSettings -Settings $settings
}

$script:AppSettings = $settings

$script:InstallRoot = if ($env:HYPETEK_CPU_THROTTLING_BASEDIR) {
    $env:HYPETEK_CPU_THROTTLING_BASEDIR
} else {
    Split-Path -Parent $PSScriptRoot
}
$xamlPath = Join-Path $script:InstallRoot 'src\MainWindow.xaml'
[xml]$xaml = Get-Content $xamlPath -Raw -Encoding UTF8
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)


$names = @(
    'btnRefresh','btnAppearance','btnDiagnostics','btnAbout','imgAppLogo','imgBackground','bgDimOverlay','txtCpu','txtOs','txtLiveLoad','txtLiveClock','txtActiveProfile','txtScheme','cmbPowerSchemes','btnApplyPowerScheme','txtCurrentValues','txtSupport','txtPowerWarning',
    'btnNew','btnFromCurrent','btnRestore','btnImportProfiles','btnExportProfiles','wrpProfiles',
    'txtProfileName','chkApplyDC','numMaxFreqAC','numMaxFreqDC','numMinStateAC','numMinStateDC','numMaxStateAC','numMaxStateDC',
    'cmbBoostAC','cmbBoostDC','cmbCoolingAC','cmbCoolingDC','numEppAC','numEppDC','btnSaveProfile','btnApplyEditor','txtExecutionLog','txtCommandPreview','txtStatus'
)
$ui = @{}
foreach ($name in $names) { $ui[$name] = $window.FindName($name) }

$logoPath = Join-Path $script:InstallRoot 'resources\app-logo.jpg'
if ($ui.imgAppLogo -and (Test-Path -LiteralPath $logoPath)) {
    try {
        $logoBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $logoBitmap.BeginInit()
        $logoBitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $logoBitmap.UriSource = New-Object System.Uri($logoPath, [System.UriKind]::Absolute)
        $logoBitmap.EndInit()
        $logoBitmap.Freeze()
        $ui.imgAppLogo.Source = $logoBitmap
        $window.Icon = $logoBitmap
    } catch { }
}


function Load-BitmapNoLock {
    param([Parameter(Mandatory)][string]$Path)
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.UriSource = New-Object System.Uri($Path, [System.UriKind]::Absolute)
    $bitmap.EndInit()
    $bitmap.Freeze()
    return $bitmap
}

function Get-ResolvedBackgroundPath {
    $value = [string]$script:AppSettings.BackgroundImage
    if ([string]::IsNullOrWhiteSpace($value)) { return $null }
    if ($value -eq '@default') {
        $defaultPath = Join-Path $script:InstallRoot 'resources\default-wallpaper.jpg'
        if (Test-Path -LiteralPath $defaultPath) { return $defaultPath }
        return $null
    }
    if (Test-Path -LiteralPath $value) { return $value }
    return $null
}

function Apply-Appearance {
    try {
        $path = Get-ResolvedBackgroundPath
        if ($ui.imgBackground) {
            if ($path) { $ui.imgBackground.Source = Load-BitmapNoLock -Path $path }
            else { $ui.imgBackground.Source = $null }

            switch ([string]$script:AppSettings.BackgroundMode) {
                'Fit'     { $ui.imgBackground.Stretch = [System.Windows.Media.Stretch]::Uniform }
                'Stretch' { $ui.imgBackground.Stretch = [System.Windows.Media.Stretch]::Fill }
                default   { $ui.imgBackground.Stretch = [System.Windows.Media.Stretch]::UniformToFill }
            }
        }

        [double]$dim = 52
        try { $dim = [double]$script:AppSettings.BackgroundDim } catch { }
        $dim = [math]::Max(0,[math]::Min(85,$dim))
        if ($ui.bgDimOverlay) { $ui.bgDimOverlay.Opacity = $dim / 100.0 }
    } catch { }
}

function Save-AppearanceSettings {
    Save-AppSettings -Settings $script:AppSettings
    Apply-Appearance
}

function Apply-EditorHintVisibility {
    if (-not $ui.txtPowerWarning) { return }
    $show = $true
    try { $show = [bool]$script:AppSettings.ShowEditorHint } catch { }
    $ui.txtPowerWarning.Visibility = if ($show) {
        [System.Windows.Visibility]::Visible
    } else {
        [System.Windows.Visibility]::Collapsed
    }
}

function Show-AppearanceDialog {
    $d = New-Object System.Windows.Window
    $d.Title = 'HypeTek CPU Throttling – Einstellungen'
    $d.Width = 570
    $d.Height = 445
    $d.MinWidth = 520
    $d.ResizeMode = 'NoResize'
    $d.WindowStartupLocation = 'CenterOwner'
    $d.Owner = $window
    $d.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#0B1220')
    $d.Foreground = [System.Windows.Media.Brushes]::White
    $d.FontFamily = 'Segoe UI'
    if ($window.Icon) { $d.Icon = $window.Icon }


    function Set-DialogButtonStyle {
        param($Button,[string]$Background='#1F2937',[string]$Border='#40556E')
        $Button.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString($Background)
        $Button.Foreground=[System.Windows.Media.Brushes]::White
        $Button.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString($Border)
        $Button.BorderThickness=[System.Windows.Thickness]::new(1)
        $Button.Cursor='Hand'
    }

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new(18)
    $gridLengthConverter = New-Object System.Windows.GridLengthConverter
    foreach ($h in @('Auto','Auto','Auto','Auto','*','Auto')) {
        $row = New-Object System.Windows.Controls.RowDefinition
        $row.Height = $gridLengthConverter.ConvertFromString($h)
        [void]$grid.RowDefinitions.Add($row)
    }

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = 'Einstellungen'
    $title.FontSize = 22
    $title.FontWeight = [System.Windows.FontWeights]::SemiBold
    $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#60A5FA')
    [System.Windows.Controls.Grid]::SetRow($title,0)
    [void]$grid.Children.Add($title)

    $desc = New-Object System.Windows.Controls.TextBlock
    $desc.Text = 'Erscheinungsbild und optionale Hinweise der Oberfläche.'
    $desc.Margin = [System.Windows.Thickness]::new(0,4,0,12)
    $desc.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#CBD5E1')
    $desc.TextWrapping = 'Wrap'
    [System.Windows.Controls.Grid]::SetRow($desc,1)
    [void]$grid.Children.Add($desc)

    $bgPanel = New-Object System.Windows.Controls.StackPanel
    $bgPanel.Orientation = 'Horizontal'
    $bgPanel.Margin = [System.Windows.Thickness]::new(0,2,0,8)
    $btnChoose = New-Object System.Windows.Controls.Button
    $btnChoose.Content = 'Bild auswählen'
    $btnChoose.Padding = [System.Windows.Thickness]::new(12,7,12,7)
    $btnChoose.Margin = [System.Windows.Thickness]::new(0,0,8,0)
    $btnDefault = New-Object System.Windows.Controls.Button
    $btnDefault.Content = 'HypeTek Standard-Wallpaper'
    $btnDefault.Padding = [System.Windows.Thickness]::new(12,7,12,7)
    $btnDefault.Margin = [System.Windows.Thickness]::new(0,0,8,0)
    $btnNone = New-Object System.Windows.Controls.Button
    $btnNone.Content = 'Kein Bild'
    $btnNone.Padding = [System.Windows.Thickness]::new(12,7,12,7)
    Set-DialogButtonStyle $btnChoose
    Set-DialogButtonStyle $btnDefault
    Set-DialogButtonStyle $btnNone
    [void]$bgPanel.Children.Add($btnChoose); [void]$bgPanel.Children.Add($btnDefault); [void]$bgPanel.Children.Add($btnNone)
    [System.Windows.Controls.Grid]::SetRow($bgPanel,2)
    [void]$grid.Children.Add($bgPanel)

    $form = New-Object System.Windows.Controls.Grid
    $form.Margin = [System.Windows.Thickness]::new(0,5,0,0)
    $c1=New-Object System.Windows.Controls.ColumnDefinition; $c1.Width=[System.Windows.GridLength]::new(160)
    $c2=New-Object System.Windows.Controls.ColumnDefinition; $c2.Width=[System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
    [void]$form.ColumnDefinitions.Add($c1); [void]$form.ColumnDefinitions.Add($c2)
    foreach ($i in 0..2) { $r=New-Object System.Windows.Controls.RowDefinition; $r.Height=[System.Windows.GridLength]::Auto; [void]$form.RowDefinitions.Add($r) }

    $lblCurrent=New-Object System.Windows.Controls.TextBlock; $lblCurrent.Text='Hintergrund'; $lblCurrent.Margin=[System.Windows.Thickness]::new(0,7,8,7)
    $txtCurrent=New-Object System.Windows.Controls.TextBlock
    $current = [string]$script:AppSettings.BackgroundImage
    $txtCurrent.Text = if ($current -eq '@default') { 'HypeTek Standard-Wallpaper' } elseif ([string]::IsNullOrWhiteSpace($current)) { 'Kein Hintergrundbild' } else { [System.IO.Path]::GetFileName($current) }
    $txtCurrent.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#A7F3D0'); $txtCurrent.Margin=[System.Windows.Thickness]::new(0,7,0,7); $txtCurrent.TextTrimming='CharacterEllipsis'
    [System.Windows.Controls.Grid]::SetRow($lblCurrent,0); [System.Windows.Controls.Grid]::SetColumn($lblCurrent,0)
    [System.Windows.Controls.Grid]::SetRow($txtCurrent,0); [System.Windows.Controls.Grid]::SetColumn($txtCurrent,1)
    [void]$form.Children.Add($lblCurrent); [void]$form.Children.Add($txtCurrent)

    $lblMode=New-Object System.Windows.Controls.TextBlock; $lblMode.Text='Bildanpassung'; $lblMode.Margin=[System.Windows.Thickness]::new(0,7,8,7)
    $cmbMode=New-Object System.Windows.Controls.ComboBox; $cmbMode.Margin=[System.Windows.Thickness]::new(0,4,0,4); $cmbMode.MinWidth=200
    foreach ($entry in @('Ausfüllen','Einpassen','Strecken')) { [void]$cmbMode.Items.Add($entry) }
    switch ([string]$script:AppSettings.BackgroundMode) { 'Fit'{$cmbMode.SelectedIndex=1};'Stretch'{$cmbMode.SelectedIndex=2};default{$cmbMode.SelectedIndex=0} }
    [System.Windows.Controls.Grid]::SetRow($lblMode,1); [System.Windows.Controls.Grid]::SetColumn($lblMode,0)
    [System.Windows.Controls.Grid]::SetRow($cmbMode,1); [System.Windows.Controls.Grid]::SetColumn($cmbMode,1)
    [void]$form.Children.Add($lblMode); [void]$form.Children.Add($cmbMode)

    $lblDim=New-Object System.Windows.Controls.TextBlock; $lblDim.Text='Abdunklung'; $lblDim.Margin=[System.Windows.Thickness]::new(0,7,8,7)
    $dimWrap=New-Object System.Windows.Controls.StackPanel; $dimWrap.Orientation='Horizontal'
    $sldDim=New-Object System.Windows.Controls.Slider; $sldDim.Minimum=0; $sldDim.Maximum=85; $sldDim.TickFrequency=5; $sldDim.IsSnapToTickEnabled=$true; $sldDim.Width=245; $sldDim.Value=[double]$script:AppSettings.BackgroundDim
    $txtDim=New-Object System.Windows.Controls.TextBlock; $txtDim.Width=60; $txtDim.Margin=[System.Windows.Thickness]::new(12,5,0,0); $txtDim.Text="$([int]$sldDim.Value)%"
    [void]$dimWrap.Children.Add($sldDim); [void]$dimWrap.Children.Add($txtDim)
    [System.Windows.Controls.Grid]::SetRow($lblDim,2); [System.Windows.Controls.Grid]::SetColumn($lblDim,0)
    [System.Windows.Controls.Grid]::SetRow($dimWrap,2); [System.Windows.Controls.Grid]::SetColumn($dimWrap,1)
    [void]$form.Children.Add($lblDim); [void]$form.Children.Add($dimWrap)
    [System.Windows.Controls.Grid]::SetRow($form,3)
    [void]$grid.Children.Add($form)

    $options = New-Object System.Windows.Controls.StackPanel
    $options.Margin = [System.Windows.Thickness]::new(0,14,0,8)
    $chkShowEditorHint = New-Object System.Windows.Controls.CheckBox
    $chkShowEditorHint.Content='Hinweistext im Profil-Editor anzeigen'
    $chkShowEditorHint.IsChecked=[bool]$script:AppSettings.ShowEditorHint
    $chkShowEditorHint.Foreground=[System.Windows.Media.Brushes]::White
    $chkShowEditorHint.Margin=[System.Windows.Thickness]::new(0,0,0,6)
    $hint = New-Object System.Windows.Controls.TextBlock
    $hint.Text='Der gelbe Hinweis erinnert daran, dass Windows-Power-Settings je nach CPU/Firmware teilweise ignoriert werden können.'
    $hint.TextWrapping='Wrap'
    $hint.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#94A3B8')
    $hint.FontSize=12
    [void]$options.Children.Add($chkShowEditorHint)
    [void]$options.Children.Add($hint)
    [System.Windows.Controls.Grid]::SetRow($options,4)
    [void]$grid.Children.Add($options)

    $bottom = New-Object System.Windows.Controls.DockPanel
    $btnReset = New-Object System.Windows.Controls.Button; $btnReset.Content='Standarddesign'; $btnReset.Padding=[System.Windows.Thickness]::new(12,7,12,7)
    $btnClose = New-Object System.Windows.Controls.Button; $btnClose.Content='Schließen'; $btnClose.Padding=[System.Windows.Thickness]::new(18,7,18,7)
    Set-DialogButtonStyle $btnReset '#182235' '#40556E'; Set-DialogButtonStyle $btnClose '#075985' '#0EA5E9'
    [System.Windows.Controls.DockPanel]::SetDock($btnReset,'Left'); [System.Windows.Controls.DockPanel]::SetDock($btnClose,'Right')
    [void]$bottom.Children.Add($btnReset); [void]$bottom.Children.Add($btnClose)
    [System.Windows.Controls.Grid]::SetRow($bottom,5)
    [void]$grid.Children.Add($bottom)

    $sldDim.Add_ValueChanged({ $txtDim.Text="$([int]$sldDim.Value)%" })
    $btnChoose.Add_Click({
        $fd = New-Object Microsoft.Win32.OpenFileDialog
        $fd.Filter='Bilder|*.jpg;*.jpeg;*.png;*.bmp;*.webp|Alle Dateien|*.*'
        if ($fd.ShowDialog() -eq $true) {
            $script:AppSettings.BackgroundImage=[string]$fd.FileName
            $txtCurrent.Text=[System.IO.Path]::GetFileName($fd.FileName)
            Save-AppearanceSettings
        }
    })
    $btnDefault.Add_Click({ $script:AppSettings.BackgroundImage='@default'; $txtCurrent.Text='HypeTek Standard-Wallpaper'; Save-AppearanceSettings })
    $btnNone.Add_Click({ $script:AppSettings.BackgroundImage=''; $txtCurrent.Text='Kein Hintergrundbild'; Save-AppearanceSettings })
    $cmbMode.Add_SelectionChanged({
        switch ($cmbMode.SelectedIndex) { 1{$script:AppSettings.BackgroundMode='Fit'};2{$script:AppSettings.BackgroundMode='Stretch'};default{$script:AppSettings.BackgroundMode='Fill'} }
        Save-AppearanceSettings
    })
    $sldDim.Add_ValueChanged({ $script:AppSettings.BackgroundDim=[int]$sldDim.Value; Save-AppearanceSettings })
    $chkShowEditorHint.Add_Click({
        $script:AppSettings.ShowEditorHint=[bool]$chkShowEditorHint.IsChecked
        Save-AppSettings -Settings $script:AppSettings
        Apply-EditorHintVisibility
    })
    $btnReset.Add_Click({
        $script:AppSettings.BackgroundImage='@default'
        $script:AppSettings.BackgroundMode='Fill'
        $script:AppSettings.BackgroundDim=52
        $txtCurrent.Text='HypeTek Standard-Wallpaper'; $cmbMode.SelectedIndex=0; $sldDim.Value=52
        Save-AppearanceSettings
    })
    $btnClose.Add_Click({ $d.Close() })

    $d.Content=$grid
    [void]$d.ShowDialog()
}


$script:Profiles = @(Get-Profiles)
$script:SelectedProfileId = $null
$script:LastSnapshot = $null
$script:CurrentState = $null
$script:PowerSchemeItems = @()
$script:LastCpuTimes = $null
$script:LastTelemetrySnapshot = $null
$script:BaseClockMHz = $null
$script:TelemetryProviderInfo = ''
$script:TelemetryTimer = $null

function Set-Status([string]$Text, [bool]$Error=$false) {
    $ui.txtStatus.Text = $Text
    $brush = if ($Error) { '#FCA5A5' } else { '#86EFAC' }
    $ui.txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($brush)
}

function Add-ExecutionLog([string[]]$Lines) {
    foreach ($line in $Lines) { $ui.txtExecutionLog.AppendText("$line$([Environment]::NewLine)") }
    $ui.txtExecutionLog.ScrollToEnd()
}

function Get-LowOverheadCpuLoad {
    if (-not ('HypeTek.CpuTelemetry.NativeMethods' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace HypeTek.CpuTelemetry {
  [StructLayout(LayoutKind.Sequential)]
  public struct FILETIME { public uint dwLowDateTime; public uint dwHighDateTime; }
  public static class NativeMethods {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GetSystemTimes(out FILETIME idle, out FILETIME kernel, out FILETIME user);
  }
}
'@
    }
    try {
        $idle = New-Object HypeTek.CpuTelemetry.FILETIME
        $kernel = New-Object HypeTek.CpuTelemetry.FILETIME
        $user = New-Object HypeTek.CpuTelemetry.FILETIME
        if (-not [HypeTek.CpuTelemetry.NativeMethods]::GetSystemTimes([ref]$idle,[ref]$kernel,[ref]$user)) { return $null }
        $to64 = { param($ft) ([uint64]$ft.dwHighDateTime -shl 32) -bor [uint64]$ft.dwLowDateTime }
        $now = [pscustomobject]@{ Idle=&$to64 $idle; Kernel=&$to64 $kernel; User=&$to64 $user }
        if ($script:LastCpuTimes) {
            [double]$idleDelta = $now.Idle - $script:LastCpuTimes.Idle
            [double]$kernelDelta = $now.Kernel - $script:LastCpuTimes.Kernel
            [double]$userDelta = $now.User - $script:LastCpuTimes.User
            [double]$total = $kernelDelta + $userDelta
            $script:LastCpuTimes = $now
            if ($total -gt 0) {
                return [math]::Max(0,[math]::Min(100,[math]::Round((1 - ($idleDelta / $total)) * 100,0)))
            }
        } else { $script:LastCpuTimes = $now }
    } catch { }
    return $null
}

function Get-ProcessorPerformanceSample {
    try {
        $all = @(Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction Stop | Where-Object { $_.Name -eq '_Total' -or $_.Name -eq '0,_Total' })
        $p = $all | Where-Object { $_.Name -eq '_Total' } | Select-Object -First 1
        if (-not $p) { $p = $all | Select-Object -First 1 }
        if ($p) {
            return [pscustomobject]@{
                PercentPerformance = if ($null -ne $p.PercentProcessorPerformance) { [double]$p.PercentProcessorPerformance } else { $null }
                PercentOfMaximumFrequency = if ($null -ne $p.PercentofMaximumFrequency) { [double]$p.PercentofMaximumFrequency } else { $null }
                ProcessorFrequencyMHz = if ($null -ne $p.ProcessorFrequency) { [double]$p.ProcessorFrequency } else { $null }
            }
        }
    } catch { }
    return $null
}

function Get-NominalBaseClockMHz {
    if ($script:BaseClockMHz -and $script:BaseClockMHz -gt 0) { return [double]$script:BaseClockMHz }
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpu.MaxClockSpeed) { $script:BaseClockMHz=[double]$cpu.MaxClockSpeed }
        elseif ($cpu.CurrentClockSpeed) { $script:BaseClockMHz=[double]$cpu.CurrentClockSpeed }
    } catch { }
    return $script:BaseClockMHz
}

function Get-LiveTelemetrySnapshot {
    $load = Get-LowOverheadCpuLoad
    $perf = Get-ProcessorPerformanceSample
    $base = Get-NominalBaseClockMHz

    $clock = $null
    $source = 'unavailable'
    if ($perf -and $null -ne $perf.PercentPerformance -and $base -and $base -gt 0) {
        # Windows reports processor performance as a percentage of the nominal/base clock.
        # Unlike Win32_Processor.CurrentClockSpeed this can represent Intel/AMD Turbo above 100%.
        $clock = [math]::Round($base * ([double]$perf.PercentPerformance / 100.0),0)
        $source = 'PercentProcessorPerformance × base clock'
    }
    elseif ($perf -and $perf.ProcessorFrequencyMHz -and $perf.ProcessorFrequencyMHz -gt 0) {
        $clock = [math]::Round($perf.ProcessorFrequencyMHz,0)
        $source = 'ProcessorFrequency counter'
    }

    return [pscustomobject]@{
        CpuLoadPercent = $load
        CurrentClockMHz = $clock
        BaseClockMHz = $base
        PercentProcessorPerformance = if ($perf) { $perf.PercentPerformance } else { $null }
        PercentOfMaximumFrequency = if ($perf) { $perf.PercentOfMaximumFrequency } else { $null }
        ProviderFrequencyMHz = if ($perf) { $perf.ProcessorFrequencyMHz } else { $null }
        Source = $source
    }
}

function Refresh-LiveTelemetry {
    try {
        $t = Get-LiveTelemetrySnapshot
        $script:LastTelemetrySnapshot = $t
        $loadText = if ($null -eq $t.CpuLoadPercent) { 'n/a' } else { "$($t.CpuLoadPercent) %" }
        $limit = $null
        try { if ($script:CurrentState -and $null -ne $script:CurrentState.AC.MaxFrequency) { $limit = [int64]$script:CurrentState.AC.MaxFrequency } } catch { }
        $clockText = if ($null -eq $t.CurrentClockMHz) { 'n/a' } else { "$($t.CurrentClockMHz) MHz" }
        if ($limit -and $limit -gt 0) { $clockText += " · Limit $limit MHz" }
        $ui.txtLiveLoad.Text = "Auslastung: $loadText"
        $ui.txtLiveClock.Text = "Takt: $clockText"
    } catch {
        $ui.txtLiveLoad.Text = 'Auslastung: n/a'
        $ui.txtLiveClock.Text = 'Takt: n/a'
    }
}

function Test-ProfileMatchesState {
    param($Profile,$State)
    if (-not $Profile -or -not $State) { return $false }
    foreach ($key in @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')) {
        if ($State.Support.$key) {
            $pv = $Profile.AC.$key
            $sv = $State.AC.$key
            if ($null -eq $pv -or $null -eq $sv) { return $false }
            if ([int64]$pv -ne [int64]$sv) { return $false }
        }
    }
    return $true
}

function Get-MatchingProfileName {
    param($State)
    foreach ($profile in $script:Profiles) {
        if (Test-ProfileMatchesState -Profile $profile -State $State) { return $profile.Name }
    }
    return 'Benutzerdefiniert / kein gespeichertes Profil'
}

function Refresh-PowerSchemeList {
    try {
        $script:PowerSchemeItems = @(Get-PowerSchemes)
        $selected = -1
        $ui.cmbPowerSchemes.Items.Clear()
        for ($i=0; $i -lt $script:PowerSchemeItems.Count; $i++) {
            $item = $script:PowerSchemeItems[$i]
            [void]$ui.cmbPowerSchemes.Items.Add(("{0}{1}" -f $item.Name, $(if ($item.IsActive) { '  [aktiv]' } else { '' })))
            if ($item.IsActive) { $selected = $i }
        }
        if ($selected -ge 0) { $ui.cmbPowerSchemes.SelectedIndex = $selected }
    }
    catch {
        $ui.cmbPowerSchemes.Items.Clear()
        [void]$ui.cmbPowerSchemes.Items.Add('Energiepläne konnten nicht gelesen werden')
        $ui.cmbPowerSchemes.SelectedIndex = 0
    }
}

function Invoke-SwitchPowerScheme {
    try {
        $idx = $ui.cmbPowerSchemes.SelectedIndex
        if ($idx -lt 0 -or $idx -ge $script:PowerSchemeItems.Count) { throw 'Bitte einen Windows-Energieplan auswählen.' }
        $item = $script:PowerSchemeItems[$idx]
        if (-not $item.IsActive) {
            $line = Set-ActivePowerScheme -SchemeGuid $item.Guid
            Add-ExecutionLog $line
            Set-Status "Windows-Energieplan '$($item.Name)' aktiviert."
        }
        Refresh-State
    }
    catch {
        Set-Status "Energieplan konnte nicht aktiviert werden: $($_.Exception.Message)" $true
    }
}

function Get-EditorProfile {
    if ([string]::IsNullOrWhiteSpace($ui.txtProfileName.Text)) { throw 'Bitte einen Profilnamen eingeben.' }
    $id = if ($script:SelectedProfileId) { $script:SelectedProfileId } else { [guid]::NewGuid().ToString() }
    [pscustomobject]@{
        Id=$id; Name=$ui.txtProfileName.Text.Trim(); ApplyDC=[bool]$ui.chkApplyDC.IsChecked
        AC=[pscustomobject]@{ MaxFrequency=[int64]$ui.numMaxFreqAC.Text; MinState=[int]$ui.numMinStateAC.Text; MaxState=[int]$ui.numMaxStateAC.Text; BoostMode=[int]$ui.cmbBoostAC.SelectedValue; CoolingPolicy=[int]$ui.cmbCoolingAC.SelectedValue; Epp=[int]$ui.numEppAC.Text }
        DC=[pscustomobject]@{ MaxFrequency=[int64]$ui.numMaxFreqDC.Text; MinState=[int]$ui.numMinStateDC.Text; MaxState=[int]$ui.numMaxStateDC.Text; BoostMode=[int]$ui.cmbBoostDC.SelectedValue; CoolingPolicy=[int]$ui.cmbCoolingDC.SelectedValue; Epp=[int]$ui.numEppDC.Text }
    }
}

function Set-EditorFromProfile($p) {
    $script:SelectedProfileId=$p.Id; $ui.txtProfileName.Text=$p.Name; $ui.chkApplyDC.IsChecked=[bool]$p.ApplyDC
    $ui.numMaxFreqAC.Text=[string]$p.AC.MaxFrequency; $ui.numMinStateAC.Text=[string]$p.AC.MinState; $ui.numMaxStateAC.Text=[string]$p.AC.MaxState; $ui.numEppAC.Text=[string]$p.AC.Epp
    $ui.numMaxFreqDC.Text=[string]$p.DC.MaxFrequency; $ui.numMinStateDC.Text=[string]$p.DC.MinState; $ui.numMaxStateDC.Text=[string]$p.DC.MaxState; $ui.numEppDC.Text=[string]$p.DC.Epp
    $ui.cmbBoostAC.SelectedValue=[int]$p.AC.BoostMode; $ui.cmbCoolingAC.SelectedValue=[int]$p.AC.CoolingPolicy; $ui.cmbBoostDC.SelectedValue=[int]$p.DC.BoostMode; $ui.cmbCoolingDC.SelectedValue=[int]$p.DC.CoolingPolicy
    Update-CommandPreview
}

function New-EditorProfile {
    $script:SelectedProfileId=$null
    $p=New-DefaultProfile 'Neues Profil'
    Set-EditorFromProfile $p
    $script:SelectedProfileId=$null
}

function Snapshot-ToProfile([string]$Name) {
    $s=Get-SystemPowerState
    [pscustomobject]@{
        Id=[guid]::NewGuid().ToString(); Name=$Name; ApplyDC=$true
        AC=[pscustomobject]@{ MaxFrequency=$s.AC.MaxFrequency; MinState=$s.AC.MinState; MaxState=$s.AC.MaxState; BoostMode=$s.AC.BoostMode; CoolingPolicy=$s.AC.CoolingPolicy; Epp=$s.AC.Epp }
        DC=[pscustomobject]@{ MaxFrequency=$s.DC.MaxFrequency; MinState=$s.DC.MinState; MaxState=$s.DC.MaxState; BoostMode=$s.DC.BoostMode; CoolingPolicy=$s.DC.CoolingPolicy; Epp=$s.DC.Epp }
    }
}

function Invoke-ApplyProfile($Profile, [bool]$Capture=$true) {
    try {
        if ($Capture) { $script:LastSnapshot=Snapshot-ToProfile 'Letzte Werte'; $ui.btnRestore.IsEnabled=$true }
        $scheme=(Get-ActivePowerScheme).Guid
        Add-ExecutionLog @("", "[$(Get-Date -Format 'HH:mm:ss.fff')] START Profil '$($Profile.Name)'")
        $cmds=Get-EquivalentPowerCfgCommands -Profile $Profile -SchemeGuid $scheme
        $result=Apply-ProfileValues -Profile $Profile -SchemeGuid $scheme
        Add-ExecutionLog $result.LogLines
        Add-ExecutionLog ($cmds | ForEach-Object { "  -> $_" })
        Refresh-State
        $ui.txtActiveProfile.Text = "Profil: $(Get-MatchingProfileName -State $script:CurrentState)"
        Add-ExecutionLog @("[$(Get-Date -Format 'HH:mm:ss.fff')] FERTIG  Profil '$($Profile.Name)' angewendet.", "")
        Set-Status "Profil '$($Profile.Name)' angewendet."
    } catch {
        Add-ExecutionLog @("[$(Get-Date -Format 'HH:mm:ss.fff')] FEHLER: $($_.Exception.Message)", "")
        Set-Status $_.Exception.Message $true
        [System.Windows.MessageBox]::Show($_.Exception.Message,'Profil konnte nicht angewendet werden','OK','Error') | Out-Null
    }
}

function Update-CommandPreview {
    try {
        $scheme=if ($script:CurrentState) { $script:CurrentState.SchemeGuid } else { (Get-ActivePowerScheme).Guid }
        $profile=Get-EditorProfile
        $ui.txtCommandPreview.Text=((Get-EquivalentPowerCfgCommands -Profile $profile -SchemeGuid $scheme) -join [Environment]::NewLine)
    } catch { $ui.txtCommandPreview.Text="Vorschau nicht verfügbar: $($_.Exception.Message)" }
}

function Import-Profiles {
    try {
        $dialog=New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title='HypeTek CPU Throttling – Profile importieren'
        $dialog.Filter='JSON-Dateien (*.json)|*.json|Alle Dateien (*.*)|*.*'
        if ($dialog.ShowDialog() -ne $true) { return }
        $raw=Get-Content -LiteralPath $dialog.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
        $incoming=@($raw)
        if ($incoming.Count -eq 0) { throw 'Die Datei enthält keine Profile.' }
        $added=0
        foreach ($entry in $incoming) {
            if (-not $entry.Name -or -not $entry.AC -or -not $entry.DC) { continue }
            $copy=[pscustomobject]@{ Id=[guid]::NewGuid().ToString(); Name=[string]$entry.Name; ApplyDC=[bool]$entry.ApplyDC; AC=$entry.AC; DC=$entry.DC }
            $script:Profiles += $copy; $added++
        }
        if ($added -eq 0) { throw 'Keine gültigen Profile gefunden.' }
        Save-Profiles $script:Profiles; Render-Profiles; Set-Status "$added Profil(e) importiert."
    } catch { Set-Status "Import fehlgeschlagen: $($_.Exception.Message)" $true; [System.Windows.MessageBox]::Show($_.Exception.Message,'Profile importieren','OK','Error') | Out-Null }
}

function Export-Profiles {
    try {
        $dialog=New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Title='HypeTek CPU Throttling – Profile exportieren'; $dialog.Filter='JSON-Datei (*.json)|*.json'; $dialog.FileName='HypeTek-CPU-Throttling-Profiles.json'
        if ($dialog.ShowDialog() -ne $true) { return }
        $script:Profiles | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dialog.FileName -Encoding UTF8
        Set-Status "Profile exportiert: $($dialog.FileName)"
    } catch { Set-Status "Export fehlgeschlagen: $($_.Exception.Message)" $true }
}

function Export-Diagnostics {
    try {
        $dialog=New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Title='HypeTek CPU Throttling – Diagnose exportieren'; $dialog.Filter='Textdatei (*.txt)|*.txt'; $dialog.FileName="HypeTek-CPU-Throttling-Diagnose-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
        if ($dialog.ShowDialog() -ne $true) { return }
        $s=Get-SystemPowerState; $t=Get-LiveTelemetrySnapshot
        $lines=New-Object System.Collections.Generic.List[string]
        $lines.Add('HypeTek CPU Throttling v0.2.0')
        $lines.Add("Zeit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
        $lines.Add("CPU: $($s.CpuName)"); $lines.Add("OS: $($s.OsName) $($s.OsVersion) $($s.Architecture)")
        $lines.Add("Energieplan: $($s.SchemeName) [$($s.SchemeGuid)]")
        $lines.Add('')
        $lines.Add('Live-Telemetrie:')
        $lines.Add("  CPU-Auslastung: $($t.CpuLoadPercent) %")
        $lines.Add("  Aktueller Takt: $($t.CurrentClockMHz) MHz")
        $lines.Add("  Basis-Takt: $($t.BaseClockMHz) MHz")
        $lines.Add("  Quelle Takt: $($t.Source)")
        $lines.Add("  PercentProcessorPerformance: $($t.PercentProcessorPerformance)")
        $lines.Add("  PercentOfMaximumFrequency: $($t.PercentOfMaximumFrequency)")
        $lines.Add("  ProviderFrequencyMHz: $($t.ProviderFrequencyMHz)")
        $lines.Add('')
        $lines.Add('Support:')
        foreach ($key in @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')) { $lines.Add("  $key = $($s.Support.$key)") }
        $lines.Add(''); $lines.Add('AC:')
        foreach ($key in @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')) { $lines.Add("  $key = $($s.AC.$key)") }
        $lines.Add('DC:')
        foreach ($key in @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')) { $lines.Add("  $key = $($s.DC.$key)") }
        [System.IO.File]::WriteAllLines($dialog.FileName,$lines,[System.Text.Encoding]::UTF8)
        Set-Status "Diagnose exportiert: $($dialog.FileName)"
    } catch { Set-Status "Diagnoseexport fehlgeschlagen: $($_.Exception.Message)" $true; [System.Windows.MessageBox]::Show($_.Exception.Message,'Diagnose exportieren','OK','Error') | Out-Null }
}

function Refresh-State {
    try {
        $script:CurrentState = Get-SystemPowerState; $s=$script:CurrentState
        $ui.txtCpu.Text="CPU: $($s.CpuName)"; $ui.txtOs.Text="$($s.OsName) · $($s.Architecture) · Build $($s.OsVersion)"; $ui.txtScheme.Text="$($s.SchemeName)`n$($s.SchemeGuid)"
        $freqText=if($null-eq$s.AC.MaxFrequency){'n/a'}elseif([int64]$s.AC.MaxFrequency-eq 0){'Unlimited'}else{"$($s.AC.MaxFrequency) MHz"}
        $boostText=if($null-eq$s.AC.BoostMode){'n/a'}elseif([int]$s.AC.BoostMode-eq 0){'Aus'}else{"Ein (Mode $($s.AC.BoostMode))"}
        $coolText=if($null-eq$s.AC.CoolingPolicy){'n/a'}elseif([int]$s.AC.CoolingPolicy-eq 0){'Passiv'}else{'Aktiv'}
        $ui.txtCurrentValues.Text="AC: $freqText · Turbo $boostText · Min/Max $($s.AC.MinState)/$($s.AC.MaxState)% · EPP $($s.AC.Epp) · Cooling $coolText"
        $ui.txtActiveProfile.Text="Profil: $(Get-MatchingProfileName -State $s)"
        $supportParts=@(); foreach($pair in @(@('MaxFrequency','Freq'),@('BoostMode','Boost'),@('MinState','Min'),@('MaxState','Max'),@('CoolingPolicy','Cooling'),@('Epp','EPP'))){if($s.Support.($pair[0])){$supportParts+="$($pair[1]) ✓"}else{$supportParts+="$($pair[1]) ✗"}}
        $ui.txtSupport.Text=($supportParts -join ' · ')
        Refresh-PowerSchemeList; Update-CommandPreview; Refresh-LiveTelemetry; Render-Profiles; Set-Status 'Systemwerte aktualisiert.'
    } catch { Set-Status "Systemwerte konnten nicht gelesen werden: $($_.Exception.Message)" $true }
}

function Find-ProfileById([string]$Id){return($script:Profiles|Where-Object{$_.Id-eq$Id}|Select-Object -First 1)}

function Render-Profiles {
    $ui.wrpProfiles.Children.Clear()
    foreach($profile in $script:Profiles){
        $button=New-Object System.Windows.Controls.Button; $button.Width=190;$button.Height=82;$button.Tag=$profile.Id
        if($script:CurrentState -and (Test-ProfileMatchesState -Profile $profile -State $script:CurrentState)){$button.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#22C55E');$button.BorderThickness=[System.Windows.Thickness]::new(2);$button.ToolTip='Dieses Profil entspricht den aktuell ausgelesenen Windows-Werten.'}
        $panel=New-Object System.Windows.Controls.StackPanel
        $title=New-Object System.Windows.Controls.TextBlock;$title.Text=$profile.Name;$title.FontWeight=[System.Windows.FontWeights]::SemiBold;$title.FontSize=14;$title.TextWrapping=[System.Windows.TextWrapping]::Wrap
        $sub=New-Object System.Windows.Controls.TextBlock;$sub.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#CBD5E1');$sub.Margin=[System.Windows.Thickness]::new(0,5,0,0)
        $freq=if([int64]$profile.AC.MaxFrequency-eq 0){'Unlimited'}else{"$($profile.AC.MaxFrequency) MHz"};$boost=if([int]$profile.AC.BoostMode-eq 0){'Turbo OFF'}else{'Turbo ON'};$sub.Text="$freq · $boost"
        [void]$panel.Children.Add($title);[void]$panel.Children.Add($sub);$button.Content=$panel
        $button.Add_Click({param($sender,$eventArgs)$p=Find-ProfileById([string]$sender.Tag);if($p){Invoke-ApplyProfile $p}})
        $menu=New-Object System.Windows.Controls.ContextMenu
        foreach($entry in @(@('Bearbeiten','edit'),@('Duplizieren','dup'),@('Löschen','delete'))){$item=New-Object System.Windows.Controls.MenuItem;$item.Header=$entry[0];$item.Tag="$($profile.Id)|$($entry[1])";$item.Add_Click({param($sender,$eventArgs)$parts=[string]$sender.Tag -split '\|',2;$p=Find-ProfileById $parts[0];if(-not$p){return};switch($parts[1]){'edit'{Set-EditorFromProfile $p;Set-Status "Profil '$($p.Name)' im Editor geöffnet."};'dup'{$copy=[pscustomobject]@{Id=[guid]::NewGuid().ToString();Name="$($p.Name) – Kopie";ApplyDC=[bool]$p.ApplyDC;AC=$p.AC;DC=$p.DC};$script:Profiles+=$copy;Save-Profiles $script:Profiles;Render-Profiles;Set-EditorFromProfile $copy};'delete'{$ans=[System.Windows.MessageBox]::Show("Profil '$($p.Name)' wirklich löschen?",'Profil löschen','YesNo','Question');if($ans-eq'Yes'){$script:Profiles=@($script:Profiles|Where-Object{$_.Id-ne$p.Id});Save-Profiles $script:Profiles;Render-Profiles;New-EditorProfile}}}});[void]$menu.Items.Add($item)}
        $button.ContextMenu=$menu;[void]$ui.wrpProfiles.Children.Add($button)
    }
}

$ui.btnRefresh.Add_Click({Refresh-State})
$ui.btnAppearance.Add_Click({Show-AppearanceDialog})
$ui.btnDiagnostics.Add_Click({Export-Diagnostics})
$ui.btnImportProfiles.Add_Click({Import-Profiles})
$ui.btnExportProfiles.Add_Click({Export-Profiles})
$ui.btnApplyPowerScheme.Add_Click({Invoke-SwitchPowerScheme})
$ui.btnNew.Add_Click({New-EditorProfile;Set-Status 'Neues Profil im Editor.'})
$ui.btnFromCurrent.Add_Click({try{$p=Convert-StateToProfile(Get-SystemPowerState)'Mein aktuelles Profil';$script:SelectedProfileId=$null;Set-EditorFromProfile $p;$script:SelectedProfileId=$null;Set-Status 'Aktuelle Werte in den Editor übernommen.'}catch{Set-Status $_.Exception.Message $true}})
$ui.btnRestore.Add_Click({if($script:LastSnapshot){Invoke-ApplyProfile $script:LastSnapshot $false}})
$ui.btnSaveProfile.Add_Click({try{$p=Get-EditorProfile;$existing=Find-ProfileById $p.Id;if($existing){$script:Profiles=@($script:Profiles|ForEach-Object{if($_.Id-eq$p.Id){$p}else{$_}})}else{$script:Profiles+=$p;$script:SelectedProfileId=$p.Id};Save-Profiles $script:Profiles;Render-Profiles;Set-Status "Profil '$($p.Name)' gespeichert."}catch{Set-Status $_.Exception.Message $true;[System.Windows.MessageBox]::Show($_.Exception.Message,'Ungültige Werte','OK','Warning')|Out-Null}})
$ui.btnApplyEditor.Add_Click({try{Invoke-ApplyProfile(Get-EditorProfile)}catch{Set-Status $_.Exception.Message $true}})
$ui.btnAbout.Add_Click({$msg=@"
HypeTek CPU Throttling v0.2.0
by HypeTek

Kompatibilität
• Windows 10 / Windows 11
• primär x64
• Intel und AMD grundsätzlich möglich
• einzelne Optionen nur, wenn Windows/CPU/Firmware sie bereitstellen bzw. beachten

Die App kann installierte Windows-Energiepläne wechseln und CPU-Energieverwaltungswerte im jeweils aktiven Energieplan ändern. Keine CPU-Spannungen, keine BIOS-/UEFI-Parameter, kein klassisches Overclocking.

Wichtig: Auch gültige Windows-Werte können auf einzelnen Plattformen ignoriert werden oder zu ungewohntem Takt-/Temperaturverhalten führen. Nutzung auf eigene Gefahr.

Profile: $script:ProfilesPath
"@;[System.Windows.MessageBox]::Show($msg,'Info / Kompatibilität','OK','Information')|Out-Null})

foreach($control in @($ui.txtProfileName,$ui.chkApplyDC,$ui.numMaxFreqAC,$ui.numMaxFreqDC,$ui.numMinStateAC,$ui.numMinStateDC,$ui.numMaxStateAC,$ui.numMaxStateDC,$ui.cmbBoostAC,$ui.cmbBoostDC,$ui.cmbCoolingAC,$ui.cmbCoolingDC,$ui.numEppAC,$ui.numEppDC)){if($control-is[System.Windows.Controls.TextBox]){$control.Add_TextChanged({Update-CommandPreview})}elseif($control-is[System.Windows.Controls.ComboBox]){$control.Add_SelectionChanged({Update-CommandPreview})}elseif($control-is[System.Windows.Controls.CheckBox]){$control.Add_Click({Update-CommandPreview})}}

Apply-Appearance
Apply-EditorHintVisibility
$ui.txtExecutionLog.Text="Noch keine Profiländerung in dieser Sitzung ausgeführt.$([Environment]::NewLine)"
New-EditorProfile
Render-Profiles
Refresh-State
$script:TelemetryTimer=New-Object System.Windows.Threading.DispatcherTimer
$script:TelemetryTimer.Interval=[TimeSpan]::FromSeconds(1)
$script:TelemetryTimer.Add_Tick({Refresh-LiveTelemetry})
$script:TelemetryTimer.Start()
$window.Add_Closed({if($script:TelemetryTimer){$script:TelemetryTimer.Stop()}})
$window.Add_ContentRendered({try{$window.Topmost=$true;[void]$window.Activate();[void]$window.Focus();$window.Topmost=$false}catch{}})
[void]$window.ShowDialog()
