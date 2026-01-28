---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #security #lockout #rate-limiting #password-policy
created: 2026-01-28
---

# ODK Central VG Security Controls

> **Source**: `docs/vg/vg-server/vg_security.md`

## Overview

VG implements comprehensive security controls for both app users and web users, including password policies, session management, login throttling, and audit logging.

## Password Policy

**Server-enforced** for app users:

| Requirement | Value |
|-------------|-------|
| Minimum length | 10 characters |
| Maximum length | 72 characters |
| Uppercase | At least one (A-Z) |
| Lowercase | At least one (a-z) |
| Digit | At least one (0-9) |
| Special | At least one (`~!@#$%^&*()_+-=,.`) |

**Enforced on**: Create, change password, reset password operations

**Validation**: `server/lib/util/vg-password.js`

## Session Management

### Session Expiry (TTL)

- **Default**: 3 days (`vg_app_user_session_ttl_days`)
- **Project override**: Supported via `vg_project_settings`
- **No sliding refresh**: Fixed expiry at issuance

### Concurrent Session Cap

- **Default**: 3 sessions (`vg_app_user_session_cap`)
- **Behavior**: Oldest sessions revoked when cap exceeded
- **Project override**: Supported

### Activation/Revocation

| Action | Behavior |
|--------|----------|
| Deactivate | Immediately revokes all sessions, blocks auth |
| Reactivate | Restores authentication ability |
| Password change | Terminates existing sessions (forces re-login) |
| Admin reset | Terminates existing sessions |
| Self revoke | Revokes current session only |

## Login Throttling and Lockouts

### App User Lockout (Per Username + IP)

**Default settings**:
- **Max failures**: 5 (`vg_app_user_lock_max_failures`)
- **Window**: 5 minutes (`vg_app_user_lock_window_minutes`)
- **Duration**: 10 minutes (`vg_app_user_lock_duration_minutes`)

**Tracking**: `vg_app_user_login_attempts` table

**Lockout storage**: `vg_app_user_lockouts` table

**Project override**: Supported

**Admin clear**: `POST /system/app-users/lockouts/clear`

### App User IP Rate Limiting

Prevents username enumeration attacks:

**Settings**:
- **Max failures**: 20 (`vg_app_user_ip_max_failures`)
- **Window**: 15 minutes (`vg_app_user_ip_lock_window_minutes`)
- **Duration**: 30 minutes (`vg_app_user_ip_lock_duration_minutes`)

**Tracking**: By IP address only (independent of username)

**Project override**: Supported

### Web User Lockout (`/v1/sessions`)

**Non-OIDC only**:

**Settings**:
- **Max failures**: 5
- **Window**: 5 minutes
- **Duration**: 10 minutes (configurable via `vg_web_user_lock_duration_minutes`)

**Features**:
- Failed login audits with normalized identifiers
- Retry-After header on lockout
- X-Login-Attempts-Remaining header
- Timing normalization (prevents account enumeration)

## Auditing

### VG Audit Actions

All VG actions emit `vg.*` audit events:

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

### Web User Audit Actions

- `user.session.create.failure`
- `user.session.lockout`

## Managed QR and admin_pw

**Purpose**: QR codes for ODK Collect settings lock

**Payload structure**:
```json
{
  "general": {
    "server_url": "https://central.local/v1/projects/1",
    "username": "app_user",
    "form_update_mode": "match_exactly",
    "automatic_update": true,
    "delete_send": false,
    "default_completed": false,
    "analytics": true,
    "metadata_username": "App User Display Name"
  },
  "admin": {
    "change_server": false,
    "admin_pw": "vg_custom"
  },
  "project": {
    "name": "Project Name",
    "project_id": "1"
  }
}
```

**Security note**: `admin_pw` is intentionally stored as plain text because it must be included in the managed QR payload. Treat as a shared secret, not a per-user credential.

**Configuration**:
- Global: `vg_settings.admin_pw`
- Project override: `vg_project_settings.admin_pw`

## Configuration

### UI/API Exposed Settings

| Endpoint | Purpose |
|----------|---------|
| `GET /system/settings` | Get global defaults |
| `PUT /system/settings` | Update global defaults |
| `GET /projects/:id/app-users/settings` | Get project settings |
| `PUT /projects/:id/app-users/settings` | Update project settings |
| `POST /system/app-users/lockouts/clear` | Clear lockouts |

### DB-Only Settings

Some lockout settings are DB-only (no UI):
- `vg_app_user_lock_max_failures`
- `vg_app_user_lock_window_minutes`
- `vg_app_user_lock_duration_minutes`
- `vg_app_user_ip_max_failures`
- `vg_app_user_ip_lock_window_minutes`
- `vg_app_user_ip_lock_duration_minutes`
- `vg_web_user_lock_duration_minutes`

Update via SQL:
```sql
-- Global
UPDATE vg_settings SET vg_key_value = '15' WHERE vg_key_name = 'vg_app_user_lock_duration_minutes';

-- Project override
INSERT INTO vg_project_settings (project_id, vg_key_name, vg_key_value)
VALUES (123, 'vg_app_user_lock_duration_minutes', '15')
ON CONFLICT (project_id, vg_key_name) DO UPDATE SET vg_key_value = EXCLUDED.vg_key_value;
```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/authentication-patterns]] - Auth types
- [[ODK-Central-vg/settings]] - Configuration details
