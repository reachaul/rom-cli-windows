@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-ROM-CLI-Windows.ps1"
set "INSTALL_EXIT=%ERRORLEVEL%"
echo.
if not "%INSTALL_EXIT%"=="0" (
  echo ROM CLI installation failed. Review the error messages above.
) else (
  echo ROM CLI for Windows was installed successfully.
)
pause
exit /b %INSTALL_EXIT%
