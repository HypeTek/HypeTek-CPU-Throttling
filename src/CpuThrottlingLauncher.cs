using System;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("HypeTek CPU Throttling")]
[assembly: AssemblyProduct("HypeTek CPU Throttling")]
[assembly: AssemblyCompany("HypeTek")]
[assembly: AssemblyDescription("Native Windows launcher for HypeTek CPU Throttling")]
[assembly: AssemblyCopyright("Copyright © 2026 HypeTek")]
[assembly: AssemblyVersion("0.2.0.0")]
[assembly: AssemblyFileVersion("0.2.0.0")]

namespace HypeTek.CpuThrottling.Launcher
{
    internal static class Program
    {
        // DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = ((DPI_AWARENESS_CONTEXT)-4)
        // The manifest remains the primary declaration. This API call is an early
        // runtime fallback and also gives WACK a second standards-compliant DPI signal.
        private static readonly IntPtr DpiAwarenessContextPerMonitorAwareV2 = new IntPtr(-4);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);

        private static void TryEnablePerMonitorV2Dpi()
        {
            try
            {
                // Must run before any UI is created. If the embedded manifest has
                // already established the process DPI mode Windows may return FALSE
                // with ERROR_ACCESS_DENIED; that is expected and can be ignored.
                SetProcessDpiAwarenessContext(DpiAwarenessContextPerMonitorAwareV2);
            }
            catch (EntryPointNotFoundException)
            {
                // Defensive fallback for unsupported Windows versions. The MSIX
                // currently targets Windows 10 2004+ where this API is available.
            }
        }

        [STAThread]
        private static int Main()
        {
            TryEnablePerMonitorV2Dpi();

            string exeDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(
                Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string appDir = Path.Combine(exeDir, "app");
            string srcDir = Path.Combine(appDir, "src");
            string powerCfgPath = Path.Combine(srcDir, "PowerCfg.ps1");
            string profileManagerPath = Path.Combine(srcDir, "ProfileManager.ps1");
            string storeCompatPath = Path.Combine(srcDir, "StoreRuntimeCompat.ps1");
            string mainPath = Path.Combine(srcDir, "Main.ps1");

            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string logDir = Path.Combine(localAppData, "HypeTek", "CPU-Throttling", "logs");
            string logPath = Path.Combine(logDir, "startup.log");

            if (!Directory.Exists(appDir))
            {
                MessageBox.Show(
                    "Der Programmordner 'app' wurde nicht gefunden.\r\n\r\n" +
                    "Bitte HypeTek-CPU-Throttling.exe zusammen mit dem kompletten app-Ordner verwenden.",
                    "HypeTek CPU Throttling",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 2;
            }

            foreach (string required in new[] { powerCfgPath, profileManagerPath, storeCompatPath, mainPath })
            {
                if (!File.Exists(required))
                {
                    MessageBox.Show(
                        "Eine erforderliche Programmdatei wurde nicht gefunden:\r\n" + required,
                        "HypeTek CPU Throttling",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error);
                    return 2;
                }
            }

            try
            {
                Directory.CreateDirectory(logDir);
                File.AppendAllText(logPath,
                    "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + "] Native EXE start; appDir=" + appDir + "\r\n",
                    Encoding.UTF8);

                // All resource and application paths stay relative to appDir.
                Environment.SetEnvironmentVariable("HYPETEK_CPU_THROTTLING_BASEDIR", appDir);

                InitialSessionState state = InitialSessionState.CreateDefault();
                try { state.ExecutionPolicy = Microsoft.PowerShell.ExecutionPolicy.Bypass; }
                catch { }

                using (Runspace runspace = RunspaceFactory.CreateRunspace(state))
                {
                    runspace.ApartmentState = ApartmentState.STA;
                    runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                    runspace.Open();

                    using (PowerShell ps = PowerShell.Create())
                    {
                        ps.Runspace = runspace;

                        string escapedAppDir = appDir.Replace("'", "''");
                        ps.AddScript("Set-Location -LiteralPath '" + escapedAppDir + "'");
                        ps.AddScript(File.ReadAllText(powerCfgPath, Encoding.UTF8));
                        ps.AddScript(File.ReadAllText(profileManagerPath, Encoding.UTF8));
                        ps.AddScript(File.ReadAllText(storeCompatPath, Encoding.UTF8));
                        ps.AddScript(File.ReadAllText(mainPath, Encoding.UTF8));
                        ps.Invoke();

                        if (ps.HadErrors)
                        {
                            StringBuilder sb = new StringBuilder();
                            sb.AppendLine("[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + "] Native host PowerShell errors:");
                            foreach (ErrorRecord error in ps.Streams.Error)
                                sb.AppendLine(error.ToString());
                            File.AppendAllText(logPath, sb.ToString(), Encoding.UTF8);

                            MessageBox.Show(
                                "HypeTek CPU Throttling hat einen Fehler gemeldet.\r\n\r\nDetails:\r\n" + logPath,
                                "HypeTek CPU Throttling",
                                MessageBoxButtons.OK,
                                MessageBoxIcon.Error);
                            return 1;
                        }
                    }
                }
                return 0;
            }
            catch (Exception ex)
            {
                try
                {
                    Directory.CreateDirectory(logDir);
                    File.AppendAllText(logPath,
                        "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + "] FATAL\r\n" + ex + "\r\n",
                        Encoding.UTF8);
                }
                catch { }

                MessageBox.Show(
                    "HypeTek CPU Throttling konnte nicht gestartet werden.\r\n\r\nDetails:\r\n" + logPath,
                    "HypeTek CPU Throttling",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 1;
            }
        }
    }
}
