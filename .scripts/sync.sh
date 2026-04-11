#!/bin/bash
# macOS/Linux: Скрипт для синхронизации настроек VSCodium и запуска IDE

# Определяем путь к папке User (на уровень выше от .scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BASE_DIR"

echo "--- Checking for updates from GitHub ---"

# 1. Pull changes
if command -v git &> /dev/null; then
    echo "Running git pull..."
    git pull --rebase
else
    echo "Git not found. Skipping sync."
fi

# 2. Install extensions
if [ -f ".scripts/extensions.sh" ]; then
    echo "Updating extensions for all profiles..."
    bash ".scripts/extensions.sh" sync-all
fi

# 3. Launch VSCodium
echo "Launching VSCodium..."

if command -v codium &> /dev/null; then
    codium . &
elif [ -d "/Applications/VSCodium.app" ]; then
    open -a VSCodium . 
else
    echo "VSCodium (codium) not found in PATH."
fi
