---
title: VG Customization Patterns for ODK Central
type: reference
domain: ODK-Central-vg
tags:
  - odk-central
  - vg-fork
  - customization
  - app-user-auth
  - modularity
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# VG Customization Patterns for ODK Central

This document describes the architectural patterns and conventions for maintaining the VG fork of ODK Central (`drguptavivek/central-backend` and `drguptavivek/central-frontend`).

## Critical Principle: Preserve Modularity for Rebasing

**Golden Rule**: Keep VG customizations **isolated and modular** to minimize merge conflicts when rebasing onto upstream `master`.

### Modularity Requirements

1. **Prefer new VG-prefixed files** over modifying core upstream files
2. **Keep upstream file edits minimal** and well-scoped
3. **Document all core file edits** in `server/docs/vg_core_server_edits.md` or `client/docs/vg_core_client_edits.md`
4. **Use VG namespace** for all custom tables, settings, routes, and components

### Example: Good Modularity

✔️ **Good**: Create `lib/resources/vg-app-user-auth.js` and `lib/model/query/vg-app-user-auth.js`
✔️ **Good**: Add single line to `lib/http/service.js` to require the new resource
✔️ **Good**: Minimal change to `lib/model/query/sessions.js` to check `vg_field_key_auth.vg_active`

❌ **Bad**: Heavily modify existing `lib/resources/app-users.js` with VG logic mixed into standard flows
❌ **Bad**: Scatter VG checks throughout multiple upstream files without clear documentation

## VG Namespace Convention

### Database Tables

**Pattern**: Prefix all VG-specific tables with `vg_`

**Examples**:
- `vg_field_key_auth`: App user credentials and active status
- `vg_settings`: Session TTL and cap configuration
- `vg_app_user_login_attempts`: Login attempt tracking for lockouts
- `vg_app_user_sessions`: Session metadata (IP, device ID, comments)
- `vg_app_user_telemetry`: Device telemetry from Collect

**Naming Convention**:
- lowercase snake_case
- pluralized for collection tables
- descriptive of VG feature scope

### Settings Keys

**Pattern**: Prefix all VG-specific settings with `vg_`

**Examples**:
- `vg_app_user_session_ttl_days` (default: 3)
- `vg_app_user_session_cap` (default: 3)

**Storage**: `vg_settings` table (key-value pairs)

### API Routes

**Pattern**: Create new VG-specific endpoints in separate resource files

**Examples**:
- `/projects/:projectId/app-users/login` (VG-only)
- `/projects/:projectId/app-users/:id/password/reset` (VG-only)
- `/projects/:projectId/app-users/:id/revoke` (VG-only)
- `/system/settings` (VG-extended)
- `/system/app-users/telemetry` (VG-only)

**Implementation**: `lib/resources/vg-app-user-auth.js`, `lib/resources/vg-telemetry.js`

### Domain and Query Modules

**Pattern**: Create VG-specific modules for VG features

**Examples**:
- `lib/domain/vg-app-user-auth.js`
- `lib/domain/vg-telemetry.js`
- `lib/model/query/vg-app-user-auth.js`
- `lib/model/query/vg-telemetry.js`

**Container Registration**: Add to `lib/model/container.js`:
```javascript
const defaultQueries = {
  // ... existing queries
  VgAppUserAuth: require('./query/vg-app-user-auth'),
  VgTelemetry: require('./query/vg-telemetry'),
};
```

### Audit Event Identifiers

**Pattern**: Use VG-prefixed action names for audit logs

**Examples**:
- `vg.app_user.create`
- `vg.app_user.login_success`
- `vg.app_user.login_failure`
- `vg.app_user.password_reset`
- `vg.app_user.revoke_sessions`
- `vg.app_user.activate` / `vg.app_user.deactivate`

### UI Components (Client)

**Pattern**: Prefix VG-specific Vue components and routes with `vg-`

**Examples**:
- `VgSettings.vue` (System settings UI)
- `VgAppUserLogin.vue` (App user login UI)
- `/system/settings` (route for VG system settings)

## VG Feature: App User Authentication

### Overview

VG replaces long-lived QR code tokens with username/password-based short-lived sessions for app users (field keys).

### Architecture Pattern

**Three-Layer Implementation**:

1. **Resources Layer** (`lib/resources/vg-app-user-auth.js`):
   - HTTP endpoints for login, password reset/change, session management
   - Request validation and auth checks
   - Response formatting

2. **Domain Layer** (`lib/domain/vg-app-user-auth.js`):
   - Business logic: password policy, lockout enforcement, session TTL/cap
   - Audit logging
   - Multi-step orchestration (e.g., login → session creation → session trimming)

