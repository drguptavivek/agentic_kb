---
title: MEDRES Persistence and Preferences
type: reference
domain: MEDRES-Collect-Customization
tags:
  - persistence
  - preferences
  - encrypted-shared-preferences
  - medres
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES Persistence and Preferences

## Overview
MEDRES ODK Collect uses a combination of custom MEDRES-specific SharedPreferences and standard ODK Collect preferences.

## Storage Architecture

### MEDRES-Specific Storage
- **medres_auth_prefs**: Stores non-sensitive global state, project metadata, and staged configuration. (Private SharedPreferences).
- **medres_auth_secure**: Stores sensitive data (tokens, PIN hashes) using `EncryptedSharedPreferences` (AES-256-GCM).

## Standard ODK Storage
- **meta**: Global metadata (`current_project_id`, `projects`).
- **general_prefs{projectUUID}**: Settings for a specific ODK project (`server_url`, `username`).
- **admin_prefs{projectUUID}**: Admin-protected settings (`admin_pw`).

> **Naming Rule**: ODK uses a random UUID for projects. Always use `general_prefs$projectUUID` instead of package-based preference naming.



### 1. `medres_auth_prefs` (Standard Private Storage)
Stores non-sensitive configuration, state flags, and project metadata.

| Constant Name | Key String | Description | Usage |
| :--- | :--- | :--- | :--- |
| `KEY_ACTIVE_PROJECT_ID` | `active_project_id` | Current Central Project ID | Tracks the currently active project context |
| `KEY_AUTH_URL` | `auth_url` | Base Server URL | [Staging] Temporarily stores scanned URL |
| `KEY_AUTH_PROJECT_ID` | `auth_project_id` | Project ID | [Staging] Temporarily stores scanned ID |
| `KEY_AUTH_PROJECT_NAME` | `auth_project_name` | Project Name | [Staging] Display name for login screen |
| `KEY_QR_GENERAL_SETTINGS` | `qr_general_settings` | JSON String | [Staging] Raw settings from QR for later parsing |
| `KEY_IS_SOFT_EXPIRY` | `is_soft_expiry` | `true`/`false` | Flag for incomplete expiry (grace period UI) |
| `KEY_LAST_DISMISSAL_TIME` | `last_soft_expiry_dismissal` | Timestamp (Long) | Tracks when user last snoozed the expiry warning |
| `KEY_MEDRES_AUTH_ENABLED` | `medres_auth_enabled` | `true`/`false` | Feature flag globally enabling Medres Auth |
| `KEY_DEV_SERVER_IP` | `dev_server_ip` | IP Address | [Debug] Overrides base URL for local testing |
| `KEY_FIRST_LAUNCH` | `first_launch` | `true`/`false` | Tracks first app launch for onboarding |
| `KEY_USER_ID` | `user_id` | User ID string | Current user's identifier (non-sensitive) |
| `KEY_USER_NAME` | `user_name` | Username | Current username for display |

### 2. `medres_auth_secure` (Encrypted Storage)
Stores high-sensitivity credentials using `EncryptedSharedPreferences` (AES-256-GCM).

| Constant Name | Key String | Description | Usage |
| :--- | :--- | :--- | :--- |
| `KEY_AUTH_TOKEN` | `auth_token` | Bearer Token | Active session credential for API calls |
| `KEY_TOKEN_EXPIRY` | `token_expiry` | ISO 8601 Date / Long | Expiration timestamp for the current token |
| `KEY_PIN_HASH` | `pin_hash` | SHA-256 Hash | Hashed user PIN for local authentication |
| `KEY_PIN_SALT` | `pin_salt` | Random Salt | Salt used for PIN hashing |
| `KEY_PIN_ATTEMPTS` | `pin_attempts` | Integer | Counter for failed PIN entries |
| `KEY_LAST_PIN_ATTEMPT` | `last_pin_attempt` | Timestamp | Time of last failed attempt (for lockout) |
| `biometric_enabled` | `true`/`false` | [Reserved/Future] if Biometric Unlock is active |
| `biometric_key_alias` | String | [Reserved/Future] Alias for the Keystore key |

### 3. Standard ODK Preferences (Integration)

