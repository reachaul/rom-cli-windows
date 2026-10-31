@echo off
setlocal
 title ROM CLI Windows Installer
 echo ========================================
 echo        ROM CLI for Windows
 echo ========================================
 echo.
 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-ROM-CLI-Windows.ps1"
 if errorlevel 1 (
   echo.
   echo Installation failed. Review the error above.
   pause
   exit /b 1
 )
 echo.
 echo Installation completed successfully.
 pause
endlocal
