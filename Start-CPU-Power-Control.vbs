Option Explicit

Dim shell, fso, baseDir, scriptPath, args
Set shell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

baseDir = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(baseDir, "CPU-Power-Control.ps1")

If Not fso.FileExists(scriptPath) Then
    MsgBox "CPU-Power-Control.ps1 wurde nicht gefunden:" & vbCrLf & scriptPath, vbCritical, "HypeTek CPU Power Control"
    WScript.Quit 2
End If

' Run Windows PowerShell 5.1 elevated and hidden. Only the WPF application window remains visible.
args = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """"

On Error Resume Next
shell.ShellExecute "powershell.exe", args, baseDir, "runas", 0
If Err.Number <> 0 Then
    MsgBox "HypeTek CPU Power Control konnte nicht gestartet werden." & vbCrLf & _
           "UAC wurde eventuell abgebrochen oder Windows PowerShell ist nicht verfuegbar." & vbCrLf & vbCrLf & _
           "Fehler: " & Err.Description, vbCritical, "HypeTek CPU Power Control"
    WScript.Quit 1
End If
On Error GoTo 0
