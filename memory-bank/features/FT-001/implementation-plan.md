---
title: "FT-001: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution plan для FT-001. Фиксирует implementation sequence, grounding, dependencies и test strategy без переопределения canonical feature scope."
derived_from:
  - feature.md
  - ../001/plan.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_001_scope
  - ft_001_architecture
  - ft_001_acceptance_criteria
  - ft_001_blocker_state
---

# Implementation Plan

## Цель текущего плана

Реализовать Staff-backed HTTP Basic Auth для admin namespace и role-gate для `GET /admin/hotels`, чтобы acceptance scenarios из `feature.md` можно было проверить через request specs и manual checks.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `Gemfile` | Объявляет application dependencies. | `bcrypt` должен быть включён для `has_secure_password`. | Раскомментировать существующую строку `bcrypt` gem. |
| `app/models/staff.rb` | Владеет Staff records и role enum. | Нужно добавить `has_secure_password`, сохранив associations и enum. | Держать model thin; не добавлять ручную password presence validation. |
| `app/controllers/admin/base_controller.rb` | Общий parent для admin controllers. | Current static Basic Auth должен быть заменён. | Сохранить request-level Basic Auth pattern, но authenticate Staff records. |
| `app/controllers/admin/hotels_controller.rb` | Показывает список отелей в admin area. | Нужен role gate для `admin` и `manager`. | Добавить controller-local authorization method. |
| `spec/requests/admin/access_spec.rb` | Existing admin namespace request coverage. | Должен продолжить проходить через Staff credentials. | Сохранить existing describe blocks и assertions. |
| `app/views/admin/hotels/index.html.erb` | Рендерит hotels list и empty state. | Empty-state acceptance является manual-only. | Проверить существующий branch `t("admin.hotels.index.empty")`. |
| `config/locales/en.yml`, `config/locales/ru.yml` | Locale files. | Empty-state message должен существовать в обеих locales. | Проверить existing keys перед редактированием. |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `spec/requests/admin/hotels_spec.rb` | `REQ-01`, `REQ-04`, `SC-01`-`SC-08`, `CHK-01` | До FT-001 отсутствует. | Добавить request specs для authentication failures и role outcomes. | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | RSpec job | Нет | `none` |
| `spec/requests/admin/access_spec.rb` | `REQ-05`, `SC-09`, `CHK-02` | Existing admin request coverage. | Обновить auth helper для Staff credentials. | `bundle exec rspec spec/requests/admin/access_spec.rb` | RSpec job | Нет | `none` |
| Manual empty-state verification | `REQ-06`, `SC-10`, `CHK-03` | View и i18n могут уже существовать. | Нет. | Manual inspection. | Нет | Integration test не может достичь zero-hotel state, потому что `Staff#hotel_id` is non-null. | `none` |
| Full suite | `EC-01`-`EC-08`, `CHK-04` | Existing suite. | Запустить после прохождения targeted specs. | `bundle exec rspec` | RSpec job | Нет | `none` |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Есть ли в development database существующие Staff rows при добавлении `password_digest` с `null: false`? | PostgreSQL отклоняет добавление non-null column без default, если rows already exist. | `STEP-04` | Проверить `Staff.count`; делать reset dev DB только после explicit human approval. |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| dependency | `bundle install` должен сделать `bcrypt` loadable. | `STEP-01`, `STEP-05` | `require 'bcrypt'` fails или `has_secure_password` не может authenticate. |
| database | PostgreSQL доступен для migration. | `STEP-02`-`STEP-04` | Migration fails или `db:migrate:status` не запускается. |
| test | `bundle exec rspec <path>` — canonical local verification command. | `CHK-01`, `CHK-02`, `CHK-04` | Non-zero exit означает failed verification. |
| manual inspection | Manual checks допустимы только для empty-state branch и hardcoded credential scan. | `CHK-03` | Missing i18n/view branch или hardcoded credentials remain. |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `CON-01` | `bcrypt` можно включить без добавления нового dependency family. | `STEP-01`, `STEP-05` | yes |
| `PRE-02` | `CON-02` | Добавление `password_digest` с `null: false` допустимо для current data state. | `STEP-03`, `STEP-04` | yes |
| `PRE-03` | `NS-07` | Existing migrations нельзя редактировать. | `STEP-02`, `STEP-03` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-1` | `REQ-01`, `REQ-02`, `REQ-03` | Staff-backed authentication foundation. | agent | `PRE-01`, `PRE-02`, `PRE-03` |
| `WS-2` | `REQ-04` | Role-gated hotels listing. | agent | `WS-1` |
| `WS-3` | `REQ-05`, `REQ-06` | Request specs и manual verification. | agent | `WS-1`, `WS-2` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | Development DB содержит Staff rows и перед migration нужен `db:reset`. | `STEP-04` | Database reset destructive для local data. | Human approval в чате. |

## Work Order

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-02`, `CON-01` | Включить `bcrypt` и установить dependencies. | `Gemfile`, `Gemfile.lock` | `bcrypt` доступен. | `CHK-03` | `EVID-03` | `bundle exec ruby -e "require 'bcrypt'"` | `PRE-01` | `none` | Dependency install fails. |
| `STEP-02` | agent | `REQ-03` | Сгенерировать migration для `staffs.password_digest`. | `db/migrate/*_add_password_digest_to_staffs.rb` | New migration file. | `CHK-03` | `EVID-03` | Inspect migration file exists. | `PRE-03` | `none` | Generator fails. |
| `STEP-03` | agent | `REQ-03`, `CON-02` | Добавить `null: false` к `password_digest`. | Migration file | Non-null column definition. | `CHK-03` | `EVID-03` | Inspect migration file. | `STEP-02` | `none` | Existing data blocks migration design. |
| `STEP-04` | agent / human | `REQ-03` | Запустить database migration. | Database schema | Migration is up. | `CHK-03` | `EVID-03` | `bin/rails db:migrate` and `bin/rails db:migrate:status` | `STEP-03`, `OQ-01` | `AG-01` if reset needed | Migration fails. |
| `STEP-05` | agent | `REQ-02` | Добавить `has_secure_password` в Staff. | `app/models/staff.rb` | Staff can authenticate. | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` | Covered by request specs. | `STEP-01`, `STEP-04` | `none` | Staff model behavior breaks. |
| `STEP-06` | agent | `REQ-05`, `CON-06` | Добавить Staff factory с role traits. | `spec/factories/staffs.rb` | Factory available for request specs. | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` | Covered by request specs. | `STEP-05` | `none` | Factory collisions or validation errors. |
| `STEP-07` | agent | `REQ-01` | Заменить static Basic Auth на Staff-backed custom auth. | `app/controllers/admin/base_controller.rb` | `authenticate_staff!`, `http_401`, `@current_staff`. | `CHK-01`, `CHK-02`, `CHK-03` | `EVID-01`, `EVID-02`, `EVID-03` | Targeted request specs and manual credential scan. | `STEP-05` | `none` | Auth failures leak through. |
| `STEP-08` | agent | `REQ-04` | Добавить role check в hotels index. | `app/controllers/admin/hotels_controller.rb` | `require_hotel_access!`. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | `STEP-07` | `none` | Admin/manager access regresses. |
| `STEP-09` | agent | `REQ-06` | Проверить empty-state locale keys. | `config/locales/en.yml`, `config/locales/ru.yml` | Locale keys confirmed or added if missing. | `CHK-03` | `EVID-03` | Manual inspection or `I18n.t`. | none | `none` | Locale keys missing. |
| `STEP-10` | agent | `REQ-06` | Проверить hotels empty-state view branch. | `app/views/admin/hotels/index.html.erb` | Empty-state branch confirmed or added if missing. | `CHK-03` | `EVID-03` | Manual inspection. | none | `none` | View branch missing. |
| `STEP-11` | agent | `REQ-05` | Обновить existing admin access spec для Staff credentials. | `spec/requests/admin/access_spec.rb` | Existing specs pass through Staff auth. | `CHK-02` | `EVID-02` | `bundle exec rspec spec/requests/admin/access_spec.rb` | `STEP-06`, `STEP-07` | `none` | Existing assertions fail. |
| `STEP-12` | agent | `REQ-04`, `REQ-05` | Добавить hotels request spec с eight scenarios. | `spec/requests/admin/hotels_spec.rb` | Role/authentication coverage. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | `STEP-06`, `STEP-07`, `STEP-08` | `none` | Scenario count or status codes mismatch. |
| `STEP-13` | agent | `REQ-01`-`REQ-06` | Запустить full suite и завершить manual checks. | test suite, source files | Feature ready for acceptance. | `CHK-03`, `CHK-04` | `EVID-03`, `EVID-04` | `bundle exec rspec`; manual inspection checklist. | `STEP-01`-`STEP-12` | `none` | Full suite fails. |

