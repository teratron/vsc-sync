#!/bin/bash
# macOS/Linux: Скрипт для синхронизации настроек VSCodium (запускается автоматически при старте IDE)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BASE_DIR"

echo "--- Syncing settings ---"

if command -v git &> /dev/null; then
    git pull --rebase 2>/dev/null
fi

if [ -f ".scripts/extensions.sh" ]; then
    bash ".scripts/extensions.sh" sync-all 2>/dev/null
fi
