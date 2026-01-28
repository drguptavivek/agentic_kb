---
title: VG Client UI Customization Patterns
type: reference
domain: ODK-Central-vg
tags:
  - odk-central
  - vg-fork
  - frontend
  - vue
  - ui
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# VG Client UI Customization Patterns

This document describes UI customization patterns for the VG fork of ODK Central frontend (`drguptavivek/central-frontend`).

## Critical Principle: Minimize Upstream File Edits

**Golden Rule**: Keep VG customizations **isolated in new files** to minimize merge conflicts when rebasing onto upstream `master`.

### Modularity Strategy

1. **Prefer new VG-prefixed components** over modifying existing components
2. **Keep upstream file edits minimal** (single-line changes where possible)
3. **Document all upstream edits** in `client/docs/vg_core_client_edits.md`
4. **Use VG prefix** for all custom components and features

### Example: Good Modularity

✔️ **Good**: Create `field-key/vg-list.vue` and update loader to point to it
✔️ **Good**: Add single route for `/system/settings` → `VgSettings`
✔️ **Good**: Add API helper functions to `src/util/request.js`

❌ **Bad**: Heavily modify existing `field-key/list.vue` with VG logic
❌ **Bad**: Scatter VG checks throughout multiple upstream components

## VG Namespace Convention

### Component Naming

**Pattern**: Prefix all VG-specific components with `vg-` or `Vg`

**Examples**:
- `src/components/field-key/vg-list.vue` (App User list)
- `src/components/field-key/vg-new.vue` (Create app user)
- `src/components/field-key/vg-edit.vue` (Edit app user)
- `src/components/field-key/vg-reset-password.vue`
- `src/components/field-key/vg-revoke.vue`
- `src/components/field-key/vg-restore.vue`
- `src/components/field-key/vg-qr-panel.vue` (Secure QR)
- `src/components/system/vg-settings.vue` (System settings)

**Loader Registration** (`src/util/load-async.js`):
```javascript
.set('FieldKeyList', loader(() => import(
  '../components/field-key/vg-list.vue'  // VG override
)))
.set('VgSettings', loader(() => import(
  '../components/system/vg-settings.vue'  // VG new
)))
```

### Route Naming

**Pattern**: Add VG-specific routes without modifying existing route structure

**Example**:
```javascript
// src/routes.js
{
  path: '/system',
  component: SystemHome,
  children: [
    // Existing routes unchanged
    asyncRoute({ path: 'audits', component: 'AuditList' }),
    asyncRoute({ path: 'analytics', component: 'AnalyticsList' }),
    // VG route added
    asyncRoute({
      path: 'settings',
      component: 'VgSettings',
      loading: 'tab',
      meta: {
        validateData: {
          currentUser: () => currentUser.can(['config.read', 'config.set'])
        },
        title: () => [i18n.t('systemHome.tab.settings'), i18n.t('systemHome.title')],
        fullWidth: true
      }
    })
  ]
}
```

### API Path Helpers

**Pattern**: Add VG-specific API paths to `src/util/request.js`

**Example**:
```javascript
// src/util/request.js
const apiPaths = {
  // Existing paths unchanged
  fieldKeys: (projectId) => `/v1/projects/${projectId}/app-users`,

  // VG paths added
  fieldKeyLogin: (projectId) => `/v1/projects/${projectId}/app-users/login`,
  fieldKeyUpdate: (projectId, id) => `/v1/projects/${projectId}/app-users/${id}`,
  fieldKeyResetPassword: (projectId, id) =>
    `/v1/projects/${projectId}/app-users/${id}/password/reset`,
  fieldKeyRevoke: (projectId, id) =>
    `/v1/projects/${projectId}/app-users/${id}/revoke-admin`,
  fieldKeyActive: (projectId, id) =>
    `/v1/projects/${projectId}/app-users/${id}/active`
};
```

## VG Feature: App User Authentication UI

### Overview

VG replaces long-lived QR token flow with username/password-based short-lived sessions.

### Component Architecture

**VG Components**:
1. **vg-list.vue**: App user list with username, phone, and actions
2. **vg-row.vue**: Individual row in list (edit, reset, revoke, restore)
3. **vg-new.vue**: Create app user modal with auto-generated password
4. **vg-edit.vue**: Edit display name and phone
5. **vg-reset-password.vue**: Admin password reset with auto-generation
6. **vg-revoke.vue**: Revoke access (deactivate)
7. **vg-restore.vue**: Restore access (reactivate)
8. **vg-qr-panel.vue**: Secure QR code panel (no credentials embedded)

