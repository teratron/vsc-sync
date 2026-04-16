#!/bin/bash
# macOS/Linux: синхронизация настроек VSCodium (запускается автоматически при старте IDE)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BASE_DIR"

echo "--- Syncing settings ---"

if command -v git >/dev/null 2>&1; then
    echo "Git pull..."
    if ! git pull --rebase 2>&1; then
        echo "⚠️  git pull --rebase failed (possible conflict or no network)." >&2
        echo "   Continuing with local settings. Resolve manually if needed." >&2
    fi
else
    echo "⚠️  git not found, skipping pull." >&2
fi

if [ -f "$SCRIPT_DIR/extensions.sh" ]; then
    bash "$SCRIPT_DIR/extensions.sh" sync-all
fi
