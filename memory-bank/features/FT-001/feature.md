---
title: "FT-001: Secure admin hotel listing by role"
doc_kind: feature
doc_function: canonical
purpose: "Canonical feature contract для замены hardcoded admin Basic Auth на Staff-backed authentication и role-based access к списку отелей в админке."
derived_from:
  - ../../domain/problem.md
  - ../../engineering/testing-policy.md
  - ../001/brief.md
  - ../001/spec.md
status: active
delivery_status: planned
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-001: Secure admin hotel listing by role

## What

### Problem

Админка защищена hardcoded HTTP Basic Auth в `Admin::BaseController`. Общая пара username/password не идентифицирует конкретного Staff member и не позволяет применять role-specific access.

В модели `Staff` уже есть enum `role` (`admin`, `manager`, `staff`), но admin controllers его не используют. Эта фича задаёт authentication и authorization pattern, который смогут переиспользовать следующие admin slices.

### Outcome

Доступ к `GET /admin/hotels` ограничен Staff identity и role, а не shared credentials. Роли `admin` и `manager` могут видеть список отелей. Роль `staff` успешно аутентифицируется, но получает `403 Forbidden`.

### Scope

- `REQ-01` Заменить hardcoded `http_basic_authenticate_with` в `Admin::BaseController` на custom HTTP Basic Auth, который аутентифицирует `Staff` records.
- `REQ-02` Добавить `password_digest` в `Staff` и включить `has_secure_password`.
- `REQ-03` Зафиксировать database-level invariant: у каждого `Staff` record должен быть non-null `password_digest`.
- `REQ-04` Добавить role-based access в `Admin::HotelsController#index`: `admin` и `manager` разрешены; `staff` получает `403 Forbidden`.
- `REQ-05` Обновить admin request specs и factories так, чтобы они использовали Staff credentials вместо hardcoded credentials.
- `REQ-06` Сохранить существующий hotels empty-state UI и locale keys, проверив их вручную, потому что integration test не может достичь zero-hotel state при non-null `Staff#hotel_id`.

### Non-Scope

- `NS-01` Не делать Staff CRUD для создания, редактирования или удаления accounts.
- `NS-02` Не делать password reset flow.
- `NS-03` Не делать session-based authentication, login form или cookies.
- `NS-04` Не добавлять Devise или другой authentication gem.
- `NS-05` Не использовать Rails HTTP auth helpers вроде `authenticate_with_http_basic` или `request_http_basic_authentication`.
- `NS-06` Не менять `Admin::StaffController`, `Admin::TicketsController` или `admin_root_path`; это покрывается следующими slices.
- `NS-07` Не менять существующие migrations, включая `20260330090000_create_domain_models.rb`.

### Constraints / Assumptions

- `CON-01` `bcrypt` должен быть present и uncommented в `Gemfile`; `has_secure_password` зависит от него.
- `CON-02` `password_digest` должен быть `null: false`.
- `CON-03` Ответ authentication failure для отсутствующих, malformed, unknown или invalid credentials — `401 Unauthorized` с `WWW-Authenticate: Basic realm="Admin"`.
- `CON-04` Custom auth implementation читает `Authorization` header напрямую, требует scheme `Basic `, декодирует credentials через `Base64.strict_decode64` и делит decoded credentials по первому `:`.
- `CON-05` `@current_staff` назначается только после успешной Staff authentication.
- `CON-06` Default role в Staff factory — `staff`, с явными traits `:admin` и `:manager`.
- `DEC-01` Решение: использовать custom HTTP Basic Auth against Staff records. Это сохраняет change small, оставляет request-level access pattern и не требует login/logout UI.

## How

### Solution

Ввести Staff-backed Basic Auth в `Admin::BaseController`, хранить Staff passwords через `has_secure_password` и добавить hotels-specific authorization guard в `Admin::HotelsController`. Request specs покрывают authentication failures, role permissions и regression coverage для существующих admin access specs.

### Change Surface

