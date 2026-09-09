Option Explicit

Dim shell, fso, baseDir, scriptPath, args
Set shell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

baseDir = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(baseDir, "CPU-Throttling.ps1")

If Not fso.FileExists(scriptPath) Then
    MsgBox "CPU-Throttling.ps1 wurde nicht gefunden:" & vbCrLf & scriptPath, vbCritical, "HypeTek CPU Throttling"
    WScript.Quit 2
End If

args = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """"

On Error Resume Next
shell.ShellExecute "powershell.exe", args, baseDir, "runas", 0
If Err.Number <> 0 Then
    MsgBox "HypeTek CPU Throttling konnte nicht gestartet werden." & vbCrLf & _
           "UAC wurde eventuell abgebrochen oder Windows PowerShell ist nicht verfuegbar." & vbCrLf & vbCrLf & _
           "Fehler: " & Err.Description, vbCritical, "HypeTek CPU Throttling"
    WScript.Quit 1
End If
On Error GoTo 0
