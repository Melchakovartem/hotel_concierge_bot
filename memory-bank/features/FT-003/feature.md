---
title: "FT-003: Hotel staff ticket workflow without admin"
doc_kind: feature
doc_function: canonical
purpose: "Canonical feature contract для operations namespace с Staff-backed HTTP Basic Auth, manager staff creation, manager ticket assignment/update и staff ticket transitions без участия admin."
derived_from:
  - ../../domain/problem.md
  - ../../engineering/testing-policy.md
  - ../003/brief.md
  - ../003/spec.md
status: active
delivery_status: planned
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-003: Hotel staff ticket workflow without admin

## What

### Problem

Операционный сценарий обработки гостевого тикета не может пройти от начала до конца без роли `admin`: операционные роли отеля не могут самостоятельно выполнить цепочку «`manager` создаёт staff-исполнителя → `manager` назначает тикет → `staff` видит тикет → `staff` переводит в `in_progress` → `staff` переводит в `done`».

Платформа поддерживает административную настройку, но не поддерживает полный операционный цикл обработки гостевого тикета персоналом отеля. В итоге:

- `manager` не может добавить `staff`-пользователя для работы с тикетами своего отеля;
- `manager` не может назначить тикет исполнителю без `admin`;
- `staff` не может принять назначенный тикет в работу и зафиксировать завершение.

`admin` — это администратор платформы, а не сотрудник отеля, и не должен быть нужен для обработки тикетов внутри отеля.

### Outcome

Операционные роли проходят полный сценарий обработки гостевого тикета без участия `admin`:

- `manager` создаёт `staff`-пользователя для своего отеля и назначает ему тикет;
- назначенный `staff` видит тикет, берёт в работу и завершает обработку;
- весь сценарий проходит без единого вмешательства `admin`.

Результат считается достигнутым, когда минимум один успешный end-to-end проход цепочки выполнен операционными ролями без admin credentials.

### Scope

- `REQ-01` Создать server-rendered namespace `/operations/**` с routes, layout, controllers и views для ролей `manager` и `staff`.
- `REQ-02` Реализовать HTTP Basic authentication в `Operations::BaseController` с realm `Operations`; сохранять аутентифицированного пользователя в `@current_staff`.
- `REQ-03` Реализовать authorization matrix: `admin` → `403`; `manager` → разрешены manager actions и ticket read/update своего отеля; `staff` → разрешены read visible tickets и start/complete лично назначенных тикетов; cross-hotel records → `404`.
- `REQ-04` Manager может создавать `staff`-пользователей для своего отеля: принимать только `[name, email, password, password_confirmation, department_id]`, принудительно выставлять `hotel: manager.hotel` и `role: :staff`, отклонять cross-hotel department и duplicate email.
- `REQ-05` Manager может просматривать все тикеты своего отеля, назначать, переназначать, снимать назначение и обновлять статус через `[staff_id, status]`; все прочие атрибуты тикета неизменяемы.
- `REQ-06` Staff может просматривать тикеты своего отеля, которые лично назначены ему или принадлежат тому же department.
- `REQ-07` Staff может выполнять `start` (new → in_progress) и `complete` (in_progress → done) только для лично назначенных тикетов.
- `REQ-08` Добавить non-destructive migration: `staffs.department_id` (null: true, FK), unique index на `staffs.email`, backfill существующих `staff`-rows до добавления DB check constraint `role != 2 OR department_id IS NOT NULL`.
- `REQ-09` Обновить модель `Staff`: `belongs_to :department, optional: true`, presence/uniqueness validations для name/email, presence validation для department при role `staff`, cross-hotel department validation.
- `REQ-10` Создать service/query objects: `Operations::Staff::CreateService`, `Operations::Tickets::ManagerUpdateService`, `Operations::Tickets::VisibleTicketsQuery`, `Operations::Tickets::StartService`, `Operations::Tickets::CompleteService`.
- `REQ-11` Обновить factories и seeds: `staff` factory назначает department для role `staff`; `ticket` factory остаётся валидным; seeds idempotent.
- `REQ-12` Добавить request specs, service specs и query specs: authentication, role matrix, staff management, ticket management, transitions, end-to-end workflow, admin regression.

### Non-Scope

