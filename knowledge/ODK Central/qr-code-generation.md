---
title: ODK Central QR Code Generation and Management
created: 2025-12-26
tags:
  - odk-central
  - qr-code
  - app-users
  - field-keys
  - vue
  - collect-settings
status: approved
type: reference
---

# ODK Central QR Code Generation and Management

## Overview

ODK Central generates QR codes to streamline app user enrollment and configuration in ODK Collect. QR codes encode settings that can be scanned to automatically configure data collection apps without manual entry.

## QR Code Types

### 1. Legacy QR Codes

**Purpose**: Direct field key credentials (deprecated approach)

**Encoded Data**:
```json
{
  "general": {
    "server_url": "https://central.example.com/v1/projects/1",
    "username": "field_key_username",
    "password": "field_key_password"
  }
}
```

**Security Issues**:
- Credentials embedded in QR code
- Password visible in encoded data
- Not suitable for secure field operations

**Status**: Deprecated in favor of managed QR codes

### 2. Managed QR Codes

**Purpose**: Secure app user enrollment with settings automation

**Encoded Data**:
```json
{
  "general": {
    "server_url": "https://central.example.com/v1/projects/1",
    "username": "app_user_id",
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

**Features**:
- No credentials embedded (login happens separately)
- Automated form management settings
- Settings lock via admin password
- Server URL locked to prevent changes
- Analytics and metadata tracking enabled

**Security Benefits**:
- Credentials transmitted securely via login flow
- No credential exposure in QR data
- Admin settings locked to prevent app user modification
- Full audit trail of access

## QR Code Generation Pipeline

### 1. Settings Assembly

Settings are built from multiple sources:

**Always Included**:
- Project ID and name
- Server URL with project path
- App user ID (username)
- App user display name (metadata_username)

**Managed Mode Only**:
- `form_update_mode`: Always `"match_exactly"`
- `automatic_update`: Always `true`
- `delete_send`: Always `false`
- `default_completed`: Always `false`
- `analytics`: Always `true`
- `admin_pw`: Fetched from system settings (default: `'vg_custom'`)

**Admin Section**:
- `change_server`: Always `false` (prevents server URL modification)
- `admin_pw`: System setting for ODK Collect settings lock

### 2. Encoding Process

```
JSON Settings
    ↓
Serialization (JSON string)
    ↓
Compression (zlib DEFLATE)
    ↓
Base64 Encoding
    ↓
QR Code Image (L error correction)
```

**Technical Details**:
- Compression reduces payload size by ~30-40%
- Base64 ensures safe transmission of binary data
- L error correction allows recovery from ~7% data loss
- Cell size set to 3 pixels per module for readability

### 3. Frontend Generation

Location: `client/src/components/field-key/vg-qr-panel.vue`

**Process**:
1. Fetch system settings (includes admin_pw)
2. Build settings object based on mode (legacy/managed)
3. Pass to `CollectQr` component
4. Component handles serialization, compression, encoding
5. Render as QR code image

**Key Implementation**:
```javascript
// Computed property builds settings dynamically
settings() {
  const settings = {
    general: {},
    project: {
      name: this.project.name,
      project_id: this.project.id.toString()
    },
    admin: {}
  };

  // ... assemble general settings ...

  if (this.managed) {
    // Add managed-specific settings
    settings.general.form_update_mode = 'match_exactly';
    settings.general.automatic_update = true;
    // ... etc ...

    // Include admin_pw from system settings
    const adminPw = this.systemSettings.dataExists
      ? this.systemSettings.data.admin_pw || 'vg_custom'
      : 'vg_custom';
    settings.admin = {
      change_server: false,
      admin_pw: adminPw
    };
  }
  return settings;
}
```

## QR Code Generation Points

### 1. App User List View

**Location**: `client/src/components/field-key/vg-list.vue`

**Trigger**: "Show QR" button next to each app user

**Mode**: Managed (by default)

**Data Flow**:
- User clicks "Show QR"
- Opens vg-field-key-qr-panel modal
- Fetches app user details
- Generates managed QR with current system settings
- Displays with toggle option to switch to legacy

### 2. Password Reset Flow

**Location**: `client/src/components/field-key/vg-field-key-reset-password.vue`

**Trigger**: "Reset Password" button

**Mode**: Managed (controlled by :managed prop)

**Data Flow**:
- User initiates password reset
- System generates temporary password
- Opens QR modal with :managed prop
- Generates QR with updated password context
- User can scan to enroll with new credentials

## Settings Configuration

### System Settings

**Storage**: `vg_settings` table (key-value store)

**Available Settings**:
- `vg_app_user_session_ttl_days` (default: 3) - Session validity period
- `vg_app_user_session_cap` (default: 3) - Max concurrent sessions
- `admin_pw` (default: `'vg_custom'`) - ODK Collect settings lock password

**Management API**:
- **GET /system/settings** - Retrieve all settings
- **PUT /system/settings** - Update one or more settings
- **Access Control**: Requires `config.read` (GET) and `config.set` (PUT)

**Fetch Pattern**:
```javascript
setup() {
  const { systemSettings } = useRequestData();
  return { systemSettings };
}