3. **Query Layer** (`lib/model/query/vg-app-user-auth.js`):
   - SQL queries for `vg_field_key_auth`, `vg_settings`, `vg_app_user_login_attempts`, `vg_app_user_sessions`
   - Session metadata storage and retrieval

### Core Edits Required

**Minimal Upstream Changes**:
1. `lib/http/service.js`: Register VG resource
2. `lib/model/container.js`: Register VG query modules
3. `lib/model/query/sessions.js`: Check `vg_active` for field_key sessions
4. `lib/model/query/field-keys.js`: Join `vg_field_key_auth` for active status
5. `lib/model/query/actors.js`: Add `updateDisplayName()` helper
6. `lib/resources/app-users.js`: Call VG domain functions for create/update
7. `lib/util/problem.js`: Add `passwordWeak` error code

**Documented In**: `server/docs/vg_core_server_edits.md` (with diffs)

### Key Behavior Changes

**App User Creation**:
- Standard: `FieldKeys.create()` issues 9999-year session
- VG: `FieldKeys.createWithoutSession()` + `VgAppUserAuth.insertAuth()` + no initial session

**App User Listing**:
- Standard: Returns `token` field with active long-lived token
- VG: Returns `token: null`, plus `active`, `username`, `phone` from VG auth

**Session Management**:
- Standard: Single long-lived session per app user
- VG: Multiple short-lived sessions (cap enforced), TTL-based expiry, no sliding refresh

**Authentication**:
- Standard: Bearer token issued at creation, embedded in QR code
- VG: Bearer token issued only after `/login` success, expires after TTL

### Password Policy (VG)

**Requirements**:
- Minimum 10 characters
- At least one uppercase, one lowercase, one digit, one special (`~!@#$%^&*()_+-=,.`)

**Implementation**: `lib/domain/vg-app-user-auth.js` → `validatePassword()`

### Lockout Policy (VG)

**Rules**:
- 5 failed login attempts (username + IP) within 5 minutes → 10-minute lockout
- Failed attempts tracked in `vg_app_user_login_attempts`

**Implementation**: `lib/domain/vg-app-user-auth.js` → `getLockStatus()`

### Session TTL and Cap (VG)

**Configuration**:
- Stored in `vg_settings` table
- Defaults: TTL = 3 days, Cap = 3 active sessions

**Enforcement**:
- TTL: Sessions expire at fixed time (no sliding refresh)
- Cap: On login, oldest sessions beyond cap are deleted via `Sessions.trimByActorId()`

**Admin UI**: `/system/settings` (VG-specific route)

## VG Feature: App User Telemetry

### Overview

VG captures device telemetry (deviceId, Collect version, device timestamp, location) from authenticated app users.

### Architecture Pattern

1. **Resources Layer** (`lib/resources/vg-telemetry.js`):
   - `POST /projects/:projectId/app-users/telemetry` (app user endpoint)
   - `GET /system/app-users/telemetry` (system admin endpoint with filters)

2. **Domain Layer** (`lib/domain/vg-telemetry.js`):
   - Validate telemetry payload (required fields, UTC timestamps, location)
   - Map authenticated actor to app user

3. **Query Layer** (`lib/model/query/vg-telemetry.js`):
   - Insert telemetry into `vg_app_user_telemetry`
   - Paginated listing with filters (projectId, deviceId, appUserId, dateFrom/dateTo)

### Telemetry Payload

**Required Fields**:
- `deviceId` (string)
- `collectVersion` (string)
- `deviceDateTime` (UTC ISO string, ending in `Z` or `+00:00`)
- `location` (object with `latitude`, `longitude`; optional: `altitude`, `accuracy`, `speed`, `bearing`, `provider`)

**Validation**: `lib/domain/vg-telemetry.js` → `validateTelemetryPayload()`

### Pagination Pattern (VG)

**VG Extension**: Use `X-Total-Count` header for paginated listings

**Implementation Pattern**:
```javascript
const getTelemetry = (filters = {}, options = QueryOptions.none) => ({ all }) =>
  all(sql`
    SELECT
      count(*) OVER () AS total_count,
      /* ... other fields */
    FROM vg_app_user_telemetry
    WHERE ${filterConditions(filters)}
    ORDER BY "dateTime" DESC
    ${page(options)}
  `);
```

