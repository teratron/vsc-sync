@echo off
REM VSCodium Extensions Manager
REM Usage: extensions.bat [command]
REM Commands:
REM   list    - Export installed extensions to extensions.list
REM   install - Install extensions from extensions.list
REM   show    - Show installed extensions
REM   help    - Show this help message

set "VSCODIUM_CMD=codium"
set "EXTENSIONS_FILE=extensions.list"

REM Check if codium is in PATH
where %VSCODIUM_CMD% >nul 2>&1
if %errorlevel% neq 0 (
    REM Try standard installation paths
    if exist "C:\Program Files\VSCodium\bin\codium.cmd" (
        set "VSCODIUM_CMD=C:\Program Files\VSCodium\bin\codium.cmd"
    ) else if exist "C:\Program Files (x86)\VSCodium\bin\codium.cmd" (
        set "VSCODIUM_CMD=C:\Program Files (x86)\VSCodium\bin\codium.cmd"
    ) else (
        echo Error: VSCodium not found. Please add it to PATH.
        pause
        exit /b 1
    )
)

if "%1"=="list" goto list
if "%1"=="install" goto install
if "%1"=="show" goto show
if "%1"=="help" goto help
if "%1"=="" goto help

goto help

:list
echo Exporting installed extensions to %EXTENSIONS_FILE%...
%VSCODIUM_CMD% --list-extensions > "%EXTENSIONS_FILE%"
echo Done! Extensions saved to %EXTENSIONS_FILE%
pause
exit /b 0

:install
if not exist "%EXTENSIONS_FILE%" (
    echo Error: %EXTENSIONS_FILE% not found!
    echo Use 'extensions.bat list' first to create it.
    pause
    exit /b 1
)

echo Installing extensions from %EXTENSIONS_FILE%...
for /f "usebackq delims=" %%a in ("%EXTENSIONS_FILE%") do (
    echo %%a | findstr /r "^#" >nul
    if errorlevel 1 (
        echo %%a | findstr /r "^[a-zA-Z]" >nul
        if not errorlevel 1 (
            echo Installing: %%a
            %VSCODIUM_CMD% --install-extension "%%a"
        )
    )
)
echo Done! All extensions installed.
pause
exit /b 0

:show
echo Installed extensions:
echo ---------------------
%VSCODIUM_CMD% --list-extensions
pause
exit /b 0

:help
echo VSCodium Extensions Manager
echo.
echo Usage: extensions.bat [command]
echo.
echo Commands:
echo   list    - Export installed extensions to %EXTENSIONS_FILE%
echo   install - Install extensions from %EXTENSIONS_FILE%
echo   show    - Show installed extensions
echo   help    - Show this help message
echo.
echo Examples:
echo   extensions.bat list      - Save current extensions
echo   extensions.bat install   - Install from saved list
echo   extensions.bat show      - View installed extensions
pause
exit /b 0