created() {
  if (!this.systemSettings.dataExists) {
    this.systemSettings.request({ url: '/v1/system/settings' });
  }
}
```

## QR Code Payload Size Management

### Size Constraints

**QR Code Capacity by Version**:
- Version 1: ~41 bytes (numeric)
- Version 5: ~154 bytes (numeric)
- Version 10: ~346 bytes (numeric)
- Standard: ~10 KB (binary)

**Managed QR Payload**:
- Uncompressed JSON: ~245 bytes
- Compressed (DEFLATE): ~156 bytes
- Base64 encoded: ~208 bytes
- Fits in QR Version 4-5

### Optimization Techniques

**1. Lean Settings**:
- Only include essential configuration
- Remove optional or rarely-changed settings
- Minimize text values

**2. Compression**:
- zlib DEFLATE reduces binary payload by ~30-40%
- Essential for fitting complex settings

**3. Strategic Defaults**:
- Many settings have sensible defaults
- Don't repeat default values in QR
- ODK Collect applies defaults on decode

## QR Decoding and Verification

### Decoding Process

**Reverse of Encoding**:
```
QR Code Image
    ↓
Extract Data (optical recognition)
    ↓
Base64 Decoding
    ↓
Decompression (zlib INFLATE)
    ↓
Parse JSON
    ↓
Settings Object
```

### Verification Tools

**Python Script** (decode-qr.py):
```bash
python3 decode-qr.py qr-image.png
```

**Output Includes**:
- Raw base64 data
- Decompressed JSON
- Payload structure validation
- Field-by-field verification

**Validation Checklist**:
- ✅ `general.server_url` includes project path
- ✅ `general.username` is present
- ✅ `general.form_update_mode` = `"match_exactly"` (managed)
- ✅ `admin.change_server` = `false`
- ✅ `admin.admin_pw` = current system setting
- ✅ No literal `"..."` truncation markers
- ✅ JSON is complete and valid

## Component Architecture

### Component Hierarchy

```
App User List (vg-list.vue)
├── Show QR Button
│   └── vg-field-key-qr-panel.vue
│       └── collect-qr.vue (QR generation)
│           └── canvas/svg rendering
└── Password Reset Button
    └── vg-field-key-reset-password.vue
        └── vg-field-key-qr-panel.vue
            └── collect-qr.vue
```

### Data Flow

```
systemSettings (useRequestData)
    ↓
vg-qr-panel.vue
    ├── Fetches: system settings
    ├── Accesses: project data
    ├── Accesses: field key data
    └── Builds: settings object
        ↓
    collect-qr.vue
        ├── Serializes: JSON
        ├── Compresses: DEFLATE
        ├── Encodes: Base64
        └── Renders: QR code
```

## Performance Considerations

### QR Generation Performance

- **Settings fetch**: ~50-200ms (network)
- **JSON serialization**: <1ms
- **DEFLATE compression**: ~2-5ms
- **Base64 encoding**: <1ms
- **QR rendering**: ~50-100ms (depends on cell size)
- **Total**: ~100-350ms (mostly network)

### Caching Strategy

- Settings are fetched on demand, not globally cached
- Each QR modal fetches fresh settings
- Ensures QR codes always reflect current configuration
- Trade-off: Network request per QR generation vs. Always current

### Optimization Opportunities

1. **Local Caching**: Cache settings in localStorage with TTL
2. **Batch Fetching**: Pre-fetch settings when listing app users
3. **Lazy QR Generation**: Generate QR only when modal opens
4. **Server-Side Generation**: Move QR generation to server (not recommended - security)

## Security Considerations

### Data Exposed in QR

✅ **Safe to Expose**:
- Server URL
- Project ID and name
- App user ID (username)
- Display name
- Form sync settings
- Admin password (intentional for ODK Collect locking)

❌ **Never in QR**:
- Field key credentials
- Session tokens
- API keys
- Private keys

### Access Control

- QR code generation requires authentication
- Only accessible to users viewing app user details
- Requires `appUser.read` permission to see app users
- System settings readable by `config.read` users

### QR Code Transmission

- QR codes are static images
- No sensitive data in transmission
- Can be safely printed, emailed, shared
- ODK Collect decodes locally on device

## Known Issues and Limitations

### Payload Truncation

**Issue**: Settings object too large → QR exceeds capacity → Base64 contains literal `"..."`

**Solution**: Trim non-essential settings from payload

**Root Cause**: Comprehensive settings object + compression limitations

### Dynamic Settings

**Issue**: Settings are fetched at QR generation time

**Benefit**: QR always reflects current admin_pw and configuration

**Challenge**: Old printed QR codes won't have new settings

**Mitigation**: Settings changes should be communicated to field teams

## Related Articles

- [[admin-pw-qr-integration]] - Admin password setting integration
- [[client-ui-patterns]] - Vue component patterns
- [[app-user-session-date-handling]] - Session management
- [[troubleshooting-vg-issues]] - Common issues and solutions

## References

- **Component**: `client/src/components/field-key/vg-qr-panel.vue`
- **UI**: `client/src/components/field-key/vg-list.vue`
- **Settings**: `server/docs/vg_settings.md`
- **API**: `server/lib/resources/vg-app-user-auth.js`
- **Database**: `server/docs/sql/vg_app_user_auth.sql`

