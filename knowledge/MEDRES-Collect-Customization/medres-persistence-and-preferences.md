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

### Standard ODK Storage
- **meta**: Core application metadata (e.g., `current_project_id`).
- **general_prefs[UUID]**: Settings for a specific ODK project.

## Key Persistence Concepts

### Staged Configuration
Before login, configuration from a QR code is stored in `medres_auth_prefs`. This allowed the UI to show the target project before an actual ODK project is created.

### Project Materialization
Upon successful login, MEDRES logic "materializes" the config into ODK by:
1. Creating/Updating an ODK project.
2. Setting a **tokenized URL** as the `server_url`.
3. Applying ODK settings from the QR code.

### Security Cleanup (Shared Device Stability)
When a logout or hard expiry occurs, MEDRES follows an "Option B" model:
- ✅ **Wiped**: Auth Tokens, Security PIN, User Profile metadata.
- ❌ **Preserved**: Blank Forms, Saved Instances, ODK Settings.
This ensures device stability and bandwidth efficiency for the next user on a shared tablet.

## Related Content
- [[medres-architectural-boundaries]]
- [[medres-authentication-architecture]]
- [[medres-telemetry-and-logging]]
