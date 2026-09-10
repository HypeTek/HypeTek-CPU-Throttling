# HypeTek CPU Throttling - parser and lightweight runtime-contract self-test
# Designed for Windows PowerShell 5.1+

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$files = @(
    (Join-Path $root 'CPU-Throttling.ps1'),
    (Join-Path $root 'src\PowerCfg.ps1'),
    (Join-Path $root 'src\ProfileManager.ps1'),
    (Join-Path $root 'src\Main.ps1')
)

$failed = $false
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    if ($errors.Count -eq 0) {
        Write-Host "OK  $file" -ForegroundColor Green
    }
    else {
        $failed = $true
        Write-Host "ERR $file" -ForegroundColor Red
        foreach ($e in $errors) {
            Write-Host ("  Line {0}, Column {1}: {2}" -f $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message) -ForegroundColor Red
        }
    }
}

if (-not $failed) {
    try {
        . (Join-Path $root 'src\PowerCfg.ps1')
        . (Join-Path $root 'src\ProfileManager.ps1')

        foreach ($commandName in @('Get-ActiveSchemeGuid','Get-PowerSchemes','Get-ActivePowerScheme','Set-PowerSettingValue','Apply-ActiveScheme')) {
            if (-not (Get-Command $commandName -CommandType Function -ErrorAction SilentlyContinue)) {
                throw "Required runtime function is missing: $commandName"
            }
            Write-Host "OK  runtime function $commandName" -ForegroundColor Green
        }
    }
    catch {
        $failed = $true
        Write-Host ("ERR runtime contract: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

if ($failed) { exit 1 }
Write-Host ''
Write-Host 'All PowerShell files parsed and required runtime functions are available.' -ForegroundColor Green
exit 0
