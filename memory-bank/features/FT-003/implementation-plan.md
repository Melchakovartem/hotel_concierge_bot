---
title: "FT-003: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution plan для FT-003. Фиксирует discovery context, layer-based steps, risks и test strategy без переопределения canonical feature scope."
derived_from:
  - feature.md
  - ../003/plan.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_003_scope
  - ft_003_architecture
  - ft_003_acceptance_criteria
  - ft_003_blocker_state
---

# Implementation Plan

## Цель текущего плана

Реализовать operations namespace с Staff-backed HTTP Basic Auth (realm `Operations`), manager staff creation, manager ticket assignment/status update и staff ticket transitions so, чтобы acceptance scenarios из `feature.md` проверялись через service/query specs, request specs и end-to-end workflow spec без admin credentials.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `Admin::BaseController` | HTTP Basic Auth с realm `Admin`; assigns `@current_staff`. | Reference implementation для `Operations::BaseController`. | Mirror алгоритм, но изменить realm на `Operations` и добавить admin→403 guard. |
| `app/services/base_service.rb`, `app/services/result.rb` | Shared service contract из FT-002. | Operations services наследуются от `BaseService` и возвращают `Result`. | Переиспользовать без изменений. |
| `Staff` model | `has_secure_password`, `belongs_to :hotel`, enum roles `admin:0, manager:1, staff:2`, assigned tickets association. | Основа authentication и authorization. | Добавить `belongs_to :department, optional: true` и validations; не трогать enum и associations. |
| `Ticket` model | `belongs_to :hotel`, `belongs_to :guest`, `belongs_to :department`, `belongs_to :staff, optional: true`; статусы `new`, `in_progress`, `done`, `canceled`. | Основа ticket visibility и transitions. | Не менять associations, enum и validations. |
| `config/routes.rb` | Имеет `namespace :admin`; нет `/operations/**`. | Нужно добавить новый namespace без изменений admin routes. | Добавить рядом с admin namespace. |
| `spec/factories/staffs.rb` | Существующая factory без `department_id`. | DB check constraint добавляется в Layer 0; factory должна быть обновлена ДО model validations, иначе существующие тесты упадут сразу после миграции. | Добавить department в role `staff`; traits admin/manager без department. |
| `spec/factories/tickets.rb` | Существующая factory; `staff` association из того же hotel. | После Staff validations factory должна оставаться валидной. | Проверить/обновить `staff` association в ticket factory. |
| `db/seeds.rb` | Seeded staff с role `:staff`; нет department. | После новых Staff validations seed упадёт без department. | Идемпотентно назначить department seeded staff user. |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `spec/services/operations/` | `REQ-10`, `EC-11`, `CHK-01` | Отсутствует до FT-003. | Service/query specs: create, update, visibility, start, complete — все cases из feature.md. | `bundle exec rspec spec/services/operations/` | RSpec job | none | `none` |
| `spec/requests/operations/authentication_spec.rb`, `access_spec.rb` | `REQ-02`, `REQ-03`, `EC-02`, `EC-03`, `CHK-02` | Отсутствует до FT-003. | Auth failure и role matrix. | `bundle exec rspec spec/requests/operations/authentication_spec.rb spec/requests/operations/access_spec.rb` | RSpec job | none | `none` |
| `spec/requests/operations/staff_spec.rb` | `REQ-04`, `EC-04`, `CHK-03` | Отсутствует до FT-003. | Manager staff management cases. | `bundle exec rspec spec/requests/operations/staff_spec.rb` | RSpec job | none | `none` |
| `spec/requests/operations/tickets_manager_spec.rb` | `REQ-05`, `EC-05`, `CHK-04` | Отсутствует до FT-003. | Manager ticket read/update cases. | `bundle exec rspec spec/requests/operations/tickets_manager_spec.rb` | RSpec job | none | `none` |
| `spec/requests/operations/tickets_staff_spec.rb` | `REQ-06`, `EC-06`, `CHK-05` | Отсутствует до FT-003. | Staff ticket visibility cases. | `bundle exec rspec spec/requests/operations/tickets_staff_spec.rb` | RSpec job | none | `none` |
| `spec/requests/operations/ticket_transitions_spec.rb` | `REQ-07`, `EC-07`, `EC-08`, `CHK-06` | Отсутствует до FT-003. | Start/complete transition cases включая 422 для same-dept unassigned. | `bundle exec rspec spec/requests/operations/ticket_transitions_spec.rb` | RSpec job | none | `none` |
| `spec/requests/operations/staff_ticket_workflow_spec.rb` | `EC-12`, `SC-17`–`SC-19`, `CHK-07` | Отсутствует до FT-003. | End-to-end workflow без admin. | `bundle exec rspec spec/requests/operations/staff_ticket_workflow_spec.rb` | RSpec job | none | `none` |
| `spec/requests/admin/access_spec.rb` | `EC-13`, `SC-20`, `CHK-08` | Существующий admin regression. | Regression после operations changes: /admin/** остаётся admin-only. | `bundle exec rspec spec/requests/admin/` | RSpec job | none | `none` |
| Full suite and style | `EC-01`–`EC-13`, `CHK-09`, `CHK-10` | Existing suite. | Full regression и style pass. | `bundle exec rubocop`; `bundle exec rspec` | RuboCop job, RSpec job | none | `none` |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Есть ли duplicate emails в `staffs` таблице в dev/test DB? | PostgreSQL отклонит добавление unique index если duplicates есть. | `STEP-02` | Выполнить preflight check; при обнаружении — остановить Layer 0 и эскалировать. |
| `OQ-02` | Есть ли в dev/test DB `staff`-rows с role=staff и без department, у hotel которого нет departments? | Migration создаст fallback department `General`, что меняет состояние данных. | `STEP-02`, `STEP-03` | По умолчанию — создать fallback `General` department согласно legacy plan; при возражениях — эскалировать. |
| `OQ-03` | Использует ли `Operations::StaffController` конфликтующее имя с `Operations::Staff` service namespace? | Legacy plan документирует это явно. | `STEP-15`, `STEP-19` | Использовать `::Staff` (с `::` prefix) для обращения к AR-модели внутри `Operations::Staff` namespace. |
| `OQ-04` | Возвращает ли существующий `Admin::BaseController#require_admin!` redirect или 403? | В operations нужен 403, а не redirect. | `STEP-11` | Реализовать `require_manager!`/`require_staff!` с 403; не копировать redirect behavior из admin. |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| dependency | `bcrypt` доступен (из FT-001); `dry-initializer` доступен (из FT-002). | `STEP-11`, `STEP-14`–`STEP-17` | Services не могут declare options; authentication не работает. |
| service contract | `BaseService` и `Result` существуют и доступны. | `STEP-14`–`STEP-17` | Services не компилируются или возвращают неожиданный shape. |
| database | PostgreSQL доступен; migration не разрушает данные. | `STEP-02`–`STEP-03` | Migration fails с constraint violation. |
| auth baseline | FT-001 Staff-backed Basic Auth уже работает в `Admin::BaseController`. | `STEP-11` | Operations BaseController не может mirror алгоритм. |
| test | `bundle exec rspec <path>` — canonical local verification command. | `CHK-01`–`CHK-10` | Non-zero exit означает failed verification. |
| style | `bundle exec rubocop` — canonical style command. | `CHK-09` | Non-zero exit означает style gate failure. |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `ASM-01` | `BaseService` и `Result` уже реализованы (FT-002). | `STEP-14`–`STEP-17` | yes |
| `PRE-02` | `ASM-02` | `Admin::BaseController` Basic Auth pattern существует и проверен. | `STEP-11` | yes |
| `PRE-03` | `NS-09` | Gems не добавляются; `bcrypt` и `dry-initializer` уже загружены. | `STEP-11`, `STEP-14`–`STEP-17` | yes |
| `PRE-04` | `CON-06`, `REQ-08` | Preflight показал, что duplicate emails отсутствуют (или решение одобрено). | `STEP-02` | yes |
| `PRE-05` | `CON-06`, `REQ-08` | Migration strategy для non-null backfill определена. | `STEP-02` | yes |
| `PRE-06` | `CON-09` | Существующие migrations не редактируются. | `STEP-02` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-0` | `REQ-08`, `REQ-09`, `REQ-11` | Data invariants и model validations заложены. | agent | `PRE-04`, `PRE-05`, `PRE-06` |
| `WS-1` | `REQ-01`, `REQ-02`, `REQ-03` | Operations namespace, auth shell и role matrix работают. | agent | `PRE-02`, `PRE-03`, `WS-0` |
| `WS-2` | `REQ-10` | Service/query objects созданы и специфицированы. | agent | `PRE-01`, `WS-0` |
| `WS-3` | `REQ-04` | Manager staff creation slice работает. | agent | `WS-1`, `WS-2` |
| `WS-4` | `REQ-05` | Manager ticket read/update slices работают. | agent | `WS-1`, `WS-2` |
| `WS-5` | `REQ-06`, `REQ-07` | Staff ticket read и transitions работают. | agent | `WS-3`, `WS-4` |
| `WS-6` | `REQ-12` | Regression и end-to-end specs проходят. | agent | `WS-1`–`WS-5` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | Duplicate emails найдены в `staffs`; нельзя безопасно добавить unique index. | `STEP-02` | Выбор записей для сохранения или объединения — бизнес-решение. | Human approval в чате. |
| `AG-02` | Fallback department `General` создаётся migration-ом для hotel без departments. | `STEP-02` | Изменение production-подобных данных требует явного подтверждения. | Human approval в чате или migration decision note. |
| `AG-03` | Любой destructive local DB reset или data cleanup. | `STEP-02`, `STEP-03` | Destructive local data operation. | Human approval в чате. |

## Work Order

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-08` | Preflight: проверить duplicate emails и staff-без-department. | Development/test DB | Preflight report. | `CHK-10` | `EVID-10` | `bin/rails runner 'puts Staff.group(:email).having("COUNT(*) > 1").count'` | `PRE-04` | `AG-01` if duplicates found | Duplicates found и нет human decision. |
| `STEP-02` | agent | `REQ-08` | Создать non-destructive migration: add_reference null:true, unique email index, backfill, check constraint. | `db/migrate/*_add_department_to_staffs.rb` | Migration file. | `CHK-10` | `EVID-10` | Inspect migration file. | `STEP-01`, `PRE-05`, `PRE-06` | `AG-02` if fallback dept needed | Migration destroys data или не покрывает backfill. |
| `STEP-03` | agent | `REQ-08` | Запустить migration и обновить schema.rb. | `db/schema.rb` | Schema reflects staffs.department_id, unique email index, FK, check constraint. | `CHK-10` | `EVID-10` | `bin/rails db:migrate` | `STEP-02` | `AG-03` if reset needed | Migration fails. |
| `STEP-04` | agent | `REQ-11` | Обновить staffs factory: role `staff` получает department из того же hotel; traits admin/manager без department. | `spec/factories/staffs.rb` | Updated factory. | `CHK-10` | `EVID-10` | Covered by existing and new specs. | `STEP-03` | none | `create(:staff)` или `create(:staff, :manager)` валидация падает. |
| `STEP-05` | agent | `REQ-11` | Обновить tickets factory: staff association из того же hotel; не создавать staff без department. | `spec/factories/tickets.rb` | Updated factory. | `CHK-10` | `EVID-10` | Covered by existing and new specs. | `STEP-04` | none | `create(:ticket)` invalidates after Staff validations. |
| `STEP-06` | agent | `REQ-11` | Обновить seeds: idempotent department assignment для seeded staff с role `staff`. | `db/seeds.rb` | Valid idempotent seeds. | `CHK-10` | `EVID-10` | `bin/rails db:seed` (optional). | `STEP-03` | none | Seeds fail после Step 07 validations. |
| `STEP-07` | agent | `REQ-09` | Обновить Staff model: belongs_to :department optional:true, presence/uniqueness validations, department hotel scope validation. | `app/models/staff.rb` | Updated model validations. | `CHK-10` | `EVID-10` | Covered by service/request specs. | `STEP-04` | none | Existing tests fail после добавления validations. |
| `STEP-08` | agent | `REQ-08`, `REQ-09`, `REQ-11` | Layer 0 checkpoint: полный suite должен проходить. | Full test suite | All existing specs green. | `CHK-10` | `EVID-10` | `bundle exec rspec` | `STEP-01`–`STEP-07` | none | Failures — исправить до перехода к Layer 1. |
| `STEP-09` | agent | `REQ-01` | Добавить operations routes в config/routes.rb. | `config/routes.rb` | Routes: /operations, /operations/staff, /operations/tickets с member actions start/complete. | `CHK-10` | `EVID-10` | `bin/rails routes -g operations` | `WS-0` | none | Admin routes изменились. |
| `STEP-10` | agent | `REQ-01` | Создать operations layout с role-aware navigation. | `app/views/layouts/operations.html.erb` | Layout с flash, tickets-nav, staff-nav только для manager. | `CHK-10` | `EVID-10` | Visual inspection при написании views. | `STEP-09` | none | Layout referencing @current_staff until BaseController sets it. |
| `STEP-11` | agent | `REQ-02`, `REQ-03` | Создать Operations::BaseController: HTTP Basic Auth realm Operations, admin guard, helper methods. | `app/controllers/operations/base_controller.rb` | authenticate_staff!, require_manager!, require_staff!, http_unauthorized, forbidden, not_found, current_staff, current_hotel. | `CHK-02` | `EVID-02` | Request specs в STEP-13. | `STEP-10`, `PRE-02` | none | Missing/invalid credentials не возвращают 401; admin получает 200. |
| `STEP-12` | agent | `REQ-01` | Создать Operations::HomeController с redirect на /operations/tickets. | `app/controllers/operations/home_controller.rb` | Authenticated redirect через controller action, не route-level redirect. | `CHK-02` | `EVID-02` | Covered by Layer 1 request specs. | `STEP-11` | none | /operations делает redirect без Basic Auth check. |
| `STEP-13` | agent | `REQ-02`, `REQ-03` | Добавить request specs для auth failures и role matrix. | `spec/requests/operations/authentication_spec.rb`, `spec/requests/operations/access_spec.rb` | Auth и access matrix specs. | `CHK-02` | `EVID-02` | `bundle exec rspec spec/requests/operations/authentication_spec.rb spec/requests/operations/access_spec.rb` | `STEP-11`, `STEP-12` | none | Auth specs fail для valid credentials. |
| `STEP-14` | agent | `REQ-10` | Создать Operations::Tickets::VisibleTicketsQuery и spec. | `app/services/operations/tickets/visible_tickets_query.rb`, `spec/services/operations/tickets/visible_tickets_query_spec.rb` | Query: manager→all hotel tickets; staff→assigned OR same-dept; admin→none. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/operations/tickets/visible_tickets_query_spec.rb` | `PRE-01`, `WS-0` | none | Query leaks cross-hotel records. |
| `STEP-15` | agent | `REQ-10` | Создать Operations::Staff::CreateService и spec (::Staff для AR model). | `app/services/operations/staff/create_service.rb`, `spec/services/operations/staff/create_service_spec.rb` | Service: whitelist, force hotel/role, return Result. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/operations/staff/create_service_spec.rb` | `PRE-01`, `STEP-07` | none | Service принимает role или hotel из params. |
| `STEP-16` | agent | `REQ-10` | Создать Operations::Tickets::ManagerUpdateService и spec. | `app/services/operations/tickets/manager_update_service.rb`, `spec/services/operations/tickets/manager_update_service_spec.rb` | Service: whitelist [staff_id, status], partial update, hotel scope. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/operations/tickets/manager_update_service_spec.rb` | `PRE-01`, `STEP-07` | none | Service меняет disallowed attributes. |
| `STEP-17` | agent | `REQ-10` | Создать StartService, CompleteService и specs. | `app/services/operations/tickets/start_service.rb`, `app/services/operations/tickets/complete_service.rb`, соответствующие specs | Services: role staff, same hotel, personal assignment, valid transition. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/operations/tickets/start_service_spec.rb spec/services/operations/tickets/complete_service_spec.rb` | `PRE-01`, `STEP-07` | none | Same-dept unassigned ticket проходит assignment check. |
| `STEP-18` | agent | `REQ-10` | Layer 2 checkpoint: все service/query specs проходят. | `spec/services/operations/` | All service/query specs green. | `CHK-01` | `EVID-01` | `bundle exec rspec spec/services/operations/` | `STEP-14`–`STEP-17` | none | Failures — исправить до Layers 3+. |
| `STEP-19` | agent | `REQ-04` | Создать Operations::StaffController: index/new/create только manager; вызывает CreateService. | `app/controllers/operations/staff_controller.rb` | require_manager! before queries; success→redirect с flash; failure→422 render new. | `CHK-03` | `EVID-03` | Covered by Step 21 request specs. | `STEP-11`, `STEP-15` | none | Staff role получает данные staff-management routes. |
| `STEP-20` | agent | `REQ-04` | Создать staff views: index, new, form partial. | `app/views/operations/staff/index.html.erb`, `app/views/operations/staff/new.html.erb`, `app/views/operations/staff/_form.html.erb` | index: name/email/department table, empty state; form: только whitelisted params; department select из manager hotel. | `CHK-03` | `EVID-03` | Visual spec coverage. | `STEP-19` | none | Form выводит role или hotel fields. |
| `STEP-21` | agent | `REQ-04`, `REQ-12` | Добавить staff request specs. | `spec/requests/operations/staff_spec.rb` | manager index/new/create cases; validation failure 422; cross-hotel dept denial; staff role→403; admin→403. | `CHK-03` | `EVID-03` | `bundle exec rspec spec/services/operations/staff/create_service_spec.rb spec/requests/operations/staff_spec.rb` | `STEP-19`, `STEP-20` | none | Spec fails на authorization checks. |
| `STEP-22` | agent | `REQ-05` | Добавить index/show actions в tickets controller (manager-only на этом слое). | `app/controllers/operations/tickets_controller.rb` | require_manager! для index/show; VisibleTicketsQuery для index; hotel-scoped show; cross-hotel→404. | `CHK-04` | `EVID-04` | Covered by Step 24 request specs. | `STEP-11`, `STEP-14` | none | Staff получает доступ к manager-only routes. |
| `STEP-23` | agent | `REQ-05` | Создать ticket index/show views (role-neutral для будущего staff access). | `app/views/operations/tickets/index.html.erb`, `app/views/operations/tickets/show.html.erb` | index: id/status/department/staff table, empty state; show: details без start/complete buttons пока. | `CHK-04` | `EVID-04` | Visual spec coverage. | `STEP-22` | none | Views hard-code manager assumptions. |
| `STEP-24` | agent | `REQ-05`, `REQ-12` | Добавить manager ticket read request specs. | `spec/requests/operations/tickets_manager_spec.rb` (read cases) | manager index/show cases; cross-hotel→404; admin→403; empty state. | `CHK-04` | `EVID-04` | `bundle exec rspec spec/services/operations/tickets/visible_tickets_query_spec.rb spec/requests/operations/tickets_manager_spec.rb` | `STEP-22`, `STEP-23` | none | Query leaks cross-hotel или admin получает 200. |
| `STEP-25` | agent | `REQ-05` | Добавить edit/update actions в tickets controller (manager-only). | `app/controllers/operations/tickets_controller.rb` | require_manager! before lookup; ManagerUpdateService; success→redirect; failure→422; staff role→403. | `CHK-04` | `EVID-04` | Covered by Step 28 request specs. | `STEP-22`, `STEP-16` | none | Update меняет disallowed attributes. |
| `STEP-26` | agent | `REQ-05` | Создать manager ticket edit view. | `app/views/operations/tickets/edit.html.erb` | fields только [staff_id, status]; assignee select из hotel staff role:staff; blank staff option для unassign; validation summary. | `CHK-04` | `EVID-04` | Visual spec coverage. | `STEP-25` | none | Form выводит guest/hotel/dept/subject/body fields. |
| `STEP-27` | agent | `REQ-05` | Обновить index/show с manager-only controls (edit link). | `app/views/operations/tickets/index.html.erb`, `app/views/operations/tickets/show.html.erb` | Edit link только при manager role. | `CHK-04` | `EVID-04` | Visual spec coverage. | `STEP-25`, `STEP-26` | none | Staff видит manager edit links. |
| `STEP-28` | agent | `REQ-05`, `REQ-12` | Добавить manager ticket update request specs. | `spec/requests/operations/tickets_manager_spec.rb` (update cases) | edit/update cases; assignment/reassignment/unassignment/status; validation 422; cross-hotel assignee denial; staff role→403; disallowed attributes. | `CHK-04` | `EVID-04` | `bundle exec rspec spec/services/operations/tickets/manager_update_service_spec.rb spec/requests/operations/tickets_manager_spec.rb` | `STEP-25`, `STEP-26`, `STEP-27` | none | Update меняет protected attributes. |
| `STEP-29` | agent | `REQ-06` | Завершить staff read authorization в tickets controller: index/show разрешены manager+staff; staff show через visible query scope. | `app/controllers/operations/tickets_controller.rb` | staff index/show: visible через VisibleTicketsQuery; cross-hotel/unrelated→404; edit/update остаются manager-only. | `CHK-05` | `EVID-05` | Covered by Step 30 request specs. | `STEP-22`, `STEP-14` | none | Staff может открывать tickets других hotel. |
| `STEP-30` | agent | `REQ-06`, `REQ-12` | Добавить staff ticket read request specs. | `spec/requests/operations/tickets_staff_spec.rb` | index: assigned ticket visible; same-dept visible; unrelated dept→404 from show; edit/update→403. | `CHK-05` | `EVID-05` | `bundle exec rspec spec/services/operations/tickets/visible_tickets_query_spec.rb spec/requests/operations/tickets_staff_spec.rb` | `STEP-29` | none | Staff видит unrelated tickets. |
| `STEP-31` | agent | `REQ-07` | Добавить start/complete actions в tickets controller (staff-only). | `app/controllers/operations/tickets_controller.rb` | require_staff! before lookup; StartService/CompleteService; visible scope check→404 если не visible; success→redirect; service failure→422 render show; manager→403. | `CHK-06` | `EVID-06` | Covered by Step 33 request specs. | `STEP-29`, `STEP-17` | none | Same-dept unassigned ticket проходит service и меняет status. |
| `STEP-32` | agent | `REQ-07` | Добавить start/complete buttons в ticket show view. | `app/views/operations/tickets/show.html.erb` | Start button: только staff, personally assigned, status new; Complete button: only staff, personally assigned, status in_progress; validation summary при @result failure. | `CHK-06` | `EVID-06` | Visual spec coverage. | `STEP-31` | none | Buttons видны manager или staff без personal assignment. |
| `STEP-33` | agent | `REQ-07`, `REQ-12` | Добавить transition request specs. | `spec/requests/operations/ticket_transitions_spec.rb` | start new; complete in_progress; direct complete from new→422; start done/canceled→422; same-dept unassigned→422; unrelated→404; cross-hotel→404; manager start/complete→403; admin→403; success flash. | `CHK-06` | `EVID-06` | `bundle exec rspec spec/services/operations/tickets/start_service_spec.rb spec/services/operations/tickets/complete_service_spec.rb spec/requests/operations/ticket_transitions_spec.rb` | `STEP-31`, `STEP-32` | none | Same-dept unassigned возвращает 403 вместо 422. |
| `STEP-34` | agent | `REQ-12` | Добавить admin regression spec. | `spec/requests/admin/access_spec.rb` | admin-only для /admin/**; operations auth не меняет admin realm; existing staff fixtures с department только где требуется role `staff`. | `CHK-08` | `EVID-08` | `bundle exec rspec spec/requests/admin/access_spec.rb` | `STEP-31` | none | Admin regression fails. |
| `STEP-35` | agent | `REQ-12`, `EC-12` | Добавить end-to-end workflow spec. | `spec/requests/operations/staff_ticket_workflow_spec.rb` | 10-step сценарий: hotel/manager/dept/guest/ticket → manager создаёт staff → manager назначает → staff видит → staff start → staff complete → status done → cross-hotel denials; admin credentials не используются. | `CHK-07` | `EVID-07` | `bundle exec rspec spec/requests/operations/staff_ticket_workflow_spec.rb` | `STEP-31`–`STEP-34` | none | Spec требует admin или не проходит cross-hotel check. |
| `STEP-36` | agent | `REQ-01`–`REQ-12` | Full acceptance verification: rspec + rubocop. | Full repo changed surface | Feature ready for acceptance. | `CHK-09`, `CHK-10` | `EVID-09`, `EVID-10` | `bundle exec rubocop`; `bundle exec rspec` | `STEP-01`–`STEP-35` | none | Full suite или style gate falls. |

## Parallelizable Work

- `PAR-01` `STEP-09` (routes) и `STEP-14`–`STEP-17` (services) могут стартовать параллельно после `WS-0` (Layer 0 checkpoint).
- `PAR-02` `STEP-04` (staffs factory) и `STEP-05` (tickets factory) могут выполняться параллельно после `STEP-03` (migration).
- `PAR-03` После Layer 2 checkpoint (`STEP-18`) slices 1 (staff management) и 2-3 (manager tickets) могут стартовать параллельно при раздельном ownership controllers и views.
- `PAR-04` `STEP-34` (admin regression) и `STEP-35` (end-to-end) могут выполняться параллельно после STEP-33, если разные файлы.

**Важно:** `Operations::TicketsController` затрагивается в STEP-22, STEP-25, STEP-29 и STEP-31. Без явного разделения ownership нельзя параллельно редактировать этот controller. Следовать строгому layer order.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-01`–`STEP-08` | Все existing specs проходят после Layer 0 (migration, factories, model validations). | `EVID-10` |
| `CP-02` | `STEP-09`–`STEP-13`, `CHK-02` | Auth и role matrix specs проходят для `/operations/**`. | `EVID-02` |
| `CP-03` | `STEP-14`–`STEP-18`, `CHK-01` | Все service/query specs проходят. | `EVID-01` |
| `CP-04` | `STEP-19`–`STEP-21`, `CHK-03` | Manager staff management request specs проходят. | `EVID-03` |
| `CP-05` | `STEP-22`–`STEP-28`, `CHK-04` | Manager ticket read/update request specs проходят. | `EVID-04` |
| `CP-06` | `STEP-29`–`STEP-33`, `CHK-05`, `CHK-06` | Staff ticket read и transition specs проходят. | `EVID-05`, `EVID-06` |
| `CP-07` | `STEP-34`–`STEP-36`, `CHK-07`–`CHK-10` | End-to-end, admin regression, rubocop и full suite проходят. | `EVID-07`–`EVID-10` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Duplicate emails в staffs блокируют unique index migration. | Migration fails. | Preflight в STEP-01; остановить до STEP-02 и эскалировать. | `PG::UniqueViolation` при apply migration. |
| `ER-02` | Hotels без departments при backfill; migration создаёт fallback `General` dept без human approval. | Неожиданное изменение prod-подобных данных. | Задокументировать в STEP-02; требовать AG-02 если fallback нужен. | Migration создаёт `General` dept. |
| `ER-03` | `Operations::Staff` namespace конфликтует с `::Staff` AR model. | NameError в service или controller. | Явно использовать `::Staff` в `Operations::Staff::*`; OQ-03 задокументирован. | `uninitialized constant Operations::Staff::Staff`. |
| `ER-04` | `authenticate_staff!` не halts после `render 401`; action продолжается. | Leaks data или double-render. | Использовать `return http_unauthorized` для early failures. | Specs показывают unexpected response body после 401. |
| `ER-05` | `VisibleTicketsQuery` staff-ветка пропускает OR condition по department_id. | Staff видит только assigned, не same-dept. | Query spec с explicit same-dept и unrelated-dept cases. | `SC-11` fails. |
| `ER-06` | StartService/CompleteService не проверяют personal assignment при same-dept ticket. | Same-dept unassigned ticket меняет status. | Service spec с explicit same-dept-unassigned denial case; NEG-01. | `SC-16` fails или `NEG-01` нарушен. |
| `ER-07` | TicketsController редактируется параллельно разными слоями без ownership разделения. | Конфликты и регрессии в controller. | Строго следовать layer order: STEP-22 → STEP-25 → STEP-29 → STEP-31. | Checkpoint suite fails после параллельной работы. |
| `ER-08` | Admin regression broken: operations auth changes меняют admin realm или 401 behavior. | `/admin/**` перестаёт работать для admin. | Admin regression spec в STEP-34; CHK-08. | `SC-20` fails. |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `OQ-01`, `AG-01`, `ER-01` | Duplicate emails найдены; нельзя безопасно добавить unique index. | Остановить Layer 0; эскалировать для human resolution данных. | Migration не применена. |
| `STOP-02` | `OQ-02`, `AG-02`, `ER-02` | Fallback `General` dept необходим, но human approval не получен. | Остановить до явного подтверждения. | Migration не содержит backfill logic. |
| `STOP-03` | `AG-03`, `ER-01` | Предложен destructive local DB reset. | Остановить; запросить human approval. | Данные не тронуты. |
| `STOP-04` | `CON-08` | Реализация требует изменения state напрямую в controller минуя services. | Остановить; рефакторить через service object. | Controller не мутирует state. |
| `STOP-05` | `NS-09` | Реализация требует добавления или обновления gems. | Остановить; эскалировать design scope change. | Gemfile не изменён. |
| `STOP-06` | `ER-07` | Checkpoint suite не проходит без расширения scope за пределы feature.md. | Остановить; обновить `feature.md` до продолжения. | Последний passing checkpoint — рабочий baseline. |

## Ready For Acceptance

- [ ] `CHK-01` passes: `bundle exec rspec spec/services/operations/`.
- [ ] `CHK-02` passes: `bundle exec rspec spec/requests/operations/authentication_spec.rb spec/requests/operations/access_spec.rb`.
- [ ] `CHK-03` passes: `bundle exec rspec spec/requests/operations/staff_spec.rb`.
- [ ] `CHK-04` passes: `bundle exec rspec spec/requests/operations/tickets_manager_spec.rb`.
- [ ] `CHK-05` passes: `bundle exec rspec spec/requests/operations/tickets_staff_spec.rb`.
- [ ] `CHK-06` passes: `bundle exec rspec spec/requests/operations/ticket_transitions_spec.rb`.
- [ ] `CHK-07` passes: `bundle exec rspec spec/requests/operations/staff_ticket_workflow_spec.rb`.
- [ ] `CHK-08` passes: `bundle exec rspec spec/requests/admin/`.
- [ ] `CHK-09` passes: `bundle exec rubocop`.
- [ ] `CHK-10` passes: `bundle exec rspec`.
- [ ] Все approval-gated decisions (AG-01, AG-02, AG-03) задокументированы до closure.
- [ ] Evidence artifacts следуют `EVID-*` contract из `feature.md`.
