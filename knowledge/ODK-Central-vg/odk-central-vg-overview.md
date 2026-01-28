---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #authentication #security
created: 2026-01-28
---

# ODK Central VG Fork - Overview

> **Source**: `docs/vg/vg-server/` in the central meta-repo

## Purpose

The VG fork of ODK Central introduces security hardening and authentication improvements, primarily focused on replacing long-lived field-key tokens with short-lived, password-based authentication for app users.

## Key Changes

### App User Authentication Model
- **Before**: Long-lived tokens (9999 years) embedded in QR codes
- **After**: Short-lived bearer tokens (default 3 days) issued via username/password login

### Main Features

| Feature | Description |
|---------|-------------|
| Short-lived tokens | Default TTL 3 days, configurable |
| Session cap | Default 3 concurrent sessions per user |
| Password policy | Min 10 chars, uppercase+lowercase+digit+special |
| Login lockout | 5 failures/5min → 10min lock (per username+IP) |
| IP rate limiting | 20 failures/15min → 30min lock (prevents enumeration) |
| Web user hardening | Lockouts, audit logging, timing normalization |
| Telemetry capture | Device metadata, Collect version, location |
| Managed QR codes | No credentials embedded, includes admin_pw for settings lock |

## Related Documentation

- [[ODK-Central-vg/authentication-patterns]] - Complete auth reference
- [[ODK-Central-vg/app-user-implementation]] - Architecture details
- [[ODK-Central-vg/security-controls]] - Security features
- [[ODK-Central-vg/api-reference]] - API endpoints
- [[ODK-Central-vg/settings]] - Configuration options
- [[ODK-Central-vg/testing]] - Test coverage

## Architecture

### Fork Pattern

The VG fork uses a minimal override pattern:
- `docker-compose.yml` - Pure upstream
- `docker-compose.override.yml` - Modsecurity/CRS only
- `docker-compose.vg-dev.yml` - VG customizations

### Database Tables

| Table | Purpose |
|-------|---------|
| `vg_field_key_auth` | App user credentials (username, password hash, phone, active) |
| `vg_settings` | Global settings (TTL, cap, lockout config, admin_pw) |
| `vg_project_settings` | Project-level overrides |
| `vg_app_user_login_attempts` | Login attempt tracking |
| `vg_app_user_lockouts` | Active lockout windows |
| `vg_app_user_sessions` | Session metadata (IP, user agent, deviceId, comments) |
| `vg_app_user_telemetry` | Device telemetry data |

### Core Modules

| Module | Purpose |
|--------|---------|
| `server/lib/domain/vg-app-user-auth.js` | Business logic orchestration |
| `server/lib/model/query/vg-app-user-auth.js` | Database queries |
| `server/lib/resources/vg-app-user-auth.js` | HTTP endpoints |
| `server/lib/domain/vg-telemetry.js` | Telemetry validation |
| `server/lib/model/query/vg-telemetry.js` | Telemetry data access |
| `server/lib/resources/vg-telemetry.js` | Telemetry HTTP endpoints |
| `server/lib/resources/sessions.js` | Web user login hardening |

## Default Settings

```javascript
vg_app_user_session_ttl_days = 3
vg_app_user_session_cap = 3
vg_app_user_lock_max_failures = 5
vg_app_user_lock_window_minutes = 5
vg_app_user_lock_duration_minutes = 10
admin_pw = 'vg_custom'
```

## Testing Status

- **Total tests**: 173+
- **Coverage**: Integration, unit, E2E
- **Key test files**:
  - `test/integration/api/vg-app-user-auth.js` (72 tests)
  - `test/integration/api/vg-tests-orgAppUsers.js` (22 tests)
  - `test/integration/api/vg-telemetry.js` (13 tests)
  - `test/integration/api/vg-webusers.js` (6 tests)
  - `test/unit/util/vg-password.js` (6 tests)

## Installation

See [[ODK-Central-vg/installation]] for setup instructions.
