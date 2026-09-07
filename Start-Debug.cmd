@echo off
setlocal
cd /d "%~dp0"
echo HypeTek CPU Power Control - Debug Start
echo.
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -NoExit -Command "try { & '%~dp0CPU-Power-Control.ps1' } catch { Write-Host $_ -ForegroundColor Red }"
endlocal
