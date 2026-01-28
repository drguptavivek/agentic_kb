---
domain: ODK-Central-vg
type: howto
status: approved
tags: #odk #vg-fork #installation #setup #docker
created: 2026-01-28
---

# ODK Central VG Installation

> **Source**: `docs/vg/vg-server/vg_installation.md`

## Prerequisites

- ODK Central backend set up per upstream instructions
- Docker environment running
- Database access for schema migrations

## Step 1: Apply VG Schema Migration

Run the VG SQL migration to create tables and seed defaults:

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk < server/docs/sql/vg_app_user_auth.sql
```

### What This Creates

| Table | Purpose |
|-------|---------|
| `vg_field_key_auth` | App user credentials |
| `vg_settings` | Global settings |
| `vg_project_settings` | Project overrides |
| `vg_app_user_login_attempts` | Login tracking |
| `vg_app_user_lockouts` | Lockout records |
| `vg_app_user_sessions` | Session metadata |
| `vg_app_user_telemetry` | Device telemetry |

### Seeded Defaults

- Session TTL: 3 days
- Session cap: 3
- Lock max failures: 5
- Lock window: 5 minutes
- Lock duration: 10 minutes
- admin_pw: `vg_custom`

## Step 2: Verify Installation

### Check Tables

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk -c "\dt vg_*"
```

Expected output:
```
              List of relations
 Schema |           Name           | Type  |  Owner
--------+-------------------------+-------+----------
 public | vg_app_user_lockouts    | table | odk
 public | vg_app_user_login_attempts | table | odk
 public | vg_app_user_sessions    | table | odk
 public | vg_app_user_telemetry   | table | odk
 public | vg_field_key_auth       | table | odk
 public | vg_project_settings     | table | odk
 public | vg_settings             | table | odk
```

### Check Settings

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk -c \
  "SELECT vg_key_name, vg_key_value FROM vg_settings WHERE vg_key_name IN \
  ('vg_app_user_session_ttl_days', 'vg_app_user_session_cap');"
```

Expected output:
```
            vg_key_name             | vg_key_value
-------------------------------------+---------------
 vg_app_user_session_ttl_days        | 3
 vg_app_user_session_cap             | 3
```

## Step 3: Start Services

```bash
# Development (with modsecurity + dev tools)
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml up -d

# Or production (with modsecurity only)
docker compose up -d
```

## Step 4: Create Admin User

```bash
# Create user
docker compose --env-file .env exec service odk-cmd --email you@example.com user-create

# Promote to admin
docker compose exec service odk-cmd --email you@example.com user-promote
```

## Step 5: Configure System Settings (Optional)

Admins can update session settings via API:

```bash
# Get current settings
curl -X GET https://central.local/v1/system/settings \
  -H "Authorization: Bearer <token>"

# Update settings
curl -X PUT https://central.local/v1/system/settings \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "vg_app_user_session_ttl_days": 5,
    "vg_app_user_session_cap": 5,
    "admin_pw": "secure_admin_pw"
  }'
```

## Step 6: Create Project

Create a project in the Central web UI (app users are project-scoped).

## Step 7: Create App User

Using the Central web UI (Project > App Users), create an app user with:
- `username` (required)
- Display name
- `password` (required)
- Phone (optional)

## Step 8: Verify Installation

### Test Login

```bash
curl -X POST https://central.local/v1/projects/1/app-users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test-user",
    "password": "GoodPass!1X",
    "deviceId": "test-device"
  }'
```

Expected response:
```json
{
  "id": 1,
  "token": "...",
  "projectId": 1,
  "expiresAt": "...",
  "serverTime": "..."
}
```

### Run Tests

```bash
# App user auth tests
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha --recursive test/integration/api/vg-app-user-auth.js'

# Telemetry tests
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha test/integration/api/vg-telemetry.js'
```

## Manual Lockout Clear

If an app user gets locked out:

```sql
-- Clear lockout for specific user+IP
docker exec -i central-postgres14-1 psql -U odk -d odk -c \
  "DELETE FROM vg_app_user_login_attempts WHERE username='user' AND ip='1.2.3.4' AND succeeded=false;"

-- Or use API
curl -X POST https://central.local/v1/system/app-users/lockouts/clear \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "ip": "1.2.3.4"}'
```

## Upgrading

For existing VG installs, re-run the migration to add new columns:

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk < server/docs/sql/vg_app_user_auth.sql
```

The migration uses `ON CONFLICT DO NOTHING` for safe re-runs.

## Troubleshooting

### Check Session History

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk -c \
  "SELECT * FROM vg_app_user_sessions WHERE \"actorId\" = 123 ORDER BY \"createdAt\" DESC LIMIT 10;"
```

### Check Lockouts

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk -c \
  "SELECT * FROM vg_app_user_lockouts WHERE expires_at > now();"
```

### Check Settings

```bash
docker exec -i central-postgres14-1 psql -U odk -d odk -c \
  "SELECT * FROM vg_settings;"

docker exec -i central-postgres14-1 psql -U odk -d odk -c \
  "SELECT * FROM vg_project_settings WHERE project_id = 123;"
```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/settings]] - Configuration details
- [[ODK-Central-vg/testing]] - Test verification
