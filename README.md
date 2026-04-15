# VSCodium Settings Sync-

Репозиторий для хранения и синхронизации настроек VSCodium между разными компьютерами через GitHub.

## 📂 Структура репозитория

- `settings.json`, `keybindings.json` — основные конфигурации.
- `extensions.list` — список установленных расширений.
- `snippets/` — ваши пользовательские сниппеты.
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
3. Запускают VSCodium.

### Настройка ярлыка для Windows

Для удобства создайте ярлык на рабочем столе:

1. **Объект (Target):**

   ```plaintext
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%APPDATA%\VSCodium\User\.scripts\Sync.ps1"
   ```

2. **Рабочая папка (Start in):** `%APPDATA%\VSCodium\User`

## 👥 Поддержка профилей

Скрипты автоматически распознают ваши профили VSCodium (например, **Python**, **Rust**, **Go**).

- `extensions.list` — расширения профиля по умолчанию (Default).
- `extensions.<Name>.list` — расширения для именованных профилей.

### Команды командной строки (PowerShell)

```powershell
# Синхронизировать ВСЕ профили сразу (используется в Sync.ps1)
.\.scripts\Extensions.ps1 sync-all

# Экспортировать списки для ВСЕХ профилей в репозиторий
.\.scripts\Extensions.ps1 list-all

# Работа с конкретным профилем
.\.scripts\Extensions.ps1 list Work
.\.scripts\Extensions.ps1 install Work
```

### Git Bash / WSL / macOS

```bash
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

## 📜 Примечания

### Ошибки выполнения PowerShell

Если скрипты не запускаются, выполните в терминале от имени пользователя:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### .gitignore

Файл `.gitignore` настроен на исключение временных файлов, логов и кэша, сохраняя только важные настройки.