- `NS-01` Не добавлять универсальный RBAC/ACL framework или permissions matrix.
- `NS-02` Не добавлять audit log, notifications или SLA tracking.
- `NS-03` Не добавлять bulk ticket operations.
- `NS-04` Не добавлять guest-facing ticket creation.
- `NS-05` Не добавлять JSON API.
- `NS-06` Не добавлять login/logout screens или session-based authentication.
- `NS-07` Не вводить новые ticket statuses и не переименовывать существующие (`new`, `in_progress`, `done`, `canceled`).
- `NS-08` Не менять публичные контракты `/admin/**` кроме сохранения admin-only access.
- `NS-09` Не добавлять и не обновлять gems.

### Constraints / Assumptions

- `CON-01` Operations workflow не использует `/admin/**`; namespace `/operations/**` изолирован.
- `CON-02` HTTP Basic realm для `/operations/**` — `Operations`; при ошибке аутентификации — `WWW-Authenticate: Basic realm="Operations"`.
- `CON-03` `@current_staff` назначается только после успешной аутентификации операционного пользователя.
- `CON-04` Роль `admin` не имеет доступа к `/operations/**`; получает `403 Forbidden`.
- `CON-05` Same-department visibility без personal assignment возвращает `422 Unprocessable Entity` при попытке `start`/`complete`, а не `403`.
- `CON-06` Migration не разрушает существующие данные; backfill выполняется до добавления DB check constraint.
- `CON-07` Invalid status value в `ManagerUpdateService` возвращает failure result, а не пробрасывает `ArgumentError`.
- `CON-08` Controllers вызывают service/query objects; не меняют ticket/staff state напрямую.
- `CON-09` Model logic ограничен validations и associations из `REQ-09`.
- `CON-10` Не писать model specs; покрывать через services, queries и request flows.
- `ASM-01` `BaseService` и `Result` уже существуют (введены в FT-002) и переиспользуются для operations services.
- `ASM-02` `Admin::BaseController` HTTP Basic Auth pattern является reference implementation для `Operations::BaseController`.
- `ASM-03` Существующие ticket statuses (`new`, `in_progress`, `done`, `canceled`) остаются без изменений.
- `ASM-04` Factories для hotels, departments, guests, staffs и tickets уже существуют; `staffs` factory пока не назначает department.
- `DEC-01` Operations controllers живут в отдельном namespace `/operations/**`, изолированном от `/admin/**`; это разделяет операционный flow от административной конфигурации.

## How

### Solution

Ввести namespace `/operations/**` с `Operations::BaseController`, реализующим HTTP Basic Auth с realm `Operations` и role-based authorization. Manager получает staff creation и ticket assignment/update. Staff получает visible ticket read и личные ticket transitions. Service/query objects инкапсулируют бизнес-логику. Non-destructive migration добавляет department_id к staffs с backfill. Request/service/query specs покрывают весь role matrix и end-to-end workflow.

### Change Surface

