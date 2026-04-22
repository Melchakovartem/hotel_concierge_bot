---
title: "FT-002: Role-based authorization and Hotel CRUD"
doc_kind: feature
doc_function: canonical
purpose: "Canonical feature contract для ограничения admin namespace ролью admin, полного CRUD отелей через slug и read-only hotel-scoped staff/tickets routes."
derived_from:
  - ../../domain/problem.md
  - ../../engineering/testing-policy.md
  - ../002/brief.md
  - ../002/spec.md
status: active
delivery_status: planned
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-002: Role-based authorization and Hotel CRUD

## What

### Problem

После slice 001 аутентификация admin namespace работает через `Staff` records, но role-based checks ещё не защищают весь административный раздел. Любой authenticated сотрудник может получить доступ к admin pages, включая управление персоналом и отелями, а управление отелями ограничено просмотром списка.

Для дальнейших Phase 1 flows нужен фундамент access control: admin-only namespace, управляемый список отелей и hotel-scoped read-only views для staff и tickets.

### Outcome

- Роли `manager` и `staff` при обращении к `/admin/**` получают `302` redirect на `/`.
- Роль `admin` имеет доступ ко всему административному разделу.
- Администратор может просматривать, создавать, редактировать и удалять отели через `/admin/hotels`.
- Каждый `Hotel` имеет уникальный immutable `slug`, генерируемый из имени при создании.
- Страница отеля показывает сведения об отеле и ссылки на hotel-scoped staff и tickets.
- Hotel-scoped staff/tickets pages показывают данные только для указанного отеля.

### Scope

- `REQ-01` Ограничить доступ к `/admin/**` только ролью `admin`: `manager` и `staff` получают `302` redirect на `root_path`, unauthenticated requests сохраняют `401` behavior из slice 001.
- `REQ-02` Добавить `Hotel#slug` как обязательный уникальный строковый URL identifier с форматом `/\A[a-z0-9-]+\z/`.
- `REQ-03` Генерировать `slug` автоматически в `Admin::Hotels::CreateService` по правилу `"#{params[:name].to_s.parameterize}-slug"`; не принимать `slug` из формы и не менять его при update.
- `REQ-04` Добавить полный Hotel CRUD через `/admin/hotels`: `index`, `new`, `create`, `show`, `edit`, `update`, `destroy`.
- `REQ-05` Обрабатывать Hotel CRUD statuses и feedback: successful create/update/destroy redirect to `/admin/hotels` с `flash[:notice]`, validation failures render form with `422`, delete restriction redirects with `flash[:alert]`.
- `REQ-06` Добавить `Hotel.name` global uniqueness и сохранить required `name`/`timezone` validations.
- `REQ-07` Добавить direct `Ticket#hotel_id` с FK/NOT NULL и поля `subject`/`body` с required values, чтобы tickets можно было показывать в hotel scope.
- `REQ-08` Добавить read-only routes `/admin/hotels/:slug/staff`, `/admin/hotels/:slug/staff/:id` и `/admin/hotels/:slug/tickets`.
- `REQ-09` В hotel-scoped staff routes показывать только staff указанного отеля; staff из другого отеля должен давать `404`.
- `REQ-10` В hotel-scoped tickets route показывать только tickets указанного отеля, включая `guest`, `department`, `staff` или localized `unassigned`.
- `REQ-11` Добавить service result infrastructure `BaseService` / `Result` и services `Admin::Hotels::CreateService` / `UpdateService` для Hotel create/update.
- `REQ-12` Обновить request/service specs, factories и seeds под новые routes, validations, associations и authorization matrix.

### Non-Scope

- `NS-01` Не менять auth mechanism из slice 001, включая Basic Auth и `401` behavior для missing/invalid credentials.
- `NS-02` Не добавлять namespaces или отдельные разделы для ролей `manager` и `staff`.
- `NS-03` Не делать CRUD для staff.
- `NS-04` Не делать CRUD для tickets.
- `NS-05` Не добавлять client-side validation.
- `NS-06` Не добавлять bulk operations.
- `NS-07` Не использовать `dry-monads`; service result pattern задаётся через `BaseService` и `Result`.
- `NS-08` Не вводить Turbo/JS-specific behavior для delete links или form failures.

### Constraints / Assumptions

