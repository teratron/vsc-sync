#!/bin/bash
# Менеджер профилей VSCodium с переносимыми шаблонами

COMMAND=$1
PROFILE_NAME=$2
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_DIR="$(dirname "$SCRIPT_DIR")"
STORAGE_FILE="$USER_DIR/globalStorage/storage.json"
PROFILES_LIST_FILE="$USER_DIR/profiles.list"
PROFILE_TEMPLATES_DIR="$USER_DIR/profile-templates"
TRACKED_FILES=("settings.json" "keybindings.json" "tasks.json" "launch.json" "projects.json")

# ---------------------------------------------------------------------------
# Утилиты
# ---------------------------------------------------------------------------

find_vscodium() {
    if command -v codium >/dev/null 2>&1; then
        echo "codium"
        return 0
    fi

    echo "Error: VSCodium not found. Make sure 'codium' is in PATH." >&2
    exit 1
}

VSCODIUM_CMD="$(find_vscodium)"

# Проверяем наличие jq — если есть, используем его, иначе awk-fallback
HAS_JQ=0
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
fi

# ---------------------------------------------------------------------------
# Парсинг storage.json
# ---------------------------------------------------------------------------

# Возвращает список имён всех именованных профилей
list_storage_profile_names() {
    [ -f "$STORAGE_FILE" ] || return

    if [ "$HAS_JQ" = "1" ]; then
        jq -r '.userDataProfiles[]?.name // empty' "$STORAGE_FILE" 2>/dev/null
        return
    fi

    # awk-fallback: собираем name и location внутри каждого объекта,
    # выводим name когда объект закрывается (защита от порядка полей)
    awk '
        /"userDataProfiles"[[:space:]]*:/ { in_profiles=1; next }
        in_profiles && /^\s*\]/ { in_profiles=0 }
        in_profiles && /\{/ { cur_name="" }
        in_profiles && /"name"[[:space:]]*:/ {
            line=$0
            sub(/.*"name"[[:space:]]*:[[:space:]]*"/, "", line)
            sub(/".*/, "", line)
            cur_name=line
        }
        in_profiles && /\}/ {
            if (cur_name != "") { print cur_name }
            cur_name=""
        }
    ' "$STORAGE_FILE"
}

# Возвращает относительный путь к каталогу профиля (profiles/<hash>)
get_profile_location() {
    local name=$1
    [ "$name" = "__default__" ] || [ -z "$name" ] && { echo "."; return; }
    [ -f "$STORAGE_FILE" ] || return

    if [ "$HAS_JQ" = "1" ]; then
        jq -r --arg n "$name" \
            '.userDataProfiles[]? | select(.name==$n) | "profiles/" + .location' \
            "$STORAGE_FILE" 2>/dev/null | head -n1
        return
    fi

    # awk-fallback: накапливаем поля объекта, выводим при закрывающей скобке
    awk -v profile_name="$name" '
        /"userDataProfiles"[[:space:]]*:/ { in_profiles=1; next }
        in_profiles && /^\s*\]/ { in_profiles=0 }
        in_profiles && /\{/ { cur_name=""; cur_loc="" }
        in_profiles && /"name"[[:space:]]*:/ {
            line=$0
            sub(/.*"name"[[:space:]]*:[[:space:]]*"/, "", line)
            sub(/".*/, "", line)
            cur_name=line
        }
        in_profiles && /"location"[[:space:]]*:/ {
            line=$0
            sub(/.*"location"[[:space:]]*:[[:space:]]*"/, "", line)
            sub(/".*/, "", line)
            cur_loc=line
        }
        in_profiles && /\}/ {
            if (cur_name == profile_name && cur_loc != "") {
                print "profiles/" cur_loc
                exit
            }
            cur_name=""; cur_loc=""
        }
    ' "$STORAGE_FILE"
}

# ---------------------------------------------------------------------------
# profiles.list: читаем и пишем (MERGE, не перезапись!)
# ---------------------------------------------------------------------------

read_profiles_list() {
    [ -f "$PROFILES_LIST_FILE" ] || return
    grep -v '^[[:space:]]*#' "$PROFILES_LIST_FILE" | sed '/^[[:space:]]*$/d' | sort -u
}

# ВАЖНО: объединяем уже записанные имена с именами из локального storage,
# чтобы не потерять профили других машин при коммите с одной машины
write_profiles_list() {
    local tmp="$PROFILES_LIST_FILE.tmp"
    {
        read_profiles_list
        list_storage_profile_names
    } | sed '/^[[:space:]]*$/d' | sort -u > "$tmp"
    mv "$tmp" "$PROFILES_LIST_FILE"
}

# ---------------------------------------------------------------------------
# Вспомогательные функции работы с файлами профилей
# ---------------------------------------------------------------------------

template_dir_for_profile() {
    local name=$1
    if [ "$name" = "__default__" ] || [ -z "$name" ]; then
        echo "$USER_DIR"
        return
    fi
    echo "$PROFILE_TEMPLATES_DIR/$name"
}

copy_profile_data() {
    local source_dir=$1
    local destination_dir=$2

    mkdir -p "$destination_dir"

    for tracked_file in "${TRACKED_FILES[@]}"; do
        if [ -f "$source_dir/$tracked_file" ]; then
            cp "$source_dir/$tracked_file" "$destination_dir/$tracked_file"
        fi
    done

    if [ -d "$source_dir/snippets" ]; then
        mkdir -p "$destination_dir/snippets"
        cp -R "$source_dir/snippets/." "$destination_dir/snippets/" 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Создание профиля (если ещё не существует)
# ---------------------------------------------------------------------------

ensure_profile_exists() {
    local name=$1
    [ "$name" = "__default__" ] && return 0

    local current_location
    current_location="$(get_profile_location "$name")"
    [ -n "$current_location" ] && return 0

    echo "⚙️  Profile [$name] not found locally. Attempting to create..."

    # Попытка 1: простой вызов --list-extensions
    "$VSCODIUM_CMD" --profile "$name" --list-extensions >/dev/null 2>&1 || true

    current_location="$(get_profile_location "$name")"
    [ -n "$current_location" ] && return 0

    # Попытка 2: установить первое расширение из шаблона (триггер создания профиля)
    local ext_file
    ext_file="$(template_dir_for_profile "$name")/extensions.list"
    if [ -f "$ext_file" ]; then
        local seed_extension
        seed_extension="$(grep -v '^[[:space:]]*#' "$ext_file" | sed '/^[[:space:]]*$/d' | head -n1)"
        if [ -n "$seed_extension" ]; then
            echo "   Installing seed extension [$seed_extension] to trigger profile creation..."
            "$VSCODIUM_CMD" --profile "$name" --install-extension "$seed_extension" >/dev/null 2>&1 || true
        fi
    fi

    current_location="$(get_profile_location "$name")"
    if [ -z "$current_location" ]; then
        echo "⚠️  Could not auto-create profile [$name]." >&2
        echo "   Please open VSCodium, create the profile manually, then re-run sync." >&2
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Экспорт: local VSCodium -> repo
# ---------------------------------------------------------------------------

export_profile() {
    local name=$1

    if [ "$name" = "__default__" ] || [ -z "$name" ]; then
        echo "📤 Exporting extensions for default profile..."
        "$VSCODIUM_CMD" --list-extensions > "$USER_DIR/extensions.list"
        return 0
    fi

    local relative_dir
    relative_dir="$(get_profile_location "$name")"
    if [ -z "$relative_dir" ]; then
        echo "⚠️  Profile [$name] not found in storage.json. Skipping export."
        return 0
    fi

    local template_dir
    template_dir="$(template_dir_for_profile "$name")"
    mkdir -p "$template_dir"

    echo "📤 Exporting profile [$name] -> [$template_dir]..."
    copy_profile_data "$USER_DIR/$relative_dir" "$template_dir"
    "$VSCODIUM_CMD" --profile "$name" --list-extensions > "$template_dir/extensions.list"
}

# ---------------------------------------------------------------------------
# Установка: repo -> local VSCodium (инкрементальная!)
# ---------------------------------------------------------------------------

install_extensions_incremental() {
    local extensions_file=$1
    local profile_args=("${@:2}")  # остальные аргументы — флаги профиля

    [ -f "$extensions_file" ] || return 0

    # Читаем нужные расширения
    local wanted
    wanted="$(grep -v '^[[:space:]]*#' "$extensions_file" | sed '/^[[:space:]]*$/d' | sort -u)"
    [ -z "$wanted" ] && return 0

    # Читаем уже установленные
    local installed
    installed="$("$VSCODIUM_CMD" "${profile_args[@]}" --list-extensions 2>/dev/null | sort -u)"

    # Считаем разницу
    local to_install
    to_install="$(comm -23 <(echo "$wanted") <(echo "$installed"))"

    if [ -z "$to_install" ]; then
        echo "   ✅ Extensions already up to date."
        return 0
    fi

    echo "   Installing $(echo "$to_install" | wc -l | tr -d ' ') new extension(s)..."
    while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        "$VSCODIUM_CMD" "${profile_args[@]}" --install-extension "$ext"
    done <<< "$to_install"
}

install_profile() {
    local name=$1
    local template_dir
    template_dir="$(template_dir_for_profile "$name")"

    if [ "$name" != "__default__" ]; then
        if [ ! -d "$template_dir" ]; then
            echo "⚠️  Template directory not found for profile [$name]. Skipping."
            return 0
        fi

        if ! ensure_profile_exists "$name"; then
            return 0
        fi

        local relative_dir
        relative_dir="$(get_profile_location "$name")"
        echo "📥 Syncing template [$name] -> [$USER_DIR/$relative_dir]..."
        copy_profile_data "$template_dir" "$USER_DIR/$relative_dir"
    fi

    local extensions_file="$template_dir/extensions.list"

    if [ "$name" = "__default__" ] || [ -z "$name" ]; then
        echo "📦 Checking extensions for default profile..."
        install_extensions_incremental "$extensions_file"
    else
        echo "📦 Checking extensions for profile [$name]..."
        install_extensions_incremental "$extensions_file" --profile "$name"
    fi
}

# ---------------------------------------------------------------------------
# Команды
# ---------------------------------------------------------------------------

case $COMMAND in
    list)
        export_profile "${PROFILE_NAME:-__default__}"
        ;;
    install)
        install_profile "${PROFILE_NAME:-__default__}"
        ;;
    sync-all)
        install_profile "__default__"
        while IFS= read -r profile_name; do
            [ -z "$profile_name" ] && continue
            install_profile "$profile_name"
        done < <(read_profiles_list)
        ;;
    list-all)
        export_profile "__default__"
        while IFS= read -r profile_name; do
            [ -z "$profile_name" ] && continue
            export_profile "$profile_name"
        done < <(list_storage_profile_names | sort -u)
        write_profiles_list
        ;;
    *)
        echo "Usage: $0 [sync-all|list-all|list|install] [profile_name]"
        ;;
esac
