---
title: Architecture Patterns
doc_kind: domain
doc_function: canonical
purpose: Каноничное место для архитектурных границ проекта. Читать при изменениях, затрагивающих модули, фоновые процессы, интеграции или конфигурацию.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Architecture Patterns

Этот документ задаёт ожидаемые архитектурные правила проекта. Реальные bounded contexts, integration boundaries и технические ограничения зафиксированы ниже.

## Module Boundaries

| Context | Owns | Must not depend on directly |
| --- | --- | --- |
| `guest-interface` | Входящие сообщения из Telegram webhook и веб-чата, сессии гостей, отправка автоответов | Детали очереди заявок `staff-portal`, внутренние модели `hotel-admin` |
| `request-processing` | Создание заявок, маршрутизация по отделу, state machine статусов, уведомления гостя о смене статуса | Telegram API (вызывается через adapter `guest-interface`), Rails UI |
| `staff-portal` | Очередь заявок для сотрудника, смена статусов, Rails ERB-интерфейс персонала | Детали Telegram-сессий, внутренности `hotel-admin` |
| `hotel-admin` | Управление отелями, отделами, сотрудниками, базой знаний (FAQ), аналитический дашборд | Бизнес-логика маршрутизации (`request-processing`), Telegram API |

Правила:

- `guest-interface` не знает о деталях `staff-portal`; взаимодействие идёт через события/модели `request-processing`.
- Маршрутизация заявок (выбор отдела по типу запроса) принадлежит только `request-processing` — ни guest-интерфейс, ни staff-portal не реализуют её самостоятельно.
- Telegram API вызывается исключительно через adapter внутри `guest-interface`; прямые вызовы из других контекстов запрещены.

## Concurrency And Critical Sections

Входящие Telegram webhook обрабатываются асинхронно через Sidekiq. Idempotency key — `telegram_update_id`; повторная постановка job с тем же ключом не порождает дублирующее действие.

Смена статуса заявки защищена оптимистичной блокировкой через `lock_version` в ActiveRecord:

```ruby
request.with_lock do
  request.update!(status: :in_progress)
end
```

Прямой `rescue` в job-классах запрещён — retry policy (exponential backoff, max 5 попыток) настраивается на уровне Sidekiq, а не внутри job. Исключение: явная бизнес-логика, требующая перевода в terminal-состояние при конкретной ошибке.

## Failure Handling And Error Tracking

- **Telegram API недоступен** → job уходит в очередь Sidekiq на retry с exponential backoff (максимум 5 попыток). После исчерпания retry — job переходит в dead queue; мониторинг алертит.
- **Заявка не может быть маршрутизирована** (отдел не найден или не настроен) → заявка получает статус `unrouted`, менеджеру отеля отправляется уведомление, заявка остаётся видимой в интерфейсе.
- **Все ошибки** пишутся в structured log с обязательным контекстом: `hotel_id`, `request_id` (где применимо). Error tracker (Sentry или аналог) получает эти поля как теги для фильтрации по клиенту.
- Вопрос ориентира: если base job class уже делает retry и нотификацию — локальный `rescue` в теле job не нужен.

## Configuration Ownership

Canonical schema конфигурации живёт в двух местах:

1. `config/credentials.yml.enc` — секреты: Telegram bot token, webhook URL, ключи сторонних сервисов.
2. `config/application.rb` — application-level defaults и non-secret settings.

Правила:

- Telegram bot token и webhook URL хранятся только в credentials; прямая запись в ENV-переменные запрещена.
- Defaults задаются в `config/application.rb`; environment-specific overrides — в `config/environments/*.rb`.
- Полный env contract (список всех переменных, их назначение и где задаются) описывается в [`../ops/config.md`](../ops/config.md).

Порядок изменения конфигурации:

1. Обновить `config/credentials.yml.enc` или `config/application.rb` (schema-owner).
2. Обновить environment overlays при необходимости.
3. Обновить [`../ops/config.md`](../ops/config.md).
