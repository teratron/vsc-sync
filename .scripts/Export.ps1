# Windows: экспортирует текущие профили и расширения из VSCodium в репозиторий

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $MyInvocation.MyCommand.Path -Parent }
$UserDir = Split-Path $ScriptDir -Parent

Push-Location $UserDir

try {
    & (Join-Path $ScriptDir "Extensions.ps1") list-all
} finally {
    Pop-Location
}