These are standard keys used by ODK Collect. MEDRES interacts with them to "materialize" the project.

#### `meta` (Global ODK State)
| Constant Name | Key String | Description | MEDRES Linkage |
| :--- | :--- | :--- | :--- |
| `KEY_INSTALL_ID` | `metadata_installid` | Unique Device ID | Used as `deviceId` in MEDRES Telemetry |
| `CURRENT_PROJECT_ID` | `current_project_id` | UUID of Active Project | MEDRES updates this upon login to switch context |
| `KEY_PROJECTS` | `projects` | JSON List of Projects | MEDRES reads/writes this to create new projects |

#### `general_prefs` (Per-Project Settings)
| Constant Name | Key String | Description | MEDRES Linkage |
| :--- | :--- | :--- | :--- |
| `KEY_SERVER_URL` | `server_url` | ODK Server URL | MEDRES injects the **Token** here: `.../v1/key/<TOKEN>/...` |
| `KEY_USERNAME` | `username` | ODK Username | Synced from MEDRES login (for metadata) |
| `KEY_PASSWORD` | `password` | ODK Password | Synced from MEDRES login (often unused by Token auth) |
| `KEY_PROTOCOL` | `protocol` | Server Protocol | MEDRES enforces `odk_default` (Server) |
| `KEY_FORM_UPDATE_MODE` | `form_update_mode` | Update Policy | Applied from `qr_general_settings` |

### D. User-Modifiable Project Settings (Detailed Reference)

These settings are accepted in the `qr_general_settings` JSON and are saved per-project in `general_prefs_{UUID}`.

| Setting Name | Key | Valid Options (Internal Value) |
| :--- | :--- | :--- |
| **Blank Form Update Mode** | `form_update_mode` | • Manual (`manual`)<br>• Previously Downloaded Only (`previously_downloaded_only`)<br>• Exactly Match Server (`match_exactly`) |
| **Auto Update Frequency** | `periodic_form_updates_check` | • Every 15 min (`every_fifteen_minutes`)<br>• Every hour (`every_one_hour`)<br>• Every 6 hours (`every_six_hours`)<br>• Every 24 hours (`every_24_hours`) |
| **Automatic Download** | `automatic_update` | • Enabled (`true`)<br>• Disabled (`false`) |
| **Hide Old Versions** | `hide_old_form_versions` | • Enabled (`true`)<br>• Disabled (`false`) |
| **Auto Send** | `autosend` | • Off (`off`)<br>• Wifi Only (`wifi_only`)<br>• Cellular Only (`cellular_only`)<br>• Wifi or Cellular (`wifi_and_cellular`) |
| **Delete After Send** | `delete_send` | • Enabled (`true`)<br>• Disabled (`false`) |
| **Navigation** | `navigation` | • Horizontal Swipes (`swipe`)<br>• Forward/Back Buttons (`buttons`)<br>• Swipes & Buttons (`swipe_buttons`) |
| **Constraint Processing** | `constraint_behavior` | • Validate on Swipe (`on_swipe`)<br>• Defer to Finalize (`on_finalize`) |
| **Font Size** | `font_size` | • Extra Small (`13`)<br>• Small (`17`)<br>• Medium (`21`)<br>• Large (`25`)<br>• Extra Large (`29`) |
| **App Language** | `app_language` | standard BCP 47 language code (e.g., `en`, `es`, `fr`, `hi`) |
| **Image Size** | `image_size` | • Original (`original_image_size`)<br>• Very Small (`very_small`)<br>• Small (`small`)<br>• Medium (`medium`)<br>• Large (`large`) |
| **High Res Video** | `high_resolution` | • Enabled (`true`)<br>• Disabled (`false`) |
| **Guidance Hints** | `guidance_hint` | • No (`no`)<br>• Yes (`yes`)<br>• Collapsed (`yes_collapsed`) |
| **External Audio Rec** | `external_app_recording` | • Enabled (`true`)<br>• Disabled (`false`) |
| **Instance Sync** | `instance_sync` | • Enabled (`true`)<br>• Disabled (`false`) (Finalize forms on import) |
| **Form Metadata** | `form_metadata` | • Enabled (`true`)<br>• Disabled (`false`) |
| **Basemap Source** | `basemap_source` | • Google (`google`)<br>• Mapbox (`mapbox`)<br>• OpenStreetMap (`osm`)<br>• USGS (`usgs`)<br>• Carto (`carto`) |

