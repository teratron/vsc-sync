# VSCodium Settings Sync

Репозиторий для хранения и синхронизации настроек VSCodium между разными компьютерами через GitHub.

## 📂 Структура репозитория

- `settings.json`, `keybindings.json` — конфигурация default-профиля.
- `extensions.list` — список расширений default-профиля.
- `profiles.list` — список именованных профилей, которые нужно переносить между машинами.
- `profile-templates/<ProfileName>/` — переносимые шаблоны именованных профилей.
- `profiles/<hash>/` — локальные рабочие папки VSCodium. Они зависят от машины и не должны считаться переносимым источником истины.
- `.scripts/` — инструменты для автоматизации.

## 🚀 Доступные инструменты

| Файл | Назначение | Команда запуска |
| --- | --- | --- |
| **Sync.ps1** | Windows (PowerShell): Pull + Extensions + запуск | `.\.scripts\Sync.ps1` |
| **sync.bat** / **sync.cmd** | Windows (CMD): Pull + Extensions + запуск | `.\.scripts\sync.bat` |
| **sync.sh** | macOS/Linux: Pull + Extensions + запуск | `bash .scripts/sync.sh` |
| **Extensions.ps1** | Манипуляция расширениями (Win PS) | `.\.scripts\Extensions.ps1` |

## 🛠 Автоматизация запуска (Sync & Start)

Скрипты `sync` автоматизируют весь процесс при старте IDE:

1. Выполняют `git pull --rebase` для загрузки свежих настроек.
2. Обновляют расширения для **всех** профилей (`sync-all`).
3. Создают недостающие профили по имени.
4. Копируют настройки профилей из `profile-templates/` в локальные папки VSCodium.
5. Устанавливают расширения для default-профиля и всех именованных профилей.

### Настройка ярлыка для Windows

Для удобства создайте ярлык на рабочем столе:

1. **Объект (Target):**

   ```plaintext
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%APPDATA%\VSCodium\User\.scripts\Sync.ps1"
   ```

2. **Рабочая папка (Start in):** `%APPDATA%\VSCodium\User`

## 👥 Поддержка профилей

Скрипты работают с двумя уровнями данных:

- `profiles.list` хранит имена переносимых профилей.
- `profile-templates/<Name>/` хранит переносимые файлы профиля: `settings.json`, `extensions.list`, `snippets/` и другие поддерживаемые конфиги.
- `globalStorage/storage.json` используется только локально, чтобы сопоставить имя профиля с текущим machine-specific hash в `profiles/<hash>/`.

Это решает проблему Linux/macOS/Windows, где один и тот же профиль может получить другой hash на новой машине.

### Миграция со старой схемы

Если в репозитории раньше лежали файлы вида `profiles/<hash>/settings.json` и `profiles/<hash>/extensions.list`, их можно оставить локально, но они больше не должны быть переносимым источником истины.

Актуальная схема такая:

- `profile-templates/<Name>/` и `profiles.list` коммитятся в git.
- `profiles/<hash>/` остаются локальными рабочими папками, которые создаёт и использует сам VSCodium на конкретной машине.

### Команды командной строки (PowerShell)

```powershell
# Синхронизировать ВСЕ профили сразу (используется в Sync.ps1)
.\.scripts\Extensions.ps1 sync-all

# Экспортировать default-профиль и ВСЕ именованные профили в переносимые шаблоны
.\.scripts\Extensions.ps1 list-all

# Работа с конкретным профилем
.\.scripts\Extensions.ps1 list Work
.\.scripts\Extensions.ps1 install Work
```

### Git Bash / WSL / macOS

```bash
# Синхронизировать все профили из profiles.list
bash .scripts/extensions.sh sync-all

# Экспортировать все локальные профили в переносимые шаблоны
bash .scripts/extensions.sh list-all

# Работа с конкретным профилем
bash .scripts/extensions.sh list Work
bash .scripts/extensions.sh install Work
```

## ⚙️ Настройка нового устройства

1. Установите VSCodium.
2. Склонируйте репозиторий в папку настроек:
   - Windows: `%APPDATA%\VSCodium\User`
   - macOS: `~/Library/Application Support/VSCodium/User`
   - Linux: `~/.config/VSCodium/User`
3. Запустите соответствующий скрипт `sync` для вашей ОС.

Если именованный профиль отсутствует на новой машине, скрипт создаст его автоматически по имени через `codium --profile "<Name>"`.

## 📜 Примечания

### Ошибки выполнения PowerShell

Если скрипты не запускаются, выполните в терминале от имени пользователя:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### .gitignore

Файл `.gitignore` настроен на исключение временных файлов, логов и кэша, сохраняя только переносимые настройки и шаблоны профилей.
