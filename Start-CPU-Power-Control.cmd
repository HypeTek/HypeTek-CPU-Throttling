@echo off
setlocal
cd /d "%~dp0"
start "" wscript.exe "%~dp0Start-CPU-Power-Control.vbs"
exit /b 0
