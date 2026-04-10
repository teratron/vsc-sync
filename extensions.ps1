# VSCodium Extensions Manager
# Usage: .\extensions.ps1 [command]
# Commands:
#   list    - Export installed extensions to extensions.list
#   install - Install extensions from extensions.list
#   show    - Show installed extensions
#   help    - Show this help message

$ExtensionsFile = "extensions.list"

# Find VSCodium executable
function Find-VSCodium {
    # Check if codium is in PATH
    $cmd = Get-Command "codium" -ErrorAction SilentlyContinue
    if ($cmd) {
        return "codium"
    }
    
    # Try standard installation paths
    $paths = @(
        "C:\Program Files\VSCodium\bin\codium.cmd",
        "C:\Program Files (x86)\VSCodium\bin\codium.cmd"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    Write-Error "VSCodium not found. Please add it to PATH."
    exit 1
}

$VSCodium = Find-VSCodium

function Show-Extensions {
    Write-Host "Installed extensions:"
    Write-Host "---------------------"
    & $VSCodium --list-extensions
}

function Export-Extensions {
    Write-Host "Exporting installed extensions to $ExtensionsFile..."
    & $VSCodium --list-extensions | Out-File -FilePath $ExtensionsFile -Encoding UTF8
    Write-Host "Done! Extensions saved to $ExtensionsFile"
}

function Install-Extensions {
    if (-not (Test-Path $ExtensionsFile)) {
        Write-Error "$ExtensionsFile not found!"
        Write-Host "Use '.\extensions.ps1 list' first to create it."
        exit 1
    }
    
    Write-Host "Installing extensions from $ExtensionsFile..."
    Get-Content $ExtensionsFile | ForEach-Object {
        $line = $_.Trim()
        # Skip empty lines and comments
        if ($line -and $line -notmatch "^#") {
            Write-Host "Installing: $line"
            & $VSCodium --install-extension $line
        }
    }
    Write-Host "Done! All extensions installed."
}

function Show-Help {
    Write-Host "VSCodium Extensions Manager"
    Write-Host ""
    Write-Host "Usage: .\extensions.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  list    - Export installed extensions to $ExtensionsFile"
    Write-Host "  install - Install extensions from $ExtensionsFile"
    Write-Host "  show    - Show installed extensions"
    Write-Host "  help    - Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\extensions.ps1 list      # Save current extensions"
    Write-Host "  .\extensions.ps1 install   # Install from saved list"
    Write-Host "  .\extensions.ps1 show      # View installed extensions"
}

# Main command handler
switch ($args[0]) {
    "list"    { Export-Extensions }
    "install" { Install-Extensions }
    "show"    { Show-Extensions }
    "help"    { Show-Help }
    default   { Show-Help }
}
