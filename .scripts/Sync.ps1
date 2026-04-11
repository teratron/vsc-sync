# Windows: Скрипт для синхронизации настроек VSCodium и запуска IDE
# Разместите этот файл в папке: .scripts/Sync-Settings.ps1

$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$BaseDir = Split-Path $ScriptDir -Parent # Папка User
Push-Location $BaseDir

Write-Host "--- Проверка обновлений настроек из GitHub ---" -ForegroundColor Cyan

# 1. Загружаем изменения из репозитория
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Выполняю git pull..."
    git pull --rebase
} else {
    Write-Host "Git не найден. Пропускаю синхронизацию." -ForegroundColor Yellow
}

# 2. Устанавливаем расширения
if (Test-Path ".scripts\Extensions.ps1") {
    Write-Host "Обновление расширений для всех профилей..."
    & ".scripts\Extensions.ps1" sync-all
}

# 3. Запуск VSCodium
Write-Host "Запуск VSCodium..." -ForegroundColor Green

function Find-VSCodium {
    $cmd = Get-Command "codium" -ErrorAction SilentlyContinue
    if ($cmd) { return "codium" }
    
    $paths = @(
        "C:\Program Files\VSCodium\bin\codium.cmd",
        "C:\Program Files (x86)\VSCodium\bin\codium.cmd",
        "$env:LOCALAPPDATA\Programs\VSCodium\bin\codium.cmd"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

$VSCodium = Find-VSCodium
if ($VSCodium) {
    Start-Process -FilePath $VSCodium
} else {
    Write-Error "Не удалось найти VSCodium. Убедитесь, что он в PATH или установлен стандартно."
    Read-Host "Нажмите Enter для выхода..."
}

Pop-Location
