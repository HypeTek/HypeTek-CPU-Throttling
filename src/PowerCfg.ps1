Set-StrictMode -Version Latest

$script:PowerGuids = [ordered]@{
    SubProcessor = [Guid]'54533251-82be-4824-96c1-47b60b740d00'
    MinState     = [Guid]'893dee8e-2bef-41e0-89c6-b55d0929964c' # PROCTHROTTLEMIN
    MaxState     = [Guid]'bc5038f7-23e0-4960-96da-33abaf5935ec' # PROCTHROTTLEMAX
    MaxFrequency = [Guid]'75b0ae3f-bce0-45a7-8c89-c9611c25e100' # PROCFREQMAX
    BoostMode    = [Guid]'be337238-0d82-4146-a960-4f3749d470c7' # PERFBOOSTMODE
    CoolingPolicy= [Guid]'94d3a615-a899-4ac5-ae2b-e4d8f634367f' # SYSCOOLPOL
    Epp          = [Guid]'36687f9e-e3a5-4dbf-b1dc-15eb381c6863' # PERFEPP
}

if (-not ('CpuThrottling.PowerApi' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace CpuThrottling {
    public static class PowerApi {
        [DllImport("powrprof.dll", SetLastError=true)]
        public static extern uint PowerGetActiveScheme(IntPtr UserRootPowerKey, out IntPtr ActivePolicyGuid);

        [DllImport("powrprof.dll", SetLastError=true)]
        public static extern uint PowerSetActiveScheme(IntPtr UserRootPowerKey, ref Guid SchemeGuid);

        [DllImport("powrprof.dll", SetLastError=true)]
        public static extern uint PowerReadACValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupOfPowerSettingsGuid, ref Guid PowerSettingGuid, out uint AcValueIndex);

        [DllImport("powrprof.dll", SetLastError=true)]
        public static extern uint PowerReadDCValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupOfPowerSettingsGuid, ref Guid PowerSettingGuid, out uint DcValueIndex);

        [DllImport("powrprof.dll", SetLastError=true)]
        public static extern uint PowerWriteACValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupOfPowerSettingsGuid, ref Guid PowerSettingGuid, uint AcValueIndex);

        [DllImport("powrprof.dll", SetLastError=true)]
        public static extern uint PowerWriteDCValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupOfPowerSettingsGuid, ref Guid PowerSettingGuid, uint DcValueIndex);

        [DllImport("kernel32.dll")]
        public static extern IntPtr LocalFree(IntPtr hMem);
    }
}
"@
}

function Get-ActiveSchemeGuid {
    $ptr = [IntPtr]::Zero
    $result = [CpuThrottling.PowerApi]::PowerGetActiveScheme([IntPtr]::Zero, [ref]$ptr)
    if ($result -ne 0 -or $ptr -eq [IntPtr]::Zero) {
        throw "PowerGetActiveScheme failed with Win32 error $result."
    }
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][Guid])
    }
    finally {
        [void][CpuThrottling.PowerApi]::LocalFree($ptr)
    }
}

function Get-ActiveSchemeName {
    param([Guid]$SchemeGuid)
    try {
        $raw = (& powercfg.exe /getactivescheme 2>$null | Out-String).Trim()
        $match = [regex]::Match($raw, '\((?<name>.+)\)\s*\*?\s*$')
        if ($match.Success) { return $match.Groups['name'].Value.Trim() }
    }
    catch { }
    return $SchemeGuid.ToString()
}

