@echo off
rem Double-click to run. Windows will ask for administrator permission.
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_patch\filament-patch.ps1" -Undo
echo.
pause