> **Note**: While ODK allows changing Server settings here, MEDRES users are generally expected to use the **Login Flow** or **QR Scan** to configure server details safely.

### E. Admin Access Control Keys (Protected Settings)

These settings are part of the `admin` object in the QR code or `admin_prefs`. They allow administrators to hide specific buttons or settings from the user, effectively "locking" the application.

| Category | Capability / Setting | Admin Key | Values |
| :--- | :--- | :--- | :--- |
| **Main Menu** | Edit Saved Form | `edit_saved` | `true`/`false` |
| **Main Menu** | Send Finalized Form | `send_finalized` | `true`/`false` |
| **Main Menu** | View Sent Form | `view_sent` | `true`/`false` |
| **Main Menu** | Get Blank Form | `get_blank` | `true`/`false` |
| **Main Menu** | Delete Saved Form | `delete_saved` | `true`/`false` |
| **User Settings** | Server Settings | `change_server` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Project Display | `change_project_display` | `true` (Editable) / `false` (Locked) |
| **User Settings** | App Language | `change_app_language` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Font Size | `change_font_size` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Navigation | `change_navigation` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Map Settings | `maps` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Form Update Mode | `form_update_mode` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Auto Update Freq | `periodic_form_updates_check` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Auto Download | `automatic_update` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Hide Old Versions | `hide_old_form_versions` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Auto Send | `change_autosend` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Delete After Send | `delete_after_send` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Constraint Processing | `change_constraint_behavior` | `true` (Editable) / `false` (Locked) |
| **User Settings** | High Res Video | `high_resolution` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Image Size | `image_size` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Guidance Hints | `guidance_hint` | `true` (Editable) / `false` (Locked) |
| **User Settings** | External Audio Rec | `external_app_recording` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Instance Sync | `instance_form_sync` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Form Metadata | `change_form_metadata` | `true` (Editable) / `false` (Locked) |
| **User Settings** | Analytics | `analytics` | `true` (Editable) / `false` (Locked) |
| **Form Entry** | Moving Backwards | `moving_backwards` | `true` (Allowed) / `false` (Prevented) |
| **Form Entry** | Access Settings | `access_settings` | `true` (Visible) / `false` (Hidden) |
| **Form Entry** | Change Language | `change_language` | `true` (Visible) / `false` (Hidden) |
| **Form Entry** | Go To Prompt | `jump_to` | `true` (Visible) / `false` (Hidden) |
| **Form Entry** | Save as Draft | `save_mid` | `true` (Visible) / `false` (Hidden) |
| **Form Entry** | Save as Draft (Exit) | `save_as_draft` | `true` (Visible) / `false` (Hidden) |
| **Form Entry** | Finalize | `finalize_in_form_entry` | `true` (Visible) / `false` (Hidden) |
| **Form Entry** | Bulk Finalize | `bulk_finalize` | `true` (Visible) / `false` (Hidden) |

### F. Recommended Admin Configuration for MEDRES

To ensure system integrity, compliance with isolation policies, and a simplified user experience, it is **highly recommended** to lock specific settings in the QR code generation.

#### Critical Security Locks (MUST LOCK)
| Blocked Capability | Admin Key | Value | Reason |
| :--- | :--- | :--- | :--- |
| **Change Server** | `change_server` | `false` | Prevents users from pointing the app to unauthorized servers or untokenized URLs. |
| **Change Identity** | `change_form_metadata` | `false` | Ensures submitted data is reliably attributed to the logged-in user (synced from auth). |
| **Reset Project** | `change_project_display` | `false` | Prevents users from renaming the project or changing its icon/color, ensuring consistent branding. |
| **Access Settings** | `access_settings` | `false` | Hides the "Settings" menu entirely to prevent any tampering. (Optional: Lock individual items instead if some settings are needed). |

