# Spec 001 — Secure admin hotel listing by role

**Ref:** [GitHub Issue #1](https://github.com/Melchakovartem/hotel_concierge_bot/issues/1)

## Overview

Replace the hardcoded `http_basic_authenticate_with` in `Admin::BaseController`
with a custom HTTP Basic Auth implementation that authenticates against `Staff`
records. Add a role check on `Admin::HotelsController#index` so that only
`admin` and `manager` roles are allowed; `staff` role is denied with 403.

**Auth mechanism decision:** Custom HTTP Basic Auth against Staff records (no
Rails auth helpers). Rationale: minimal surface change, consistent with the
existing request pattern, and straightforward to replicate in slices 002–003.
No login/logout UI is needed at this stage.

---

## Pre-conditions / Setup

- `bcrypt` gem MUST be present and uncommented in `Gemfile` (required by
  `has_secure_password`).
- Every `Staff` record MUST have a `password_digest` — Staff without a password
  is not a valid state in any environment (dev, test, production).

---

## Database

### New migration — `add_password_digest_to_staffs`

```ruby
add_column :staffs, :password_digest, :string, null: false
```

Column is `NOT NULL` — enforces the invariant that every Staff record has a
password at the database level.

---

## Model — `Staff`

Add `has_secure_password` to `app/models/staff.rb`. All existing associations
and the `role` enum remain unchanged.

`has_secure_password` provides `authenticate(plain_password)` — used by the
controller — and a presence validation on `password` at create time.

---

## Controller — `Admin::BaseController`

Replace the single `http_basic_authenticate_with` line with a custom
`before_action :authenticate_staff!` that does **not** use any Rails HTTP auth
helpers (`authenticate_with_http_basic`, `request_http_basic_authentication`,
etc.).

Implementation steps:

1. Read the `Authorization` header from `request.headers["Authorization"]`.
2. Check it starts with `"Basic "` — if absent or malformed, respond with
   `401 Unauthorized` and `WWW-Authenticate: Basic realm="Admin"` header, then
   `return` to halt the filter chain.
3. Strict-Base64-decode (`Base64.strict_decode64`) the credentials part — if
   decoding raises `ArgumentError` (malformed input), respond with 401 and
   return. Otherwise split on `":"` (max 2 parts) to extract email and password.
4. Find a `Staff` record by `email`; call `authenticate(password)` on it.
5. On failure: same 401 response as step 2.
6. On success: assign the authenticated record to `@current_staff`.

```ruby
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_staff!
    layout "admin"

    private

    def authenticate_staff!
      header = request.headers["Authorization"]

      unless header&.start_with?("Basic ")
        return http_401
      end

      decoded = Base64.strict_decode64(header.delete_prefix("Basic "))
      email, password = decoded.split(":", 2)
      @current_staff = Staff.find_by(email: email)&.authenticate(password)

      http_401 unless @current_staff
    rescue ArgumentError
      http_401
    end

    def http_401
      response.headers["WWW-Authenticate"] = 'Basic realm="Admin"'
      render plain: "Unauthorized", status: :unauthorized
    end
  end
end
```

---

## Controller — `Admin::HotelsController`

Add `before_action :require_hotel_access!` (runs after `authenticate_staff!`
inherited from `BaseController`).

Access rule:
- `admin` role → allowed
- `manager` role → allowed
- `staff` role → denied with `403 Forbidden`

```ruby
module Admin
  class HotelsController < BaseController
    before_action :require_hotel_access!

    def index
      @hotels = Hotel.order(:name)
    end

    private

    def require_hotel_access!
      return if @current_staff.admin? || @current_staff.manager?

      render plain: "Forbidden", status: :forbidden
    end
  end
end
```

---

## Factory

Add a `:staff` factory to `spec/factories/staffs.rb` (new file). Default role
is `:staff` (most restricted). Use traits to build privileged records.

```ruby
FactoryBot.define do
  factory :staff do
    association :hotel
    sequence(:name) { |n| "Staff Member #{n}" }
    sequence(:email) { |n| "staff#{n}@example.com" }
    password { "password" }
    role { :staff }

    trait :admin do
      role { :admin }
    end

    trait :manager do
      role { :manager }
    end
  end
end
```

---

## Specs

### Update `spec/requests/admin/access_spec.rb`

Replace the hardcoded `authorization_header` helper with Staff-based
credentials. The `staff_member` MUST be created with the `:admin` trait so
that all three existing `describe` blocks (including `GET /admin/hotels`) pass
with a 200.

Concrete changes:
- Create `staff_member` via `create(:staff, :admin, hotel: hotel)`.
- Update `authorization_header` to encode `staff_member.email` and `"password"`
  using manual Base64 encoding (matching the custom auth implementation):
  ```ruby
  def authorization_header
    encoded = Base64.strict_encode64("#{staff_member.email}:password")
    { "Authorization" => "Basic #{encoded}" }
  end
  ```
- The three existing `describe` blocks and their assertions remain — only the
  auth mechanism changes.

### New file `spec/requests/admin/hotels_spec.rb`

Covers role-based access on `GET /admin/hotels`.

| Scenario | Setup | Expected |
|----------|-------|----------|
| Unauthenticated | No `Authorization` header | `401`, `WWW-Authenticate` header present |
| Wrong scheme | `Authorization: Bearer token` (not Basic) | `401`, `WWW-Authenticate` header present |
| Invalid base64 | `Authorization: Basic !!!` (malformed base64) | `401`, `WWW-Authenticate` header present |
| Unknown email | Valid Base64, email not in DB | `401` |
| Wrong password | Valid email, incorrect password | `401` |
| `admin` role | Authenticates with admin staff | `200`, hotel name in body |
| `manager` role | Authenticates with manager staff | `200`, hotel name in body |
| `staff` role | Authenticates with staff role | `403` |

> **Note — empty state:** `Staff#hotel_id` is `NOT NULL`, so a zero-hotel DB state
> cannot be reached in an integration test without violating the FK constraint.
> The empty state branch (`t("admin.hotels.index.empty")`) is present in the view
> and verified by [manual check] only.

```ruby
RSpec.describe "GET /admin/hotels" do
  let(:hotel) { create(:hotel) }

  def auth_header(staff_record)
    encoded = Base64.strict_encode64("#{staff_record.email}:password")
    { "Authorization" => "Basic #{encoded}" }
  end

  context "when unauthenticated" do
    it "returns 401 with WWW-Authenticate header" do
      get admin_hotels_path

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to eq('Basic realm="Admin"')
    end
  end

  context "when Authorization header uses wrong scheme" do
    it "returns 401 with WWW-Authenticate header" do
      get admin_hotels_path, headers: { "Authorization" => "Bearer sometoken" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to eq('Basic realm="Admin"')
    end
  end

  context "when Authorization header contains malformed base64" do
    it "returns 401 with WWW-Authenticate header" do
      get admin_hotels_path, headers: { "Authorization" => "Basic !!!" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to eq('Basic realm="Admin"')
    end
  end

  context "when email is not found in the database" do
    it "returns 401" do
      encoded = Base64.strict_encode64("nonexistent@example.com:password")
      get admin_hotels_path, headers: { "Authorization" => "Basic #{encoded}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when password is incorrect" do
    it "returns 401" do
      staff = create(:staff, :admin, hotel: hotel)
      encoded = Base64.strict_encode64("#{staff.email}:wrongpassword")
      get admin_hotels_path, headers: { "Authorization" => "Basic #{encoded}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated as admin" do
    it "returns 200 and renders the hotels list" do
      staff = create(:staff, :admin, hotel: hotel)
      get admin_hotels_path, headers: auth_header(staff)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(hotel.name)
    end
  end

  context "when authenticated as manager" do
    it "returns 200 and renders the hotels list" do
      staff = create(:staff, :manager, hotel: hotel)
      get admin_hotels_path, headers: auth_header(staff)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(hotel.name)
    end
  end

  context "when authenticated as staff role" do
    it "returns 403" do
      staff = create(:staff, hotel: hotel)
      get admin_hotels_path, headers: auth_header(staff)

      expect(response).to have_http_status(:forbidden)
    end
  end

end
```

---

## Acceptance Criteria

- [ ] `admin` role authenticates and receives `200` on `GET /admin/hotels`; hotel name is present in the response body
- [ ] `manager` role authenticates and receives `200` on `GET /admin/hotels`; hotel name is present in the response body
- [ ] Empty hotel list: view renders `t("admin.hotels.index.empty")` [manual check — not automatable due to `hotel_id NOT NULL` constraint on Staff]
- [ ] `staff` role authenticates successfully but receives `403` on
      `GET /admin/hotels`
- [ ] Unauthenticated request receives `401` with `WWW-Authenticate: Basic realm="Admin"` header
- [ ] Request with non-Basic scheme (e.g. `Bearer`) receives `401` with `WWW-Authenticate` header
- [ ] Request with malformed base64 payload receives `401` with `WWW-Authenticate` header
- [ ] Request with unknown email receives `401`
- [ ] Request with correct email but wrong password receives `401`
- [ ] `spec/requests/admin/access_spec.rb` is updated to use Staff credentials
      (`:admin` role) and all examples pass
- [ ] `spec/requests/admin/hotels_spec.rb` exists and all eight examples pass
- [ ] No hardcoded `"admin"/"password"` credentials remain in `BaseController` [manual check]
- [ ] `bcrypt` gem is present and uncommented in `Gemfile` [manual check]

---

## Files Changed

| File | Action |
|------|--------|
| `db/migrate/<timestamp>_add_password_digest_to_staffs.rb` | New migration |
| `app/models/staff.rb` | Add `has_secure_password` |
| `app/controllers/admin/base_controller.rb` | Replace static Basic Auth with custom implementation |
| `app/controllers/admin/hotels_controller.rb` | Add role check |
| `spec/factories/staffs.rb` | New factory with `:admin` and `:manager` traits |
| `spec/requests/admin/access_spec.rb` | Update auth to use Staff credentials |
| `spec/requests/admin/hotels_spec.rb` | New role-based request specs |
| `config/locales/en.yml` | Add `admin.hotels.index.empty: "No hotels found."` |
| `config/locales/ru.yml` | Add `admin.hotels.index.empty: "Отели не найдены."` |
| `app/views/admin/hotels/index.html.erb` | Render empty state message when no hotels |

---

## Out of Scope

- Staff CRUD (create/edit/delete accounts)
- Password reset flow
- Session-based auth (login form, cookies)
- Securing `Admin::StaffController` and `Admin::TicketsController` (slices 002–003)
- Role check on `GET /admin` (`admin_root_path`) — covered in slice 002–003 sweep
- Any changes to `20260330090000_create_domain_models.rb`