- `CON-01` FT-002 зависит от slice 001: `Admin::BaseController` уже authenticates Staff records and assigns `@current_staff`.
- `CON-02` `before_action` order в `Admin::BaseController`: `authenticate_staff!` затем `require_admin!`.
- `CON-03` `manager` и `staff` получают `302` redirect на `/`, а не `403`.
- `CON-04` `Hotel.slug` unique, non-null, lowercase Latin letters / digits / hyphen only, and immutable after creation.
- `CON-05` Existing Hotel associations with `dependent: :restrict_with_exception` should remain unchanged.
- `CON-06` Destroying a hotel with associated records must not return `500`; UI receives `flash[:alert]` text `Hotel has associated records and cannot be deleted.`
- `CON-07` Rails forms use `time_zone_select` with `ActiveSupport::TimeZone.all`; stored timezone value is ActiveSupport-friendly string such as `"Moscow"`.
- `CON-08` Project runs on Ruby 3.3.3, so `Data.define` is available for `Result`.
- `CON-09` `BaseService.call` must not rescue `Dry::Types::ConstraintError` or `Dry::Types::MissingKeyError`.
- `ASM-01` Legacy spec assumes `hotels` and `tickets` tables may be empty during migration, but also documents safe rollout paths for non-empty data.
- `DEC-01` Legacy spec explicitly accepts that the slice consolidates features 002-005 and touches 6+ modules; TAUS/Scoped risk is accepted in the source spec.

## How

### Solution

Add an admin-only authorization layer in `Admin::BaseController`, expand Hotel from list-only to slug-based CRUD, introduce minimal service result objects for create/update, and add read-only nested controllers for hotel-scoped staff and tickets. The implementation keeps slice 001 authentication unchanged and verifies role boundaries through request specs.

### Change Surface

| Surface | Type | Why it changes |
| --- | --- | --- |
| `app/controllers/admin/base_controller.rb` | controller | Add `require_admin!` after Staff authentication for all `/admin/**`. |
| `app/controllers/admin/hotels_controller.rb` | controller | Replace manager-access listing with full admin-only Hotel CRUD. |
| `app/controllers/admin/hotel_staff_controller.rb` | controller | Add read-only hotel-scoped staff index/show. |
| `app/controllers/admin/hotel_tickets_controller.rb` | controller | Add read-only hotel-scoped tickets index. |
| `config/routes.rb` | routes | Add slug-param Hotel CRUD and nested staff/tickets routes. |
| `app/models/hotel.rb` | model | Add slug/name/timezone validations, `has_many :tickets`, `to_param`. |
| `app/models/ticket.rb` | model | Add `belongs_to :hotel` and `subject`/`body` validations. |
| `db/migrate/*` | database | Add Hotel slug, unique Hotel name index, Ticket hotel reference, subject and body. |
| `db/schema.rb` | database schema | Reflect migrations. |
| `db/seeds.rb` | data | Make seeds valid with slug, ticket hotel, subject and body. |
| `app/services/base_service.rb`, `app/services/result.rb` | service infrastructure | Define shared service call/result contract. |
| `app/services/admin/hotels/create_service.rb`, `app/services/admin/hotels/update_service.rb` | services | Encapsulate Hotel create/update and validation failures. |
| `app/views/admin/hotels/*` | views | Add CRUD screens, links, forms, validation errors and empty states. |
| `app/views/admin/hotel_staff/*` | views | Add hotel-scoped staff pages. |
| `app/views/admin/hotel_tickets/index.html.erb` | view | Add hotel-scoped tickets list and unassigned fallback. |
| `app/views/shared/_errors.html.erb` | view partial | Shared validation errors partial for forms. |
| `app/views/layouts/admin.html.erb` | layout | Render `flash[:notice]` and `flash[:alert]`. |
| `config/locales/en.yml`, `config/locales/ru.yml` | i18n | Add action links, empty states and unassigned copy. |
| `spec/factories/*` | test data | Add required slug/ticket fields and related factories. |
| `spec/requests/admin/*` | request specs | Cover CRUD, nested routes and auth matrix. |
| `spec/services/admin/hotels/*` | service specs | Cover create/update service result behavior. |

### Flow