## Parallelizable Work

- `PAR-01` `STEP-06`, `STEP-07`, `STEP-08` и `STEP-09` могут выполняться независимо после готовности Staff authentication foundation.
- `PAR-02` `STEP-09` и `STEP-10` являются verification-only, если keys или view branch не отсутствуют.
- `PAR-03` `STEP-11` и `STEP-12` не должны запускаться до готовности auth и factory work.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-01`-`STEP-05` | Staff records can authenticate with password. | `EVID-01`, `EVID-02` |
| `CP-02` | `STEP-07`, `STEP-08`, `STEP-12` | Hotels request spec passes all role/auth scenarios. | `EVID-01` |
| `CP-03` | `STEP-11` | Existing admin access spec passes with Staff credentials. | `EVID-02` |
| `CP-04` | `STEP-13` | Full RSpec suite passes и manual checks complete. | `EVID-03`, `EVID-04` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Existing Staff rows block `null: false` migration. | Migration fails. | Check data first; request approval before local DB reset. | `PG::NotNullViolation` или non-zero `Staff.count`. |
| `ER-02` | Auth filter does not halt after rendering `401`. | Controller action может продолжиться после failed auth. | Использовать `return http_401` для early failures. | Specs show unexpected response body/status. |
| `ER-03` | Request specs use wrong auth header key. | Specs fail despite valid implementation. | Использовать `Authorization` header matching custom implementation. | Specs fail with `401` for valid Staff. |
| `ER-04` | Empty-state acceptance cannot be tested through request spec. | False expectation of automated coverage. | Keep manual-only check documented in `CHK-03`. | Attempt to create Staff without hotel violates DB constraint. |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `AG-01`, `ER-01` | Migration requires destructive local DB reset. | Stop and ask human approval. | No migration applied. |
| `STOP-02` | `ER-02`, `ER-03` | Targeted request specs cannot be made green without changing public scope. | Stop and update `feature.md` before continuing. | Code changes paused; feature contract reviewed. |
| `STOP-03` | `NS-04` | Implementation appears to require adding an auth gem. | Stop and escalate design change. | Keep custom Basic Auth scope. |

## Ready For Acceptance

- [ ] `CHK-01` passes: `bundle exec rspec spec/requests/admin/hotels_spec.rb`.
- [ ] `CHK-02` passes: `bundle exec rspec spec/requests/admin/access_spec.rb`.
- [ ] `CHK-03` manual checks completed: no hardcoded admin credentials in `Admin::BaseController`, `bcrypt` enabled, empty-state locale/view present.
- [ ] `CHK-04` passes: `bundle exec rspec`.
- [ ] Any manual-only evidence is recorded under the `EVID-*` contract from `feature.md`.
