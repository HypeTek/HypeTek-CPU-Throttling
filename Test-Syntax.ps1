# HypeTek CPU Power Control - parser self-test
# Designed for Windows PowerShell 5.1+

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$files = @(
    (Join-Path $root 'CPU-Power-Control.ps1'),
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

if ($failed) { exit 1 }
Write-Host ''
Write-Host 'All PowerShell files parsed successfully.' -ForegroundColor Green
exit 0