#### Workflow Integrity Locks (SHOULD LOCK)
| Blocked Capability | Admin Key | Value | Reason |
| :--- | :--- | :--- | :--- |
| **Disable Autosend** | `change_autosend` | `false` | Enforces the "Auto Send" policy (e.g., Wifi Only) to ensure data reaches the server timely. |
| **Delete Saved Forms** | `delete_saved` | `false` | **Crucial**: Blocks the entire "Delete Saved Form" interface. This prevents deleting Key Execution Data (Sent Forms/Audit Trail) and Blank Forms. <br>*(Note: This also prevents deleting Drafts, as ODK does not support granular deletion permissions).* |
| **Manual Updates** | `form_update_mode` | `false` | If using "Match Exactly", prevents users from switching to Manual or interfering with sync. |
| **Check Frequency** | `periodic_form_updates_check` | `false` | Enforces the standard update interval (e.g., Every 15 minutes). |

#### JSON Snippet for ODK Central
When generating a QR code (or editing the JSON directly), include these keys in the `admin` object:

```json
"admin": {
    "change_server": false,
    "change_project_display": false,
    "change_form_metadata": false,
    "change_autosend": false,
    "delete_saved": false,
    "periodic_form_updates_check": false,
    "form_update_mode": false,
    "access_settings": false
}
```

### G. Unified Configuration Reference (Master Table)

This table consolidates the application settings, their valid values, recommended MEDRES configuration, and the corresponding Admin Control to enforce these choices.

| App Setting (General Key) | Possible Values (Internal) | Recommended Value | Admin Control Key | Admin Option (Lock) |
| :--- | :--- | :--- | :--- | :--- |
| **Server URL**<br>`server_url` | Any valid URL | *Dynamic (Injected)* | `change_server` | `false` (Locked) |
| **Project Identity**<br>`form_metadata` | `true`, `false` | `false` (Managed by Login) | `change_form_metadata` | `false` (Locked) |
| **Project Display**<br>`project_name`, `icon` | String | *Dynamic (From Login)* | `change_project_display` | `false` (Locked) |
| **Auto Send**<br>`autosend` | • `off`<br>• `wifi_only`<br>• `cellular_only`<br>• `wifi_and_cellular` | `wifi_and_cellular` | `change_autosend` | `true` (Unlocked) |
| **Delete After Send**<br>`delete_send` | `true`, `false` | `true` (Clean up forms) | `delete_after_send` *(User Settings)* | `false` (Locked) |
| **Delete Saved Forms**<br>N/A | N/A | N/A | `delete_saved` *(Main Menu)* | `false` (Locked) |
| **Form Update Mode**<br>`form_update_mode` | • `manual`<br>• `previously_downloaded`<br>• `match_exactly` | `match_exactly` | `form_update_mode` | `false` (Locked) |
| **Update Frequency**<br>`periodic_form_updates_check` | • `every_fifteen_minutes`<br>• `every_one_hour`<br>• `every_six_hours`<br>• `every_24_hours` | `every_fifteen_minutes` | `periodic_form_updates_check` | `false` (Locked) |
| **Auto Download**<br>`automatic_update` | `true`, `false` | `true` | `automatic_update` | `false` (Locked) |
| **Hide Old Versions**<br>`hide_old_form_versions` | `true`, `false` | `true` | `hide_old_form_versions` | `false` (Locked) |
| **Constraint Processing**<br>`constraint_behavior` | • `on_swipe`<br>• `on_finalize` | `on_swipe` | `change_constraint_behavior` | `false` (Locked) |
| **Navigation**<br>`navigation` | • `swipe`<br>• `buttons`<br>• `swipe_buttons` | `swipe` | `change_navigation` | `true` (Unlocked) |
| **Guidance Hints**<br>`guidance_hint` | • `yes`<br>• `yes_collapsed`<br>• `no` | `yes` | `guidance_hint` | `true` (Unlocked) |
| **Image Size**<br>`image_size` | • `original_image_size`<br>• `large` (3072px)<br>• `medium` (2048px)<br>• `small` (1024px)<br>• `very_small` (640px) | `medium` (2048px) | `image_size` | `false` (Locked) |
| **High Res Video**<br>`high_resolution` | `true`, `false` | `true` | `high_resolution` | `false` (Locked) |
| **External Audio Rec**<br>`external_app_recording` | `true`, `false` | `false` | `external_app_recording` | `false` (Locked) |
| **Instance Sync**<br>`instance_sync` | `true`, `false` | `true` | `instance_form_sync` | `false` (Locked) |
| **Analytics**<br>`analytics` | `true`, `false` | `false` (Anonymous Usage Data) | `analytics` | `false` (Locked) |
| **Maps**<br>`basemap_source` | `google`, `mapbox`, `osm`, etc. | `google` | `maps` | `false` (Locked) |

