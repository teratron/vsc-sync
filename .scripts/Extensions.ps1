# Менеджер профилей VSCodium с переносимыми шаблонами
# Использование: .\Extensions.ps1 [command] [profile_name]

param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1)]
    [string]$ProfileName
)

$UserDir = Split-Path $PSScriptRoot -Parent
$StorageFile = Join-Path $UserDir "globalStorage\storage.json"
$ProfilesListFile = Join-Path $UserDir "profiles.list"
$ProfileTemplatesDir = Join-Path $UserDir "profile-templates"
$TrackedFiles = @("settings.json", "keybindings.json", "tasks.json", "launch.json", "projects.json")

# ---------------------------------------------------------------------------
# Утилиты
# ---------------------------------------------------------------------------

function Find-VSCodium {
    $cmd = Get-Command "codium" -ErrorAction SilentlyContinue
    if ($cmd) { return "codium" }

    $path = "C:\Program Files\VSCodium\bin\codium.cmd"
    if (Test-Path $path) { return $path }

    throw "VSCodium executable was not found. Make sure 'codium' is in PATH."
}

function Get-StorageData {
    if (-not (Test-Path $StorageFile)) { return $null }
    try {
        return Get-Content $StorageFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to parse storage.json: $_"
        return $null
    }
}

# ---------------------------------------------------------------------------
# Парсинг storage.json — централизованный, на основе PowerShell JSON
# ---------------------------------------------------------------------------

function Get-LiveProfileMap {
    $map = @{ "__default__" = "." }
    $storage = Get-StorageData

    if ($storage -and $storage.userDataProfiles) {
        foreach ($profile in $storage.userDataProfiles) {
            if ($profile.name -and $profile.location) {
                $map[$profile.name] = "profiles/$($profile.location)"
            }
        }
    }

    return $map
}

function Get-LiveProfileNames {
    $storage = Get-StorageData
    if (-not $storage -or -not $storage.userDataProfiles) { return @() }
    return @(
        $storage.userDataProfiles |
            Where-Object { $_.name } |
            Select-Object -ExpandProperty name |
            Sort-Object -Unique
    )
}

# ---------------------------------------------------------------------------
# profiles.list: чтение и запись (MERGE, не перезапись!)
# ---------------------------------------------------------------------------

function Get-TrackedProfileNames {
    if (-not (Test-Path $ProfilesListFile)) { return @() }
    return @(
        Get-Content $ProfilesListFile -Encoding UTF8 |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith("#") } |
            Sort-Object -Unique
    )
}

# ВАЖНО: объединяем уже записанные имена с именами из локального storage,
# чтобы не потерять профили других машин при коммите с одной машины
function Set-TrackedProfileNames {
    param([string[]]$NewNames)

    $existing = Get-TrackedProfileNames
    $merged = @(
        ($existing + $NewNames) |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    Set-Content -Path $ProfilesListFile -Value $merged -Encoding UTF8
}

# ---------------------------------------------------------------------------
# Вспомогательные функции
# ---------------------------------------------------------------------------

function Get-TemplateDir {
    param([string]$ProfileName)
    if ($ProfileName -eq "__default__") { return $UserDir }
    return Join-Path $ProfileTemplatesDir $ProfileName
}

function Get-ExtensionFile {
    param([string]$ProfileName)
    return Join-Path (Get-TemplateDir $ProfileName) "extensions.list"
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-ProfileData {
    param([string]$SourceDir, [string]$DestinationDir)

    Ensure-Directory $DestinationDir

    foreach ($file in $TrackedFiles) {
        $src = Join-Path $SourceDir $file
        $dst = Join-Path $DestinationDir $file
        if (Test-Path $src) {
            Copy-Item -LiteralPath $src -Destination $dst -Force
        }
    }

    $srcSnippets = Join-Path $SourceDir "snippets"
    if (Test-Path $srcSnippets) {
        $dstSnippets = Join-Path $DestinationDir "snippets"
        Ensure-Directory $dstSnippets
        Get-ChildItem -LiteralPath $srcSnippets -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dstSnippets $_.Name) -Recurse -Force
        }
    }
}

# ---------------------------------------------------------------------------
# Создание профиля (если ещё не существует)
# ---------------------------------------------------------------------------

function Ensure-ProfileExists {
    param([string]$Name)

    if ($Name -eq "__default__") { return $true }

    $profileMap = Get-LiveProfileMap
    if ($profileMap.ContainsKey($Name)) { return $true }

    Write-Host "⚙️  Profile [$Name] not found locally. Attempting to create..." -ForegroundColor Cyan

    # Попытка 1: простой вызов --list-extensions
    & $script:VSCodium --profile $Name --list-extensions 2>$null | Out-Null
    $profileMap = Get-LiveProfileMap
    if ($profileMap.ContainsKey($Name)) { return $true }

    # Попытка 2: установить первое расширение из шаблона
    $extFile = Get-ExtensionFile $Name
    if (Test-Path $extFile) {
        $seedExtension = Get-Content $extFile -Encoding UTF8 |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith("#") } |
            Select-Object -First 1

        if ($seedExtension) {
            Write-Host "   Installing seed extension [$seedExtension] to trigger profile creation..." -ForegroundColor Cyan
            & $script:VSCodium --profile $Name --install-extension $seedExtension 2>$null | Out-Null
        }
    }

    $profileMap = Get-LiveProfileMap
    if (-not $profileMap.ContainsKey($Name)) {
        Write-Warning "Could not auto-create profile [$Name]."
        Write-Warning "Please open VSCodium, create the profile manually, then re-run sync."
        return $false
    }

    return $true
}

