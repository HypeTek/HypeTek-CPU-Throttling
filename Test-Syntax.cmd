@echo off
setlocal
cd /d "%~dp0"
echo HypeTek CPU Power Control - PowerShell 5.1 syntax test
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-Syntax.ps1"
echo.
pause
endlocal
