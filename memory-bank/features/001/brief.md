# Feature 001 — Secure admin hotel listing by role

## Problem

The admin panel is protected by hardcoded HTTP Basic Auth (`http_basic_authenticate_with` with a static username/password pair in `Admin::BaseController`). There is no Staff record lookup and no role check — anyone with the hardcoded credentials can access any admin page regardless of their role.

## For Whom

Admin panel users: Staff members with roles `admin`, `manager`, and `staff`. Access to sensitive operations should depend on who the person actually is, not a shared password.

## Origin

The `Staff` model already has a `role` enum (`admin: 0`, `manager: 1`, `staff: 2`), but the admin controllers don't use it. This gap was identified while preparing the admin namespace for production use — slices 002 and 003 depend on this pattern being established first.

## Desired Outcome

Access to `GET /admin/hotels` (and the admin namespace going forward) is gated by the staff member's identity and role — not a hardcoded credential. This slice establishes the auth + authorization pattern that slices 002 and 003 will replicate.
