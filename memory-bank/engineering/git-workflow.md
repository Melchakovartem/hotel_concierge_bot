---
title: Git Workflow
doc_kind: engineering
doc_function: convention
purpose: Git workflow проекта: default branch, issue-linked ветки, commit style, PR expectations и локальные проверки.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Git Workflow

## Default Branch

Default branch: `main`.

Подтверждено через `origin/HEAD -> origin/main`.

## Branches

Фичи создаются через GitHub Issues. Если GitHub предлагает issue-linked branch name, используй его без переименования.

Примеры project-style branch names:

- `1-feature-001-secure-admin-hotel-listing-by-role`
- `3-feature-002-role-based-authorization-hotel-crud`

Если issue branch не был создан автоматически, fallback-формат:

```text
<issue-number>-<feature-id-or-type>-<short-slug>
```

Branch names должны быть на английском.

## Commits

- Пиши коротко, в present tense / imperative mood.
- Хорошо: `Add staff ticket workflow`, `Fix ticket transition validation`, `Update engineering docs`.
- Conventional commits допустимы, но не являются обязательным правилом проекта: commit history не показывает стабильного требования к `feat:`, `fix:`, `docs:`.
- Не смешивай несвязанные изменения в одном commit.
- Commit messages должны быть на английском.

## Pull Requests

Перед PR зафиксируй:

- Что изменено.
- Как проверено локально.
- Какие миграции добавлены, если они есть.
- Есть ли влияние на guest/staff messages или notification delivery.
- Есть ли влияние на Redis, Sidekiq/background jobs, queues, retries или scheduled behavior.
- Есть ли изменения auth/security логики, ролей или публичных API-контрактов.
- Manual steps, rollout notes или risks, если они остаются.

## Canonical Local Checks

Минимум перед PR:

```bash
bundle exec rspec
```

Если изменение затрагивает Ruby/Rails код или форматирование:

```bash
bundle exec rubocop
```

`bundle exec rubocop -A` разрешён только в рамках текущей задачи, после просмотра diff и без unrelated style churn.

## Worktrees

Git worktrees не используются как обязательная практика проекта. Если для параллельной задачи нужен worktree, сначала согласуй naming/location и bootstrap steps.
