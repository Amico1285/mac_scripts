# ClaudePing System

Автоматическая система для поддержания активности 5-часовых интервалов Claude Code через регулярные пинги модели.

## Назначение

Claude Code имеет 5-часовые интервалы тарификации. Система ClaudePing автоматически отправляет пинги Claude каждые 5 часов 1 минуту, чтобы поддерживать активность сессии и максимизировать использование оплаченных интервалов.

## Архитектура системы

### Основные компоненты

1. **ping_claude.sh** - основной скрипт пинга
2. **config.json** - конфигурация времени и настроек
3. **generate_schedule.sh** - генератор расписания launchd
4. **claudeping** - TUI интерфейс управления
5. **4 launchd сервиса** - автоматическое выполнение по расписанию

### Как работает система

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   config.json   │───▶│ generate_schedule │───▶│  4 pинга в день │
│   start_hour: 7 │    │      .sh         │    │ 07:00, 12:01,   │
└─────────────────┘    └──────────────────┘    │ 17:02, 22:03    │
                                               └─────────────────┘
                              │
                              ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   pmset wake    │◀───│   launchd plist  │───▶│  ping_claude.sh │
│   в 06:59:00    │    │     файлы        │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │ claude -p ping  │
                                               │ model: sonnet-4 │
                                               └─────────────────┘
```

## Структура файлов

```
Mac_scripts/
├── CLAUDE.md                    # Документация проекта
├── README.md                    # Пользовательская документация  
├── config.json                  # Конфигурация (start_hour, log_file)
├── ping_claude.sh               # Основной скрипт пинга Claude
├── generate_schedule.sh         # Генератор launchd расписания
├── claudeping                   # TUI интерфейс управления
├── install.sh                   # Установка системы
├── install_global.sh            # Глобальная установка команды claudeping
├── uninstall.sh                 # Удаление системы
└── setup_wake.sh                # Настройка пробуждения Mac
```

## Техническая реализация

### Расчет времени пингов

При `start_hour: 7` система генерирует:
- Пинг 1: 07:00 (старт)
- Пинг 2: 12:01 (07:00 + 5:01)  
- Пинг 3: 17:02 (12:01 + 5:01)
- Пинг 4: 22:03 (17:02 + 5:01)

Интервал 5:01 обеспечивает перекрытие 5-часовых интервалов Claude Code.

### launchd сервисы

Создаются 4 файла в `~/Library/LaunchAgents/`:
```xml
com.user.claude-ping-1.plist  # 07:00
com.user.claude-ping-2.plist  # 12:01  
com.user.claude-ping-3.plist  # 17:02
com.user.claude-ping-4.plist  # 22:03
```

Каждый содержит:
```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>7</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

### Команда пинга

```bash
echo "ping" | /Users/aleksandrilinskii/.bun/bin/claude \
    -p "When I send you the command ping, respond with just one word: ping" \
    --model claude-sonnet-4-20250514
```

### PATH для launchd

launchd запускается с минимальным PATH, поэтому в скриптах добавлен:
```bash
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
```

### Автоматическое пробуждение Mac

```bash
sudo pmset repeat wakeorpoweron MTWRFSU 06:59:00
```
Будит Mac в 06:59 для первого пинга в 07:00.

## Логирование

Все пинги записываются в `~/Library/Logs/claude_ping.log`:
```
2025-06-22 07:00:05 ping
2025-06-22 12:01:03 ping  
2025-06-22 17:02:07 ping
2025-06-22 22:03:02 ping
```

Формат: `YYYY-MM-DD HH:MM:SS ping`

Ошибки логируются как:
```
2025-06-22 07:00:05 ERROR: command not found
```

## Управление системой

### Команда claudeping

TUI интерфейс с dialog:
- Toggle Service (Start/Stop)
- Configure Start Time (5-12)  
- View Logs
- View Schedule
- Exit

### Базовые команды

```bash
# Установка
./install.sh

# Глобальная команда
./install_global.sh
claudeping

# Изменение времени
echo '{"start_hour": 8}' > config.json
./generate_schedule.sh
./install.sh

# Удаление
./uninstall.sh

# Логи
tail -f ~/Library/Logs/claude_ping.log
```

## Системные требования

- **macOS** с launchd
- **Claude Code CLI** установленный и настроенный
- **jq** для работы с JSON (автоматически устанавливается)
- **dialog** для TUI (автоматически устанавливается)  
- **Права sudo** для настройки пробуждения

## Энергосбережение

Система настраивает:
```bash
sudo pmset -a womp 1          # Wake on Magic Packet
sudo pmset repeat wakeorpoweron MTWRFSU HH:MM:SS
```

В System Preferences появляются 4 записи "bash" в Login Items & Extensions.

## Troubleshooting

### Частые проблемы

**Claude command not found:**
- Проверить путь к claude: `which claude`
- Обновить в ping_claude.sh полный путь

**Node not found:**
- Проверить PATH в скриптах
- Добавить `/usr/local/bin` в PATH

**Не просыпается Mac:**
- Проверить pmset настройки: `pmset -g sched`
- В System Preferences включить "Wake for Wi-Fi network access"
- Отключить "Put hard disks to sleep"

**Сервисы не загружаются:**
```bash
launchctl list | grep claude-ping
launchctl load ~/Library/LaunchAgents/com.user.claude-ping-*.plist
```

### Отладка

```bash
# Проверить статус сервисов
launchctl list | grep claude

# Тестовый запуск скрипта
./ping_claude.sh

# Проверить логи системы
log show --predicate 'subsystem == "com.apple.launchd"' --last 1h | grep claude

# Проверить планировщик
pmset -g sched
```

## Конфигурация

### config.json

```json
{
  "start_hour": 7,
  "log_file": "~/Library/Logs/claude_ping.log"
}
```

- `start_hour`: 5-23, час первого пинга
- `log_file`: путь к файлу логов

### Изменение интервала

Для изменения с 5:01 на другой интервал отредактировать в `generate_schedule.sh`:
```bash
# Текущий: добавляем 5 часов 1 минуту
CURRENT_MINUTE=$((CURRENT_MINUTE + 1))
CURRENT_HOUR=$((CURRENT_HOUR + 5))
```

### Количество пингов

Для изменения количества пингов в день изменить цикл:
```bash
# Текущий: 4 пинга
for i in {1..4}; do
```

## Безопасность

- Логи не содержат чувствительной информации
- Используется официальный Claude CLI
- Код открытый и проверяемый
- Нет сетевых подключений кроме Claude API
- Минимальные системные права

## Мониторинг

```bash
# Статус сервисов
claudeping

# Последние пинги  
tail ~/Library/Logs/claude_ping.log

# Планировщик Mac
pmset -g sched

# Активные сервисы
launchctl list | grep claude-ping
```

## Производительность

- **CPU**: ~0.1% на 1-2 секунды при пинге
- **Память**: ~10MB на время выполнения
- **Диск**: ~50 байт лога в день
- **Сеть**: ~1KB на пинг (4KB в день)
- **Батарея**: 4 пробуждения в день по ~5 секунд

Система практически не влияет на производительность Mac.