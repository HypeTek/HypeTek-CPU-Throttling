@echo off
setlocal
cd /d "%~dp0"
start "" wscript.exe "%~dp0Start-CPU-Throttling.vbs"
exit /b 0
