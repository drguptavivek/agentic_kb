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
  - session-management
  - cross-tab-sync
  - frontend-patterns
  - testing-patterns
status: approved
created: 2025-12-25
updated: 2026-02-07
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

## VG Feature: Session Inactivity Auto-Logout (Client)

### Overview

VG implements automatic logout after 30 minutes of user inactivity in the frontend. Activity in any browser tab resets the timer for all tabs.

### Architecture Pattern: Cross-Tab Synchronization

**Challenge**: Browser tabs don't share JavaScript state. Each tab runs independently.

**Solution**: Use localStorage + storage events for cross-tab communication.

**Key Implementation Pattern**:

```javascript
// 1. Track activity timestamp in localStorage
export const setLastActivityAt = (millis = Date.now()) => {
  localStorage.setItem('vgSessionLastActivityAt', millis.toString());
};

// 2. Listen for storage events (fires when OTHER tabs write to localStorage)
export const attachActivityStorageListener = (callback) => {
  const handler = (event) => {
    if (event.key === 'vgSessionLastActivityAt' && event.newValue != null) {
      callback(); // Activity detected from another tab
    }
  };
  window.addEventListener('storage', handler);
  return () => window.removeEventListener('storage', handler);
};

// 3. In session management hook
export const useSessions = () => {
  const checkInactivity = logOutAfterInactivity(container);

  // Attach activity listeners in THIS tab
  const activityHandler = createInactivityActivityHandler();
  const removeInactivityListeners = attachInactivityListeners(activityHandler);

  // Listen for activity from OTHER tabs
  const removeActivityStorageListener = attachActivityStorageListener(() => {
    checkInactivity(); // Re-check immediately when other tab has activity
  });

  onBeforeUnmount(() => {
    removeInactivityListeners();
    removeActivityStorageListener();
  });
};
```

**Why This Works**:
- `storage` event fires only in **other tabs**, not the tab that wrote the value
- When Tab A has activity → writes to localStorage → Tab B receives storage event → Tab B re-checks inactivity timer
- All tabs share the same `lastActivityAt` timestamp
- Prevents inactive tabs from logging out active tabs

### Inactivity Tracking Pattern

**Requirements**:
- Track user activity events (click, keydown, mousemove, etc.)
- Throttle localStorage updates to avoid excessive I/O
- Show warning before auto-logout
- Reset warning when activity resumes

**Implementation**:

```javascript
// 1. Throttled activity handler (max once per 15 seconds)
export const createInactivityActivityHandler = (throttleMillis = 15000) => {
  let lastSavedAt = 0;
  return () => {
    const now = Date.now();
    if (now - lastSavedAt < throttleMillis) return;
    setLastActivityAt(now);
    lastSavedAt = now;
  };
};

// 2. Attach listeners for activity events
const activityEvents = ['click', 'keydown', 'mousedown', 'mousemove', 'scroll', 'touchstart'];

export const attachInactivityListeners = (handler) => {
  for (const event of activityEvents)
    window.addEventListener(event, handler, { passive: true });
  return () => {
    for (const event of activityEvents)
      window.removeEventListener(event, handler);
  };
};

// 3. Check inactivity with warning logic
const logOutAfterInactivity = (container) => {
  const { i18n, requestData, alert, router } = container;
  let lastActivityWhenWarned = null;

  return () => {
    if (router.currentRoute.value.meta.skipAutoLogout) return;
    if (!requestData.session.dataExists) return;

    const now = Date.now();
    const lastActivityAt = getLastActivityAt();
    if (lastActivityAt == null) return;

    const millisSinceActivity = now - lastActivityAt;
    const millisUntilLogout = inactivityLogoutMillis - millisSinceActivity;

    // Reset warning if there was activity since last warning
    if (lastActivityWhenWarned != null && lastActivityAt > lastActivityWhenWarned) {
      lastActivityWhenWarned = null;
    }

    // Log out if timeout reached
    if (millisUntilLogout <= 0) {
      logOut(container, true)
        .then(() => { alert.info(i18n.t('util.session.alert.expired')); })
        .catch(noop);
    }
    // Warn 3 minutes before timeout
    else if (millisUntilLogout <= 180000 && lastActivityWhenWarned == null) {
      alert.info(i18n.t('util.session.alert.expiresSoon'));
      lastActivityWhenWarned = lastActivityAt;
    }
  };
};
```

**Key Patterns**:
- **Throttling**: Prevents localStorage writes on every mousemove (would cause performance issues)
- **Warning state**: Tracks when warning was shown using closure variable
- **Warning reset**: Compares `lastActivityWhenWarned` to `lastActivityAt` to detect new activity
- **Passive listeners**: `{ passive: true }` prevents scroll jank

### Testing Pattern: Fake Timers + Cross-Tab Scenarios

**Challenge**: Testing time-based behavior and cross-tab communication.

**Solution**: Use Sinon fake timers + StorageEvent simulation.

**Pattern**:

