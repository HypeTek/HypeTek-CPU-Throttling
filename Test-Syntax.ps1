# HypeTek CPU Throttling - parser and runtime-contract self-test
# Designed for Windows PowerShell 5.1+

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$files = @(
    (Join-Path $root 'CPU-Throttling.ps1'),
    (Join-Path $root 'src\PowerCfg.ps1'),
    (Join-Path $root 'src\ProfileManager.ps1'),
    (Join-Path $root 'src\StoreRuntimeCompat.ps1'),
    (Join-Path $root 'src\Main.ps1'),
    (Join-Path $root 'tools\Run-WackLocal.ps1'),
    (Join-Path $root 'tools\Test-DpiAwareness.ps1')
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
        $contracts = [ordered]@{
            'src\PowerCfg.ps1' = @(
                'Get-ActiveSchemeGuid','Get-ActiveSchemeName','Get-PowerSchemes',
                'Get-PowerSettingValue','Test-PowerSettingSupport','Set-PowerSettingValue',
                'Apply-ActiveScheme','Get-SystemPowerState','Get-EquivalentPowerCfgCommands'
            )
            'src\ProfileManager.ps1' = @(
                'Initialize-AppData','Get-Profiles','Save-Profiles','Get-AppSettings','Save-AppSettings'
            )
            'src\StoreRuntimeCompat.ps1' = @(
                'Get-ActivePowerScheme','Set-ActivePowerScheme','Apply-ProfileValues',
                'Convert-StateToProfile','New-DefaultProfile'
            )
        }

        foreach ($relativePath in $contracts.Keys) {
            $path = Join-Path $root $relativePath
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
            if ($errors.Count -ne 0) { throw "Cannot inspect runtime contract because $relativePath has parser errors." }

            $defined = @($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true) | ForEach-Object { $_.Name })

            foreach ($commandName in $contracts[$relativePath]) {
                if ($defined -notcontains $commandName) {
                    throw "Required app function is not defined by ${relativePath}: $commandName"
                }
                Write-Host "OK  source function $commandName ($relativePath)" -ForegroundColor Green
            }
        }

        # Load exactly the modules the Store launcher loads, in the same order.
        . (Join-Path $root 'src\PowerCfg.ps1')
        . (Join-Path $root 'src\ProfileManager.ps1')
        . (Join-Path $root 'src\StoreRuntimeCompat.ps1')

        foreach ($commandName in @(
            'Get-ActivePowerScheme','Set-ActivePowerScheme','Apply-ProfileValues',
            'Convert-StateToProfile','New-DefaultProfile'
        )) {
            if (-not (Get-Command $commandName -CommandType Function -ErrorAction SilentlyContinue)) {
                throw "Required runtime function is not callable after loading app modules: $commandName"
            }
            Write-Host "OK  callable runtime function $commandName" -ForegroundColor Green
        }
    }
    catch {
        $failed = $true
        Write-Host ("ERR runtime contract: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

if ($failed) { exit 1 }
Write-Host ''
Write-Host 'All PowerShell files parsed and the Store runtime contract is complete.' -ForegroundColor Green
exit 0