### Key UX Changes

#### 1. Auto-Generated Passwords

**Pattern**:
```javascript
// src/util/password-generator.js
export function generatePassword() {
  const length = 16;
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '~!@#$%^&*()_+-=,.';
  const all = uppercase + lowercase + numbers + special;

  let password = '';
  password += uppercase[Math.floor(Math.random() * uppercase.length)];
  password += lowercase[Math.floor(Math.random() * lowercase.length)];
  password += numbers[Math.floor(Math.random() * numbers.length)];
  password += special[Math.floor(Math.random() * special.length)];

  for (let i = 4; i < length; i++) {
    password += all[Math.floor(Math.random() * all.length)];
  }

  return password.split('').sort(() => Math.random() - 0.5).join('');
}
```

**Usage in Create Modal**:
```vue
<script>
import { generatePassword } from '../../util/password-generator';

export default {
  data() {
    return {
      username: '',
      fullName: '',
      phone: '',
      password: generatePassword()  // Auto-generated
    };
  },
  methods: {
    submit() {
      this.$http.post(`/v1/projects/${this.projectId}/app-users`, {
        username: this.username,
        fullName: this.fullName,
        phone: this.phone,
        password: this.password
      })
      .then(response => {
        this.createdUser = { ...response.data, password: this.password };
        this.$alert().success('App User created');
      });
    }
  }
};
</script>
```

#### 2. Secure QR Code (No Credentials)

**Pattern**:
```vue
<!-- vg-qr-panel.vue -->
<template>
  <div class="vg-qr-panel">
    <!-- QR code contains ONLY server URL + project info -->
    <collect-qr :settings="qrSettings" :error-correction-level="'M'"/>

    <!-- Credentials shown separately (NOT in QR) -->
    <div class="credentials">
      <dl>
        <dt>Server URL</dt>
        <dd>{{ qrSettings.general.server_url }}</dd>
        <dt>Username</dt>
        <dd>{{ username }}</dd>
        <dt>Password</dt>
        <dd class="password-display">{{ password }}</dd>
      </dl>
      <p class="help-block">
        Enter these credentials manually in ODK Collect after scanning the QR code.
      </p>
    </div>
  </div>
</template>

<script>
export default {
  props: ['username', 'password', 'projectId'],
  computed: {
    qrSettings() {
      return {
        general: {
          server_url: window.location.origin,
          form_update_mode: 'match_exactly',
          autosend: 'wifi_and_cellular'
        },
        project: { name: this.project.name },
        admin: {}
        // ⚠️ NO username or password in settings
      };
    }
  }
};
</script>
```

**Key Security Change**:
- **Upstream**: QR code includes credentials (`username`, `password`)
- **VG**: QR code excludes credentials; shown separately for manual entry

#### 3. Username and Phone Fields

**Pattern in vg-list.vue**:
```vue
<template>
  <table class="table">
    <thead>
      <tr>
        <th>Display Name</th>
        <th>Username</th>     <!-- VG added -->
        <th>Phone</th>         <!-- VG added -->
        <th>Created</th>
        <th>Last Used</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <vg-row v-for="fieldKey in fieldKeys" :key="fieldKey.id"
        :field-key="fieldKey" @edit="showEditModal"
        @reset="showResetModal" @revoke="showRevokeModal"
        @restore="showRestoreModal"/>
    </tbody>
  </table>
</template>
```

**Phone Validation**:
```javascript
// Pattern: (+xx) xxxxxxxxxx
const phonePattern = /^\+\d{1,3}\s?\d{7,15}$/;

if (phone && !phonePattern.test(phone)) {
  this.$alert().danger('Invalid phone number format');
  return;
}
```

#### 4. Revoke vs. Restore

**Pattern in vg-row.vue**:
```vue
<template>
  <tr>
    <td>{{ fieldKey.displayName }}</td>
    <td>{{ fieldKey.username }}</td>
    <td>{{ fieldKey.phone }}</td>
    <td><date-time :iso="fieldKey.createdAt"/></td>
    <td><date-time :iso="fieldKey.lastUsed"/></td>
    <td>
      <template v-if="fieldKey.active">
        <button @click="$emit('edit', fieldKey)">Edit</button>
        <button @click="$emit('reset', fieldKey)">Reset Password</button>
        <button @click="$emit('revoke', fieldKey)">Revoke Access</button>
      </template>
      <template v-else>
        <button @click="$emit('restore', fieldKey)">Restore Access</button>
      </template>
    </td>
  </tr>
</template>
```

