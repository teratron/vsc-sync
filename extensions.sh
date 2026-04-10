#!/bin/bash

# VSCodium Extensions Manager
# Usage: ./extensions.sh [command]
# Commands:
#   list    - Export installed extensions to extensions.list
#   install - Install extensions from extensions.list
#   show    - Show installed extensions
#   help    - Show this help message

VSCODIUM_CMD="codium"
EXTENSIONS_FILE="extensions.list"

# Check if codium command exists
if ! command -v $VSCODIUM_CMD &> /dev/null; then
    # Try alternative paths for Windows
    if [ -x "/c/Program Files/VSCodium/bin/codium" ]; then
        VSCODIUM_CMD="/c/Program Files/VSCodium/bin/codium"
    elif [ -x "/c/Program Files (x86)/VSCodium/bin/codium" ]; then
        VSCODIUM_CMD="/c/Program Files (x86)/VSCodium/bin/codium"
    else
        echo "Error: VSCodium not found. Please add it to PATH."
        exit 1
    fi
fi

case "$1" in
    list)
        echo "Exporting installed extensions to $EXTENSIONS_FILE..."
        $VSCODIUM_CMD --list-extensions > "$EXTENSIONS_FILE"
        echo "Done! Extensions saved to $EXTENSIONS_FILE"
        ;;
    
    install)
        if [ ! -f "$EXTENSIONS_FILE" ]; then
            echo "Error: $EXTENSIONS_FILE not found!"
            echo "Use './extensions.sh list' first to create it."
            exit 1
        fi
        
        echo "Installing extensions from $EXTENSIONS_FILE..."
        while IFS= read -r extension; do
            # Skip empty lines and comments
            [[ -z "$extension" || "$extension" =~ ^# ]] && continue
            
            echo "Installing: $extension"
            $VSCODIUM_CMD --install-extension "$extension"
        done < "$EXTENSIONS_FILE"
        echo "Done! All extensions installed."
        ;;
    
    show)
        echo "Installed extensions:"
        echo "---------------------"
        $VSCODIUM_CMD --list-extensions
        ;;
    
    help|*)
        echo "VSCodium Extensions Manager"
        echo ""
        echo "Usage: ./extensions.sh [command]"
        echo ""
        echo "Commands:"
        echo "  list    - Export installed extensions to $EXTENSIONS_FILE"
        echo "  install - Install extensions from $EXTENSIONS_FILE"
        echo "  show    - Show installed extensions"
        echo "  help    - Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./extensions.sh list      # Save current extensions"
        echo "  ./extensions.sh install   # Install from saved list"
        echo "  ./extensions.sh show      # View installed extensions"
        ;;
esac
