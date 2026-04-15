# Windows: Скрипт для синхронизации настроек VSCodium (запускается автоматически при старте IDE)
# НЕ запускает VSCodium повторно!

$BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $MyInvocation.MyCommand.Path -Parent }
Push-Location $BaseDir

Write-Host "--- Синхронизация настроек ---" -ForegroundColor Cyan

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git pull..."
    git pull --rebase 2>&1 | Out-Null
}

if (Test-Path ".scripts\Extensions.ps1") {
    & ".scripts\Extensions.ps1" sync-all 2>$null
}

Pop-Location