| Surface | Type | Why it changes |
| --- | --- | --- |
| `config/routes.rb` | routes | Добавить namespace `:operations` с staff и tickets resources и member routes для start/complete. |
| `app/views/layouts/operations.html.erb` | layout | Создать operations layout с role-aware navigation. |
| `app/controllers/operations/base_controller.rb` | controller | Создать `Operations::BaseController` с HTTP Basic Auth realm "Operations", admin guard и helper methods. |
| `app/controllers/operations/home_controller.rb` | controller | Создать authenticated redirect с /operations на /operations/tickets. |
| `app/controllers/operations/staff_controller.rb` | controller | Manager-only staff index/new/create через `Operations::Staff::CreateService`. |
| `app/controllers/operations/tickets_controller.rb` | controller | Manager+staff read (index/show) и manager edit/update, staff start/complete через services. |
| `app/views/operations/staff/index.html.erb` | view | Staff list для manager: name, email, department. |
| `app/views/operations/staff/new.html.erb` | view | Staff creation form (manager only). |
| `app/views/operations/staff/_form.html.erb` | view partial | Whitelisted staff form fields. |
| `app/views/operations/tickets/index.html.erb` | view | Ticket list: id, status, department, staff; empty state. |
| `app/views/operations/tickets/show.html.erb` | view | Ticket details с role-specific actions (edit link для manager, start/complete buttons для staff). |
| `app/views/operations/tickets/edit.html.erb` | view | Manager ticket edit form: staff_id, status. |
| `app/services/operations/staff/create_service.rb` | service | Staff creation: whitelist, force hotel/role, return Result. |
| `app/services/operations/tickets/visible_tickets_query.rb` | query | Role-scoped ticket visibility. |
| `app/services/operations/tickets/manager_update_service.rb` | service | Manager ticket assignment/status update. |
| `app/services/operations/tickets/start_service.rb` | service | Start transition: new → in_progress. |
| `app/services/operations/tickets/complete_service.rb` | service | Complete transition: in_progress → done. |
| `app/models/staff.rb` | model | Добавить `belongs_to :department, optional: true` и validations из `REQ-09`. |
| `db/migrate/*_add_department_to_staffs.rb` | database | Non-destructive migration с backfill. |
| `db/schema.rb` | database schema | Отразить migration. |
| `db/seeds.rb` | data | Идемпотентно назначить department seeded staff user с role `staff`. |
| `spec/factories/staffs.rb` | test factory | Назначать department для role `staff`; traits admin/manager без department. |
| `spec/factories/tickets.rb` | test factory | Ticket factory остаётся валидным после новых Staff validations. |
| `spec/requests/operations/authentication_spec.rb` | request spec | Auth failure и credential matrix. |
| `spec/requests/operations/access_spec.rb` | request spec | Role access matrix: admin/manager/staff. |
| `spec/requests/operations/staff_spec.rb` | request spec | Manager staff management cases. |
| `spec/requests/operations/tickets_manager_spec.rb` | request spec | Manager ticket read/update cases. |
| `spec/requests/operations/tickets_staff_spec.rb` | request spec | Staff ticket visibility cases. |
| `spec/requests/operations/ticket_transitions_spec.rb` | request spec | Start/complete transition cases. |
| `spec/requests/operations/staff_ticket_workflow_spec.rb` | request spec | End-to-end workflow spec без admin. |
| `spec/requests/admin/access_spec.rb` | request spec | Regression: /admin/** остаётся admin-only. |
| `spec/services/operations/staff/create_service_spec.rb` | service spec | Staff creation service cases. |
| `spec/services/operations/tickets/visible_tickets_query_spec.rb` | query spec | Visibility logic cases. |
| `spec/services/operations/tickets/manager_update_service_spec.rb` | service spec | Manager update service cases. |
| `spec/services/operations/tickets/start_service_spec.rb` | service spec | Start transition service cases. |
| `spec/services/operations/tickets/complete_service_spec.rb` | service spec | Complete transition service cases. |

### Flow

1. Request попадает в `/operations/**`.
2. `Operations::BaseController#authenticate_staff!` читает `Authorization` header.
3. Missing/malformed/invalid credentials → `401` с `WWW-Authenticate: Basic realm="Operations"`.
4. Если аутентифицированный пользователь — `admin` → `403 Forbidden`.
5. `@current_staff` назначается для manager/staff.
6. Controller проверяет role-specific guard (`require_manager!` или `require_staff!`).
7. Record lookup через `current_hotel` scope; cross-hotel → `404`.
8. Controller вызывает service/query object; сам state не меняет.
9. Service/query возвращает `Result` (success/failure) или `ActiveRecord::Relation`.
10. Controller рендерит response или redirect с flash.

### Routes

| Method | Path | Controller#Action | Roles |
|---|---|---|---|
| GET | `/operations` | redirect to `/operations/tickets` | manager, staff |
| GET | `/operations/staff` | `operations/staff#index` | manager |
| GET | `/operations/staff/new` | `operations/staff#new` | manager |
| POST | `/operations/staff` | `operations/staff#create` | manager |
| GET | `/operations/tickets` | `operations/tickets#index` | manager, staff |
| GET | `/operations/tickets/:id` | `operations/tickets#show` | manager, staff |
| GET | `/operations/tickets/:id/edit` | `operations/tickets#edit` | manager |
| PATCH | `/operations/tickets/:id` | `operations/tickets#update` | manager |
| PATCH | `/operations/tickets/:id/start` | `operations/tickets#start` | staff |
| PATCH | `/operations/tickets/:id/complete` | `operations/tickets#complete` | staff |

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| --- | --- | --- | --- |
| `CTR-01` | `WWW-Authenticate: Basic realm="Operations"` | `Operations::BaseController` / HTTP client | Возвращается при всех authentication failures. |
| `CTR-02` | `@current_staff` | `Operations::BaseController` / operations controllers | Присутствует только после успешной аутентификации; admin→403 до назначения. |
| `CTR-03` | Role/action matrix: admin→403; manager→manager routes+read; staff→read+transitions; cross-hotel→404 | HTTP request / controllers | Описан в `REQ-03`. |
| `CTR-04` | `Operations::Staff::CreateService(manager:, params:) → Result` | controller / service | Whitelist `[name, email, password, password_confirmation, department_id]`; forces hotel+role; returns success(result: staff) or failure(error_code:, messages:, result: staff). |
| `CTR-05` | `Operations::Tickets::ManagerUpdateService(manager:, ticket:, params:) → Result` | controller / service | Whitelist `[staff_id, status]`; hotel-scoped; supports partial update; allows blank staff_id for unassign; returns Result. |
| `CTR-06` | `Operations::Tickets::VisibleTicketsQuery(staff:) → ActiveRecord::Relation` | controller / query | manager: all hotel tickets; staff: assigned OR same-dept tickets; admin: none. |
| `CTR-07` | `Operations::Tickets::StartService(staff:, ticket:) → Result` | controller / service | Requires role staff, same hotel, personal assignment, status new; returns Result. |
| `CTR-08` | `Operations::Tickets::CompleteService(staff:, ticket:) → Result` | controller / service | Requires role staff, same hotel, personal assignment, status in_progress; returns Result. |

### Invariants

| Invariant ID | Statement |
| --- | --- |
| `INV-01` | Каждый operations query scoped by `@current_staff.hotel`; cross-hotel data не видны, не назначаемы и не изменяемы. |
| `INV-02` | Роль `staff` принадлежит ровно одному department в том же отеле; `admin` и `manager` не требуют department. |
| `INV-03` | Email staff-пользователя глобально уникален. |
| `INV-04` | Пользователи, созданные manager-ом, всегда получают `hotel: manager.hotel` и `role: :staff`; role никогда не принимается из params. |
| `INV-05` | Manager ticket updates меняют только `staff_id` и `status`; `guest_id`, `hotel_id`, `department_id`, `subject`, `body`, `priority` неизменяемы. |
| `INV-06` | `start` разрешён только для тикетов в статусе `new`; устанавливает `in_progress`. |
| `INV-07` | `complete` разрешён только для тикетов в статусе `in_progress`; устанавливает `done`. |

### Failure Modes

- `FM-01` Missing/malformed/invalid credentials → `401` с `WWW-Authenticate: Basic realm="Operations"`.
- `FM-02` Admin accessing `/operations/**` → `403 Forbidden`.
- `FM-03` Staff accessing manager-only routes → `403 Forbidden`.
- `FM-04` Manager accessing staff-only transition routes (start/complete) → `403 Forbidden`.
- `FM-05` Cross-hotel record access → `404 Not Found`.
- `FM-06` Same-department ticket without personal assignment for start/complete → `422` с validation messages.
- `FM-07` Invalid status value in `ManagerUpdateService` → failure result, не `ArgumentError`.
- `FM-08` Cross-hotel department или assignee в creation/update → `422` с validation messages.
- `FM-09` Duplicate staff email → `422` с validation messages.
- `FM-10` Invalid status transition (e.g. direct new→done) → `422` с validation messages.

### ADR Dependencies

ADR не требуется. FT-003 использует существующий service/query pattern (`BaseService`, `Result` из FT-002), request-level Basic Auth pattern из FT-001 и стандартные Rails controller patterns.

## Verify

### Exit Criteria

- `EC-01` Namespace `/operations/**` существует и изолирован от `/admin/**`.
- `EC-02` HTTP Basic Auth с realm `Operations` возвращает `401` для missing/malformed/invalid credentials.
- `EC-03` Admin credentials возвращают `403` для всех `/operations/**` endpoints.
- `EC-04` Manager может создать `staff`-пользователя с принудительным hotel и role; cross-hotel department и duplicate email отклоняются.
- `EC-05` Manager видит все тикеты своего отеля; может назначать, переназначать, снимать назначение и обновлять статус; прочие атрибуты неизменяемы.
- `EC-06` Staff видит лично назначенные и same-department тикеты; не может открывать manager-only routes.
- `EC-07` Staff может start (new→in_progress) и complete (in_progress→done) только лично назначенных тикетов.
- `EC-08` Same-department тикет без personal assignment возвращает `422` при start/complete.
- `EC-09` Non-destructive migration применена: `staffs.department_id`, unique email index, check constraint.
- `EC-10` Существующие `staff`-rows backfill-ены с department до добавления check constraint.
- `EC-11` Service/query specs проходят для всех operations services и queries.
- `EC-12` End-to-end request spec проходит без admin credentials.
- `EC-13` `/admin/**` остаётся admin-only после operations changes.

### Acceptance Scenarios

- `SC-01` Manager отправляет valid credentials на `/operations`, получает redirect на `/operations/tickets`.
- `SC-02` Staff отправляет valid credentials на `/operations`, получает redirect на `/operations/tickets`.
- `SC-03` Request без credentials на `/operations/**` → `401` с `WWW-Authenticate: Basic realm="Operations"`.
- `SC-04` Admin credentials на `/operations/**` → `403 Forbidden`.
- `SC-05` Manager создаёт `staff`-пользователя с same-hotel department; пользователь создан с forced hotel и role `:staff`; redirect на `/operations/staff` с flash `Staff created`.
- `SC-06` Manager пытается создать staff с cross-hotel department → `422`; redirect на форму с validation messages.
- `SC-07` Manager открывает `/operations/tickets` и видит все тикеты своего отеля.
- `SC-08` Manager назначает тикет staff-пользователю; `staff_id` обновлён; `guest_id`, `hotel_id`, `department_id`, `subject`, `body` не изменились.
- `SC-09` Manager снимает назначение тикета; `staff_id` становится nil.
- `SC-10` Staff открывает `/operations/tickets` и видит лично назначенный тикет.
- `SC-11` Staff открывает `/operations/tickets` и видит тикет того же department.
- `SC-12` Staff не видит тикет другого department того же отеля без личного назначения.
- `SC-13` Staff пытается открыть manager edit/update route → `403`.
- `SC-14` Staff начинает personally assigned тикет в статусе `new` → status становится `in_progress`; redirect на show с flash `Ticket updated`.
- `SC-15` Staff завершает personally assigned тикет в статусе `in_progress` → status становится `done`.
- `SC-16` Staff пытается start/complete same-department, но не лично назначенный тикет → `422` с validation messages.
- `SC-17` End-to-end: manager создаёт staff → manager назначает тикет → staff видит тикет → staff start → staff complete → status `done`; admin credentials не используются ни разу.
- `SC-18` Manager из другого отеля получает `404` при попытке доступа к тикету.
- `SC-19` Staff из другого отеля получает `404` при попытке доступа к тикету.
- `SC-20` `/admin/**` остаётся доступным только для `admin`; operations auth changes не меняют admin realm.

### Negative / Edge Cases

- `NEG-01` Same-department visibility не должна давать права на start/complete; должна возвращать `422`, не `403`.
- `NEG-02` Admin не должен получать `200` ни для одного `/operations/**` endpoint.
- `NEG-03` Cross-hotel records должны возвращать `404`, не `403` и не `200`.
- `NEG-04` Role никогда не принимается из operations staff creation params; всегда принудительно `:staff`.
- `NEG-05` Manager ticket update не должен менять `guest_id`, `hotel_id`, `department_id`, `subject`, `body` или `priority`.
- `NEG-06` Staff не может завершить тикет напрямую из статуса `new` минуя `in_progress`.
- `NEG-07` Staff не может start тикет в статусе `done` или `canceled`.
- `NEG-08` Invalid status value в update params должен возвращать failure result, не пробрасывать `ArgumentError`.

### Traceability Matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| --- | --- | --- | --- | --- |
| `REQ-01` | `CON-01`, `DEC-01`, `CTR-03`, `FM-01`–`FM-05` | `EC-01`, `SC-01`, `SC-02`, `SC-03`, `SC-04` | `CHK-02`, `CHK-10` | `EVID-02`, `EVID-10` |
| `REQ-02` | `CON-02`, `CON-03`, `CTR-01`, `CTR-02`, `FM-01` | `EC-02`, `SC-01`, `SC-02`, `SC-03`, `NEG-02` | `CHK-02`, `CHK-10` | `EVID-02`, `EVID-10` |
| `REQ-03` | `CON-04`, `CON-05`, `CTR-03`, `FM-02`, `FM-03`, `FM-04`, `FM-05` | `EC-03`, `SC-04`, `SC-13`, `SC-20`, `NEG-02`, `NEG-03` | `CHK-02`, `CHK-03`, `CHK-04`, `CHK-05`, `CHK-06`, `CHK-08`, `CHK-10` | `EVID-02`, `EVID-03`, `EVID-04`, `EVID-05`, `EVID-06`, `EVID-08`, `EVID-10` |
| `REQ-04` | `CON-06`, `INV-01`, `INV-02`, `INV-03`, `INV-04`, `CTR-04`, `FM-08`, `FM-09` | `EC-04`, `SC-05`, `SC-06`, `NEG-04` | `CHK-01`, `CHK-03`, `CHK-10` | `EVID-01`, `EVID-03`, `EVID-10` |
| `REQ-05` | `CON-07`, `CON-08`, `INV-01`, `INV-05`, `CTR-05`, `FM-07`, `FM-08` | `EC-05`, `SC-07`, `SC-08`, `SC-09`, `SC-18`, `SC-19`, `NEG-05` | `CHK-01`, `CHK-04`, `CHK-10` | `EVID-01`, `EVID-04`, `EVID-10` |
| `REQ-06` | `CTR-06`, `INV-01`, `FM-05` | `EC-06`, `SC-10`, `SC-11`, `SC-12`, `SC-13`, `SC-19`, `NEG-03` | `CHK-01`, `CHK-05`, `CHK-10` | `EVID-01`, `EVID-05`, `EVID-10` |
| `REQ-07` | `CON-05`, `INV-06`, `INV-07`, `CTR-07`, `CTR-08`, `FM-06`, `FM-10` | `EC-07`, `EC-08`, `SC-14`, `SC-15`, `SC-16`, `NEG-01`, `NEG-06`, `NEG-07` | `CHK-01`, `CHK-06`, `CHK-10` | `EVID-01`, `EVID-06`, `EVID-10` |
| `REQ-08` | `CON-06`, `INV-02`, `INV-03` | `EC-09`, `EC-10` | `CHK-10` | `EVID-10` |
| `REQ-09` | `INV-02`, `INV-03`, `INV-04` | `EC-09` | `CHK-10` | `EVID-10` |
| `REQ-10` | `ASM-01`, `CTR-04`, `CTR-05`, `CTR-06`, `CTR-07`, `CTR-08` | `EC-11`, `SC-05`–`SC-16` | `CHK-01`, `CHK-10` | `EVID-01`, `EVID-10` |
| `REQ-11` | `ASM-04` | `EC-09`, `EC-10` | `CHK-10` | `EVID-10` |
| `REQ-12` | `EC-11`, `EC-12`, `EC-13` | `SC-01`–`SC-20` | `CHK-01`–`CHK-10` | `EVID-01`–`EVID-10` |

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| --- | --- | --- | --- | --- |
| `CHK-01` | `EC-11`, `SC-05`–`SC-16`, `REQ-10` | `bundle exec rspec spec/services/operations/` | Service и query specs проходят для всех operations services. | `artifacts/ft-003/verify/chk-01/` |
| `CHK-02` | `EC-02`, `EC-03`, `SC-01`–`SC-04`, `NEG-02` | `bundle exec rspec spec/requests/operations/authentication_spec.rb spec/requests/operations/access_spec.rb` | Auth failures и role matrix specs проходят. | `artifacts/ft-003/verify/chk-02/` |
| `CHK-03` | `EC-04`, `SC-05`, `SC-06`, `NEG-04` | `bundle exec rspec spec/requests/operations/staff_spec.rb` | Manager staff management specs проходят. | `artifacts/ft-003/verify/chk-03/` |
| `CHK-04` | `EC-05`, `SC-07`–`SC-09`, `SC-18`, `SC-19`, `NEG-05` | `bundle exec rspec spec/requests/operations/tickets_manager_spec.rb` | Manager ticket read/update specs проходят. | `artifacts/ft-003/verify/chk-04/` |
| `CHK-05` | `EC-06`, `SC-10`–`SC-13`, `NEG-03` | `bundle exec rspec spec/requests/operations/tickets_staff_spec.rb` | Staff ticket visibility specs проходят. | `artifacts/ft-003/verify/chk-05/` |
| `CHK-06` | `EC-07`, `EC-08`, `SC-14`–`SC-16`, `NEG-01`, `NEG-06`, `NEG-07`, `NEG-08` | `bundle exec rspec spec/requests/operations/ticket_transitions_spec.rb` | Transition specs проходят. | `artifacts/ft-003/verify/chk-06/` |
| `CHK-07` | `EC-12`, `SC-17`–`SC-19` | `bundle exec rspec spec/requests/operations/staff_ticket_workflow_spec.rb` | End-to-end workflow spec проходит без admin. | `artifacts/ft-003/verify/chk-07/` |
| `CHK-08` | `EC-13`, `SC-20` | `bundle exec rspec spec/requests/admin/` | Admin regression: `/admin/**` остаётся admin-only. | `artifacts/ft-003/verify/chk-08/` |
| `CHK-09` | Code style for all changed Ruby files | `bundle exec rubocop` | RuboCop exits successfully. | `artifacts/ft-003/verify/chk-09/` |
| `CHK-10` | `EC-01`–`EC-13` | `bundle exec rspec` | Full RSpec suite passes. | `artifacts/ft-003/verify/chk-10/` |

### Test Matrix

| Check ID | Evidence IDs | Evidence path |
| --- | --- | --- |
| `CHK-01` | `EVID-01` | `artifacts/ft-003/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-003/verify/chk-02/` |
| `CHK-03` | `EVID-03` | `artifacts/ft-003/verify/chk-03/` |
| `CHK-04` | `EVID-04` | `artifacts/ft-003/verify/chk-04/` |
| `CHK-05` | `EVID-05` | `artifacts/ft-003/verify/chk-05/` |
| `CHK-06` | `EVID-06` | `artifacts/ft-003/verify/chk-06/` |
| `CHK-07` | `EVID-07` | `artifacts/ft-003/verify/chk-07/` |
| `CHK-08` | `EVID-08` | `artifacts/ft-003/verify/chk-08/` |
| `CHK-09` | `EVID-09` | `artifacts/ft-003/verify/chk-09/` |
| `CHK-10` | `EVID-10` | `artifacts/ft-003/verify/chk-10/` |

### Evidence

- `EVID-01` RSpec output для `spec/services/operations/`.
- `EVID-02` RSpec output для authentication и access request specs.
- `EVID-03` RSpec output для `spec/requests/operations/staff_spec.rb`.
- `EVID-04` RSpec output для `spec/requests/operations/tickets_manager_spec.rb`.
- `EVID-05` RSpec output для `spec/requests/operations/tickets_staff_spec.rb`.
- `EVID-06` RSpec output для `spec/requests/operations/ticket_transitions_spec.rb`.
- `EVID-07` RSpec output для `spec/requests/operations/staff_ticket_workflow_spec.rb`.
- `EVID-08` RSpec output для `spec/requests/admin/`.
- `EVID-09` RuboCop output.
- `EVID-10` Full RSpec suite output.

### Evidence Contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| --- | --- | --- | --- | --- |
| `EVID-01` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-01/` | `CHK-01` |
| `EVID-02` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-02/` | `CHK-02` |
| `EVID-03` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-03/` | `CHK-03` |
| `EVID-04` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-04/` | `CHK-04` |
| `EVID-05` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-05/` | `CHK-05` |
| `EVID-06` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-06/` | `CHK-06` |
| `EVID-07` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-07/` | `CHK-07` |
| `EVID-08` | RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-08/` | `CHK-08` |
| `EVID-09` | RuboCop output log | local rubocop run / CI | `artifacts/ft-003/verify/chk-09/` | `CHK-09` |
| `EVID-10` | Full RSpec output log | local rspec run / CI | `artifacts/ft-003/verify/chk-10/` | `CHK-10` |