1. Request enters `/admin/**`.
2. `Admin::BaseController` authenticates Staff using existing slice 001 Basic Auth.
3. `require_admin!` redirects non-admin Staff roles to `root_path`.
4. Admin can access Hotel CRUD routes using slug-param paths.
5. Hotel create uses permitted `name` and `timezone`, generates slug, and returns service `Result`.
6. Hotel update uses permitted `name` and `timezone`; slug params are ignored.
7. Hotel destroy redirects with notice on success or alert on `ActiveRecord::DeleteRestrictionError`.
8. Hotel-scoped nested controllers find `Hotel` by `params[:hotel_slug]` and query through `@hotel.staff` or `@hotel.tickets`.
9. Missing hotel or cross-hotel staff lookup renders plain `Not Found` with `404`.

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| --- | --- | --- | --- |
| `CTR-01` | Staff Basic Auth identity and `@current_staff` | Slice 001 `Admin::BaseController` / FT-002 `require_admin!` | FT-002 must keep authentication behavior unchanged. |
| `CTR-02` | `/admin/**` role matrix | HTTP request / admin controllers | `admin` allowed; `manager` and `staff` redirect to `/`; no auth returns `401`. |
| `CTR-03` | `resources :hotels, param: :slug` | routes / controllers and views | `admin_hotel_path(hotel)` must use `Hotel#to_param == slug`. |
| `CTR-04` | `Hotel#slug` | `CreateService` / route lookup | Generated as `"#{name.parameterize}-slug"`, unique, required, immutable. |
| `CTR-05` | `Result(success:, error_code:, messages:, result:)` | services / controllers | Supports `success?` and `failure?`; `error_code` and `messages` default for success. |
| `CTR-06` | Hotel CRUD status/flash behavior | `Admin::HotelsController` / browser and request specs | Success uses `302`; invalid create/update uses `422`; restricted destroy redirects with alert. |
| `CTR-07` | `Ticket#hotel_id`, `subject`, `body` | database/models / nested tickets controller | Ticket is always hotel-bound and has displayable text fields. |
| `CTR-08` | i18n keys under `admin.hotels`, `admin.hotel_staff`, `admin.hotel_tickets` | locale files / views and specs | Empty states and action links are localized in `en.yml` and `ru.yml`. |

### Failure Modes

- `FM-01` Authenticated non-admin Staff reaches any `/admin/**` endpoint: redirect to `/`.
- `FM-02` Missing or invalid auth reaches `/admin/**`: keep `401` from slice 001.
- `FM-03` Create/update missing `name` or `timezone`: render form with `422` and validation errors.
- `FM-04` Duplicate `name` / generated duplicate `slug`: render form with `422` and validation errors.
- `FM-05` Unknown hotel slug for show/edit/update/destroy or nested routes: render plain `Not Found` with `404`.
- `FM-06` Staff show lookup for staff member from another hotel: render `404`.
- `FM-07` Destroy hotel with associated records: redirect to hotels index with alert, no `500`.
- `FM-08` Ticket without assigned staff in nested tickets list: render localized `unassigned` text.
- `FM-09` Existing database rows can make direct NOT NULL migrations fail without safe rollout/backfill.

### ADR Dependencies

ADR не требуется. Legacy spec фиксирует local decision: `BaseService` + `Result` PORO, no `dry-monads`, no Turbo-specific behavior.

## Verify

### Exit Criteria

- `EC-01` `Admin::BaseController` applies `require_admin!` after `authenticate_staff!`.
- `EC-02` `manager` and `staff` get `302` redirect to `/` for every protected admin endpoint covered by specs.
- `EC-03` `admin` can access Hotel CRUD pages and successful mutating actions redirect with notice.
- `EC-04` Hotel create/update invalid data returns `422` and form errors.
- `EC-05` Hotel slug is generated, unique, format-constrained and not updateable through params or forms.
- `EC-06` Hotel destroy with associated records redirects with exact alert text and does not raise `500`.
- `EC-07` Hotel show page renders hotel attributes and links to staff/tickets nested pages.
- `EC-08` Hotel-scoped staff index/show routes return only staff for the selected hotel and `404` for cross-hotel staff.
- `EC-09` Hotel-scoped tickets route returns only tickets for the selected hotel and shows `unassigned` when `ticket.staff` is nil.
- `EC-10` Request specs cover success, validation failure and each role for protected endpoints.
- `EC-11` Service specs cover Hotel create/update service success and failure outcomes.
- `EC-12` Full RSpec suite passes after all slices.

### Acceptance Scenarios