**Revoke Endpoint**:
```javascript
// vg-revoke.vue
this.$http.post(`/v1/projects/${projectId}/app-users/${id}/revoke-admin`)
  .then(() => {
    this.fieldKey.active = false;  // Update local state
    this.$alert().success('Access revoked');
  });
```

**Restore Endpoint**:
```javascript
// vg-restore.vue
this.$http.post(`/v1/projects/${projectId}/app-users/${id}/active`, { active: true })
  .then(() => {
    this.fieldKey.active = true;
    this.$alert().success('Access restored');
  });
```

## VG Feature: System Settings UI

### Component

**Location**: `src/components/system/vg-settings.vue`

**Pattern**:
```vue
<template>
  <div>
    <loading :state="systemSettings.initiallyLoading"/>
    <page-section v-if="systemSettings.dataExists">
      <template #heading>
        <span>{{ $t('vgSettings.heading') }}</span>
      </template>
      <template #body>
        <form @submit.prevent="submit">
          <form-group v-model.number="ttl" type="number"
            :placeholder="$t('vgSettings.ttl')"
            required min="1"/>
          <form-group v-model.number="cap" type="number"
            :placeholder="$t('vgSettings.cap')"
            required min="1"/>
          <button type="submit" class="btn btn-primary"
            :disabled="state.awaitingResponse">
            Save Settings
          </button>
        </form>
      </template>
    </page-section>
  </div>
</template>

<script>
export default {
  inject: ['systemSettings', 'currentUser'],
  data() {
    return {
      ttl: 3,
      cap: 3,
      state: { awaitingResponse: false }
    };
  },
  created() {
    this.$http.get('/v1/system/settings')
      .then(response => {
        this.ttl = response.data.vg_app_user_session_ttl_days;
        this.cap = response.data.vg_app_user_session_cap;
      });
  },
  methods: {
    submit() {
      if (this.ttl < 1 || this.cap < 1) {
        this.$alert().danger(this.$t('vgSettings.alert.invalidValues'));
        return;
      }

      this.state.awaitingResponse = true;
      this.$http.put('/v1/system/settings', {
        vg_app_user_session_ttl_days: this.ttl,
        vg_app_user_session_cap: this.cap
      })
      .then(() => {
        this.$alert().success('Settings saved');
      })
      .catch(() => {
        this.$alert().danger('Failed to save settings');
      })
      .finally(() => {
        this.state.awaitingResponse = false;
      });
    }
  }
};
</script>
```

### Resource Registration

**Pattern** (`src/request-data/resources.js`):
```javascript
createResource('systemSettings', noargs(setupOption));
```

### i18n Strings

**Pattern** (`src/locales/en.json5`):
```json5
{
  systemHome: {
    tab: {
      settings: "App User Settings"
    }
  },
  vgSettings: {
    heading: "Configure App User Session Settings",
    ttl: "Session TTL (Days)",
    cap: "Max Sessions per User",
    alert: {
      invalidValues: "Values must be at least 1."
    }
  }
}
```

## VG Feature: Alert Styling

### Green Success Toast

**Change**: Success alerts now display as green toasts instead of default blue.

**Implementation** (`src/components/toast.vue`):
```vue
<template>
  <alert class="toast" :class="toast.options?.type" :alert="toast"/>
</template>

<style lang="scss" scoped>
.toast {
  &.success {
    background-color: $color-success;
  }
  &.info {
    background-color: $color-info;
  }
}
</style>
```

**Container** (`src/container/alerts.js`):
```javascript
export default ({ toast, alert }) => ({
  alert: () => ({
    success: (message) => toast.show(message, { type: 'success' }),
    info: (message) => toast.show(message, { type: 'info', autoHide: false }),
    danger: (message) => alert.danger(message)
  })
});
```

## VG Feature: Form Access with Active Flag

### Issue

Upstream checks `fieldKey.token != null` to show app users in Form Access. VG short-lived tokens are not returned in listings, so active users wouldn't appear.

### Solution

**Change** (`src/request-data/project.js`):
```javascript
// Before (upstream):
const fieldKeys = createResource('fieldKeys', () => ({
  withToken: computeIfExists(() =>
    fieldKeys.filter(fieldKey => fieldKey.token != null))
}));

// After (VG):
const fieldKeys = createResource('fieldKeys', () => ({
  // Show all active app users in Form Access. Tokens are short-lived and not
  // returned in listings, so rely on active flag rather than token presence.
  withToken: computeIfExists(() =>
    fieldKeys.filter(fieldKey => fieldKey.active === true))
}));
```

