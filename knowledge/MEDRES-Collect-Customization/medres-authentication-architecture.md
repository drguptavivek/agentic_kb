---
title: MEDRES Authentication Architecture
type: reference
domain: MEDRES-Collect-Customization
tags:
  - authentication
  - medres
  - bearer-token
  - jwt
  - security
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES Authentication Architecture

## Overview
The MEDRES authentication system replaces ODK's standard Basic Auth with a custom Bearer Token system using JWT.

## Key Features
- **Short-lived tokens**: Default 3-day validity.
- **Bearer authentication**: JWT tokens injected via OkHttp interceptors.
- **Offline grace period**: 6 hours of continued work after token expiry.
- **Soft expiry**: User-friendly re-auth prompts when online.
- **Hard expiry**: Forced logout after grace period deadline.

## Authentication State Machine
The system moves from `LOGGED_OUT` to `LOGGED_IN` upon successful login. Within `LOGGED_IN`, it can transition to a `GRACE_PERIOD` state if the token expires.

### States
- **ACTIVE**: Token is valid.
- **GRACE_PERIOD**: Token expired but within 6-hour window.
- **SOFT_EXPIRY**: Grace period + server reachable = prompt user to re-auth.
- **OFFLINE_GRACE**: Grace period + server unreachable = allow offline work.

## Secure Storage
Sensitive data is stored via `EncryptedSharedPreferences` (`medres_auth_secure`).
- `deviceToken`: JWT bearer token.
- `tokenExpiry`: Expiry timestamp in milliseconds.
- `pin_hash`: PBKDF2-HMAC-SHA1 hash of the security PIN.

## Re-Authentication Flow
Triggered by:
1. Soft expiry detection.
2. Manual refresh in settings.
3. MEDRES API 401 detection via `AuthInterceptor`.

When in re-auth mode, `MedresLoginActivity` pre-fills the username and prompts only for the password.

## Security Properties
- **Revocation**: Server-side `/revoke` endpoint.
- **Failed attempts**: 3 failed PIN attempts trigger a local wipe (security context) and logout.
- **Clock Manipulation**: Detected via `ClockValidator` using `last_valid_wall_time` from server responses.

## Related Content
- [[medres-architectural-boundaries]]
- [[medres-persistence-and-preferences]]
- [[medres-telemetry-and-logging]]
