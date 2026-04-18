#!/bin/bash
# Linux/macOS: синхронизирует настройки, запускает VSCodium, ждёт закрытия и затем делает export

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_DIR="$(dirname "$SCRIPT_DIR")"

find_vscodium() {
    if command -v codium >/dev/null 2>&1; then
        echo "codium"
        return 0
    fi

    echo "Error: VSCodium not found." >&2
    exit 1
}

cd "$USER_DIR"
bash "$SCRIPT_DIR/sync.sh"

VSCODIUM_CMD="$(find_vscodium)"

echo "Launching VSCodium and waiting for window close..."
"$VSCODIUM_CMD" --wait "$USER_DIR"

echo "VSCodium closed. Exporting local profile state..."
bash "$SCRIPT_DIR/export.sh"
