#!/bin/bash
# Linux/macOS: синхронизирует настройки и затем запускает VSCodium

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_DIR="$(dirname "$SCRIPT_DIR")"

cd "$USER_DIR"
bash "$SCRIPT_DIR/sync.sh"

if command -v codium >/dev/null 2>&1; then
    exec codium "$USER_DIR"
fi

echo "Error: VSCodium not found." >&2
exit 1
