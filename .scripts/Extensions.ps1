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

function Find-VSCodium {
    $cmd = Get-Command "codium" -ErrorAction SilentlyContinue
    if ($cmd) { return "codium" }

    $path = "C:\Program Files\VSCodium\bin\codium.cmd"
    if (Test-Path $path) { return $path }

    throw "VSCodium executable was not found."
}

function Get-StorageData {
    if (-not (Test-Path $StorageFile)) {
        return $null
    }

    try {
        return Get-Content $StorageFile -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

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

function Get-TrackedProfileNames {
    if (-not (Test-Path $ProfilesListFile)) {
        return @()
    }

    return @(
        Get-Content $ProfilesListFile |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith("#") } |
            Sort-Object -Unique
    )
}

function Set-TrackedProfileNames {
    param([string[]]$Names)

    $content = @(
        $Names |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    Set-Content -Path $ProfilesListFile -Value $content
}

function Get-TemplateDir {
    param([string]$ProfileName)

    if ($ProfileName -eq "__default__") {
        return $UserDir
    }

    return Join-Path $ProfileTemplatesDir $ProfileName
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-ProfileData {
    param(
        [string]$SourceDir,
        [string]$DestinationDir
    )

    Ensure-Directory $DestinationDir

    foreach ($file in $TrackedFiles) {
        $sourceFile = Join-Path $SourceDir $file
        $destinationFile = Join-Path $DestinationDir $file

        if (Test-Path $sourceFile) {
            Copy-Item -LiteralPath $sourceFile -Destination $destinationFile -Force
        }
    }

    $sourceSnippets = Join-Path $SourceDir "snippets"
    if (Test-Path $sourceSnippets) {
        $destinationSnippets = Join-Path $DestinationDir "snippets"
        Ensure-Directory $destinationSnippets

        Get-ChildItem -LiteralPath $sourceSnippets -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destinationSnippets $_.Name) -Recurse -Force
        }
    }
}

function Get-ExtensionFile {
    param([string]$ProfileName)

    return Join-Path (Get-TemplateDir $ProfileName) "extensions.list"
}

function Ensure-ProfileExists {
    param([string]$Name)

    if ($Name -eq "__default__") {
        return Get-LiveProfileMap
    }

    $profileMap = Get-LiveProfileMap
    if ($profileMap.ContainsKey($Name)) {
        return $profileMap
    }

    Write-Host "Creating missing profile [$Name]..." -ForegroundColor Cyan
    & $script:VSCodium --profile $Name --list-extensions | Out-Null

    $profileMap = Get-LiveProfileMap
    if ($profileMap.ContainsKey($Name)) {
        return $profileMap
    }

    $extFile = Get-ExtensionFile $Name
    if (Test-Path $extFile) {
        $seedExtension = Get-Content $extFile |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith("#") } |
            Select-Object -First 1

        if ($seedExtension) {
            & $script:VSCodium --profile $Name --install-extension $seedExtension | Out-Null
        }
    }

    return Get-LiveProfileMap
}

function Export-Profile {
    param([string]$Name)

    if ($Name -eq "__default__") {
        $extFile = Get-ExtensionFile $Name
        Write-Host "Exporting extensions for default profile..." -ForegroundColor Cyan
        & $script:VSCodium --list-extensions | Out-File -FilePath $extFile -Encoding UTF8
        return
    }

    $profileMap = Get-LiveProfileMap
    if (-not $profileMap.ContainsKey($Name)) {
        Write-Host "Profile [$Name] not found in storage.json. Skipping export." -ForegroundColor Yellow
        return
    }

    $sourceDir = Join-Path $UserDir $profileMap[$Name]
    $templateDir = Get-TemplateDir $Name
    Ensure-Directory $templateDir

    Write-Host "Exporting profile [$Name] to template [$templateDir]..." -ForegroundColor Cyan
    Copy-ProfileData $sourceDir $templateDir
    & $script:VSCodium --profile $Name --list-extensions | Out-File -FilePath (Get-ExtensionFile $Name) -Encoding UTF8
}

function Install-Profile {
    param([string]$Name)

    $templateDir = Get-TemplateDir $Name
    $extFile = Get-ExtensionFile $Name
    $profileArgs = if ($Name -eq "__default__") { @() } else { @("--profile", $Name) }

    if ($Name -ne "__default__") {
        if (-not (Test-Path $templateDir)) {
            Write-Host "Template directory not found for profile [$Name]. Skipping." -ForegroundColor Yellow
            return
        }

        $profileMap = Ensure-ProfileExists $Name
        if (-not $profileMap.ContainsKey($Name)) {
            Write-Host "Profile [$Name] could not be created automatically. Skipping." -ForegroundColor Yellow
            return
        }

        $destinationDir = Join-Path $UserDir $profileMap[$Name]
        Write-Host "Syncing template [$Name] into [$destinationDir]..." -ForegroundColor Cyan
        Copy-ProfileData $templateDir $destinationDir
    }

    if (Test-Path $extFile) {
        Write-Host "Installing extensions for profile [$Name]..." -ForegroundColor Cyan
        Get-Content $extFile | ForEach-Object {
            $line = $_.Trim()
            if ($line -and $line -notmatch "^#") {
                & $script:VSCodium $profileArgs --install-extension $line
            }
        }
    }
}

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

        $profileMap = Get-LiveProfileMap
        $names = @(
            $profileMap.Keys |
                Where-Object { $_ -ne "__default__" } |
                Sort-Object -Unique
        )

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
