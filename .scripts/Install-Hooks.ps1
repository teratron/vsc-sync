# Windows: подключает versioned git hooks из репозитория

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $MyInvocation.MyCommand.Path -Parent }
$UserDir = Split-Path $ScriptDir -Parent

Push-Location $UserDir

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git executable was not found."
    }

    git config --local core.hooksPath .githooks
    Write-Host "Git hooks path configured locally: .githooks" -ForegroundColor Green
} finally {
    Pop-Location
}
