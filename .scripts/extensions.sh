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

find_vscodium() {
    if command -v codium >/dev/null 2>&1; then
        echo "codium"
        return 0
    fi

    echo "Error: VSCodium not found." >&2
    exit 1
}

VSCODIUM_CMD="$(find_vscodium)"

template_dir_for_profile() {
    local name=$1
    if [ "$name" = "__default__" ] || [ -z "$name" ]; then
        echo "$USER_DIR"
        return
    fi

    echo "$PROFILE_TEMPLATES_DIR/$name"
}

list_storage_profile_names() {
    if [ ! -f "$STORAGE_FILE" ]; then
        return
    fi

    awk '
        /"userDataProfiles"[[:space:]]*:/ { in_profiles=1; next }
        in_profiles && /\]/ { in_profiles=0 }
        in_profiles && /"name"[[:space:]]*:/ {
            line=$0
            sub(/.*"name"[[:space:]]*:[[:space:]]*"/, "", line)
            sub(/".*/, "", line)
            if (line != "") {
                print line
            }
        }
    ' "$STORAGE_FILE"
}

get_profile_location() {
    local name=$1
    if [ "$name" == "__default__" ] || [ -z "$name" ]; then
        echo "."
        return
    fi

    if [ -f "$STORAGE_FILE" ]; then
        awk -v profile_name="$name" '
            /"userDataProfiles"[[:space:]]*:/ { in_profiles=1; next }
            in_profiles && /\]/ { in_profiles=0 }
            in_profiles && /"location"[[:space:]]*:/ {
                location_line=$0
                sub(/.*"location"[[:space:]]*:[[:space:]]*"/, "", location_line)
                sub(/".*/, "", location_line)
                current_location=location_line
            }
            in_profiles && /"name"[[:space:]]*:/ {
                name_line=$0
                sub(/.*"name"[[:space:]]*:[[:space:]]*"/, "", name_line)
                sub(/".*/, "", name_line)
                if (name_line == profile_name && current_location != "") {
                    print "profiles/" current_location
                    exit
                }
                current_location=""
            }
        ' "$STORAGE_FILE"
    fi
}

read_profiles_list() {
    if [ -f "$PROFILES_LIST_FILE" ]; then
        grep -v '^[[:space:]]*#' "$PROFILES_LIST_FILE" | sed '/^[[:space:]]*$/d' | sort -u
        return
    fi

    list_storage_profile_names | sort -u
}

write_profiles_list() {
    list_storage_profile_names | sort -u > "$PROFILES_LIST_FILE"
}

copy_profile_data() {
    local source_dir=$1
    local destination_dir=$2

    mkdir -p "$destination_dir"

    local tracked_file
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

ensure_profile_exists() {
    local name=$1

    if [ "$name" = "__default__" ]; then
        return 0
    fi

    local current_location
    current_location="$(get_profile_location "$name")"
    if [ -n "$current_location" ]; then
        return 0
    fi

    echo "Creating missing profile [$name]..."
    "$VSCODIUM_CMD" --profile "$name" --list-extensions >/dev/null 2>&1 || true

    current_location="$(get_profile_location "$name")"
    if [ -n "$current_location" ]; then
        return 0
    fi

    local ext_file
    ext_file="$(template_dir_for_profile "$name")/extensions.list"
    if [ -f "$ext_file" ]; then
        local seed_extension
        seed_extension="$(grep -v '^[[:space:]]*#' "$ext_file" | sed '/^[[:space:]]*$/d' | head -n 1)"
        if [ -n "$seed_extension" ]; then
            "$VSCODIUM_CMD" --profile "$name" --install-extension "$seed_extension" >/dev/null 2>&1 || true
        fi
    fi

    current_location="$(get_profile_location "$name")"
    [ -n "$current_location" ]
}

export_profile() {
    local name=$1

    if [ "$name" = "__default__" ] || [ -z "$name" ]; then
        echo "Exporting extensions for default profile..."
        "$VSCODIUM_CMD" --list-extensions > "$USER_DIR/extensions.list"
        return 0
    fi

    local relative_dir
    relative_dir="$(get_profile_location "$name")"
    if [ -z "$relative_dir" ]; then
        echo "Profile [$name] not found in storage.json. Skipping export."
        return 0
    fi

    local template_dir
    template_dir="$(template_dir_for_profile "$name")"
    mkdir -p "$template_dir"

    echo "Exporting profile [$name] to template [$template_dir]..."
    copy_profile_data "$USER_DIR/$relative_dir" "$template_dir"
    "$VSCODIUM_CMD" --profile "$name" --list-extensions > "$template_dir/extensions.list"
}

install_profile() {
    local name=$1
    local template_dir
    template_dir="$(template_dir_for_profile "$name")"

    if [ "$name" != "__default__" ] && [ ! -d "$template_dir" ]; then
        echo "Template directory not found for profile [$name]. Skipping."
        return 0
    fi

    if [ "$name" != "__default__" ]; then
        if ! ensure_profile_exists "$name"; then
            echo "Profile [$name] could not be created automatically. Skipping."
            return 0
        fi

        local relative_dir
        relative_dir="$(get_profile_location "$name")"
        echo "Syncing template [$name] into [$USER_DIR/$relative_dir]..."
        copy_profile_data "$template_dir" "$USER_DIR/$relative_dir"
    fi

    local extensions_file
    extensions_file="$template_dir/extensions.list"
    if [ ! -f "$extensions_file" ]; then
        return 0
    fi

    echo "Installing extensions for profile [$name]..."
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in
            ""|\#*) continue ;;
        esac

        if [ "$name" = "__default__" ] || [ -z "$name" ]; then
            "$VSCODIUM_CMD" --install-extension "$line"
        else
            "$VSCODIUM_CMD" --profile "$name" --install-extension "$line"
        fi
    done < "$extensions_file"
}

case $COMMAND in
    list)
        export_profile "${PROFILE_NAME:-__default__}"
        ;;
    install)
        install_profile "${PROFILE_NAME:-__default__}"
        ;;
    sync-all)
        install_profile "__default__"
        while IFS= read -r profile_name || [ -n "$profile_name" ]; do
            [ -z "$profile_name" ] && continue
            install_profile "$profile_name"
        done < <(read_profiles_list)
        ;;
    list-all)
        export_profile "__default__"
        while IFS= read -r profile_name || [ -n "$profile_name" ]; do
            [ -z "$profile_name" ] && continue
            export_profile "$profile_name"
        done < <(list_storage_profile_names | sort -u)
        write_profiles_list
        ;;
    *)
        echo "Usage: $0 [sync-all|list-all|list|install] [profile_name]"
        ;;
esac
