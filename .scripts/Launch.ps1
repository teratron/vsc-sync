# Windows: синхронизирует настройки, запускает VSCodium, ждёт закрытия и затем делает export

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $MyInvocation.MyCommand.Path -Parent }
$UserDir = Split-Path $ScriptDir -Parent

function Find-VSCodium {
    $cmd = Get-Command "codium" -ErrorAction SilentlyContinue
    if ($cmd) { return "codium" }

    $path = "C:\Program Files\VSCodium\bin\codium.cmd"
    if (Test-Path $path) { return $path }

    throw "VSCodium executable was not found."
}

Push-Location $UserDir

try {
    & (Join-Path $ScriptDir "Sync.ps1")
    $VSCodium = Find-VSCodium
    Write-Host "Launching VSCodium and waiting for window close..." -ForegroundColor Cyan
    & $VSCodium --wait $UserDir
    Write-Host "VSCodium closed. Exporting local profile state..." -ForegroundColor Cyan
    & (Join-Path $ScriptDir "Export.ps1")
} finally {
    Pop-Location
}
