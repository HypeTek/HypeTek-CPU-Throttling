#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$cer = Join-Path $root 'HypeTek-CPU-Throttling-Store-Test.cer'
$msix = Join-Path $root 'HypeTek-CPU-Throttling-v0.2.0-Store-Test.msix'
$packageName = 'HypeTek.CPUThrottling.Dev'
$publisherSubject = 'CN=HypeTek Development'

if (-not (Test-Path -LiteralPath $cer)) { throw "Certificate not found: $cer" }
if (-not (Test-Path -LiteralPath $msix)) { throw "MSIX not found: $msix" }

Write-Host 'HypeTek CPU Throttling - Store test installer'
Write-Host 'This admin prompt is ONLY for development package setup.'
Write-Host 'The installed application itself is designed to run without elevation.'
Write-Host ''

# CI creates a new temporary signing certificate for every test build. Remove an
# older copy of the development package first so the same package version can be
# replaced safely during rapid test iterations. User profiles/settings live in
# %APPDATA%\HypeTek\CPU-Throttling and are intentionally left untouched.
$existing = @(Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue)
foreach ($pkg in $existing) {
    Write-Host ("Removing previous Store test package: {0} {1}" -f $pkg.Name, $pkg.Version)
    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
}

# Remove stale CI development certificates from TrustedPeople before trusting
# the certificate that belongs to this artifact.
$staleCerts = @(Get-ChildItem 'Cert:\LocalMachine\TrustedPeople' | Where-Object { $_.Subject -eq $publisherSubject })
foreach ($oldCert in $staleCerts) {
    Write-Host ("Removing stale development certificate: {0}" -f $oldCert.Thumbprint)
    Remove-Item -LiteralPath $oldCert.PSPath -Force
}

$cert = Import-Certificate -FilePath $cer -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
Write-Host ('Trusted development certificate: {0}' -f $cert.Thumbprint)

Add-AppxPackage -Path $msix
Write-Host ''
Write-Host 'MSIX installed. Launch HypeTek CPU Throttling from the Start menu.'
Write-Host 'After testing, uninstall the app and remove the development certificate from Local Computer -> Trusted People.'
