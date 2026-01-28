---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #client #ui #app-user #vue
created: 2026-01-28
---

# ODK Central VG App User UI Components

> **Source**: `docs/vg/vg-client/vg_client_changes.md`

## Overview

VG replaces the upstream app user (Field Key) components with a new UI that supports username/password authentication, secure QR codes, and session management.

## Component Architecture

```
src/components/field-key/
├── vg-list.vue          # Main list view (replaces list.vue)
├── vg-row.vue           # Table row with actions
├── vg-new.vue           # Create app user modal
├── vg-qr-panel.vue      # Secure QR code display
├── vg-edit.vue          # Edit details modal
├── vg-reset-password.vue # Admin reset modal
├── vg-revoke.vue        # Revoke sessions modal
└── vg-restore.vue       # Reactivate user modal
```

## VG List Component

**File**: `vg-list.vue`

**Features**:
- Replaces upstream `list.vue`
- Added columns: **Username**, **Phone**, **Active**
- Removed: Token display (tokens are short-lived)
- Actions: Edit, Reset Password, Revoke Access, Restore Access

**Loader registration**:
```javascript
// src/util/load-async.js
.set('FieldKeyList', loader(() => import(
  '../components/field-key/vg-list.vue'  // Changed from list.vue
)))
```

## VG Row Component

**File**: `vg-row.vue`

**Row actions**:

| Action | Permission | Behavior |
|--------|-----------|----------|
| Edit details | `field_key.update` | Opens edit modal |
| Reset password | `field_key.update` | Auto-generates new password |
| Revoke access | `session.end` | Terminates all sessions |
| Restore access | `session.end` | Reactivates deactivated user |

**Active status display**:
- Green checkmark for active users
- Gray indicator for deactivated users
- Filterable in the list view

## Create App User Flow

**File**: `vg-new.vue`

**Fields**:
- Display name (required)
- Username (required, validated)
- Phone (optional, max 25 chars)
- Password (auto-generated, not shown in input)

**Password generation**:
```javascript
// src/util/password-generator.js
const generatePassword = () => {
  // 16 chars, meets policy: uppercase, lowercase, digit, special
};
```

**Post-create modal**:
1. Shows username and generated password
2. Displays QR code (no credentials embedded)
3. Copy-to-clipboard buttons
4. Print/download options

## QR Panel Component

**File**: `vg-qr-panel.vue`

**QR Payload** (managed QR):
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

**Security**: Username/password shown below QR, NOT embedded

**Processing**:
1. Serialize to JSON
2. Compress via zlib DEFLATE
3. Base64 encode
4. Generate QR code

## Edit App User Flow

**File**: `vg-edit.vue`

**Editable fields**:
- Display name
- Phone number

**Validation**:
- Phone max 25 characters
- Trimmed automatically

## Reset Password Flow

**File**: `vg-reset-password.vue`

**Admin reset**:
1. Auto-generates new password (16 chars, meets policy)
2. Terminates all existing sessions
3. Shows updated credentials
4. Displays new QR code

**API call**:
```javascript
POST /v1/projects/:projectId/app-users/:id/password/reset
{ "newPassword": "<generated>" }
```

## Revoke Access Flow

**File**: `vg-revoke.vue`

**Admin revoke**:
- Terminates all sessions for the user
- User remains active but must log in again
- Requires `session.end` permission

**API call**:
```javascript
POST /v1/projects/:projectId/app-users/:id/revoke-admin
```

## Restore Access Flow

**File**: `vg-restore.vue`

**Reactivate user**:
- Sets `active` flag to `true`
- User can log in again
- Requires `session.end` permission

**API call**:
```javascript
POST /v1/projects/:projectId/app-users/:id/active
{ "active": true }
```

## Project App User Settings

**File**: `../project/vg-app-user-settings.vue`

**Route**: `/projects/:projectId/app-users/settings`

**Settings**:
- Session TTL (days) - project override
- Max sessions per user - project override
- Admin password for QR codes - project override

**Permissions**: `project.update`

## Form Access Behavior

**File**: `src/request-data/project.js`

**Change**: Filter by `active` flag instead of `token` presence

```javascript
// Before: Show users with tokens
withToken: computeIfExists(() =>
  fieldKeys.filter(fieldKey => fieldKey.token != null))

// After: Show active users (tokens are short-lived)
withToken: computeIfExists(() =>
  fieldKeys.filter(fieldKey => fieldKey.active === true))
```

## Related Documentation

- [[ODK-Central-vg/client-overview]] - Client changes overview
- [[ODK-Central-vg/app-user-api]] - Backend API endpoints
- [[ODK-Central-vg/settings]] - Settings configuration
