---
title: "FT-002: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution plan для FT-002. Фиксирует discovery context, steps, risks и test strategy без переопределения canonical feature scope."
derived_from:
  - feature.md
  - ../002/plan.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_002_scope
  - ft_002_architecture
  - ft_002_acceptance_criteria
  - ft_002_blocker_state
---

# Implementation Plan

## Цель текущего плана

Реализовать admin-only authorization для `/admin/**`, slug-based Hotel CRUD и read-only hotel-scoped staff/tickets routes так, чтобы canonical scenarios из `feature.md` проверялись request/service specs и full RSpec suite.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `Admin::BaseController` | Выполняет `authenticate_staff!`, но legacy plan фиксирует отсутствие `require_admin!`. | FT-002 должен добавить admin-only gate после Staff authentication. | Keep slice 001 auth and `401` behavior unchanged. |
| `Admin::HotelsController` | Legacy plan фиксирует `require_hotel_access!` для admin + manager and only `index`. | Нужно заменить role gate и расширить до CRUD. | Remove hotels-local role gate after base admin gate exists. |
| `Hotel` model | Legacy plan фиксирует отсутствие `slug`, validations and `has_many :tickets`. | Нужны slug routing, validations and destroy restrictions. | Keep existing associations with `dependent: :restrict_with_exception`. |
| `Ticket` model | Legacy plan фиксирует отсутствие direct `hotel_id`, `subject`, `body`. | Nested hotel tickets need direct hotel scope and display fields. | Preserve existing guest/department/staff associations; `staff` can be optional. |
| `config/routes.rb` | Legacy plan фиксирует hotels `only: :index`, no nested resources. | Нужно добавить slug-param CRUD and nested resources. | Use `resources :hotels, param: :slug`. |
| `app/services/` | Legacy plan фиксирует only example ping service, no `BaseService` / `Result`. | Create/update flows use service result contract. | Use `dry-initializer`; do not introduce `dry-monads`. |
| `spec/factories/hotels.rb` | Existing factory has `sequence(:name)`, no `slug`. | Required validations make factories invalid without slug. | Add slug sequence; see `OQ-02` for exact legacy conflict. |
| `spec/factories/tickets.rb` | Legacy plan says create if absent. | Request specs need hotel-bound tickets with subject/body. | Factory should align guest/department/staff hotel associations. |
| `app/views/admin/hotels/index.html.erb` | Only hotels index view exists. | CRUD and nested links require more views. | Keep existing empty state with `t(".empty")`. |
| `config/locales/en.yml`, `config/locales/ru.yml` | Hold admin view copy. | Empty states and action links must be localized. | Add only keys used by views/specs. |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `spec/services/` | `REQ-11`, `SC-16`, `CHK-01` | No `BaseService` / `Result` coverage documented. | Cover service result contract if service specs are added. | `bundle exec rspec spec/services/` | RSpec job | none | `none` |
| `spec/services/admin/hotels/*` | `REQ-03`, `REQ-11`, `SC-05`, `SC-16`, `CHK-01` | Absent before FT-002. | Add create/update service specs for valid, invalid and duplicate cases. | `bundle exec rspec spec/services/admin/hotels/` | RSpec job | none | `none` |
| `spec/requests/admin/access_spec.rb` | `REQ-01`, `SC-01`-`SC-03`, `CHK-02` | Existing admin access coverage. | Add manager/staff authorization cases for `GET /admin`, `GET /admin/staff`, `GET /admin/tickets`; keep admin happy paths and unauth `401`. | `bundle exec rspec spec/requests/` | RSpec job | none | `none` |
| `spec/requests/admin/hotels_spec.rb` | `REQ-01`-`REQ-06`, `REQ-12`, `SC-01`-`SC-11`, `CHK-03` | Existing index/auth examples must be updated. | Grow CRUD and auth coverage slice-by-slice. | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | RSpec job | none | `none` |
| `spec/requests/admin/hotel_staff_spec.rb` | `REQ-08`, `REQ-09`, `SC-12`, `SC-13`, `CHK-04` | Absent before FT-002. | Add hotel-scoped staff index/show, auth and `404` coverage. | `bundle exec rspec spec/requests/admin/hotel_staff_spec.rb` | RSpec job | none | `none` |
| `spec/requests/admin/hotel_tickets_spec.rb` | `REQ-08`, `REQ-10`, `SC-14`, `SC-15`, `CHK-04` | Absent before FT-002. | Add hotel-scoped tickets, empty, unassigned, auth and `404` coverage. | `bundle exec rspec spec/requests/admin/hotel_tickets_spec.rb` | RSpec job | none | `none` |
| Full suite and style | `EC-12`, `CHK-05`, `CHK-06` | Existing suite. | Full regression and style pass after feature slices. | `bundle exec rubocop`; `bundle exec rspec` | RuboCop job, RSpec job | none | `none` |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Есть ли existing rows in `hotels` or `tickets` during migration? | Legacy spec assumes empty tables but also documents safe rollout for non-empty data. | `STEP-04`, `STEP-05` | Use safe rollout/backfill. Escalate if deterministic backfill is impossible. |
| `OQ-02` | Какой exact slug sequence должен быть в `spec/factories/hotels.rb`: `"hotel-#{n}"` or `"hotel-#{n}-slug"`? | Legacy `spec.md` says `"hotel-#{n}"`; legacy `plan.md` says `"hotel-#{n}-slug"`. | `STEP-06` | Choose during implementation to satisfy validations/specs and record decision in evidence or implementation notes. |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| Ruby | Ruby 3.3.3 supports `Data.define`. | `STEP-02` | `Result = Data.define(...)` fails. |
| dependencies | `dry-initializer` is available for `BaseService` and services. | `STEP-02`, `STEP-09` | Service objects cannot initialize `option` params. |
| database | PostgreSQL available for migrations; safe rollout required for non-empty tables. | `STEP-04`, `STEP-05`, `STEP-07` | Migration fails with NOT NULL, FK or unique constraint errors. |
| auth baseline | Slice 001 Staff-backed Basic Auth already works and returns `401` for invalid/missing auth. | `STEP-03`, `STEP-12`-`STEP-14` | Auth specs fail before FT-002 role checks. |
| test | RSpec is canonical verification command. | `CHK-01`-`CHK-06` | Non-zero RSpec exit means verification failed. |
| style | RuboCop is canonical quality command. | `CHK-05` | Non-zero RuboCop exit means style gate failed. |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `CON-01` | Slice 001 authentication pattern is present and assigns `@current_staff`. | `STEP-03`, `STEP-12`-`STEP-14` | yes |
| `PRE-02` | `ASM-01`, `FM-09`, `OQ-01` | Migration strategy accounts for empty and non-empty `hotels` / `tickets` tables. | `STEP-04`, `STEP-05` | yes |
| `PRE-03` | `CON-08` | Runtime supports `Data.define`. | `STEP-02` | yes |
| `PRE-04` | `NS-07` | Implementation uses `BaseService` + `Result`, not `dry-monads`. | `STEP-02`, `STEP-09` | yes |
| `PRE-05` | `NS-08` | Delete/form behavior does not require Turbo/JS-specific contract. | `STEP-11`, `STEP-12` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-1` | `REQ-11` | Service infrastructure contract exists. | agent | `PRE-03`, `PRE-04` |
| `WS-2` | `REQ-01` | Admin-only authorization baseline across `/admin/**`. | agent | `PRE-01` |
| `WS-3` | `REQ-02`, `REQ-06`, `REQ-07` | Database/model/factory/seeds prerequisites are valid. | agent | `PRE-02` |
| `WS-4` | `REQ-03`-`REQ-06`, `REQ-11` | Hotel CRUD is implemented slice-by-slice. | agent | `WS-1`, `WS-2`, `WS-3` |
| `WS-5` | `REQ-08`-`REQ-10` | Nested hotel staff/tickets routes and views are implemented. | agent | `WS-2`, `WS-3`, `WS-4` |
| `WS-6` | `REQ-12` | Specs, factories and final verification are complete. | agent | `WS-1`-`WS-5` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | Existing data cannot be deterministically backfilled for `hotels.slug` or `tickets.hotel_id`. | `STEP-04`, `STEP-05` | Data mapping could alter business data semantics. | Human approval in chat or migration decision note. |
| `AG-02` | Any proposed local DB reset or destructive data cleanup. | `STEP-04`, `STEP-05`, `STEP-07` | Destructive local data operation. | Human approval in chat. |

## Work Order

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-12` | Confirm current baseline and inspect relevant files. | Files listed in Current State | Grounding notes in plan/evidence. | `CHK-06` | `EVID-06` | Inspect files and run targeted baseline only if needed. | none | none | Current code contradicts legacy assumptions. |
| `STEP-02` | agent | `REQ-11` | Create `BaseService` and `Result`. | `app/services/base_service.rb`, `app/services/result.rb` | Shared service contract. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/` | `PRE-03`, `PRE-04` | none | `Data.define` or `dry-initializer` unavailable. |
| `STEP-03` | agent | `REQ-01` | Add `require_admin!` after `authenticate_staff!`. | `app/controllers/admin/base_controller.rb`, `app/controllers/admin/hotels_controller.rb`, request specs | Admin-only baseline. | `CHK-02` | `EVID-02` | `bundle exec rspec spec/requests/` | `PRE-01` | none | Existing auth behavior changes unexpectedly. |
| `STEP-04` | agent | `REQ-02`, `REQ-06` | Add Hotel slug and unique Hotel name database constraints with safe rollout. | `db/migrate/*`, `db/schema.rb` | Slug and name constraints. | `CHK-03`, `CHK-06` | `EVID-03`, `EVID-06` | `bin/rails db:migrate`; request/service specs later. | `PRE-02`, `OQ-01` | `AG-01`/`AG-02` if data mapping/reset needed | Migration cannot preserve existing data. |
| `STEP-05` | agent | `REQ-07` | Add Ticket hotel reference and `subject`/`body` fields. | `db/migrate/*`, `db/schema.rb` | Hotel-bound tickets with display text. | `CHK-04`, `CHK-06` | `EVID-04`, `EVID-06` | `bin/rails db:migrate`; nested request specs later. | `PRE-02`, `OQ-01` | `AG-01`/`AG-02` if data mapping/reset needed | Existing tickets cannot map to hotels. |
| `STEP-06` | agent | `REQ-02`, `REQ-06`, `REQ-07`, `REQ-12` | Update factories for hotels, guests, departments and tickets. | `spec/factories/*` | Valid test data. | `CHK-01`-`CHK-04` | `EVID-01`-`EVID-04` | Covered by targeted specs. | `STEP-04`, `STEP-05`, `OQ-02` | none | Factory slug choice breaks specs or validations. |
| `STEP-07` | agent | `REQ-02`, `REQ-06`, `REQ-07` | Update `Hotel`, `Ticket` and seeds. | `app/models/hotel.rb`, `app/models/ticket.rb`, `db/seeds.rb` | Valid models and idempotent seeds. | `CHK-03`, `CHK-04`, `CHK-06` | `EVID-03`, `EVID-04`, `EVID-06` | `bundle exec rspec`; optional seed check if changed. | `STEP-04`, `STEP-05` | none | Existing specs fail due to new validations. |
| `STEP-08` | agent | `REQ-12` | Update existing admin access specs for new ticket requirements and role matrix. | `spec/requests/admin/access_spec.rb` | Existing access coverage remains valid. | `CHK-02` | `EVID-02` | `bundle exec rspec spec/requests/` | `STEP-03`, `STEP-06`, `STEP-07` | none | Specs require scope change. |
| `STEP-09` | agent | `REQ-03`, `REQ-11` | Add Hotel create/update services and service specs. | `app/services/admin/hotels/*`, `spec/services/admin/hotels/*` | Service-backed create/update. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/admin/hotels/` | `STEP-02`, `STEP-06`, `STEP-07` | none | Service result shape conflicts with controller needs. |
| `STEP-10` | agent | `REQ-04`, `REQ-05`, `REQ-12` | Preserve/grow hotels index coverage and view. | `routes`, `HotelsController#index`, `hotels/index`, `hotels_spec` | Index auth, non-empty and empty states. | `CHK-03` | `EVID-03` | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | `STEP-03`, `STEP-07` | none | Existing index behavior regresses. |
| `STEP-11` | agent | `REQ-04`, `REQ-05` | Add `show`, `new/create`, `edit/update`, `destroy` Hotel CRUD slices. | `routes`, `HotelsController`, `hotels/*`, shared errors, admin layout, locales | Full Hotel CRUD. | `CHK-03` | `EVID-03` | Run `bundle exec rspec spec/requests/admin/hotels_spec.rb` after each CRUD slice. | `STEP-09`, `PRE-05` | none | Status/flash behavior diverges from `feature.md`. |
| `STEP-12` | agent | `REQ-08`, `REQ-09`, `REQ-12` | Add hotel-scoped staff routes, controller, views and specs. | `routes`, `HotelStaffController`, `hotel_staff/*`, locales, specs | Staff index/show scoped by hotel. | `CHK-04` | `EVID-04` | `bundle exec rspec spec/requests/admin/hotel_staff_spec.rb` | `STEP-11` | none | Cross-hotel staff cannot be made `404` without scope change. |
| `STEP-13` | agent | `REQ-08`, `REQ-10`, `REQ-12` | Add hotel-scoped tickets routes, controller, view and specs. | `routes`, `HotelTicketsController`, `hotel_tickets/index`, locales, specs | Tickets index scoped by hotel with unassigned fallback. | `CHK-04` | `EVID-04` | `bundle exec rspec spec/requests/admin/hotel_tickets_spec.rb` | `STEP-12` | none | Ticket associations conflict with legacy assumptions. |
| `STEP-14` | agent | `REQ-12` | Run final verification and simplify review. | Full repo changed surface | Feature ready for acceptance. | `CHK-05`, `CHK-06` | `EVID-05`, `EVID-06` | `bundle exec rubocop`; `bundle exec rspec` | `STEP-01`-`STEP-13` | none | Full suite or style gate fails. |

## Parallelizable Work

- `PAR-01` `STEP-02` and `STEP-03` can start independently after `PRE-01`, `PRE-03`, `PRE-04`.
- `PAR-02` Factory updates in `STEP-06` can be prepared while migrations in `STEP-04` and `STEP-05` are being reviewed, but specs should run only after schema/model updates.
- `PAR-03` `STEP-12` and `STEP-13` share routes/model prerequisites and should not be implemented before Hotel CRUD routes are stable.
- `PAR-04` Locale additions can be batched with corresponding view slices, but unused locale keys should not be added speculatively.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-02`, `CHK-01` | Service infrastructure works. | `EVID-01` |
| `CP-02` | `STEP-03`, `STEP-08`, `CHK-02` | Admin authorization matrix is updated without breaking authentication. | `EVID-02` |
| `CP-03` | `STEP-04`-`STEP-07` | Schema, models, factories and seeds support slugged hotels and hotel-bound tickets. | `EVID-03`, `EVID-04`, `EVID-06` |
| `CP-04` | `STEP-09`-`STEP-11`, `CHK-03` | Hotel CRUD specs pass. | `EVID-03` |
| `CP-05` | `STEP-12`, `STEP-13`, `CHK-04` | Nested staff/tickets specs pass. | `EVID-04` |
| `CP-06` | `STEP-14`, `CHK-05`, `CHK-06` | Full suite and style gate pass. | `EVID-05`, `EVID-06` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Existing hotels/tickets block direct NOT NULL or unique migrations. | Migration failure or unsafe data mutation. | Use legacy safe rollout; escalate if mapping is ambiguous. | `PG::NotNullViolation`, duplicate slug/name, missing guest hotel. |
| `ER-02` | `require_admin!` runs before authentication. | `@current_staff` nil errors or wrong redirects. | Keep before_action order from `CON-02`. | Request specs fail with unexpected `500` or redirect. |
| `ER-03` | `manager` legacy access expectations remain in specs. | Request specs fail after intended auth change. | Update legacy `manager 200` and `staff 403` examples to `302`. | Existing hotels spec failures. |
| `ER-04` | Slug accepted from params or edit form. | Immutable slug contract breaks. | Permit only `name`, `timezone`; omit slug from form. | `NEG-04` fails. |
| `ER-05` | Delete links rely on JS/Turbo method spoofing. | Request/UI behavior may not issue DELETE. | Use `button_to` for delete per legacy plan. | Delete action not reached. |
| `ER-06` | Ticket factory creates mismatched hotel/guest/department/staff records. | Scoped tickets specs become flaky or invalid. | Tie associated records to the same hotel in factory. | Nested tickets specs show wrong hotel data. |
| `ER-07` | Legacy accepted large scope causes late integration failures. | Multiple modules fail after downstream slices. | Keep checkpoint discipline; fix current layer before moving forward. | Checkpoint suite fails. |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `OQ-01`, `AG-01`, `AG-02`, `ER-01` | Existing data cannot be safely backfilled or a reset is proposed. | Stop and ask for human approval. | No destructive data action taken. |
| `STOP-02` | `CON-01`, `REQ-01` | Implementing FT-002 appears to require changing slice 001 authentication semantics. | Stop and update canonical feature/ADR before coding. | Authentication remains unchanged. |
| `STOP-03` | `NS-07` | Service implementation appears to require `dry-monads` or a different result contract. | Stop and resolve design conflict upstream. | No new service contract introduced. |
| `STOP-04` | `NS-08` | CRUD behavior depends on Turbo/JS-specific contract. | Stop and choose non-JS Rails behavior from legacy plan. | CRUD views remain server-rendered. |
| `STOP-05` | `DEC-01`, `ER-07` | A checkpoint cannot pass without expanding scope beyond legacy spec. | Stop; revise `feature.md` before continuing. | Last passing checkpoint remains the working baseline. |

## Ready For Acceptance

- [ ] `CHK-01` passes: `bundle exec rspec spec/services/ spec/services/admin/hotels/`.
- [ ] `CHK-02` passes: `bundle exec rspec spec/requests/` after authorization baseline.
- [ ] `CHK-03` passes: `bundle exec rspec spec/requests/admin/hotels_spec.rb`.
- [ ] `CHK-04` passes: `bundle exec rspec spec/requests/admin/hotel_staff_spec.rb spec/requests/admin/hotel_tickets_spec.rb`.
- [ ] `CHK-05` passes: `bundle exec rubocop`.
- [ ] `CHK-06` passes: `bundle exec rspec`.
- [ ] Any approval-gated migration/data decision is recorded before closure.
- [ ] Evidence artifacts follow the `EVID-*` contract from `feature.md`.