function Get-PowerSchemes {
    $activeGuid = Get-ActiveSchemeGuid
    $results = New-Object 'System.Collections.Generic.List[object]'

    try {
        $raw = (& powercfg.exe /list 2>$null | Out-String)
        $pattern = '(?im)^\s*.*?(?<guid>[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})\s+\((?<name>.*)\)\s*(?<active>\*)?\s*$'
        $seen = @{}
        foreach ($match in [regex]::Matches($raw, $pattern)) {
            $guidText = $match.Groups['guid'].Value.ToLowerInvariant()
            if ($seen.ContainsKey($guidText)) { continue }
            $seen[$guidText] = $true
            $guid = [Guid]$guidText
            $name = $match.Groups['name'].Value.Trim()
            if ([string]::IsNullOrWhiteSpace($name)) { $name = $guidText }
            $results.Add([pscustomobject]@{
                Name = $name
                Guid = $guid
                GuidText = $guid.ToString()
                IsActive = ($guid -eq $activeGuid)
                DisplayName = if ($guid -eq $activeGuid) { "$name  [aktiv]" } else { $name }
            })
        }
    }
    catch { }

    if ($results.Count -eq 0) {
        $name = Get-ActiveSchemeName -SchemeGuid $activeGuid
        $results.Add([pscustomobject]@{
            Name = $name
            Guid = $activeGuid
            GuidText = $activeGuid.ToString()
            IsActive = $true
            DisplayName = "$name  [aktiv]"
        })
    }

    return @($results | Sort-Object @{Expression='IsActive';Descending=$true}, Name)
}

function Get-PowerSettingValue {
    param(
        [Parameter(Mandatory)][ValidateSet('MinState','MaxState','MaxFrequency','BoostMode','CoolingPolicy','Epp')][string]$Setting,
        [Parameter(Mandatory)][ValidateSet('AC','DC')][string]$Source,
        [Guid]$SchemeGuid = (Get-ActiveSchemeGuid)
    )

    $sub = $script:PowerGuids.SubProcessor
    $settingGuid = $script:PowerGuids[$Setting]
    [uint32]$value = 0

    if ($Source -eq 'AC') {
        $result = [CpuThrottling.PowerApi]::PowerReadACValueIndex([IntPtr]::Zero, [ref]$SchemeGuid, [ref]$sub, [ref]$settingGuid, [ref]$value)
    }
    else {
        $result = [CpuThrottling.PowerApi]::PowerReadDCValueIndex([IntPtr]::Zero, [ref]$SchemeGuid, [ref]$sub, [ref]$settingGuid, [ref]$value)
    }

    if ($result -ne 0) { return $null }
    return [int64]$value
}

function Test-PowerSettingSupport {
    param([Parameter(Mandatory)][string]$Setting)
    try {
        return ((Get-PowerSettingValue -Setting $Setting -Source AC) -ne $null)
    }
    catch { return $false }
}

function Set-PowerSettingValue {
    param(
        [Parameter(Mandatory)][ValidateSet('MinState','MaxState','MaxFrequency','BoostMode','CoolingPolicy','Epp')][string]$Setting,
        [Parameter(Mandatory)][ValidateSet('AC','DC')][string]$Source,
        [Parameter(Mandatory)][uint32]$Value,
        [Guid]$SchemeGuid = (Get-ActiveSchemeGuid)
    )

    $sub = $script:PowerGuids.SubProcessor
    $settingGuid = $script:PowerGuids[$Setting]

    if ($Source -eq 'AC') {
        $result = [CpuThrottling.PowerApi]::PowerWriteACValueIndex([IntPtr]::Zero, [ref]$SchemeGuid, [ref]$sub, [ref]$settingGuid, $Value)
    }
    else {
        $result = [CpuThrottling.PowerApi]::PowerWriteDCValueIndex([IntPtr]::Zero, [ref]$SchemeGuid, [ref]$sub, [ref]$settingGuid, $Value)
    }

    if ($result -ne 0) {
        throw "Could not write $Setting ($Source). Win32 error: $result"
    }
}

function Apply-ActiveScheme {
    param([Guid]$SchemeGuid = (Get-ActiveSchemeGuid))
    $result = [CpuThrottling.PowerApi]::PowerSetActiveScheme([IntPtr]::Zero, [ref]$SchemeGuid)
    if ($result -ne 0) { throw "PowerSetActiveScheme failed with Win32 error $result." }
}


