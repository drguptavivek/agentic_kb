---
title: ODK Central Admin Password QR Code Integration
created: 2025-12-26
tags:
  - odk-central
  - vg-fork
  - admin-settings
  - qr-code
  - vue
  - nodejs
  - postgresql
status: approved
type: reference
domain: ODK-Central-vg
---

# ODK Central Admin Password QR Code Integration

## Overview

Implementation of system-wide `admin_pw` setting for ODK Central that gets included in managed QR code payloads for ODK Collect configuration locking.

## Problem Solved

ODK Collect needs a way to lock down admin settings. The admin password is now stored as a system setting in Central and automatically included in QR codes for app user enrollment.

## Architecture

### Database Layer

- **Storage**: `vg_settings` key-value table
- **Key**: `admin_pw`
- **Default**: `'vg_custom'`
- **Format**: Plain text string (no encryption)
- **Schema file**: `server/docs/sql/vg_app_user_auth.sql`

### Server API

**GET /system/settings**
- Returns `admin_pw` along with TTL and session cap
- Authorization: Requires `config.read` permission

**PUT /system/settings**
- Accepts and validates `admin_pw`
- Authorization: Requires `config.set` permission
- Validation: Non-empty string, no complexity requirements

### Query Layer Pattern

```javascript
const getAdminPw = () => ({ maybeOne }) =>
  maybeOne(sql`SELECT vg_key_value FROM vg_settings WHERE vg_key_name='admin_pw' LIMIT 1`)
    .then((opt) => opt.map((row) => row.vg_key_value).orElse('vg_custom'));
```

Location: `server/lib/model/query/vg-app-user-auth.js`

## QR Code Integration

### Payload Structure

Managed QR codes include admin_pw in the admin section:

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

### Encoding Process

1. **Serialization**: Convert to JSON string
2. **Compression**: Apply zlib DEFLATE compression
3. **Encoding**: Base64 encode the compressed data
4. **QR Format**: Encode into QR code image

### Key Implementation Details

- Payload is generated dynamically at request time
- Fetches current `admin_pw` from settings on each request
- Falls back to default `'vg_custom'` if not yet fetched
- Both "Show QR" and password reset QR codes use identical structure
- QR code generation happens in the frontend

## Client Implementation

### Components Involved

**vg-settings.vue** - System Settings UI
- Location: `client/src/components/system/vg-settings.vue`
- Input field for admin_pw configuration
- PUT request to save changes to server
- Fetches current value on component creation
- Displays in System Settings page at `/system/settings`

**vg-qr-panel.vue** - QR Code Generator
- Location: `client/src/components/field-key/vg-qr-panel.vue`
- Injects `systemSettings` resource using Vue Composition API
- Fetches settings if not already loaded
- Includes admin_pw in managed QR payload
- Used in both "Show QR" and password reset flows

### State Management Pattern

- Uses Vue Composition API's `useRequestData()` composable
- `systemSettings` reactive resource for managing API state
- Data binding for two-way form field synchronization
- Automatic updates when settings change

## Testing Approach

### Manual Testing Workflow

1. Navigate to `/system/settings` in Central UI
2. Update the admin_pw field to a test value
3. Click Save
4. Generate a QR code for an app user ("Show QR" button)
5. Decode the QR code using decode-qr.py script
6. Verify admin_pw is present in payload

### QR Decoding Verification

Use the provided decode-qr.py utility:

```bash
python3 decode-qr.py qr-screenshot.png
```

Expected output includes:

```json
{
  "admin": {
    "change_server": false,
    "admin_pw": "<your-test-value>"
  }
}
```

### Test Cases

- Default value is `'vg_custom'`
- Custom value persists across page reloads
- Both "Show QR" and reset password QR include the setting
- Changing admin_pw updates all new QR codes
- Old QR codes don't change (they're static)

## Performance Considerations

- Settings are fetched on demand (not globally cached)
- Minimal overhead: Single SELECT query per request
- Default fallback ensures operation even if setting not found
- No blocking operations in QR generation pipeline

## Security Notes

- Stored as plain text in database (intentional for ODK Collect integration)
- Accessible only to users with `config.read` or `config.set` permissions
- Included in QR codes which are only accessible to authenticated admins
- No password complexity validation (allows any non-empty string)
- Not encrypted due to ODK Collect's requirement to read it from QR

## Files Modified

### Server

- `server/docs/sql/vg_app_user_auth.sql` - Added default seed
- `server/lib/model/query/vg-app-user-auth.js` - Added `getAdminPw()` getter
- `server/lib/resources/vg-app-user-auth.js` - Updated GET/PUT endpoints
- `server/docs/vg_settings.md` - Documented settings and QR payload

### Client

- `client/src/components/system/vg-settings.vue` - Added UI field and save logic
- `client/src/components/field-key/vg-qr-panel.vue` - Fetch and include admin_pw

## Related Patterns

- **Settings Storage**: Uses existing `vg_settings` key-value table pattern
- **Query Layer**: Follows Option monad pattern with fallback defaults
- **Vue Components**: Uses Composition API with `useRequestData()` composable
- **API Design**: Follows RESTful conventions with permission-based access control

## Related Articles

- [[ODK-Central-vg/client-ui-patterns]] - Vue component patterns used in implementation
- [[ODK-Central-vg/app-user-session-date-handling]] - Related session settings management