- `SC-01` Admin Staff opens `/admin/hotels`, `/admin/staff` and `/admin/tickets` and receives successful admin responses.
- `SC-02` Manager or staff role opens any protected admin endpoint and receives `302` redirect to `/`.
- `SC-03` Request without authentication opens protected admin endpoint and receives `401`.
- `SC-04` Admin opens hotels index with hotels and sees hotel names; with no hotels sees `t("admin.hotels.index.empty")`.
- `SC-05` Admin creates a hotel with valid `name` and `timezone`, receives `302` to `/admin/hotels`, and the hotel has generated slug.
- `SC-06` Admin creates or updates a hotel with missing `name`, missing `timezone`, duplicate name/slug or invalid slug and receives validation failure on the form.
- `SC-07` Admin opens `/admin/hotels/:slug` and sees `name`, `timezone`, `slug`, staff link and tickets link.
- `SC-08` Admin opens unknown hotel slug for show/edit/update/destroy or nested routes and receives `404`.
- `SC-09` Admin updates valid hotel attributes and receives `302`; supplied slug params do not change the original slug.
- `SC-10` Admin deletes hotel without associated records and receives `302` with notice.
- `SC-11` Admin deletes hotel with associated records and receives `302` with alert `Hotel has associated records and cannot be deleted.`
- `SC-12` Admin opens `/admin/hotels/:slug/staff` and sees only staff for that hotel or the localized empty state.
- `SC-13` Admin opens `/admin/hotels/:slug/staff/:id`; staff belonging to the hotel returns `200`, staff from another hotel returns `404`.
- `SC-14` Admin opens `/admin/hotels/:slug/tickets` and sees only tickets for that hotel or the localized empty state.
- `SC-15` Admin opens hotel tickets containing a ticket without staff and sees `t("admin.hotel_tickets.index.unassigned")`.
- `SC-16` Hotel create/update services return `Success` for valid params and `Failure` with errors for invalid params.

### Negative / Edge Cases

- `NEG-01` `manager` and `staff` must not receive `200` for any protected admin endpoint.
- `NEG-02` Missing auth must remain `401`, not redirect.
- `NEG-03` Duplicate generated slug must surface validation errors, not create a duplicate row.
- `NEG-04` `slug` passed to update params must be ignored.
- `NEG-05` Unknown hotel slug must return `404`.
- `NEG-06` Staff member from another hotel must return `404` in hotel-scoped staff show.
- `NEG-07` Hotel destroy with associated records must not raise `500`.
- `NEG-08` Ticket with nil staff must render localized unassigned fallback.

