---
title: Coding Style
doc_kind: engineering
doc_function: convention
purpose: Rails/Ruby code style, tooling и архитектурные соглашения проекта Hotel Concierge Bot.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Coding Style

## Стек

- **Runtime:** Ruby 3.3, Ruby on Rails 7.1
- **База данных:** PostgreSQL
- **Кэш / runtime state:** Redis
- **Тестирование:** RSpec, FactoryBot
- **Lint:** RuboCop
- **Service initialization:** `dry-initializer`
- **Background jobs:** Sidekiq пока не установлен в `Gemfile`; он будет добавлен отдельной feature-работой, когда появится background job layer.

## Инструменты

- Запускай style check через `bundle exec rubocop`.
- `bundle exec rubocop -A` разрешён только в рамках текущей задачи, после просмотра diff и без unrelated style churn.
- Не меняй зависимости и не добавляй gems без явного запроса.

## Rails Conventions

- Держи контроллеры тонкими: authentication/authorization, parameter whitelisting, orchestration, redirects/renders.
- Выноси бизнес-логику в service objects под `app/services`.
- Предпочитай один публичный entrypoint сервиса: `call`.
- Сервисы, наследующиеся от `BaseService`, используют `Dry::Initializer` options и возвращают `Result` objects для success/failure flows.
- Держи модели тонкими. Associations, enums, простые validations и DB-backed integrity checks допустимы; workflow decisions должны жить в сервисах.
- Избегай ActiveRecord callbacks, если нет явной persistence-level причины и тестов на side effect.
- Не размещай бизнес-логику во views. Views рендерят подготовленное состояние и validation/error messages.
- Следуй Rails naming conventions для файлов, constants, routes, controllers и specs.
- Методы должны быть маленькими и явными; избегай скрытых side effects.

## Data Integrity

- Критичная целостность должна быть защищена на уровне БД, когда это практично: `null` constraints, unique indexes, foreign keys и check constraints.
- Service-layer validations должны объяснять business failures и возвращать явные `Result` failures.
- Не полагайся на view/controller checks как на единственную защиту role, hotel или assignment boundaries.

## Test Placement Hints

- Service behavior размещай в `spec/services`.
- HTTP/role/route behavior размещай в `spec/requests`.
- Background job behavior, когда появится Sidekiq/background job layer, размещай в `spec/jobs`.
- Shared test setup размещай в `spec/support`.
- Не добавляй model specs по умолчанию; model-backed invariants покрывай через service/request specs.

## Domain Naming Hints

Используй имена, которые соответствуют домену hotel operations:

- guest request handling
- staff assignment
- message routing
- notification delivery
- reservation or guest context
- ticket transition
- department visibility
- hotel boundary

Не придумывай domain abstractions, которых нет в scope feature или существующем коде.

## Optional Rails Layers

`app/forms`, `app/presenters` и `app/decorators` существуют, но проектный паттерн там ещё не установлен. Добавляй классы в эти слои только если feature реально требует этого слоя и после следования локальному стилю первой реализации.

## Change Discipline

- Не переписывай несвязанный код только ради единообразия, если задача этого не требует.
- При touch-up изменениях следуй существующему локальному стилю файла, если нет явного конфликта с canonical rule.
- Весь код, комментарии, branch names и commit messages — на английском.
- Если два project patterns конфликтуют, остановись и спроси, какой из них canonical.
