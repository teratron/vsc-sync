@echo off
REM Windows CMD: Синхронизация и запуск VSCodium
SETLOCAL

SET "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

echo --- Checking for updates from GitHub ---

where git >nul 2>&1
if %errorlevel% equ 0 (
    echo Running git pull...
    git pull --rebase
) else (
    echo Git not found. Skipping sync.
)

if exist ".scripts\extensions.cmd" (
    echo Updating extensions for all profiles...
    call ".scripts\extensions.cmd" sync-all
)

echo Launching VSCodium...

set "VSCODIUM_CMD=codium"
where %VSCODIUM_CMD% >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Program Files\VSCodium\bin\codium.cmd" (
        set "VSCODIUM_CMD=C:\Program Files\VSCodium\bin\codium.cmd"
    ) else if exist "C:\Program Files (x86)\VSCodium\bin\codium.cmd" (
        set "VSCODIUM_CMD=C:\Program Files (x86)\VSCodium\bin\codium.cmd"
    )
)

start "" "%VSCODIUM_CMD%"
ENDLOCAL