| Surface | Type | Why it changes |
| --- | --- | --- |
| `Gemfile` | dependency config | Включить `bcrypt` для `has_secure_password`. |
| `db/migrate/<timestamp>_add_password_digest_to_staffs.rb` | database | Добавить `staffs.password_digest` с `null: false`. |
| `app/models/staff.rb` | model | Добавить `has_secure_password`. |
| `app/controllers/admin/base_controller.rb` | controller | Заменить static Basic Auth на Staff-backed authentication. |
| `app/controllers/admin/hotels_controller.rb` | controller | Добавить role check для доступа к hotels listing. |
| `spec/factories/staffs.rb` | test factory | Добавить Staff factory с traits `:admin` и `:manager`. |
| `spec/requests/admin/access_spec.rb` | request spec | Заменить hardcoded credentials на Staff credentials. |
| `spec/requests/admin/hotels_spec.rb` | request spec | Добавить role и authentication coverage для `GET /admin/hotels`. |
| `config/locales/en.yml`, `config/locales/ru.yml` | i18n | Проверить empty-state translations для hotels index. |
| `app/views/admin/hotels/index.html.erb` | view | Проверить, что empty-state branch рендерит hotels empty message. |

### Flow

1. Admin request попадает в controller, наследующийся от `Admin::BaseController`.
2. `authenticate_staff!` читает `request.headers["Authorization"]`.
3. Missing или non-Basic credentials возвращают `401` с `WWW-Authenticate`.
4. Basic credentials strict-Base64-decode и делятся на email/password.
5. Staff ищется по email и аутентифицируется через `authenticate(password)`.
6. При успехе назначается `@current_staff`.
7. `Admin::HotelsController#index` разрешает `admin` и `manager`; `staff` получает `403`.

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| --- | --- | --- | --- |
| `CTR-01` | `Authorization: Basic <base64(email:password)>` | HTTP client / `Admin::BaseController` | Принимается только scheme `Basic `. |
| `CTR-02` | `WWW-Authenticate: Basic realm="Admin"` | `Admin::BaseController` / HTTP client | Возвращается при всех authentication failures. |
| `CTR-03` | `@current_staff` | `Admin::BaseController` / admin controllers | Присутствует только после успешной authentication. |
| `CTR-04` | `Staff#password_digest` | database / `Staff#authenticate` | Non-null и управляется через `has_secure_password`. |

### Failure Modes

- `FM-01` Missing `Authorization` header возвращает `401` с `WWW-Authenticate`.
- `FM-02` Non-Basic scheme возвращает `401` с `WWW-Authenticate`.
- `FM-03` Malformed base64 возвращает `401` с `WWW-Authenticate`.
- `FM-04` Unknown Staff email возвращает `401`.
- `FM-05` Wrong password возвращает `401`.
- `FM-06` Authenticated Staff с role `staff` получает `403` на `GET /admin/hotels`.

### ADR Dependencies

ADR не требуется. Фича использует существующие Rails controller patterns, `has_secure_password` и request specs.

## Verify

### Exit Criteria

- `EC-01` Hardcoded credentials `"admin"` / `"password"` удалены из `Admin::BaseController`.
- `EC-02` Staff authentication через Basic Auth работает для valid Staff credentials.
- `EC-03` Authentication failures возвращают ожидаемые `401` responses.
- `EC-04` `admin` и `manager` имеют доступ к `GET /admin/hotels`.
- `EC-05` `staff` аутентифицируется, но получает `403` на `GET /admin/hotels`.
- `EC-06` Existing admin access request specs используют Staff credentials и проходят.
- `EC-07` Empty-state locale keys и view branch присутствуют и проверены вручную.
- `EC-08` `bcrypt` включён в `Gemfile`.

### Acceptance Scenarios

- `SC-01` Admin Staff отправляет valid Basic Auth credentials на `GET /admin/hotels` и получает `200 OK` с hotel name в response body.
- `SC-02` Manager Staff отправляет valid Basic Auth credentials на `GET /admin/hotels` и получает `200 OK` с hotel name в response body.
- `SC-03` Staff role отправляет valid Basic Auth credentials на `GET /admin/hotels` и получает `403 Forbidden`.
- `SC-04` Request без `Authorization` получает `401 Unauthorized` с `WWW-Authenticate: Basic realm="Admin"`.
- `SC-05` Request с non-Basic `Authorization` scheme получает `401 Unauthorized` с `WWW-Authenticate`.
- `SC-06` Request с malformed base64 получает `401 Unauthorized` с `WWW-Authenticate`.
- `SC-07` Request с valid base64, но unknown email получает `401 Unauthorized`.
- `SC-08` Request с valid email и wrong password получает `401 Unauthorized`.
- `SC-09` Existing admin access request specs authenticate through admin Staff record и всё ещё проходят.
- `SC-10` Hotels empty state рендерит `t("admin.hotels.index.empty")`; это manual check, потому что `Staff#hotel_id` is non-null.