#### Master JSON Snippet (Copy-Paste)

This JSON object includes the **Recommended General Settings** (including Auto-Delete and Medium Images) matched with the **Locked Admin Controls** (allowing Autosend, Navigation, and Guidance changes).

```json
{
  "general": {
    "autosend": "wifi_and_cellular",
    "delete_send": true,
    "form_update_mode": "match_exactly",
    "periodic_form_updates_check": "every_fifteen_minutes",
    "automatic_update": true,
    "hide_old_form_versions": true,
    "constraint_behavior": "on_swipe",
    "navigation": "swipe",
    "guidance_hint": "yes",
    "image_size": "medium",
    "high_resolution": true,
    "external_app_recording": false,
    "instance_sync": true,
    "analytics": false
  },
  "admin": {
    "change_server": false,
    "change_form_metadata": false,
    "change_project_display": false,
    "change_autosend": true,
    "delete_saved": false,
    "form_update_mode": false,
    "periodic_form_updates_check": false,
    "automatic_update": false,
    "hide_old_form_versions": false,
    "change_constraint_behavior": false,
    "change_navigation": true,
    "guidance_hint": true,
    "image_size": false,
    "high_resolution": false,
    "external_app_recording": false,
    "instance_form_sync": false,
    "analytics": false,
    "maps": false,
    "access_settings": false
  }
}
```

---

## Linkage Logic (MEDRES <-> ODK)

The system maintains a mapping to bridge the two worlds:

1.  **Central World**: Identifying projects by numeric ID (e.g., `1`, `42`).
2.  **ODK World**: Identifying projects by random UUID (e.g., `a1b2-c3d4...`).

**The Bridge Key:**
*   Location: `medres_auth_prefs`
*   Key: `central_to_odk_{CentralID}` (e.g., `central_to_odk_1`)
*   Value: `ODK_Project_UUID` (e.g., `a1b2-c3d4...`)

**Flow:**
*   **Login**: MEDRES Login obtains `CentralID` -> Looks up `UUID` -> Sets `current_project_id = UUID`.
*   **API**: `MedresAuthManager` needs to update ODK settings -> Lookup `UUID` using `CentralID`.


## Related Content
- [[medres-architectural-boundaries]]
- [[medres-authentication-architecture]]
- [[medres-telemetry-and-logging]]

---

## Preference Lifecycle

### Phase 1: Application Installation & First Launch
On the first launch, the application initializes its base state:
- **`metadata_installid`**: Generated and stored in `meta` SharedPreferences. This serves as the `deviceId` for MEDRES telemetry.
- **`medres_auth_enabled`**: Read from resource values (defined in `build.gradle` flavor configuration).
- **`first_launch`**: Set to `true` in `medres_auth_prefs` to trigger initial configuration flows.

### Phase 2: Configuration (Staged State)
When a user scans a QR code or enters details manually via `MedresLoginActivity`:
- **Staged Details**: Base configuration is stored in `medres_auth_prefs` to enable the login UI without yet creating an ODK project.
- **`auth_url`**, **`auth_project_id`**, and **`qr_general_settings`** are populated.
- **UI State**: The login screen displays the configured project and changes the "Scan QR" button to **"Rescan QR Code"**.

### Phase 3: Login & Project Materialization
Upon successful authentication, the configuration is "materialized" into the standard ODK storage:
- **Tokenized URL**: A specialized URL is constructed and saved to `server_url` in `general_prefs[UUID]`.
  - Format: `<BaseURL>/key/<BearerToken>/projects/<PID>`
- **Project Creation**: A standard ODK project is created/updated in the `meta` prefs `projects` repository.
- **Settings Application**: Properties from `qr_general_settings` (like `form_update_mode`) are mapped to `general_prefs[UUID]`.
- **Identity**: `current_project_id` in `meta` is set to the ODK UUID of the new project.
- **Mapping**: `central_to_odk_$pid` is saved to link the systems.

