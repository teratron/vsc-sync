#!/bin/bash
# VSCodium Extensions Manager (Local Profile Support)

COMMAND=$1
PROFILE_NAME=$2
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_DIR="$(dirname "$SCRIPT_DIR")"
STORAGE_FILE="$USER_DIR/globalStorage/storage.json"

# Function to find profile location (hash) by name
get_profile_location() {
    local name=$1
    if [ "$name" == "__default__" ] || [ -z "$name" ]; then
        echo "."
        return
    fi
    
    if [ -f "$STORAGE_FILE" ]; then
        # Try to find the location hash using grep/sed
        # Search for "name": "ProfileName" and take "location" from the previous lines
        # This is a bit fragile without jq, but works for standard storage.json
        local hash=$(grep -B 2 "\"name\": \"$name\"" "$STORAGE_FILE" | grep "\"location\":" | sed 's/.*"location": "\(.*\)".*/\1/')
        if [ ! -z "$hash" ]; then
            echo "profiles/$hash"
            return
        fi
    fi
    echo ""
}

RELATIVE_DIR=$(get_profile_location "$PROFILE_NAME")

if [ -z "$RELATIVE_DIR" ]; then
    echo "Error: Profile '$PROFILE_NAME' not found or storage.json missing."
    exit 1
fi

EXTENSIONS_FILE="$USER_DIR/$RELATIVE_DIR/extensions.list"
PROFILE_ARGS=""
if [ ! -z "$PROFILE_NAME" ] && [ "$PROFILE_NAME" != "__default__" ]; then
    PROFILE_ARGS="--profile $PROFILE_NAME"
    echo "Working with profile: $PROFILE_NAME ($RELATIVE_DIR)"
else
    echo "Working with default profile"
fi

VSCODIUM_CMD="codium"
if ! command -v $VSCODIUM_CMD &> /dev/null; then
    echo "Error: VSCodium not found."
    exit 1
fi

case $COMMAND in
    list)
        echo "Exporting extensions to $RELATIVE_DIR/extensions.list..."
        $VSCODIUM_CMD $PROFILE_ARGS --list-extensions > "$EXTENSIONS_FILE"
        echo "Done."
        ;;
    install)
        if [ ! -f "$EXTENSIONS_FILE" ]; then
            echo "Warning: $EXTENSIONS_FILE not found. Skipping."
            exit 0
        fi
        echo "Installing extensions from $RELATIVE_DIR/extensions.list..."
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            echo "Installing: $line"
            $VSCODIUM_CMD $PROFILE_ARGS --install-extension "$line"
        done < "$EXTENSIONS_FILE"
        echo "Done."
        ;;
    sync-all)
        # For sync-all in bash, we would need to parse all names. 
        # For now, it handles default.
        bash "$0" install "__default__"
        ;;
    *)
        echo "Usage: $0 [list|install|show] [profile_name]"
        ;;
esac