function Get-LiveCpuTelemetry {
    $load = $null
    $current = $null
    $baseMax = $null
    $temp = $null
    $loadSource = 'Unavailable'
    $clockSource = 'Unavailable'
    $utility = $null
    $percentMax = $null
    $percentPerformance = $null
    $perfFrequency = $null

    function Get-CimNumericProperty {
        param([object]$Object,[string]$Name)
        try {
            if ($null -eq $Object) { return $null }
            $prop = $Object.CimInstanceProperties[$Name]
            if ($prop -and $null -ne $prop.Value) { return [double]$prop.Value }
        } catch { }
        return $null
    }

    # Very low-overhead CPU busy-time sampler. Repeated CIM polling itself can
    # noticeably influence the load reading on some systems, so live load is
    # measured from GetSystemTimes deltas instead.
    if (-not ('CpuThrottling.TelemetryNative' -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace CpuThrottling {
    [StructLayout(LayoutKind.Sequential)]
    public struct FILETIME_COUNTER {
        public uint Low;
        public uint High;
    }
    public static class TelemetryNative {
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool GetSystemTimes(
            out FILETIME_COUNTER idleTime,
            out FILETIME_COUNTER kernelTime,
            out FILETIME_COUNTER userTime);
    }
}
"@
    }

    function Convert-FileTimeCounterToUInt64 {
        param($Counter)
        return (([uint64]$Counter.High -shl 32) -bor [uint64]$Counter.Low)
    }

    try {
        $idle = New-Object CpuThrottling.FILETIME_COUNTER
        $kernel = New-Object CpuThrottling.FILETIME_COUNTER
        $user = New-Object CpuThrottling.FILETIME_COUNTER
        if ([CpuThrottling.TelemetryNative]::GetSystemTimes([ref]$idle,[ref]$kernel,[ref]$user)) {
            [uint64]$idleNow = Convert-FileTimeCounterToUInt64 $idle
            [uint64]$kernelNow = Convert-FileTimeCounterToUInt64 $kernel
            [uint64]$userNow = Convert-FileTimeCounterToUInt64 $user
            [uint64]$totalNow = $kernelNow + $userNow

            if ($null -ne $script:TelemetryPrevTotal -and $totalNow -gt [uint64]$script:TelemetryPrevTotal) {
                [double]$deltaTotal = [double]($totalNow - [uint64]$script:TelemetryPrevTotal)
                [double]$deltaIdle = [double]($idleNow - [uint64]$script:TelemetryPrevIdle)
                if ($deltaTotal -gt 0) {
                    $busy = (($deltaTotal - $deltaIdle) / $deltaTotal) * 100.0
                    $load = [int][math]::Round([math]::Max(0,[math]::Min(100,$busy)))
                    $loadSource = 'Windows GetSystemTimes'
                }
            }

            $script:TelemetryPrevIdle = $idleNow
            $script:TelemetryPrevTotal = $totalNow
        }
    } catch { }

    # Cache the processor nominal/base clock; this value does not change during
    # the session and Win32_Processor is comparatively expensive to query.
    if ($null -eq $script:TelemetryBaseClockMHz) {
        try {
            $cpus = @(Get-CimInstance Win32_Processor -ErrorAction Stop)
            $maxes = @($cpus | ForEach-Object {
                if ($null -ne $_.MaxClockSpeed) { [double]$_.MaxClockSpeed }
            })
            if ($maxes.Count) {
                $script:TelemetryBaseClockMHz = [int][math]::Round(($maxes | Measure-Object -Maximum).Maximum)
            }
        } catch { }
    }
    $baseMax = $script:TelemetryBaseClockMHz

    # Windows' Processor Information provider exposes % Processor Performance.
    # Unlike Win32_Processor.CurrentClockSpeed and "% of Maximum Frequency",
    # this counter can exceed 100% during Turbo and is therefore suitable for
    # deriving the Task-Manager-like effective package clock from base speed.
    try {
        $perfRows = @(Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction Stop)
        $perf = $perfRows | Where-Object { [string]$_.Name -eq '_Total' } | Select-Object -First 1
        if (-not $perf) {
            $perf = $perfRows | Where-Object { [string]$_.Name -like '*,_Total' } | Select-Object -First 1
        }
        if (-not $perf -and $perfRows.Count -eq 1) { $perf = $perfRows[0] }

        if ($perf) {
            $utility = Get-CimNumericProperty $perf 'PercentProcessorUtility'
            $percentPerformance = Get-CimNumericProperty $perf 'PercentProcessorPerformance'
            $percentMax = Get-CimNumericProperty $perf 'PercentofMaximumFrequency'
            $perfFrequency = Get-CimNumericProperty $perf 'ProcessorFrequency'

            if ($null -eq $load -and $null -ne $utility) {
                # First UI sample has no GetSystemTimes delta yet. Use the
                # Task-Manager family utility counter only for this warm-up.
                $load = [int][math]::Round([math]::Max(0,[math]::Min(100,$utility)))
                $loadSource = 'Windows Processor Utility (warm-up)'
            }

            if ($null -ne $percentPerformance -and $null -ne $baseMax -and $baseMax -gt 0 -and $percentPerformance -gt 0) {
                $current = [int][math]::Round(([double]$baseMax * [double]$percentPerformance) / 100.0)
                $clockSource = '% Processor Performance × base clock'
            }
            elseif ($null -ne $perfFrequency -and $perfFrequency -gt 0) {
                $current = [int][math]::Round($perfFrequency)
                $clockSource = 'ProcessorFrequency fallback'
            }
        }
    } catch { }

    # Last-resort fallback only.
    if ($null -eq $current) {
        try {
            $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
            if ($cpu -and $null -ne $cpu.CurrentClockSpeed) {
                $current = [int][math]::Round([double]$cpu.CurrentClockSpeed)
                $clockSource = 'Win32_Processor fallback'
            }
        } catch { }
    }


    return [pscustomobject]@{
        LoadPercent = $load
        CurrentClockMHz = $current
        BaseClockMHz = $baseMax
        Source = "Load: $loadSource; Clock: $clockSource"
        LoadSource = $loadSource
        ClockSource = $clockSource
        ProcessorUtilityPercent = $utility
        PercentProcessorPerformance = $percentPerformance
        PercentOfMaximumFrequency = $percentMax
        ProviderFrequencyMHz = $perfFrequency
    }
}

function Get-SystemPowerState {
    $scheme = Get-ActiveSchemeGuid
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $os = Get-CimInstance Win32_OperatingSystem

    $support = [ordered]@{}
    foreach ($name in @('MaxFrequency','MinState','MaxState','BoostMode','CoolingPolicy','Epp')) {
        $support[$name] = Test-PowerSettingSupport -Setting $name
    }

    $ac = [ordered]@{}
    $dc = [ordered]@{}
    foreach ($name in $support.Keys) {
        $ac[$name] = Get-PowerSettingValue -Setting $name -Source AC -SchemeGuid $scheme
        $dc[$name] = Get-PowerSettingValue -Setting $name -Source DC -SchemeGuid $scheme
    }

    [pscustomobject]@{
        CpuName      = if ($cpu) { $cpu.Name.Trim() } else { 'Unknown CPU' }
        Manufacturer = if ($cpu) { $cpu.Manufacturer } else { 'Unknown' }
        OsName       = if ($os) { $os.Caption } else { 'Windows' }
        OsVersion    = if ($os) { $os.Version } else { '' }
        Architecture = $env:PROCESSOR_ARCHITECTURE
        SchemeGuid   = $scheme
        SchemeName   = Get-ActiveSchemeName -SchemeGuid $scheme
        Support      = [pscustomobject]$support
        AC           = [pscustomobject]$ac
        DC           = [pscustomobject]$dc
    }
}

function Get-EquivalentPowerCfgCommands {
    param(
        [Parameter(Mandatory)]$Profile,
        [Guid]$SchemeGuid = (Get-ActiveSchemeGuid)
    )

    $aliases = @{
        MaxFrequency = 'PROCFREQMAX'
        MinState      = 'PROCTHROTTLEMIN'
        MaxState      = 'PROCTHROTTLEMAX'
        BoostMode     = 'PERFBOOSTMODE'
        CoolingPolicy = 'SYSCOOLPOL'
        Epp           = 'PERFEPP'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $aliases.Keys) {
        $value = $Profile.AC.$name
        $lines.Add("powercfg /setacvalueindex $SchemeGuid SUB_PROCESSOR $($aliases[$name]) $value")
    }
    if ($Profile.ApplyDC) {
        foreach ($name in $aliases.Keys) {
            $value = $Profile.DC.$name
            $lines.Add("powercfg /setdcvalueindex $SchemeGuid SUB_PROCESSOR $($aliases[$name]) $value")
        }
    }
    $lines.Add("powercfg /setactive $SchemeGuid")
    return $lines
}
