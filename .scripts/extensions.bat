@echo off
REM VSCodium Extensions Manager Wrapper
REM This script delegates work to Extensions.ps1 for better profile support.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Extensions.ps1" %*
