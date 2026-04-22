---
title: Testing Policy
doc_kind: engineering
doc_function: canonical
purpose: Testing policy Rails/RSpec проекта: automated regression coverage, contract verification, test levels и manual-only gaps.
derived_from:
  - ../dna/governance.md
  - ../flows/feature-flow.md
status: active
canonical_for:
  - repository_testing_policy
  - feature_test_case_inventory_rules
  - automated_test_requirements
  - sufficient_test_coverage_definition
  - manual_only_verification_exceptions
  - simplify_review_discipline
  - verification_context_separation
must_not_define:
  - feature_acceptance_criteria
  - feature_scope
audience: humans_and_agents
---

# Testing Policy

## Project Test Stack

- **Framework:** RSpec
- **Test data:** FactoryBot
- **Primary command:** `bundle exec rspec`
- **Quality check:** `bundle exec rubocop`
- **Current test surfaces:** service specs, request specs, config specs
- **Default model-spec rule:** не писать model specs по умолчанию

## Core Rules

- Любое изменение поведения, которое можно проверить детерминированно, обязано получить automated regression coverage.
- Любой новый или изменённый contract обязан получить contract-level automated verification.
- Любой bugfix обязан добавить regression test на воспроизводимый сценарий.
- Required automated tests считаются закрывающими риск только если они проходят локально и в CI.
- Manual-only verify допустим только как явное исключение и не заменяет automated coverage там, где automation реалистична.

## Test Levels

- **Service specs:** бизнес-логика, workflow decisions, validations на уровне use case, query objects, ticket transitions, staff assignment.
- **Request specs:** routes, controllers, authentication, authorization, role boundaries, redirects/renders, HTTP status codes.
- **Job specs:** background jobs, retries, idempotency, queue behavior and delivery orchestration, когда появится Sidekiq/background job layer.
- **Config specs:** runtime configuration that affects behavior, such as Redis client setup.
- **Integration/system specs:** только если browser-level или multi-surface behavior нельзя проверить через service/request/job specs.

## Model Testing Rule

Не писать model specs по умолчанию.

Models должны оставаться тонкими, но текущие models содержат associations, enums, validations и hotel-boundary invariants. Покрывай эти invariants через service specs и request specs, когда они влияют на поведение.

## Domain-Specific Expectations

Тесты не должны отправлять реальные сообщения гостям, персоналу или внешним системам.

Когда появляется delivery behavior:

- mock external delivery clients или используй fake adapters;
- проверяй intended delivery request без вызова live APIs;
- покрывай idempotency для входящей и исходящей обработки сообщений;
- покрывай duplicate inbound messages и retry-safe behavior;
- проверяй, что delivery side effects происходят только после authorization и state checks.

Negative cases, которые нужно рассматривать, когда они релевантны:

- unknown guest;
- closed request/ticket;
- duplicate message;
- unavailable staff member;
- invalid status transition;
- missing or insufficient access rights;
- ticket, staff, department или guest из другого hotel.

## Contract Verification

Добавляй или обновляй contract-level tests при изменении:

- public routes или controller behavior;
- service `Result` shape или error codes;
- role/access behavior;
- database constraints, на которые опираются user flows;
- Redis, Sidekiq/background job behavior;
- message routing или notification delivery behavior.

## Ownership Split

- Canonical test cases delivery-единицы задаются в `feature.md` через `SC-*`, feature-specific `NEG-*`, `CHK-*` и `EVID-*`.
- `implementation-plan.md` владеет только стратегией исполнения: какие test surfaces будут добавлены или обновлены, какие gaps временно остаются manual-only и почему.

## Feature Flow Expectations

Canonical lifecycle gates живут в [../flows/feature-flow.md](../flows/feature-flow.md):

- к `Design Ready` `feature.md` уже фиксирует test case inventory;
- к `Plan Ready` `implementation-plan.md` содержит `Test Strategy` с planned automated coverage и manual-only gaps;
- к `Done` required tests добавлены, локальные команды зелёные и CI не противоречит локальному verify.

## Что Считается Sufficient Coverage

Coverage считается достаточным, когда:

- покрыт основной changed behavior;
- покрыт ближайший regression path;
- покрыты новые или изменённые contracts, events, schema или integration boundaries;
- покрыты critical failure modes и feature-specific negative/edge scenarios;
- tests проверяют behavior, а не только implementation details.

Процент line coverage сам по себе недостаточен: нужен scenario- и contract-level coverage.

## Когда Manual-Only Допустим

- Сценарий зависит от live infra, внешних систем, hardware, недетерминированной среды или human оценки UI.
- Для каждого manual-only gap: причина, ручная процедура, owner follow-up.
- Если manual-only gap оставляет без regression protection критичный путь, feature не считается завершённой.

## Simplify Review

Отдельный проход верификации после функционального тестирования. Цель: убедиться, что реализация минимально сложна.

- Выполняется после прохождения tests, но до closure gate.
- Паттерны: premature abstractions, глубокая вложенность, дублирование логики, dead code, overengineering.
- Три похожие строки лучше premature abstraction. Абстракция оправдана только когда она реально уменьшает риск или повтор.

## Verification Context Separation

Разные этапы верификации — отдельные проходы:

1. **Функциональная верификация** — tests проходят, acceptance scenarios покрыты
2. **Simplify review** — код минимально сложен
3. **Acceptance test** — end-to-end по `SC-*`

Для small features допустимо в одной сессии, но simplify review не пропускается.

## Canonical Local Commands

```bash
bundle exec rspec
bundle exec rubocop
```
