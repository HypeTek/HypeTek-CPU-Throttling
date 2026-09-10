#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$PackageName = 'HypeTek.CPUThrottling.Dev',
    [string]$ReportDirectory = (Join-Path $env:USERPROFILE 'Documents\HypeTek\CPU-Throttling\WACK')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    throw 'Windows App Certification Kit must be started from an elevated PowerShell session.'
}

$appCertCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\App Certification Kit\appcert.exe'),
    (Join-Path $env:ProgramFiles 'Windows Kits\10\App Certification Kit\appcert.exe')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$appCert = $appCertCandidates | Select-Object -First 1
if (-not $appCert) {
    throw @'
Windows App Certification Kit (appcert.exe) was not found.
Install the current Windows SDK / Windows App Certification Kit and run this script again.
Typical path: C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe
'@
}

$packages = @(Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue | Sort-Object Version -Descending)
if ($packages.Count -eq 0) {
    throw "Installed Store-test package '$PackageName' was not found. Install the current MSIX first with Install-StoreTest.ps1."
}

$package = $packages[0]
New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportPath = Join-Path $ReportDirectory "HypeTek-CPU-Throttling-WACK-$stamp.xml"

Write-Host 'HypeTek CPU Throttling - Windows App Certification Kit' -ForegroundColor Cyan
Write-Host ("WACK:    {0}" -f $appCert)
Write-Host ("Package: {0}" -f $package.PackageFullName)
Write-Host ("Report:  {0}" -f $reportPath)
Write-Host ''
Write-Host 'The certification test may launch and close the app automatically. Do not use the machine heavily while the test is running.' -ForegroundColor Yellow
Write-Host ''

# Ensure the app is not already running. WACK activates the installed package itself.
Get-Process -Name 'HypeTek-CPU-Throttling' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host '[1/2] Resetting Windows App Certification Kit state...'
& $appCert reset
$resetExit = $LASTEXITCODE
if ($resetExit -ne 0) {
    throw "appcert.exe reset failed with exit code $resetExit."
}

Write-Host '[2/2] Running certification tests...'
& $appCert test -packagefullname $package.PackageFullName -reportoutputpath $reportPath
$testExit = $LASTEXITCODE

Write-Host ''
if (Test-Path -LiteralPath $reportPath) {
    Write-Host ("WACK report created: {0}" -f $reportPath) -ForegroundColor Green

    # WACK versions differ slightly in report formatting, so only emit a best-effort summary.
    try {
        $raw = Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8
        if ($raw -match '(?i)OVERALL_RESULT\s*=\s*["'']PASS["'']' -or $raw -match '(?i)<OVERALL_RESULT>\s*PASS\s*</OVERALL_RESULT>') {
            Write-Host 'Detected overall result: PASS' -ForegroundColor Green
        }
        elseif ($raw -match '(?i)OVERALL_RESULT\s*=\s*["'']FAIL["'']' -or $raw -match '(?i)<OVERALL_RESULT>\s*FAIL\s*</OVERALL_RESULT>') {
            Write-Host 'Detected overall result: FAIL' -ForegroundColor Red
        }
        else {
            Write-Host 'The report was created; open the XML/HTML report for the detailed result.' -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host 'The report was created; automatic summary parsing was skipped.' -ForegroundColor Yellow
    }
}
else {
    Write-Warning 'No WACK report file was found at the expected path.'
}

Write-Host ("appcert.exe test exit code: {0}" -f $testExit)
Write-Host ''
Write-Host 'Send the generated WACK XML (and HTML if present) back for review before Store submission.' -ForegroundColor Cyan

if ($testExit -ne 0) { exit $testExit }
exit 0
