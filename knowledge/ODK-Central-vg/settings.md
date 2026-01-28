---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #settings #configuration
created: 2026-01-28
---

# ODK Central VG Settings

> **Source**: `docs/vg/vg-server/vg_settings.md`

## Overview

VG stores configuration in the `vg_settings` table with optional project-level overrides in `vg_project_settings`.

## Default Settings

### Seeded by Migration

| Key | Default | Description |
|-----|---------|-------------|
| `vg_app_user_session_ttl_days` | 3 | Session time-to-live in days |
| `vg_app_user_session_cap` | 3 | Max concurrent sessions per user |
| `vg_app_user_lock_max_failures` | 5 | Max failed attempts before lockout |
| `vg_app_user_lock_window_minutes` | 5 | Time window for counting failures |
| `vg_app_user_lock_duration_minutes` | 10 | How long to lock account |
| `admin_pw` | `vg_custom` | Admin password for QR codes |

### IP Rate Limiting Settings

| Key | Default | Description |
|-----|---------|-------------|
| `vg_app_user_ip_max_failures` | 20 | Max IP failures before lockout |
| `vg_app_user_ip_lock_window_minutes` | 15 | IP time window for failures |
| `vg_app_user_ip_lock_duration_minutes` | 30 | IP lockout duration |

### Web User Settings

| Key | Default | Description |
|-----|---------|-------------|
| `vg_web_user_lock_duration_minutes` | 10 | Web user lockout duration |

## Settings Hierarchy

Settings are resolved in this order:
1. Project override (`vg_project_settings`)
2. Global default (`vg_settings`)
3. Runtime default (for some keys)

## Update Methods

### API (UI Exposed)

| Endpoint | Purpose | Auth |
|----------|---------|------|
| `GET /system/settings` | Get global defaults | `config.read` |
| `PUT /system/settings` | Update global defaults | `config.set` |
| `GET /projects/:id/app-users/settings` | Get project settings | `project.read` |
| `PUT /projects/:id/app-users/settings` | Update project settings | `project.update` |

### DB-Only (No UI)

Some settings require direct DB updates:

```sql
-- Update global setting
UPDATE vg_settings
SET vg_key_value = '15'
WHERE vg_key_name = 'vg_app_user_lock_duration_minutes';

-- Add project override
INSERT INTO vg_project_settings (project_id, vg_key_name, vg_key_value)
VALUES (123, 'vg_app_user_lock_duration_minutes', '15')
ON CONFLICT (project_id, vg_key_name)
DO UPDATE SET vg_key_value = EXCLUDED.vg_key_value;
```

## Settings by Feature

### Session Management

**TTL** (`vg_app_user_session_ttl_days`):
- Type: Positive integer
- Unit: Days
- Default: 3
- Project override: Yes
- API exposed: Yes

**Cap** (`vg_app_user_session_cap`):
- Type: Positive integer
- Unit: Count
- Default: 3
- Project override: Yes
- API exposed: Yes

### App User Lockout

**Max failures** (`vg_app_user_lock_max_failures`):
- Type: Positive integer
- Default: 5
- Project override: Yes
- API exposed: No

**Window** (`vg_app_user_lock_window_minutes`):
- Type: Positive integer
- Unit: Minutes
- Default: 5
- Project override: Yes
- API exposed: No

**Duration** (`vg_app_user_lock_duration_minutes`):
- Type: Positive integer
- Unit: Minutes
- Default: 10
- Project override: Yes
- API exposed: No

### App User IP Rate Limiting

**Max failures** (`vg_app_user_ip_max_failures`):
- Type: Positive integer
- Default: 20
- Project override: Yes
- API exposed: No

**Window** (`vg_app_user_ip_lock_window_minutes`):
- Type: Positive integer
- Unit: Minutes
- Default: 15
- Project override: Yes
- API exposed: No

**Duration** (`vg_app_user_ip_lock_duration_minutes`):
- Type: Positive integer
- Unit: Minutes
- Default: 30
- Project override: Yes
- API exposed: No

### Web User Lockout

**Duration** (`vg_web_user_lock_duration_minutes`):
- Type: Positive integer
- Unit: Minutes
- Default: 10
- Project override: No
- API exposed: No
- Fallback: 10 if missing/invalid

### Managed QR

**admin_pw**:
- Type: String
- Max length: 72
- Default: `vg_custom`
- Project override: Yes
- API exposed: Yes
- **Important**: Stored as plain text (shared secret, not per-user credential)

## Validation

### TTL & Cap
- Parsed as positive integers
- DB constraints enforce positive values

### Lock Settings
- Parsed as positive integers
- DB constraints enforce positive values

### admin_pw
- Max 72 characters
- API rejects empty/blank values
- No complexity requirements
- No encryption (plain text for QR inclusion)

## QR Code Payload

The `admin_pw` is included in managed QR codes:

```json
{
  "admin": {
    "change_server": false,
    "admin_pw": "vg_custom"
  }
}
```

Payload processing:
1. Serialized to JSON
2. Compressed via zlib DEFLATE
3. Base64 encoded
4. Encoded into QR code

## Verification

### Check Settings

```sql
-- View all settings
SELECT vg_key_name, vg_key_value FROM vg_settings;

-- View project overrides
SELECT project_id, vg_key_name, vg_key_value FROM vg_project_settings;
```

### Effective Settings

The API returns the effective value (project override or global):

```bash
curl -H "Authorization: Bearer <token>" \
  https://central.local/v1/projects/1/app-users/settings
```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/security-controls]] - Security features
- [[ODK-Central-vg/app-user-api]] - API endpoints
