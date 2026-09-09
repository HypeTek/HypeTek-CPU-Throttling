# HypeTek CPU Throttling
# Version 0.2.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = if ($env:HYPETEK_CPU_THROTTLING_BASEDIR) {
    $env:HYPETEK_CPU_THROTTLING_BASEDIR
} else {
    Split-Path -Parent $PSCommandPath
}
$LogRoot = Join-Path $env:LOCALAPPDATA 'CPUPowerControl\logs'
$LogFile = Join-Path $LogRoot 'startup.log'

function Write-StartupLog {
    param([string]$Message)
    try {
        if (-not (Test-Path $LogRoot)) { New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null }
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Add-Content -LiteralPath $LogFile -Encoding UTF8 -Value "[$stamp] $Message"
    } catch { }
}

function Show-FatalError {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)
    $detail = if ($ErrorRecord) {
        $pos = if ($ErrorRecord.InvocationInfo -and $ErrorRecord.InvocationInfo.PositionMessage) { "`n`n$($ErrorRecord.InvocationInfo.PositionMessage)" } else { '' }
        "$($ErrorRecord.Exception.GetType().FullName): $($ErrorRecord.Exception.Message)$pos"
    } else { 'Unbekannter Fehler.' }

    Write-StartupLog "FATAL: $detail"
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        [System.Windows.MessageBox]::Show(
            "HypeTek CPU Throttling konnte nicht gestartet werden.`n`n$detail`n`nLogdatei:`n$LogFile",
            'HypeTek CPU Throttling – Startfehler',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    } catch {
        Write-Host "HypeTek CPU Throttling – Startfehler" -ForegroundColor Red
        Write-Host $detail -ForegroundColor Red
        Write-Host "Logdatei: $LogFile"
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

try {
    Write-StartupLog "Start. PS=$($PSVersionTable.PSVersion) CLR=$($PSVersionTable.CLRVersion) Arch=$env:PROCESSOR_ARCHITECTURE Apartment=$([Threading.Thread]::CurrentThread.GetApartmentState()) Admin=$(Test-IsAdministrator)"

    if ($env:OS -ne 'Windows_NT') {
        throw 'HypeTek CPU Throttling benötigt Windows 10 oder Windows 11.'
    }

    if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne [Threading.ApartmentState]::STA) {
        Write-StartupLog 'Relaunching in STA mode.'
        $args = @('-NoProfile','-STA','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
        Start-Process -FilePath 'powershell.exe' -ArgumentList ($args -join ' ')
        exit 0
    }

    if (-not (Test-IsAdministrator)) {
        Write-StartupLog 'Requesting elevation.'
        $argLine = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argLine | Out-Null
        exit 0
    }

    Set-Location -LiteralPath $Root
    foreach ($required in @('src\PowerCfg.ps1','src\ProfileManager.ps1','src\Main.ps1','src\MainWindow.xaml')) {
        $p = Join-Path $Root $required
        if (-not (Test-Path -LiteralPath $p)) { throw "Datei fehlt: $required" }
    }

    Write-StartupLog 'Loading PowerCfg.ps1.'
    . (Join-Path $Root 'src\PowerCfg.ps1')
    Write-StartupLog 'Loading ProfileManager.ps1.'
    . (Join-Path $Root 'src\ProfileManager.ps1')
    Write-StartupLog 'Loading Main.ps1.'
    . (Join-Path $Root 'src\Main.ps1')
    Write-StartupLog 'Normal application exit.'
}
catch {
    Show-FatalError $_
    exit 1
}
