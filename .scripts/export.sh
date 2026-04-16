#!/bin/bash
# Linux/macOS: экспортирует текущие профили и расширения из VSCodium в репозиторий

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_DIR="$(dirname "$SCRIPT_DIR")"

cd "$USER_DIR"
bash "$SCRIPT_DIR/extensions.sh" list-all