```javascript
describe('logout after inactivity', () => {
  let clock;

  beforeEach(() => {
    clock = sinon.useFakeTimers(); // Mock Date.now() and setTimeout
  });

  afterEach(() => {
    clock.restore(); // CRITICAL: Restore real timers to prevent test pollution
  });

  it('logs out after inactivity timeout is reached', () => {
    // ... setup ...
    return mockHttp(container)
      .request(() => logIn(container, true))
      .respondWithData(() => testData.extendedUsers.first())
      .testNoRequest(() => {
        clock.tick(inactivityLogoutMillis - 15000); // Advance to 29:45
      })
      .request(() => {
        clock.tick(15000); // Advance to 30:00 → triggers logout
      })
      .respondWithSuccess()
      .afterResponse(() => {
        session.dataExists.should.be.false;
      });
  });

  it('prevents logout when activity detected from other tabs', () => {
    // ... setup ...
    return mockHttp(container)
      .request(() => logIn(container, true))
      .respondWithData(() => testData.extendedUsers.first())
      .testNoRequest(() => {
        clock.tick(inactivityLogoutMillis - 30000); // Near timeout

        // Simulate activity in another tab
        const now = Date.now();
        localStorage.setItem(inactivityStorageKey, now.toString());
        window.dispatchEvent(new StorageEvent('storage', {
          key: inactivityStorageKey,
          newValue: now.toString(),
          oldValue: (now - (inactivityLogoutMillis - 30000)).toString()
        }));
      })
      .testNoRequest(() => {
        clock.tick(60000); // Advance past original timeout
      })
      .afterResponse(() => {
        session.dataExists.should.be.true; // Still logged in
      });
  });
});
```

**Critical Testing Patterns**:
1. **Cleanup hooks**: Always `clock.restore()` in `afterEach()` to prevent test pollution
2. **StorageEvent simulation**: Use `new StorageEvent('storage', { key, newValue, oldValue })` to simulate cross-tab writes
3. **Time advancement**: Use `clock.tick()` to advance fake timers precisely
4. **No-request assertions**: Use `.testNoRequest()` to verify logout **doesn't** happen when activity detected

### localStorage Key Naming (VG)

**Pattern**: Prefix with `vg` to clearly identify VG-specific browser storage

**Examples**:
- `vgSessionLastActivityAt` (inactivity tracking)
- Standard: `sessionExpires` (existing, non-VG)

**Why Prefix**:
- Avoids conflicts with potential upstream features
- Easy to identify during debugging
- Clear separation for removal/migration

### File Naming (Client VG)

**Pattern**: Prefix new VG-specific files with `vg-`

**Examples**:
- `src/util/vg-session-inactivity.js` (VG feature)
- `docs/vg/vg-client/vg_client_changes.md` (VG documentation)

**Core File Edits**:
- Minimal changes to `src/util/session.js` (documented in `client/docs/vg/vg-client/vg_core_client_edits.md`)

### Documentation Requirements (Client VG)

**Required Files**:
1. **docs/vg/vg-client/README.md**: Overview and quick reference
2. **docs/vg/vg-client/vg_client_changes.md**: Feature list with descriptions
3. **docs/vg/vg-client/vg_core_client_edits.md**: Line-by-line tracking of upstream file modifications

**Purpose**: Enable easy rebasing and conflict resolution when merging upstream changes

**Format** (vg_core_client_edits.md):
```markdown
### `src/util/session.js`

**VG Feature:** Session Inactivity Auto-Logout

**Changes Made:**

#### 1. Imports (lines ~67-73)
Added VG session inactivity module imports:
```javascript
import { ... } from './vg-session-inactivity';
```

**Merge Strategy:** If upstream modifies imports section, add VG import after upstream changes.
```

### Integration Pattern: Minimal Core File Changes

**Goal**: Minimize merge conflicts during upstream rebases

**Pattern**:
1. Create new VG-specific file (`vg-*.js`)
2. Add **single import** to core file
3. Add **minimal integration code** (call VG functions)
4. Document all changes in `vg_core_client_edits.md`

**Example**:
```javascript
// Core file: src/util/session.js
import { setLastActivityAt } from './vg-session-inactivity'; // 1 line added

export const logIn = (container, newSession) => {
  // ... existing code ...
  setLastActivityAt(); // 1 line added
  // ... existing code ...
};
```

**Benefit**: Only 2 lines modified in core file → minimal rebase conflicts

### Reusable Patterns Summary

#### Cross-Tab State Sync
1. Write shared state to localStorage
2. Listen for `storage` events in all tabs
3. Re-check state when event fires
4. Remember: `storage` event fires only in **other tabs**

#### Activity Tracking
1. Monitor user interaction events
2. Throttle updates to reduce I/O
3. Use passive listeners for performance
4. Store timestamp in localStorage for cross-tab sharing

#### Warning Before Auto-Action
1. Calculate time until action
2. Show warning at threshold (e.g., 3 min before)
3. Track warning state in closure
4. Reset warning when condition changes

#### Testing Time-Based Features
1. Use `sinon.useFakeTimers()` in `beforeEach()`
2. **Always** `clock.restore()` in `afterEach()`
3. Advance time with `clock.tick(milliseconds)`
4. Simulate cross-tab with `StorageEvent`

## Related

- [[server-architecture-patterns]] - Standard ODK Central patterns
- [[git-submodule-workflows]] - Managing client/server submodules
- [[sveltekit-state-management]] - Modern frontend state patterns

## References

- CLAUDE.md - VG fork workflow and branch policy
- server/docs/vg_core_server_edits.md - Authoritative log of upstream edits
- client/docs/vg/vg-client/vg_core_client_edits.md - Client upstream edits log
- server/docs/vg_api.md - VG API reference
- server/docs/vg_implementation.md - Implementation details
