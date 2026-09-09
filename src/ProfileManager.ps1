Set-StrictMode -Version Latest

$script:AppDataRoot = Join-Path $env:APPDATA 'CPUPowerControl'
$script:ProfilesPath = Join-Path $script:AppDataRoot 'profiles.json'
$script:SettingsPath = Join-Path $script:AppDataRoot 'settings.json'
$script:AppearanceAssetsRoot = Join-Path $script:AppDataRoot 'assets'

function Initialize-AppData {
    if (-not (Test-Path $script:AppDataRoot)) {
        New-Item -ItemType Directory -Path $script:AppDataRoot -Force | Out-Null
    }

    if (-not (Test-Path $script:ProfilesPath)) {
        $defaults = @(
            [pscustomobject]@{
                Id = [guid]::NewGuid().ToString()
                Name = 'Gaming 3900 (Example)'
                ApplyDC = $false
                AC = [pscustomobject]@{ MaxFrequency=3900; MinState=5; MaxState=100; BoostMode=1; CoolingPolicy=1; Epp=25 }
                DC = [pscustomobject]@{ MaxFrequency=3200; MinState=5; MaxState=90; BoostMode=0; CoolingPolicy=1; Epp=60 }
            },
            [pscustomobject]@{
                Id = [guid]::NewGuid().ToString()
                Name = 'Eco (Example)'
                ApplyDC = $true
                AC = [pscustomobject]@{ MaxFrequency=3200; MinState=5; MaxState=100; BoostMode=0; CoolingPolicy=1; Epp=70 }
                DC = [pscustomobject]@{ MaxFrequency=2600; MinState=5; MaxState=80; BoostMode=0; CoolingPolicy=1; Epp=85 }
            }
        )
        Save-Profiles -Profiles $defaults
    }

    if (-not (Test-Path $script:AppearanceAssetsRoot)) {
        New-Item -ItemType Directory -Path $script:AppearanceAssetsRoot -Force | Out-Null
    }

    if (-not (Test-Path $script:SettingsPath)) {
        [ordered]@{
            DisclaimerAccepted = $false
            BackgroundImage = '@default'
            BackgroundMode = 'Cover'
            BackgroundDim = 52
            ShowEditorHint = $true
        } | ConvertTo-Json | Set-Content -Path $script:SettingsPath -Encoding UTF8
    }
}

function Get-Profiles {
    Initialize-AppData
    try {
        $content = Get-Content -Path $script:ProfilesPath -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { return @() }
        $result = $content | ConvertFrom-Json
        return @($result)
    }
    catch {
        throw "Could not load profiles: $($_.Exception.Message)"
    }
}

function Save-Profiles {
    param([Parameter(Mandatory)]$Profiles)
    if (-not (Test-Path $script:AppDataRoot)) {
        New-Item -ItemType Directory -Path $script:AppDataRoot -Force | Out-Null
    }
    @($Profiles) | ConvertTo-Json -Depth 8 | Set-Content -Path $script:ProfilesPath -Encoding UTF8
}

function Get-AppSettings {
    Initialize-AppData
    try {
        $settings = Get-Content $script:SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        $settings = [pscustomobject]@{ DisclaimerAccepted = $false }
    }

    # Backward-compatible appearance defaults. Existing v0.1.x settings remain valid.
    if (-not $settings.PSObject.Properties['DisclaimerAccepted']) {
        $settings | Add-Member -NotePropertyName DisclaimerAccepted -NotePropertyValue $false -Force
    }
    if (-not $settings.PSObject.Properties['BackgroundImage']) {
        $settings | Add-Member -NotePropertyName BackgroundImage -NotePropertyValue '@default' -Force
    }
    if (-not $settings.PSObject.Properties['BackgroundMode']) {
        $settings | Add-Member -NotePropertyName BackgroundMode -NotePropertyValue 'Cover' -Force
    }
    if (-not $settings.PSObject.Properties['BackgroundDim']) {
        $settings | Add-Member -NotePropertyName BackgroundDim -NotePropertyValue 52 -Force
    }
    if (-not $settings.PSObject.Properties['ShowEditorHint']) {
        $settings | Add-Member -NotePropertyName ShowEditorHint -NotePropertyValue $true -Force
    }
    return $settings
}

function Save-AppSettings {
    param([Parameter(Mandatory)]$Settings)
    $Settings | ConvertTo-Json -Depth 4 | Set-Content -Path $script:SettingsPath -Encoding UTF8
}
