using System;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;

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
        [STAThread]
        private static int Main()
        {
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
