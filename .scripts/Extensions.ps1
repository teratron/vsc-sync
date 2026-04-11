# VSCodium Extensions Manager (Local Profile Support)
# Usage: .\Extensions.ps1 [command] [profile_name]

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$ProfileName
)

$UserDir = Split-Path $PSScriptRoot -Parent
$StorageFile = Join-Path $UserDir "globalStorage\storage.json"

function Get-ProfileMap {
    $map = @{ "__default__" = "." } # Default profile is in User/ (root)
    if (Test-Path $StorageFile) {
        try {
            $storage = Get-Content $StorageFile -Raw | ConvertFrom-Json
            if ($storage.userDataProfiles) {
                foreach ($p in $storage.userDataProfiles) {
                    $map[$p.name] = "profiles/$($p.location)"
                }
            }
        } catch { }
    }
    return $map
}

function Run-ForProfile {
    param($cmd, $profileName, $relativeDir)
    
    $fullDir = Join-Path $UserDir $relativeDir
    $extFile = Join-Path $fullDir "extensions.list"
    $pArgs = if ($profileName -eq "__default__") { @() } else { @("--profile", $profileName) }
    
    if (-not (Test-Path $fullDir)) {
        Write-Host "Profile directory not found: $relativeDir. Skipping." -ForegroundColor Yellow
        return
    }

    $VSCodium = Find-VSCodium
    
    switch ($cmd) {
        "list" {
            Write-Host "Exporting extensions for profile [$profileName] to $relativeDir/extensions.list..." -ForegroundColor Cyan
            & $VSCodium $pArgs --list-extensions | Out-File -FilePath "$extFile" -Encoding UTF8
        }
        "install" {
            if (Test-Path $extFile) {
                Write-Host "Installing extensions for profile [$profileName] from $relativeDir/extensions.list..." -ForegroundColor Cyan
                Get-Content $extFile | ForEach-Object {
                    $line = $_.Trim()
                    if ($line -and $line -notmatch "^#") {
                        & $VSCodium $pArgs --install-extension $line
                    }
                }
            }
        }
    }
}

function Find-VSCodium {
    $cmd = Get-Command "codium" -ErrorAction SilentlyContinue
    if ($cmd) { return "codium" }
    $p = "C:\Program Files\VSCodium\bin\codium.cmd"
    if (Test-Path $p) { return $p }
    exit 1
}

$profileMap = Get-ProfileMap

switch ($Command) {
    "sync-all" {
        foreach ($name in $profileMap.Keys) {
            Run-ForProfile "install" $name $profileMap[$name]
        }
    }
    "list-all" {
        foreach ($name in $profileMap.Keys) {
            Run-ForProfile "list" $name $profileMap[$name]
        }
    }
    "list" {
        $name = if ($ProfileName) { $ProfileName } else { "__default__" }
        if ($profileMap.ContainsKey($name)) {
            Run-ForProfile "list" $name $profileMap[$name]
        } else {
            Write-Error "Profile '$name' not found in storage.json"
        }
    }
    "install" {
        $name = if ($ProfileName) { $ProfileName } else { "__default__" }
        if ($profileMap.ContainsKey($name)) {
            Run-ForProfile "install" $name $profileMap[$name]
        }
    }
}
