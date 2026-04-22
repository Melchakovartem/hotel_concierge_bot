---
title: Engineering Documentation Index
doc_kind: engineering
doc_function: index
purpose: Навигация по engineering-level документации проекта Hotel Concierge Bot.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Engineering Documentation Index

`memory-bank/engineering/` содержит правила разработки, тестирования, git workflow и границы автономии для Hotel Concierge Bot: Rails 7, PostgreSQL, Redis, RSpec и FactoryBot.

- [Autonomy Boundaries](autonomy-boundaries.md)
  **Что:** Что агент может делать сам, где нужна контрольная точка, а где требуется эскалация.
  **Читать, чтобы:** понять, можно ли менять код, данные, delivery behavior, авторизацию, Redis/Sidekiq/background jobs или production/live data без подтверждения.

- [Coding Style](coding-style.md)
  **Что:** Rails/Ruby code style, сервисный слой, контроллеры, модели, views, tooling и naming hints.
  **Читать, чтобы:** реализовывать изменения в стиле текущего Rails-проекта и не добавлять неподтверждённые архитектурные паттерны.

- [Testing Policy](testing-policy.md)
  **Что:** Уровни тестов, обязательное regression coverage, contract verification, manual-only gaps и локальные quality checks.
  **Читать, чтобы:** решить, какие RSpec-тесты нужны для изменения и чем подтвердить готовность.

- [Git Workflow](git-workflow.md)
  **Что:** Default branch, issue-linked ветки, commit style, PR expectations и локальные проверки перед PR.
  **Читать, чтобы:** подготовить ветку, коммиты и PR без нарушения workflow проекта.
