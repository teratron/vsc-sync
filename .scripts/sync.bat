@echo off
REM Windows CMD/BAT: Синхронизация и запуск VSCodium
SETLOCAL

REM Переходим в папку User (на уровень выше от .scripts)
SET "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

echo --- Checking for updates from GitHub ---

REM 1. Pull changes
where git >nul 2>&1
if %errorlevel% equ 0 (
    echo Running git pull...
    git pull --rebase
) else (
    echo Git not found. Skipping sync.
)

REM 2. Install extensions
if exist ".scripts\extensions.bat" (
    echo Updating extensions for all profiles...
    call ".scripts\extensions.bat" sync-all
)

REM 3. Launch VSCodium
echo Launching VSCodium...

set "VSCODIUM_CMD=codium"
where %VSCODIUM_CMD% >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Program Files\VSCodium\bin\codium.cmd" (
        set "VSCODIUM_CMD=C:\Program Files\VSCodium\bin\codium.cmd"
    ) else if exist "C:\Program Files (x86)\VSCodium\bin\codium.cmd" (
        set "VSCODIUM_CMD=C:\Program Files (x86)\VSCodium\bin\codium.cmd"
    ) else (
        echo Error: VSCodium not found.
        pause
        exit /b 1
    )
)

start "" "%VSCODIUM_CMD%"
ENDLOCAL
