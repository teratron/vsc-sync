@echo off
REM Windows CMD/BAT: sync -> launch VSCodium -> wait for close -> export
SETLOCAL

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch.ps1"

ENDLOCAL
