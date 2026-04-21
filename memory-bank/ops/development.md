---
title: Development Environment
doc_kind: engineering
doc_function: canonical
purpose: Шаблон документа для локальной разработки. Читать при адаптации setup, dev-команд и browser/database workflow под проект.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Development Environment

После копирования шаблона замени placeholders ниже на реальные команды проекта.

## Setup

```bash
bin/setup
```

## Daily Commands

```bash
bin/rails s          # запустить сервер
bundle exec rspec    # запустить тесты
bin/rails db:migrate # выполнить миграции
bin/rails console    # консоль Rails
```

## Browser Testing

Если проект имеет UI, опиши:

- как определить локальный URL;
- где брать порт или host;
- можно ли искать их автоматически;
- какие способы browser verification считаются canonical.

Пример:

1. Сначала читать `DEV_HOST` или `.env`.
2. Если переменная не задана, использовать documented default.
3. Не сканировать порты вручную без явного запроса пользователя.

## Database And Services

Документируй только то, что действительно важно для локальной работы:

- миграции;
- пересоздание локальной БД;
- обязательные сервисы;
- seeded data;
- known pitfalls для разработчиков и агентов.

## Adoption Checklist

- [ ] указаны реальные setup-команды
- [ ] указаны реальные test/lint commands
- [ ] документирован способ определения локального URL
- [ ] перечислены локальные зависимости и сервисы
- [ ] удалены нерелевантные примеры
