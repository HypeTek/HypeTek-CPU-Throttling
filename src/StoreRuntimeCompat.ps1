Set-StrictMode -Version Latest

# Store/MSIX runtime compatibility helpers.
# These functions are deliberately kept on the experimental Store branch so the
# stable v0.2.0 release on main remains untouched while the packaged app is tested.

function Get-ActivePowerScheme {
    $guid = Get-ActiveSchemeGuid
    $name = Get-ActiveSchemeName -SchemeGuid $guid
    return [pscustomobject]@{
        Name        = $name
        Guid        = $guid
        GuidText    = $guid.ToString()
        IsActive    = $true
        DisplayName = "$name  [aktiv]"
    }
}

function Set-ActivePowerScheme {
    param(
        [Parameter(Mandatory)]
        [Guid]$SchemeGuid
    )

    Apply-ActiveScheme -SchemeGuid $SchemeGuid
    return "powercfg /setactive $SchemeGuid"
}

function Apply-ProfileValues {
    param(
        [Parameter(Mandatory)]$Profile,
        [Guid]$SchemeGuid = (Get-ActiveSchemeGuid)
    )

    $log = [System.Collections.Generic.List[string]]::new()
    $settings = @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')

    foreach ($setting in $settings) {
        if (-not (Test-PowerSettingSupport -Setting $setting)) {
            $log.Add("SKIP AC $setting (not supported)")
            continue
        }

        $value = $Profile.AC.$setting
        if ($null -eq $value) {
            $log.Add("SKIP AC $setting (no value)")
            continue
        }

        Set-PowerSettingValue -Setting $setting -Source AC -Value ([uint32]$value) -SchemeGuid $SchemeGuid
        $log.Add("WRITE AC $setting = $value")
    }

    if ([bool]$Profile.ApplyDC) {
        foreach ($setting in $settings) {
            if (-not (Test-PowerSettingSupport -Setting $setting)) {
                $log.Add("SKIP DC $setting (not supported)")
                continue
            }

            $value = $Profile.DC.$setting
            if ($null -eq $value) {
                $log.Add("SKIP DC $setting (no value)")
                continue
            }

            Set-PowerSettingValue -Setting $setting -Source DC -Value ([uint32]$value) -SchemeGuid $SchemeGuid
            $log.Add("WRITE DC $setting = $value")
        }
    }

    Apply-ActiveScheme -SchemeGuid $SchemeGuid
    $log.Add("APPLY scheme $SchemeGuid")

    return [pscustomobject]@{
        SchemeGuid = $SchemeGuid
        LogLines   = @($log)
    }
}

function Convert-StateToProfile {
    param(
        [Parameter(Mandatory)]$State,
        [string]$Name = 'Mein aktuelles Profil'
    )

    return [pscustomobject]@{
        Id      = [guid]::NewGuid().ToString()
        Name    = $Name
        ApplyDC = $true
        AC      = [pscustomobject]@{
            MaxFrequency = $State.AC.MaxFrequency
            MinState     = $State.AC.MinState
            MaxState     = $State.AC.MaxState
            BoostMode    = $State.AC.BoostMode
            CoolingPolicy= $State.AC.CoolingPolicy
            Epp          = $State.AC.Epp
        }
        DC      = [pscustomobject]@{
            MaxFrequency = $State.DC.MaxFrequency
            MinState     = $State.DC.MinState
            MaxState     = $State.DC.MaxState
            BoostMode    = $State.DC.BoostMode
            CoolingPolicy= $State.DC.CoolingPolicy
            Epp          = $State.DC.Epp
        }
    }
}

function New-DefaultProfile {
    param([string]$Name = 'Neues Profil')

    try {
        return Convert-StateToProfile -State (Get-SystemPowerState) -Name $Name
    }
    catch {
        return [pscustomobject]@{
            Id      = [guid]::NewGuid().ToString()
            Name    = $Name
            ApplyDC = $true
            AC      = [pscustomobject]@{ MaxFrequency=0; MinState=5; MaxState=100; BoostMode=1; CoolingPolicy=1; Epp=50 }
            DC      = [pscustomobject]@{ MaxFrequency=0; MinState=5; MaxState=80; BoostMode=0; CoolingPolicy=1; Epp=80 }
        }
    }
}
