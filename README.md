# VSCodium

Скрипты для управления расширениями VSCodium: экспорт, установка и просмотр.

## Доступные скрипты

| Файл | Для чего | Запуск |
| --- | --- | --- |
| `.scripts/Sync-Settings.ps1` | Windows: Синхронизация и запуск | `.\.scripts\Sync-Settings.ps1` |
| `.scripts/sync.sh` | macOS/Linux: Синхронизация и запуск | `bash .scripts/sync.sh` |
| `.scripts/extensions.ps1` | Управление расширениями (Win) | `.\.scripts\extensions.ps1` |

## Автоматизация (Sync & Start)

Скрипты синхронизации автоматизируют:
1. `git pull --rebase` для получения настроек.
2. Установку расширений из `extensions.list`.
3. Запуск VSCodium.

### Как использовать:

1. Создайте ярлык для `Sync-Settings.ps1` на рабочем столе.
2. В свойствах ярлыка в поле "Объект" (Target) укажите:
   ```plaintext
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Oleg\AppData\Roaming\VSCodium\User\.scripts\Sync-Settings.ps1"
   ```
3. Используйте этот ярлык вместо стандартного для запуска VSCodium.

## Быстрый старт

### PowerShell (рекомендуется)

```powershell
# Сохранить текущие расширения
.\extensions.ps1 list

# Посмотреть установленные расширения
.\extensions.ps1 show

# Установить расширения из файла
.\extensions.ps1 install
```

### Командная строка

```cmd
extensions.bat list
extensions.bat show
extensions.bat install
```

### Git Bash / WSL

```bash
./extensions.sh list
./extensions.sh show
./extensions.sh install
```

## Формат файла extensions.list

```plaintext
# Это комментарий - строки с # игнорируются
publisher.extension1
publisher.extension2
```

## Настройка для PowerShell

Если при запуске появляется ошибка выполнения скриптов:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## Требования

- VSCodium должен быть установлен и добавлен в PATH
- Или установлен в стандартную директорию:
  - `C:\Program Files\VSCodium\`
  - `C:\Program Files (x86)\VSCodium\`

## Примеры использования

### Перенос расширений на другой компьютер

1. На старом ПК: `.\extensions.ps1 list`
2. Скопировать файл `extensions.list`
3. На новом ПК: `.\extensions.ps1 install`

### Резервное копирование

```powershell
.\extensions.ps1 list
# Сохранить extensions.list в безопасное место
```

### Восстановление из резервной копии

```powershell
# Поместить extensions.list в директорию скрипта
.\extensions.ps1 install
```
