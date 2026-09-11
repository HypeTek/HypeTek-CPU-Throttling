# HypeTek CPU Throttling - runtime DPI-awareness probe
# Run while the packaged Store-test app is open. Does not require elevation.

$ErrorActionPreference = 'Stop'

$process = Get-Process -Name 'HypeTek-CPU-Throttling' -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object -First 1

if (-not $process) {
    Write-Host 'HypeTek CPU Throttling is not running with a visible main window.' -ForegroundColor Yellow
    Write-Host 'Launch the packaged app from Start, leave it open, and run this script again.'
    exit 2
}

if (-not ('HypeTekDpi.NativeMethods' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace HypeTekDpi
{
    public static class NativeMethods
    {
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowDpiAwarenessContext(IntPtr hwnd);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool AreDpiAwarenessContextsEqual(IntPtr dpiContextA, IntPtr dpiContextB);
    }
}
'@
}

$hwnd = [IntPtr]$process.MainWindowHandle
$context = [HypeTekDpi.NativeMethods]::GetWindowDpiAwarenessContext($hwnd)

$known = [ordered]@{
    'PerMonitorV2' = [IntPtr](-4)
    'PerMonitor'   = [IntPtr](-3)
    'SystemAware'  = [IntPtr](-2)
    'Unaware'      = [IntPtr](-1)
    'UnawareGdiScaled' = [IntPtr](-5)
}

$effective = 'Unknown'
foreach ($name in $known.Keys) {
    if ([HypeTekDpi.NativeMethods]::AreDpiAwarenessContextsEqual($context, $known[$name])) {
        $effective = $name
        break
    }
}

Write-Host 'HypeTek CPU Throttling - runtime DPI-awareness probe'
Write-Host ("Process ID: {0}" -f $process.Id)
Write-Host ("Main HWND : 0x{0:X}" -f $process.MainWindowHandle.ToInt64())
Write-Host ("Context   : {0}" -f $effective)

if ($effective -eq 'PerMonitorV2') {
    Write-Host 'PASS: The actual application window is running as PerMonitorV2 DPI-aware.' -ForegroundColor Green
    exit 0
}

Write-Host ("WARNING: Expected PerMonitorV2 but the actual window context is {0}." -f $effective) -ForegroundColor Yellow
exit 1
