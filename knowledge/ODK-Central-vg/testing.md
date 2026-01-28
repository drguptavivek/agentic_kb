---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #testing #test-coverage
created: 2026-01-28
---

# ODK Central VG Testing

> **Source**: `docs/vg/vg-server/vg_tests.md`

## Test Inventory

### Summary

| Category | File | Tests | Status |
|----------|------|-------|--------|
| Integration | `vg-app-user-auth.js` | 72 | ✅ Pass |
| Integration | `vg-tests-orgAppUsers.js` | 22 | ✅ Pass |
| Integration | `vg-telemetry.js` | 13 | ✅ Pass |
| Integration | `vg-webusers.js` | 6 | ✅ Pass |
| Integration | `vg-web-user-ip-rate-limit.js` | 11 | ✅ Pass |
| Integration | `vg-web-user-lockout.js` | 16 | ✅ Pass |
| Integration | `vg-app-user-ip-rate-limit.js` | 12 | ✅ Pass |
| Integration | `vg-enketo-status.js` | 5 | ✅ Pass |
| Integration | `vg-enketo-status-domain.js` | 3 | ✅ Pass |
| Integration | `vg-enketo-status-api.js` | 6 | ✅ Pass |
| Unit | `vg-password.js` | 6 | ✅ Pass |
| Unit | `vg-app-user-auth.js` | 1 | ✅ Pass |
| **Total** | | **173** | ✅ **Pass** |

## Test Commands

### App User Auth
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha --recursive test/integration/api/vg-app-user-auth.js'
```

### Org App Users
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha test/integration/api/vg-tests-orgAppUsers.js'
```

### Telemetry
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha test/integration/api/vg-telemetry.js'
```

### Web Users
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha test/integration/api/vg-webusers.js'
```

### Password Policy (Unit)
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha test/unit/util/vg-password.js'
```

### Domain (Unit)
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha test/unit/domain/vg-app-user-auth.js'
```

## Test Scenarios

### App User Auth

| Scenario | Coverage |
|----------|----------|
| Create app user (no long-lived session) | ✅ |
| Login issues short token + projectId | ✅ |
| Session TTL ≈ 3 days | ✅ |
| Lockout policy (5 failures/5min → 10min lock) | ✅ |
| Lockout recovery after window | ✅ |
| Session caps (default 3, DB override 2) | ✅ |
| Fourth login prunes oldest | ✅ |
| Audit logging across lifecycle | ✅ |
| Password change resets sessions | ✅ |
| Admin reset blocks login | ✅ |
| Deactivate blocks authentication | ✅ |
| Deactivated token rejected | ✅ |
| Username rules (normalized, duplicates, blank) | ✅ |
| RBAC guards (self-only, block web users) | ✅ |
| Expired token rejection | ✅ |

### Org App Users (Submission)

| Scenario | Coverage |
|----------|----------|
| Happy path via /key/:token | ✅ |
| Submission denied after admin revoke | ✅ |
| Submission denied when deactivated | ✅ |
| Submission denied for unassigned form | ✅ |
| Expired token rejected | ✅ |
| Foreign project token rejected | ✅ |
| Malformed token rejected | ✅ |
| Old token fails after password change | ✅ |
| New token works after password change | ✅ |

### Telemetry

| Scenario | Coverage |
|----------|----------|
| Capture + admin listing | ✅ |
| Filters (projectId, deviceId, appUserId) | ✅ |
| Date range filters | ✅ |
| Pagination | ✅ |

### Web User Hardening

| Scenario | Coverage |
|----------|----------|
| Failed login audits | ✅ |
| Lockout duration | ✅ |
| Attempts remaining header | ✅ |
| Retry-After header | ✅ |
| Timing normalization | ✅ |

### Rate Limiting

| Scenario | Coverage |
|----------|----------|
| IP-based (20/15min → 30min lock) | ✅ |
| Time window filtering | ✅ |
| Different IPs tracked separately | ✅ |
| Settings API validation | ✅ |
| Project overrides | ✅ |
| App users blocked from settings | ✅ |
| Cross-project access blocked | ✅ |

### Enketo Status

| Scenario | Coverage |
|----------|----------|
| Status summary across all projects | ✅ |
| Count by status type | ✅ |
| Filter by projectId | ✅ |
| Determine closed status | ✅ |
| Regenerate enketoId (domain) | ✅ |
| API endpoints (GET/POST system/enketo-status) | ✅ |
| RBAC (config.read/config.set) | ✅ |

### Unit Tests

| Scenario | Coverage |
|----------|----------|
| Password policy accept | ✅ |
| Password too short | ✅ |
| Missing special char | ✅ |
| Missing uppercase | ✅ |
| Missing lowercase | ✅ |
| Missing digit | ✅ |
| Self revoke requires current session | ✅ |

## Test Database Setup

```bash
# Create test DB
docker exec -e PGPASSWORD=odk central-postgres14-1 psql -U odk -c "CREATE DATABASE odk_integration_test OWNER odk_test_user"

# Apply VG schema to test DB
docker exec -i central-postgres14-1 psql -U odk -d odk_integration_test < server/docs/sql/vg_app_user_auth.sql
```

**Note**: The test suite uses fixtures (`server/test/integration/fixtures/03-vg-app-user-auth.js`) to create VG tables in the test DB. The SQL file is for manual setup only.

## Running All Tests

```bash
# Run all VG tests
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml exec service sh -lc \
  'cd /usr/odk && NODE_CONFIG_ENV=test BCRYPT=insecure npx mocha \
  test/integration/api/vg-app-user-auth.js \
  test/integration/api/vg-tests-orgAppUsers.js \
  test/integration/api/vg-telemetry.js \
  test/integration/api/vg-webusers.js \
  test/integration/api/vg-web-user-ip-rate-limit.js \
  test/integration/api/vg-web-user-lockout.js \
  test/integration/api/vg-app-user-ip-rate-limit.js \
  test/integration/api/vg-enketo-status.js \
  test/integration/api/vg-enketo-status-domain.js \
  test/integration/api/vg-enketo-status-api.js \
  test/unit/util/vg-password.js \
  test/unit/domain/vg-app-user-auth.js'
```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/implementation]] - Architecture details
