@echo off
REM Windows CMD: Скрипт синхронизации настроек (запускается автоматически)
SETLOCAL

cd /d "%~dp0.."

where git >nul 2>&1
if %errorlevel% equ 0 (
    git pull --rebase 2>nul
)

if exist ".scripts\extensions.cmd" (
    call ".scripts\extensions.cmd" sync-all 2>nul
)

ENDLOCAL
