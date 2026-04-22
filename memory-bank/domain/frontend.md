---
title: Frontend
doc_kind: domain
doc_function: canonical
purpose: Описание UI-поверхностей, правил компонентов и i18n-слоя. Читать при работе с Rails-интерфейсами персонала, менеджера или встроенным гостевым виджетом.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Frontend

Проект не имеет отдельного SPA и мобильного приложения. UI-слой — Rails ERB с Hotwire, плюс отдельный встроенный виджет для гостей.

## UI Surfaces

**`guest-interface` — Telegram-бот и встроенный веб-чат.**
Это не Rails UI. Гость взаимодействует через Telegram (webhook → Sidekiq) или через embedded web-chat widget, встроенный на страницу отеля по QR-коду или ссылке. Виджет — самостоятельная поверхность, не часть Rails admin. Boundary с backend — JSON API или WebSocket для веб-чата.

**`staff-portal` — Rails ERB + Hotwire/Turbo.**
Интерфейс для сотрудников (горничные, технический персонал, официанты): очередь заявок своего отдела, смена статусов. Real-time обновления очереди — Turbo Streams. Код лежит внутри Rails-приложения в стандартных `app/views/staff/` и соответствующих контроллерах.

**`hotel-admin` — Rails ERB + Hotwire/Turbo.**
Интерфейс менеджера отеля: управление персоналом и отделами, редактирование базы знаний (FAQ), аналитический дашборд. Код в `app/views/admin/`. Администратор платформы управляет аккаунтами отелей через тот же Rails-интерфейс с отдельными правами.

Нет мобильного приложения. Нет SPA. Нет отдельной component library.

## Component And Styling Rules

- Стек: Rails 7 + Hotwire (Turbo Frames, Turbo Streams) + Stimulus.
- Новые UI-элементы оформляются как стандартные Rails partials (`app/views/shared/`).
- Локальные стили допустимы внутри feature boundary; глобальные изменения стилей согласовываются явно.
- Отдельной design system в v1 нет; консистентность обеспечивается через shared layouts (`app/views/layouts/`) и общие partials.
- Сложная клиентская интерактивность (не покрываемая Turbo + Stimulus) требует ADR перед реализацией.

## Interaction Patterns

- Основной паттерн: server-rendered HTML + Turbo Streams для real-time обновлений (статусы заявок, новые заявки в очереди).
- Не смешивать Turbo и SPA-подходы (React, Vue и т.д.) без явного ADR.
- Встроенный веб-чат для гостей — отдельный embedded widget; он не является частью Rails admin и разрабатывается изолированно.

## Localization

- Поддерживаемые языки: `ru` (основной), `en`.
- Переводы: Rails i18n, файлы `config/locales/ru.yml` и `config/locales/en.yml`.
- Fallback locale: `ru`.
- Новые ключи добавляются одновременно в оба locale-файла; ключ без перевода в одном из файлов считается ошибкой.
