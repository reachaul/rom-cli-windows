@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-ROM-CLI-Windows.ps1"
if errorlevel 1 (
  echo.
  echo Installation failed. Read the error above.
  pause
  exit /b 1
)
echo.
echo ROM CLI Windows installation completed.
pause