---

## Security Cleanup (Logout/Wipe) Behavior

When a security event occurs (manual logout, 3 failed PIN attempts, or hard expiry), the application follows an **"Option B" (Shared Device Stability)** model. It clears the sensitive security context but preserves project data to ensure continuity for the next user on the same device.

| Category | Item | Action | Rationale |
|----------|------|--------|-----------|
| **Security** | Auth Token (JWT) | ✅ **Wiped** | Prevents unauthorized API access. |
| **Security** | Security PIN | ✅ **Wiped** | Forces next user to set their own PIN. |
| **Security** | Session State | ✅ **Wiped** | Clears `is_authenticated` and `active_project_id`. |
| **Security** | Clock State | ✅ **Wiped** | Resets `last_valid_wall_time` to prevent replay. |
| **User Data** | User Profile | ✅ **Wiped** | Clears `user_data_$pid` (ID, Username). |
| **Project Data** | Blank Forms | ❌ **Preserved** | Bandwidth efficiency; shared team access. |
| **Project Data** | Saved Instances | ❌ **Preserved** | Team visibility; shared device drafts. |
| **Project Data** | Submitted History | ❌ **Preserved** | Local audit trail for device users. |
| **Configuration** | Project URL/Name | ❌ **Preserved** | Simplifies re-login for the next user. |
| **Configuration** | ODK Settings | ❌ **Preserved** | Maintains ODK core stability. |

---

### H. QR Code to Settings Translation Process

The translation of a QR code into active application settings follows a strict multi-stage pipeline designed to ensure security (isolation) and consistency (all users get the same settings).

#### Stage 1: Scanning & Parsing (`MedresQrScannerActivity`)
When a user scans a QR code, the app performs the following:
1.  **Decompression**: The QR payload is decompressed (gzip).
2.  **Validation**: It checks for required keys (`server_url`, `project_id`) and ensures it is NOT a standard ODK QR (must be a MEDRES-formatted JSON).
3.  **Extraction**:
    *   **Auth Data**: Extracts `server_url` and `project_id`.
    *   **Settings Data**: Extracts the `general` object **verbatim** as a raw JSON string.
4.  **Staging**:
    *   `auth_url` and `auth_project_id` are saved to `medres_auth_prefs`.
    *   The `general` JSON string is saved to the key `qr_general_settings` in `medres_auth_prefs`.
    *   **Crucially**, no ODK settings are changed yet. The user is not yet logged in.

#### Stage 2: Authentication & Materialization (`MedresLoginActivity`)
Settings are only applied **AFTER** a successful login to prevent unauthorized configuration changes.
1.  **Login Verification**: The user enters credentials. The app authenticates against the `auth_url`.
2.  **Context Match**: The app verifies that the logged-in Project ID matches the Staged Project ID from the QR code.
3.  **Project Creation**:
    *   If a matching ODK Project (by Project ID) exists, it is selected.
    *   If not, a new ODK Project is created using the name from the QR code (or a default "MEDRES Project [ID]").
4.  **Settings Application ("The Import Loop")**:
    *   The app reads the `qr_general_settings` JSON string from `medres_auth_prefs`.
    *   It opens the `general_prefs_[UUID]` file for the specific ODK Project.
    *   **Dynamic Usage**: It iterates through **ALL** keys present in the JSON object (e.g., `autosend`, `navigation`, `image_size`) and applies them directly to the preferences file, respecting their data types (Boolean, String, Integer).
    *   **Safeguard**: Sensitive keys like `server_url`, `username`, and `password` are skipped during this loop as they are handled explicitly by the specialized login logic.
    *   **Server Injection**: The `server_url` is constructed securely (`.../v1/key/[Token]/projects/[ID]`) and written separately to ensure connectivity.

#### Stage 3: Admin Lock Application
Admin settings (from the `admin` object in the QR) follow a similar path but target the `admin_prefs_[UUID]` file.
*   These booleans (e.g., `change_autosend`: `false`) are written to the admin preferences.
*   The ODK UI layer reads these preferences to determine visibility of menus and settings buttons.
