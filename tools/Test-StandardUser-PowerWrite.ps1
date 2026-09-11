#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host 'HypeTek CPU Throttling - Standard User power-write probe'
Write-Host ('Elevated token: {0}' -f $isAdmin)

if ($isAdmin) {
    Write-Warning 'This probe must be run from a NON-elevated Windows PowerShell 5.1 window, otherwise it does not prove Store compatibility.'
    exit 2
}

$candidates = @(
    (Join-Path (Split-Path -Parent $PSScriptRoot) 'src\PowerCfg.ps1'),
    (Join-Path $PSScriptRoot 'PowerCfg.ps1')
)
$powerCfg = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $powerCfg) {
    throw "PowerCfg.ps1 not found. Checked: $($candidates -join ', ')"
}

. $powerCfg

$scheme = Get-ActiveSchemeGuid
Write-Host ('Active scheme: {0}' -f $scheme)

$results = New-Object 'System.Collections.Generic.List[object]'
$settings = @('MinState','MaxState','MaxFrequency','BoostMode','CoolingPolicy','Epp')

foreach ($setting in $settings) {
    $supported = Test-PowerSettingSupport -Setting $setting
    if (-not $supported) {
        $results.Add([pscustomobject]@{ Setting=$setting; Source='-'; Value='-'; Result='Not supported' })
        continue
    }

    foreach ($source in @('AC','DC')) {
        try {
            $value = Get-PowerSettingValue -Setting $setting -Source $source -SchemeGuid $scheme
            if ($null -eq $value) {
                $results.Add([pscustomobject]@{ Setting=$setting; Source=$source; Value='-'; Result='Read unavailable' })
                continue
            }

            # Write the exact value that is already configured. This exercises the
            # real write API without intentionally changing the user's power profile.
            Set-PowerSettingValue -Setting $setting -Source $source -Value ([uint32]$value) -SchemeGuid $scheme
            $results.Add([pscustomobject]@{ Setting=$setting; Source=$source; Value=$value; Result='WRITE OK' })
        }
        catch {
            $results.Add([pscustomobject]@{ Setting=$setting; Source=$source; Value='-'; Result=('FAILED: ' + $_.Exception.Message) })
        }
    }
}

try {
    Apply-ActiveScheme -SchemeGuid $scheme
    $applyResult = 'OK'
}
catch {
    $applyResult = 'FAILED: ' + $_.Exception.Message
}

$results | Format-Table -AutoSize
Write-Host ('Apply active scheme: {0}' -f $applyResult)

$failed = @($results | Where-Object { $_.Result -like 'FAILED:*' })
if ($applyResult -like 'FAILED:*') { $failed += [pscustomobject]@{ Result=$applyResult } }

if ($failed.Count -gt 0) {
    Write-Error 'At least one power write failed without elevation. Do not mark the MSIX path Store-ready yet.'
    exit 1
}

Write-Host 'PASS: Supported power-setting writes succeeded without elevation.'
exit 0