### Traceability Matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| --- | --- | --- | --- | --- |
| `REQ-01` | `CON-01`, `CON-02`, `CON-03`, `CTR-01`, `CTR-02`, `FM-01`, `FM-02` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `SC-03`, `NEG-01`, `NEG-02` | `CHK-02`, `CHK-03`, `CHK-04`, `CHK-06` | `EVID-02`, `EVID-03`, `EVID-04`, `EVID-06` |
| `REQ-02` | `CON-04`, `CTR-03`, `CTR-04`, `FM-04`, `FM-09` | `EC-05`, `SC-05`, `SC-06`, `NEG-03` | `CHK-01`, `CHK-03`, `CHK-06` | `EVID-01`, `EVID-03`, `EVID-06` |
| `REQ-03` | `CON-04`, `CTR-04` | `EC-05`, `SC-05`, `SC-09`, `NEG-04` | `CHK-01`, `CHK-03`, `CHK-06` | `EVID-01`, `EVID-03`, `EVID-06` |
| `REQ-04` | `CTR-03`, `CTR-06`, `FM-03`, `FM-05` | `EC-03`, `EC-04`, `SC-04`-`SC-11` | `CHK-03`, `CHK-06` | `EVID-03`, `EVID-06` |
| `REQ-05` | `CTR-06`, `FM-03`, `FM-07` | `EC-03`, `EC-04`, `EC-06`, `SC-05`, `SC-06`, `SC-09`, `SC-10`, `SC-11`, `NEG-07` | `CHK-03`, `CHK-06` | `EVID-03`, `EVID-06` |
| `REQ-06` | `CON-04`, `FM-04` | `EC-04`, `EC-05`, `SC-06`, `NEG-03` | `CHK-01`, `CHK-03`, `CHK-06` | `EVID-01`, `EVID-03`, `EVID-06` |
| `REQ-07` | `CTR-07`, `FM-09` | `EC-09`, `SC-14`, `SC-15`, `NEG-08` | `CHK-04`, `CHK-06` | `EVID-04`, `EVID-06` |
| `REQ-08` | `CTR-03`, `FM-05` | `EC-07`, `EC-08`, `EC-09`, `SC-12`-`SC-15` | `CHK-04`, `CHK-06` | `EVID-04`, `EVID-06` |
| `REQ-09` | `FM-06` | `EC-08`, `SC-12`, `SC-13`, `NEG-06` | `CHK-04`, `CHK-06` | `EVID-04`, `EVID-06` |
| `REQ-10` | `CTR-07`, `CTR-08`, `FM-08` | `EC-09`, `SC-14`, `SC-15`, `NEG-08` | `CHK-04`, `CHK-06` | `EVID-04`, `EVID-06` |
| `REQ-11` | `CTR-05`, `CON-08`, `CON-09` | `EC-11`, `SC-16` | `CHK-01`, `CHK-06` | `EVID-01`, `EVID-06` |
| `REQ-12` | `CTR-08` | `EC-10`, `EC-11`, `EC-12` | `CHK-01`, `CHK-02`, `CHK-03`, `CHK-04`, `CHK-05`, `CHK-06` | `EVID-01`, `EVID-02`, `EVID-03`, `EVID-04`, `EVID-05`, `EVID-06` |

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| --- | --- | --- | --- | --- |
| `CHK-01` | `EC-05`, `EC-11`, `SC-16` | `bundle exec rspec spec/services/ spec/services/admin/hotels/` | Service infrastructure and Hotel create/update service specs pass. | `artifacts/ft-002/verify/chk-01/` |
| `CHK-02` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `SC-03` | `bundle exec rspec spec/requests/` after authorization baseline | Admin request authorization matrix passes with `302` for non-admin roles and `401` for no auth. | `artifacts/ft-002/verify/chk-02/` |
| `CHK-03` | `EC-03`-`EC-07`, `SC-04`-`SC-11`, `NEG-03`-`NEG-07` | `bundle exec rspec spec/requests/admin/hotels_spec.rb` | Hotel CRUD, slug, status, flash and auth cases pass. | `artifacts/ft-002/verify/chk-03/` |
| `CHK-04` | `EC-08`, `EC-09`, `SC-12`-`SC-15`, `NEG-06`, `NEG-08` | `bundle exec rspec spec/requests/admin/hotel_staff_spec.rb spec/requests/admin/hotel_tickets_spec.rb` | Nested staff/tickets request specs pass. | `artifacts/ft-002/verify/chk-04/` |
| `CHK-05` | Code style for changed Ruby files | `bundle exec rubocop` | RuboCop exits successfully. | `artifacts/ft-002/verify/chk-05/` |
| `CHK-06` | `EC-01`-`EC-12` | `bundle exec rspec` | Full RSpec suite passes. | `artifacts/ft-002/verify/chk-06/` |

### Test Matrix

| Check ID | Evidence IDs | Evidence path |
| --- | --- | --- |
| `CHK-01` | `EVID-01` | `artifacts/ft-002/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-002/verify/chk-02/` |
| `CHK-03` | `EVID-03` | `artifacts/ft-002/verify/chk-03/` |
| `CHK-04` | `EVID-04` | `artifacts/ft-002/verify/chk-04/` |
| `CHK-05` | `EVID-05` | `artifacts/ft-002/verify/chk-05/` |
| `CHK-06` | `EVID-06` | `artifacts/ft-002/verify/chk-06/` |

### Evidence

- `EVID-01` RSpec output для service specs.
- `EVID-02` RSpec output для request specs after authorization baseline.
- `EVID-03` RSpec output для `spec/requests/admin/hotels_spec.rb`.
- `EVID-04` RSpec output для nested staff/tickets request specs.
- `EVID-05` RuboCop output.
- `EVID-06` Full RSpec suite output.

### Evidence Contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| --- | --- | --- | --- | --- |
| `EVID-01` | RSpec output log | local rspec run / CI | `artifacts/ft-002/verify/chk-01/` | `CHK-01` |
| `EVID-02` | RSpec output log | local rspec run / CI | `artifacts/ft-002/verify/chk-02/` | `CHK-02` |
| `EVID-03` | RSpec output log | local rspec run / CI | `artifacts/ft-002/verify/chk-03/` | `CHK-03` |
| `EVID-04` | RSpec output log | local rspec run / CI | `artifacts/ft-002/verify/chk-04/` | `CHK-04` |
| `EVID-05` | RuboCop output log | local rubocop run / CI | `artifacts/ft-002/verify/chk-05/` | `CHK-05` |
| `EVID-06` | Full RSpec output log | local rspec run / CI | `artifacts/ft-002/verify/chk-06/` | `CHK-06` |