**Key Change**: Check `active === true` instead of `token != null`

## Dev Environment Customizations

### Dockerized Vite Dev Container

**File**: `client/Dockerfile.dev`

**Purpose**: Run Vite dev server + Nginx proxy in Docker for consistent dev environment

**Pattern**:
```dockerfile
FROM node:22-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .

# Expose Vite port
EXPOSE 8989

CMD ["npm", "run", "dev"]
```

### Vite Configuration

**File**: `vite.config.js`

**Changes**:
```javascript
export default {
  server: {
    host: true,  // VG: Allow external connections
    port: 8989,
    allowedHosts: ['central.local']  // VG: Allow central.local
  }
};
```

### Nginx Proxy Configuration

**File**: `main.nginx.conf`

**Changes**:
```nginx
location ~ ^/v\d {
  # VG: Proxy to https://central.local instead of http://localhost:8383
  proxy_pass https://central.local;
  proxy_redirect off;

  # VG: SSL configuration for local dev
  proxy_ssl_verify off;
  proxy_set_header Host central.local;
}

location /version.txt {
  # VG: Return development version
  default_type text/plain;
  return 200 "development\n";
}
```

### E2E Test Defaults

**File**: `e2e-tests/run-tests.sh`

**Changes**:
```bash
# VG: Default domain changed
ODK_DOMAIN="central.local"  # Was: central-dev.localhost

# VG: Always install (removed --skip-install flag)
npm ci
npx playwright install --with-deps
```

## Upstream File Edits (Minimal)

### Files Modified

1. **src/util/load-async.js** (1 line): Point `FieldKeyList` to `vg-list.vue`
2. **src/routes.js** (1 route): Add `/system/settings` route
3. **src/util/request.js** (5 lines): Add VG API path helpers
4. **src/request-data/project.js** (3 lines): Change `withToken` filter
5. **src/request-data/resources.js** (1 line): Add `systemSettings` resource
6. **src/components/system/home.vue** (4 lines): Add Settings tab
7. **src/locales/en.json5** (10 lines): Add VG i18n strings
8. **src/components/toast.vue** (2 lines): Add type class and success style
9. **src/container/alerts.js** (2 lines): Add type to success/info
10. **vite.config.js** (2 lines): Add host and allowedHosts
11. **main.nginx.conf** (10 lines): Update proxy and version endpoint
12. **e2e-tests/*** (test reliability improvements)

**Total Upstream Edits**: ~50 lines across 12 files

**Documented In**: `client/docs/vg_core_client_edits.md` (2248 lines with full diffs)

## Testing Strategy

### VG-Specific Tests

- VG components are covered by standard unit tests
- E2E tests updated for `central.local` default
- Playwright response assertions simplified (`response.ok()`)

### Legacy Test Compatibility

- VG changes should not break existing tests
- If conflicts arise, document in test files

## Documentation Structure

### Required VG Docs (Client)

**Location**: `client/docs/`

1. **vg_client_changes.md**: High-level summary of customizations
2. **vg_core_client_edits.md**: **Critical** - Full diff log of upstream edits
3. **walkthrough.md**: UX walkthrough of VG features
4. **dev-server.md**: Dev environment setup

## Rebase Workflow

### Before Rebasing

1. **Review vg_core_client_edits.md**: Identify all upstream files touched
2. **Check upstream changes**: Compare with upstream master
3. **Plan conflict resolution**: How to re-apply VG changes

### After Rebasing

1. **Verify VG components**: Ensure all `vg-*.vue` files intact
2. **Check loader mappings**: Verify `load-async.js` still points to VG components
3. **Test core flows**: Create/list/edit app users, system settings
4. **Update docs**: Add new edits to `vg_core_client_edits.md`

### Minimizing Conflicts

- Keep VG components isolated (no upstream modifications)
- Single-line integrations where possible
- Document every upstream edit with diff

## Related

- [[client-ui-patterns]] - Standard ODK Central UI patterns
- [[vg-customization-patterns]] - VG server customizations

## References

- client/docs/vg_client_changes.md - Summary of customizations
- client/docs/vg_core_client_edits.md - Full diff log
- client/docs/walkthrough.md - UX walkthrough
- client/src/components/field-key/vg-*.vue - VG components
