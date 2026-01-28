---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #architecture #implementation #database
created: 2026-01-28
---

# ODK Central VG Implementation

> **Source**: `docs/vg/vg-server/vg_implementation.md`

## Overview

VG implements app-user auth through layered architecture: domain (business logic), model (data access), and resources (HTTP endpoints).

## Database Tables

### vg_field_key_auth
One-to-one with `field_keys` by `actorId`. Stores app-user credentials.

| Column | Type | Description |
|--------|------|-------------|
| `actorId` | bigint | Primary key, references `actors.id` |
| `vg_username` | varchar(255) | Login username (lowercase) |
| `vg_password_hash` | varchar(255) | Bcrypt hash |
| `vg_phone` | varchar(25) | Optional phone number |
| `vg_active` | boolean | Active status (default true) |

### vg_settings
Global settings storage.

| Column | Type | Description |
|--------|------|-------------|
| `vg_key_name` | varchar(255) | Setting key (unique) |
| `vg_key_value` | text | Setting value |

### vg_project_settings
Project-level overrides.

| Column | Type | Description |
|--------|------|-------------|
| `project_id` | bigint | References `projects.id` |
| `vg_key_name` | varchar(255) | Setting key |
| `vg_key_value` | text | Setting value |
| **Unique** | `(project_id, vg_key_name)` | |

### vg_app_user_login_attempts
Login attempt tracking for lockouts.

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `username` | varchar(255) | Login username |
| `ip` | varchar(45) | Client IP |
| `succeeded` | boolean | Attempt success |
| `logged_at` | timestamp | Attempt time |

### vg_app_user_lockouts
Active lockout records.

| Column | Type | Description |
|--------|------|-------------|
| `username` | varchar(255) | Locked username |
| `ip` | varchar(45) | Client IP |
| `locked_at` | timestamp | Lock start time |
| `expires_at` | timestamp | Lock expiry time |

### vg_app_user_sessions
Session metadata (preserved after session reap).

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `token` | varchar(64) | References `sessions.token` |
| `actorId` | bigint | References `actors.id` |
| `ip` | varchar(45) | Client IP |
| `user_agent` | text | User agent string |
| `device_id` | text | Device identifier |
| `comments` | text | Session comments |
| `created_at` | timestamp | Session creation |
| `expires_at` | timestamp | Session expiry |

### vg_app_user_telemetry
Device telemetry data.

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `actorId` | bigint | App user ID |
| `project_id` | bigint | Project ID |
| `device_id` | text | Device identifier |
| `collect_version` | varchar(50) | Collect version |
| `device_date_time` | timestamp | Device-generated time |
| `location` | jsonb | Geo coordinates |
| `event_id` | text | Event ID for dedupe |
| `event_type` | text | Event type |
| `event_occurred_at` | timestamp | Event time |
| `event_details` | jsonb | Event details |
| `created_at` | timestamp | Server receive time |

## Core Modules

### Domain Layer

**`server/lib/domain/vg-app-user-auth.js`**
- `createAppUser()` - Validate and create app user
- `updateAppUser()` - Update display name and phone
- `login()` - Enforce lockout, verify password, issue session
- `changePassword()` - Verify old password, enforce policy, rotate sessions
- `resetPassword()` - Admin reset, enforce policy, rotate sessions
- `revokeSessions()` - Terminate sessions
- `setActive()` - Toggle active flag, terminate sessions on deactivate
- `clearLockout()` - Clear login lockouts
- `listSessions()` - List session history
- `listProjectSessions()` - List project sessions

**`server/lib/domain/vg-telemetry.js`**
- `recordTelemetry()` - Validate and insert telemetry

### Query Layer

**`server/lib/model/query/vg-app-user-auth.js`**
- `getSessionTtlDays()` - Get TTL default
- `getSessionCap()` - Get cap default
- `getSettingWithProjectOverride()` - Get effective setting
- `insertAuth()` - Create auth record
- `updatePassword()` - Update password
- `updatePhone()` - Update phone
- `setActive()` - Set active flag
- `recordAttempt()` - Record login attempt
- `getLockStatus()` - Check lockout status
- `recordSession()` - Record session metadata
- `getActiveSessionsByActorId()` - Get user sessions
- `getSessionsByProject()` - Get project sessions

**`server/lib/model/query/vg-telemetry.js`**
- `insertTelemetry()` - Insert telemetry record
- `getTelemetry()` - List telemetry with filters

### Resources Layer

**`server/lib/resources/vg-app-user-auth.js`**
- Maps HTTP routes to domain functions
- Enforces auth/permission checks
- Handles request/response validation

**`server/lib/resources/vg-telemetry.js`**
- `POST /projects/:id/app-users/telemetry` - Capture telemetry
- `GET /system/app-users/telemetry` - Admin listing

## Modified Upstream Behavior

### sessions.js
- Rejects sessions for deactivated app users (`vg_active=false`)
- Web user lockout enforcement
- Audit logging for failures

### field-keys.js
- Joins `vg_field_key_auth` for username/phone/active
- `createWithoutSession()` for VG auth flow

## Endpoint to Handler Mapping

| Endpoint | Handler |
|----------|---------|
| `POST /projects/:id/app-users/login` | `vgAppUserAuth.login()` |
| `POST /projects/:id/app-users/:id/password/change` | `vgAppUserAuth.changePassword()` |
| `POST /projects/:id/app-users/:id/password/reset` | `vgAppUserAuth.resetPassword()` |
| `POST /projects/:id/app-users/:id/revoke` | `vgAppUserAuth.revokeSessions()` (self) |
| `POST /projects/:id/app-users/:id/revoke-admin` | `vgAppUserAuth.setActive(false)` |
| `GET /projects/:id/app-users/:id/sessions` | `vgAppUserAuth.listSessions()` |
| `POST /projects/:id/app-users/:id/active` | `vgAppUserAuth.setActive(active)` |
| `GET /projects/:id/app-users/settings` | `VgAppUserAuth.getSettingWithProjectOverride*()` |
| `PUT /projects/:id/app-users/settings` | `VgAppUserAuth.upsertProjectSetting()` |
| `POST /system/app-users/lockouts/clear` | `vgAppUserAuth.clearLockout()` |
| `POST /projects/:id/app-users/telemetry` | `vgTelemetry.recordTelemetry()` |
| `GET /system/app-users/telemetry` | `VgTelemetry.getTelemetry()` |
| `GET /system/settings` | `VgAppUserAuth.getSessionTtlDays()` + `getSessionCap()` + `getAdminPw()` |
| `PUT /system/settings` | `VgAppUserAuth.upsertSetting()` |

## Audit Events

VG emits `vg.*` actions:
- `vg.app_user.create`
- `vg.app_user.update`
- `vg.app_user.login.success`
- `vg.app_user.login.failure`
- `vg.app_user.password.change`
- `vg.app_user.password.reset`
- `vg.app_user.session.revoke`
- `vg.app_user.activate`
- `vg.app_user.deactivate`
- `vg.app_user.lockout.clear`

## Migration

**File**: `server/docs/sql/vg_app_user_auth.sql`

Creates VG tables and seeds defaults (TTL 3, cap 3).

For Docker setup:
```bash
docker exec -i central-postgres14-1 psql -U odk -d odk < server/docs/sql/vg_app_user_auth.sql
```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/app-user-api]] - API endpoints
- [[ODK-Central-vg/settings]] - Configuration
