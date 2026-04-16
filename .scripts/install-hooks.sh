#!/bin/bash
# Linux/macOS: подключает versioned git hooks из репозитория

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_DIR="$(dirname "$SCRIPT_DIR")"

cd "$USER_DIR"

if ! command -v git >/dev/null 2>&1; then
    echo "Error: Git not found." >&2
    exit 1
fi

chmod +x .githooks/pre-commit
chmod +x .scripts/*.sh

git config core.hooksPath .githooks
echo "Git hooks path configured: .githooks"