# ---------------------------------------------------------------------------
# Установка расширений: инкрементальная (только новые)
# ---------------------------------------------------------------------------

function Install-ExtensionsIncremental {
    param([string]$ExtFile, [string[]]$ProfileArgs)

    if (-not (Test-Path $ExtFile)) { return }

    $wanted = @(
        Get-Content $ExtFile -Encoding UTF8 |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith("#") } |
            Sort-Object -Unique
    )
    if ($wanted.Count -eq 0) { return }

    $installed = @(& $script:VSCodium $ProfileArgs --list-extensions 2>$null | Sort-Object -Unique)

    $toInstall = $wanted | Where-Object { $_ -notin $installed }

    if ($toInstall.Count -eq 0) {
        Write-Host "   ✅ Extensions already up to date." -ForegroundColor Green
        return
    }

    Write-Host "   Installing $($toInstall.Count) new extension(s)..." -ForegroundColor Cyan
    foreach ($ext in $toInstall) {
        & $script:VSCodium $ProfileArgs --install-extension $ext
    }
}

# ---------------------------------------------------------------------------
# Экспорт: local VSCodium -> repo
# ---------------------------------------------------------------------------

function Export-Profile {
    param([string]$Name)

    if ($Name -eq "__default__") {
        Write-Host "📤 Exporting extensions for default profile..." -ForegroundColor Cyan
        & $script:VSCodium --list-extensions | Out-File -FilePath (Get-ExtensionFile $Name) -Encoding UTF8
        return
    }

    $profileMap = Get-LiveProfileMap
    if (-not $profileMap.ContainsKey($Name)) {
        Write-Host "⚠️  Profile [$Name] not found in storage.json. Skipping export." -ForegroundColor Yellow
        return
    }

    $sourceDir = Join-Path $UserDir $profileMap[$Name]
    $templateDir = Get-TemplateDir $Name
    Ensure-Directory $templateDir

    Write-Host "📤 Exporting profile [$Name] -> [$templateDir]..." -ForegroundColor Cyan
    Copy-ProfileData $sourceDir $templateDir
    & $script:VSCodium --profile $Name --list-extensions | Out-File -FilePath (Get-ExtensionFile $Name) -Encoding UTF8
}

# ---------------------------------------------------------------------------
# Установка: repo -> local VSCodium
# ---------------------------------------------------------------------------

function Install-Profile {
    param([string]$Name)

    $templateDir = Get-TemplateDir $Name

    if ($Name -ne "__default__") {
        if (-not (Test-Path $templateDir)) {
            Write-Host "⚠️  Template directory not found for profile [$Name]. Skipping." -ForegroundColor Yellow
            return
        }

        if (-not (Ensure-ProfileExists $Name)) { return }

        $profileMap = Get-LiveProfileMap
        $destinationDir = Join-Path $UserDir $profileMap[$Name]
        Write-Host "📥 Syncing template [$Name] -> [$destinationDir]..." -ForegroundColor Cyan
        Copy-ProfileData $templateDir $destinationDir
    }

    $extFile = Get-ExtensionFile $Name
    $profileArgs = if ($Name -eq "__default__") { @() } else { @("--profile", $Name) }

    Write-Host "📦 Checking extensions for profile [$Name]..." -ForegroundColor Cyan
    Install-ExtensionsIncremental $extFile $profileArgs
}

# ---------------------------------------------------------------------------
# Команды
# ---------------------------------------------------------------------------

$script:VSCodium = Find-VSCodium

switch ($Command) {
    "sync-all" {
        Install-Profile "__default__"
        foreach ($name in Get-TrackedProfileNames) {
            Install-Profile $name
        }
    }
    "list-all" {
        Export-Profile "__default__"

        $names = Get-LiveProfileNames

        foreach ($name in $names) {
            Export-Profile $name
        }

        Set-TrackedProfileNames $names
    }
    "list" {
        $name = if ($ProfileName) { $ProfileName } else { "__default__" }
        Export-Profile $name
    }
    "install" {
        $name = if ($ProfileName) { $ProfileName } else { "__default__" }
        Install-Profile $name
    }
    default {
        Write-Host "Usage: .\Extensions.ps1 [sync-all|list-all|list|install] [profile_name]" -ForegroundColor Yellow
    }
}
