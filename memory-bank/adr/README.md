---
title: Architecture Decision Records Index
doc_kind: adr
doc_function: index
purpose: Навигация по ADR проекта. Читать, чтобы найти уже принятые решения или завести новый ADR по шаблону.
derived_from:
  - ../dna/governance.md
  - ../flows/templates/adr/ADR-XXX.md
status: active
audience: humans_and_agents
---

# Architecture Decision Records Index

Каталог `memory-bank/adr/` хранит instantiated ADR проекта.

- Заводи новый ADR из шаблона [`../flows/templates/adr/ADR-XXX.md`](../flows/templates/adr/ADR-XXX.md).
- Держи в этом каталоге только реальные decision records, а не заметки или черновые исследования.
- Если ADR пока нет, этот индекс остается пустым и служит ожидаемой точкой размещения для будущих решений.

## When to Create an ADR

Для Hotel Concierge Bot заводи ADR, когда решение влияет на долгоживущую архитектуру, границы ответственности или future change constraints.

ADR нужен для решений про:

- каналы коммуникации между гостями и персоналом;
- доставку сообщений, retry policy, очереди, Redis и background jobs;
- модель ролей и доступа для guests, staff и admins;
- хранение сообщений, истории диалогов, персональных данных и audit trail;
- интеграции с PMS, CRM, мессенджерами, email или SMS-провайдерами;
- границы между Rails-приложением, ботом и внешними сервисами;
- устойчивые архитектурные паттерны: service objects, event-driven flows, state machines, serializers/presenters.

## What Does Not Belong Here

Не заводи ADR для:

- обычного CRUD без архитектурных последствий;
- локального рефакторинга внутри существующих правил;
- acceptance criteria или scope конкретной feature;
- временных research notes, spikes или черновиков;
- описания текущего поведения системы, если оно принадлежит `features/`, `domain/` или current-state specs.

## Records

No ADRs yet.

## Naming

- Формат файла: `ADR-XXX-short-decision-name.md`
- Нумерация монотонная и не переиспользуется
- Заголовок файла должен совпадать с `title` во frontmatter

## Statuses

- `proposed` — решение сформулировано, но еще не принято
- `accepted` — решение принято и считается canonical input для downstream-документов
- `superseded` — решение заменено другим ADR
- `rejected` — решение рассмотрено и отклонено
