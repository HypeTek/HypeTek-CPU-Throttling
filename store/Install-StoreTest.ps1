#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$cer = Join-Path $root 'HypeTek-CPU-Throttling-Store-Test.cer'
$msix = Join-Path $root 'HypeTek-CPU-Throttling-v0.2.0-Store-Test.msix'

if (-not (Test-Path -LiteralPath $cer)) { throw "Certificate not found: $cer" }
if (-not (Test-Path -LiteralPath $msix)) { throw "MSIX not found: $msix" }

Write-Host 'HypeTek CPU Throttling - Store test installer'
Write-Host 'This admin prompt is ONLY for trusting the temporary development certificate.'
Write-Host 'The installed application itself is designed to run without elevation.'
Write-Host ''

$cert = Import-Certificate -FilePath $cer -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
Write-Host ('Trusted development certificate: {0}' -f $cert.Thumbprint)

Add-AppxPackage -Path $msix
Write-Host ''
Write-Host 'MSIX installed. Launch HypeTek CPU Throttling from the Start menu.'
Write-Host 'After testing, uninstall the app and remove the development certificate from Local Computer -> Trusted People.'
