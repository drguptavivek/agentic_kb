---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #client #frontend #vue #components
created: 2026-01-28
---

# ODK Central VG Client Overview

> **Source**: `docs/vg/vg-client/vg_client_changes.md`

## Summary of Customizations

The VG client fork introduces significant UI/UX changes for app user authentication, system settings, and Enketo management.

## Main Features

### 1. App User Auth Overhaul

| Feature | Description |
|---------|-------------|
| Short-lived sessions | No long-lived tokens in QR codes or listings |
| Username/password flow | Generated passwords, secure QR display |
| Additional fields | Username and phone columns |
| New actions | Edit, reset password, revoke, restore access |

### 2. System Settings UI

New **System > App User Settings** tab for global configuration:
- Session TTL (days)
- Max sessions per user
- Admin password for QR codes

### 3. Enketo Status UI

New **System > Enketo Status** tab for viewing and regenerating Enketo IDs across all forms.

### 4. Dev Environment Updates

- Dockerized Vite dev container (`Dockerfile.dev`)
- Proxy defaults to `https://central.local`
- Vite `allowedHosts: ['central.local']`

### 5. E2E Test Reliability

- Default domain: `central.local`
- Always install dependencies
- Use `response.ok()` for assertions

## VG Components

### Field Key Components

| Component | Purpose |
|-----------|---------|
| `vg-list.vue` | App user list with username/phone columns |
| `vg-row.vue` | Table row with edit/reset/revoke/restore actions |
| `vg-new.vue` | Create app user with generated password |
| `vg-qr-panel.vue` | Secure QR display (no credentials) |
| `vg-edit.vue` | Edit display name and phone |
| `vg-reset-password.vue` | Admin reset with auto-generated password |
| `vg-revoke.vue` | Revoke all sessions |
| `vg-restore.vue` | Reactivate deactivated user |

### System Components

| Component | Purpose |
|-----------|---------|
| `vg-settings.vue` | System app user settings (TTL, cap, admin_pw) |
| `vg-enketo-status.vue` | Enketo status overview and regeneration |

### Project Components

| Component | Purpose |
|-----------|---------|
| `vg-app-user-settings.vue` | Project-level app user settings |
| `vg-telemetry.vue` | Device telemetry listing |
| `vg-login-history.vue` | App user session history |

## Modified Upstream Behavior

### Field Key List

**Before**: Used `list.vue` with token display
**After**: Uses `vg-list.vue` with:
- Username column
- Phone column
- Active status indicator
- No token (short-lived)
- New action buttons

### Form Access

**Before**: Filtered by `token != null`
**After**: Filters by `active === true` (tokens are short-lived and not returned)

### Toast Styling

Added success type class and green styling:
```scss
&.success {
  background-color: $color-success;
}
```

## API Path Helpers

New request helpers added to `src/util/request.js`:

```javascript
fieldKeyLogin: (projectId) => `/v1/projects/${projectId}/app-users/login`
fieldKeyUpdate: (projectId, id) => `/v1/projects/${projectId}/app-users/${id}`
fieldKeyResetPassword: (projectId, id) => `/v1/projects/${projectId}/app-users/${id}/password/reset`
fieldKeyRevoke: (projectId, id) => `/v1/projects/${projectId}/app-users/${id}/revoke-admin`
fieldKeyActive: (projectId, id) => `/v1/projects/${projectId}/app-users/${id}/active`
```

## Routes Added

| Path | Component | Permissions |
|------|-----------|-------------|
| `/system/settings` | VgSettings | `config.read`, `config.set` |
| `/system/enketo-status` | VgEnketoStatus | `config.read`, `config.set` |
| `/projects/:id/telemetry` | VgProjectTelemetry | `config.read` |
| `/projects/:id/login-history` | VgProjectLoginHistory | `field_key.list` |

## i18n Keys Added

```javascript
// System tabs
"systemHome.tab.settings": "App User Settings"
"systemHome.tab.enketoStatus": "Enketo Status"

// Project tabs
"projectShow.tab.telemetry": "Telemetry"
"projectShow.tab.loginHistory": "Login History"

// Settings
"vgSettings.heading": "Configure App User Session Settings"
"vgSettings.ttl": "Session TTL (Days)"
"vgSettings.cap": "Max Sessions per User"
"vgSettings.alert.invalidValues": "Values must be at least 1."

// Enketo status (labels for status types, actions, alerts, filters)
```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/app-user-ui]] - App user UI components
- [[ODK-Central-vg/enketo-status]] - Enketo management UI
- [[ODK-Central-vg/development]] - Dev environment setup
