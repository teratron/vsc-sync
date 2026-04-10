# VSCodium

Скрипты для управления расширениями VSCodium: экспорт, установка и просмотр.

## Доступные скрипты

| Файл | Для чего | Запуск |
| --- | --- | --- |
| `extensions.ps1` | PowerShell (рекомендуется для Windows 11) | `.\extensions.ps1 list` |
| `extensions.bat` | Командная строка Windows | `extensions.bat list` |
| `extensions.cmd` | Командная строка Windows | `extensions.cmd list` |
| `extensions.sh` | Git Bash / WSL | `./extensions.sh list` |

## Команды

| Команда | Описание |
| --- | --- |
| `list` | Экспортировать установленные расширения в `extensions.list` |
| `install` | Установить расширения из файла `extensions.list` |
| `show` | Показать установленные расширения |
| `help` | Показать справку |

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