**Resource Layer**:
```javascript
service.get('/system/app-users/telemetry', endpoint(
  ({ VgTelemetry }, { queryOptions }, __, response) =>
    VgTelemetry.getTelemetry(filters, queryOptions)
      .then((rows) => {
        const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
        response.set('X-Total-Count', total);
        return rows.map(formatRow);
      })
));
```

**Key Pattern**: Use `count(*) OVER ()` window function to get total count without separate query.

## Testing Pattern (VG)

### Fixture Setup

**Pattern**: Create VG tables via test fixtures, not SQL migrations

**Location**: `server/test/integration/fixtures/03-vg-app-user-auth.js`

**Why**: Test DB schema managed by fixtures; production DB uses `server/docs/sql/vg_app_user_auth.sql`

### Test Organization

**VG-Specific Test Files**:
- `test/integration/api/vg-app-user-auth.js`
- `test/integration/api/vg-telemetry.js`

**Pattern**: Keep VG tests separate from upstream tests to avoid merge conflicts

**Legacy Tests**: Upstream app-user tests in `test/integration/api/app-users.js` remain for standard flow

### Test Isolation

**Good Practice**:
- Test VG behavior in VG-specific test files
- Minimize changes to upstream test files
- Document test coverage in `server/docs/vg_tests.md`

## VG Documentation Structure

### Required VG Docs (Server)

**Location**: `server/docs/`

1. **vg_overview.md**: High-level scope and key changes
2. **vg_api.md**: API reference for all VG endpoints (frontend-oriented)
3. **vg_implementation.md**: File-by-file implementation details
4. **vg_settings.md**: Configuration keys and defaults
5. **vg_core_server_edits.md**: **Critical** - Diff log of all upstream file changes
6. **vg_tests.md**: Test coverage and organization
7. **vg_user_behavior.md**: Expected behavior from user perspective

### vg_core_server_edits.md Format

**Purpose**: Enable auditing of rebase conflicts and upstream changes

**Format**:
```markdown
- Date: YYYY-MM-DD
  File: lib/path/to/file.js
  Change summary: Brief description
  Reason: Why this change was needed
  Risk/notes: Rebase conflict likelihood
  Related commits/PRs: vg-work history
  Diff:
  ```diff
  [actual git diff]
  ```
```

**Example**:
```markdown
- Date: 2025-12-21
  File: lib/model/query/sessions.js
  Change summary: Require vg_field_key_auth presence to authenticate field_key sessions.
  Reason: Block legacy long-lived field-key tokens without VG auth records.
  Risk/notes: High; app-user authentication behavior.
  Related commits/PRs: vg-work history
  Diff:
  [diff content]
```

## Rebase Workflow

### Before Rebasing onto Upstream

1. **Review vg_core_server_edits.md**: Identify all upstream files touched by VG
2. **Check upstream changes**: `git diff upstream/master..HEAD -- <file>` for each VG-edited file
3. **Plan conflict resolution**: Decide how to re-apply VG changes if upstream modified same files

### After Rebasing

1. **Verify core edits**: Ensure all VG changes from `vg_core_server_edits.md` are still present
2. **Update docs**: Add new entries to `vg_core_server_edits.md` if rebase introduced new edits
3. **Run VG tests**: `npm test test/integration/api/vg-*` to verify functionality

### Minimizing Rebase Pain

**Strategy**:
- Rebase every 3-6 months (not too frequent, not too stale)
- Keep VG changes in isolated files whenever possible
- Use single-line integrations in upstream files (e.g., `require('./vg-resource')`)

## Client-Side VG Patterns

### UI Component Prefixing

**Pattern**: Prefix all VG-specific Vue components with `Vg`

**Examples**:
- `VgSettings.vue`
- `VgAppUserLogin.vue`
- `VgAppUserSessions.vue`

### Route Naming

**Pattern**: Use `/system/settings` or `/projects/:id/app-users/...` routes for VG features

**Implementation**: `client/src/routes.js`

### Dev Environment

**VG Extensions**:
- Dockerized Vite dev container (`client/Dockerfile.dev`)
- Dev proxy defaults to `https://central.local`
- Self-signed cert with SANs for `DOMAIN` and `EXTRA_SERVER_NAME`

**Configuration**: `docker-compose.vg-dev.yml` overrides

## Related

- [[server-architecture-patterns]] - Standard ODK Central patterns
- [[git-submodule-workflows]] - Managing client/server submodules

## References

- CLAUDE.md - VG fork workflow and branch policy
- server/docs/vg_core_server_edits.md - Authoritative log of upstream edits
- server/docs/vg_api.md - VG API reference
- server/docs/vg_implementation.md - Implementation details