### Negative / Edge Cases

- `NEG-01` Malformed base64 не должен приводить к uncaught exception.
- `NEG-02` Non-Basic authorization не должен запускать Staff lookup.
- `NEG-03` Успешно authenticated Staff user без hotel-listing role не должен получать `200`.

### Traceability Matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| --- | --- | --- | --- | --- |
| `REQ-01` | `CON-03`, `CON-04`, `CON-05`, `CTR-01`, `CTR-02`, `CTR-03`, `FM-01`-`FM-05`, `DEC-01` | `EC-01`, `EC-02`, `EC-03`, `SC-04`-`SC-08` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-02` | `CON-01`, `CTR-04` | `EC-02`, `SC-01`, `SC-02`, `SC-03`, `SC-09` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-03` | `CON-02`, `CTR-04` | `EC-02`, `SC-01`, `SC-02`, `SC-03` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-04` | `FM-06` | `EC-04`, `EC-05`, `SC-01`, `SC-02`, `SC-03` | `CHK-01` | `EVID-01` |
| `REQ-05` | `CON-06` | `EC-06`, `SC-09` | `CHK-02` | `EVID-02` |
| `REQ-06` | `NS-07` | `EC-07`, `SC-10` | `CHK-03` | `EVID-03` |

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| --- | --- | --- | --- | --- |
| `CHK-01` | `EC-02`-`EC-05`, `SC-01`-`SC-08`, `NEG-01`-`NEG-03` | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | Все восемь role/authentication examples проходят. | `artifacts/ft-001/verify/chk-01/` |
| `CHK-02` | `EC-06`, `SC-09` | `bundle exec rspec spec/requests/admin/access_spec.rb` | Existing admin access specs проходят со Staff credentials. | `artifacts/ft-001/verify/chk-02/` |
| `CHK-03` | `EC-01`, `EC-07`, `EC-08`, `SC-10` | Manual inspection of `Admin::BaseController`, `Gemfile`, locale files и hotels index view. | Нет hardcoded admin credentials, `bcrypt` включён, empty-state i18n/view присутствует. | `artifacts/ft-001/verify/chk-03/` |
| `CHK-04` | `EC-01`-`EC-08` | `bundle exec rspec` | Full test suite passes. | `artifacts/ft-001/verify/chk-04/` |

### Test Matrix

| Check ID | Evidence IDs | Evidence path |
| --- | --- | --- |
| `CHK-01` | `EVID-01` | `artifacts/ft-001/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-001/verify/chk-02/` |
| `CHK-03` | `EVID-03` | `artifacts/ft-001/verify/chk-03/` |
| `CHK-04` | `EVID-04` | `artifacts/ft-001/verify/chk-04/` |

### Evidence

- `EVID-01` RSpec output для `spec/requests/admin/hotels_spec.rb`.
- `EVID-02` RSpec output для `spec/requests/admin/access_spec.rb`.
- `EVID-03` Manual check notes для hardcoded credentials, `bcrypt` и hotels empty state.
- `EVID-04` Full RSpec suite output.

### Evidence Contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| --- | --- | --- | --- | --- |
| `EVID-01` | RSpec output log | local rspec run / CI | `artifacts/ft-001/verify/chk-01/` | `CHK-01` |
| `EVID-02` | RSpec output log | local rspec run / CI | `artifacts/ft-001/verify/chk-02/` | `CHK-02` |
| `EVID-03` | Manual inspection notes | human / agent reviewer | `artifacts/ft-001/verify/chk-03/` | `CHK-03` |
| `EVID-04` | Full RSpec output log | local rspec run / CI | `artifacts/ft-001/verify/chk-04/` | `CHK-04` |
