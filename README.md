# VSCodium Settings Sync

Репозиторий хранит переносимые настройки VSCodium и автоматизирует два направления синхронизации:

- `repo -> local VSCodium` при запуске IDE или при ручном `sync`
- `local VSCodium -> repo` при ручном `export` и автоматически перед `git commit`

## 📂 Структура репозитория

- `settings.json`, `keybindings.json`, `snippets/` — переносимые файлы default-профиля.
- `extensions.list` — список расширений default-профиля.
- `profiles.list` — список именованных профилей, которые нужно переносить между машинами.
- `profile-templates/<ProfileName>/` — переносимые шаблоны именованных профилей.
- `profiles/<hash>/` — локальные рабочие каталоги VSCodium. Они зависят от машины и не являются переносимым источником истины.
- `.scripts/` — пользовательские точки входа для всех сценариев.
- `.githooks/pre-commit` — автoэкспорт профилей перед коммитом.

## 🔁 Как работает синхронизация

### Поток `repo -> local VSCodium`

Этот поток используют `Sync.ps1`, `sync.sh`, `Launch.ps1`, `launch.sh`.

Они делают:

1. `git pull --rebase`
2. `sync-all` для всех профилей
3. создание отсутствующих профилей по имени
4. копирование файлов из `profile-templates/<Name>/` в локальные `profiles/<hash>/`
5. установку расширений для default-профиля и всех именованных профилей

### Поток `local VSCodium -> repo`

Этот поток используют `Export.ps1`, `export.sh` и git hook `.githooks/pre-commit`.

Они делают:

1. читают живые профили из локального `globalStorage/storage.json`
2. обновляют `profiles.list`
3. экспортируют `settings.json`, `snippets/` и другие переносимые файлы в `profile-templates/<Name>/`
4. обновляют `extensions.list` и `profile-templates/<Name>/extensions.list`

Именно `export` нужен после установки новых extensions или изменения настроек именованных профилей.

## 🚀 Скрипты и сценарии

### Windows PowerShell

- `.\.scripts\Launch.ps1`
  - полный сценарий: `git pull` -> `sync` -> запуск VSCodium
- `.\.scripts\Sync.ps1`
  - `git pull` и синхронизация профилей без запуска IDE
- `.\.scripts\Export.ps1`
  - экспорт текущего состояния профилей и расширений из VSCodium в репозиторий
- `.\.scripts\Install-Hooks.ps1`
  - подключение versioned git hooks из `.githooks`
- `.\.scripts\Extensions.ps1 sync-all`
  - низкоуровневая синхронизация профилей и расширений
- `.\.scripts\Extensions.ps1 list-all`
  - низкоуровневый экспорт всех профилей

### Linux / macOS

- `bash .scripts/launch.sh`
  - полный сценарий: `git pull` -> `sync` -> запуск VSCodium
- `bash .scripts/sync.sh`
  - `git pull` и синхронизация профилей без запуска IDE
- `bash .scripts/export.sh`
  - экспорт текущего состояния профилей и расширений из VSCodium в репозиторий
- `bash .scripts/install-hooks.sh`
  - подключение versioned git hooks из `.githooks` и выставление `chmod +x` для shell-скриптов
- `bash .scripts/extensions.sh sync-all`
  - низкоуровневая синхронизация профилей и расширений
- `bash .scripts/extensions.sh list-all`
  - низкоуровневый экспорт всех профилей

## 🧭 Рекомендуемый рабочий процесс

### Новый компьютер

1. Установите VSCodium и Git.
2. Склонируйте репозиторий:
   - Windows: `%APPDATA%\VSCodium\User`
   - macOS: `~/Library/Application Support/VSCodium/User`
   - Linux: `~/.config/VSCodium/User`
3. Один раз подключите git hooks:
   - Windows: `.\.scripts\Install-Hooks.ps1`
   - Linux/macOS: `bash .scripts/install-hooks.sh`
4. Запускайте IDE через launcher:
   - Windows: `.\.scripts\Launch.ps1`
   - Linux/macOS: `bash .scripts/launch.sh`

### Обычный ежедневный запуск

- если нужен полный сценарий, запускайте `Launch.ps1` или `launch.sh`
- если IDE уже открыта, можно запустить только `Sync.ps1` или `sync.sh`

### После изменения профилей или extensions

- default-профиль меняет файлы в корне репозитория сразу
- именованные профили и их extensions нужно экспортировать:
  - Windows: `.\.scripts\Export.ps1`
  - Linux/macOS: `bash .scripts/export.sh`

### Перед коммитом

Если установлен hook, ручной `export` перед коммитом обычно не нужен.

Hook делает следующее автоматически:

1. запускает `export`
2. обновляет `profiles.list`
3. добавляет экспортированные файлы в индекс

Подключение hook'а:

```powershell
git config core.hooksPath .githooks
```

Или через скрипты `Install-Hooks.ps1` / `install-hooks.sh`.

## 🧩 Автоматизация внутри IDE

Файл `tasks.json` содержит задачи:

- `Sync (Startup)`
  - запускается автоматически при `folderOpen`
- `Sync Now`
  - ручной запуск синхронизации из IDE
- `Export Profiles`
  - ручной экспорт профилей из IDE
- `Install Git Hooks`
  - настройка `core.hooksPath` прямо из IDE

Важно: задача `Sync (Startup)` запускается уже после открытия workspace. Поэтому для сценария «сначала `git pull`, потом открыть IDE» нужно использовать `Launch.ps1` или `launch.sh`, а не только задачи IDE.

## 🐧 Linux `.desktop` launchers

В `.scripts/` лежат готовые `.desktop` файлы:

- `launch.desktop`
  - `git pull` + `sync` + запуск IDE
- `sync.desktop`
  - `git pull` + `sync` без запуска IDE
- `export.desktop`
  - экспорт профилей и расширений в репозиторий
- `install-hooks.desktop`
  - подключение git hooks

Установка всех launcher'ов:

```bash
mkdir -p ~/.local/share/applications
cp ~/.config/VSCodium/User/.scripts/*.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

Если нужно обновить launcher'ы после `git pull`, просто выполните ту же команду копирования ещё раз.

## 👥 Поддержка профилей

Скрипты используют два уровня данных:

- `profiles.list` — переносимый список имён профилей
- `profile-templates/<Name>/` — переносимые файлы профиля
- `globalStorage/storage.json` — локальная карта имени профиля к machine-specific hash

Это устраняет проблему, когда на Windows и Linux один и тот же профиль получает разный каталог `profiles/<hash>`.

## 🔄 Миграция со старой схемы

Если раньше в git лежали файлы вида `profiles/<hash>/settings.json` и `profiles/<hash>/extensions.list`, они могли работать только на той машине, где были созданы.

Теперь переносимым источником истины считаются:

- `settings.json`
- `extensions.list`
- `profiles.list`
- `profile-templates/<Name>/`

А `profiles/<hash>/` остаются только локальными рабочими каталогами VSCodium.

## ⚠️ Примечания

### PowerShell Execution Policy

Если PowerShell-скрипты не запускаются:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Что попадает в git

`.gitignore` настроен так, чтобы сохранять только переносимые настройки, шаблоны профилей, скрипты и versioned hooks.
