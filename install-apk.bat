@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-apk.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
if "%EXITCODE%"=="0" (
    echo [RESULT] Install finished successfully.
) else (
    echo [RESULT] Install FAILED - exit code %EXITCODE%. See messages above.
)
echo.
echo Press any key to close this window...
pause >nul
