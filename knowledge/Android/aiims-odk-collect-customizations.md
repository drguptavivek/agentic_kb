---
title: AIIMS ODK Customizations
type: reference
domain: Android Development
tags:
  - aiims
  - auth
  - customization
  - odk
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# AIIMS ODK Collect Customizations

## Overview
This document details the modifications made to the standard ODK Collect to support the AIIMS project requirements: **Bearer Token Authentication**, **Strict Data Isolation**, and **PIN Security**.

## 1. Authentication Module (`aiims_auth_module`)
A custom Android Library module added to the project. It handles the initial user login before handing control to ODK Core.

### Bearer Token Flow
- **Standard ODK**: Uses Basic Auth (Username/Password).
- **AIIMS Customization**:
    1.  `AiimsLoginActivity` captures credentials.
    2.  Authenticates against `/projects/{id}/app-users/login`.
    3.  Receives a **JWT Bearer Token**.
    4.  Stores token in `aiims_auth_prefs`.

### Token Injection
The token is injected into ODK's networking layer via `OkHttpOpenRosaServerClientProvider` using an OkHttp Interceptor:
`Authorization: Bearer <token>`

## 2. PIN Security & App Lock
- **Requirement**: Prevent unauthorized access on shared devices if the app is minimized.
- **Implementation**:
    - **`AiimsAppLock`**: Tracks Activity lifecycle. When the app returns to foreground (`onActivityStarted`), it checks if a PIN is required.
    - **`PinEntryActivity`**: Blocks access until the correct PIN is entered.
    - **Wipe Policy**: 3 failed PIN attempts triggers a full **Logout** (Session Wipe).

## 3. Data Isolation (Project Cleaner)
- **Requirement**: User A must NOT see User B's blank forms on a shared device.
- **Implementation**:
    - **`ProjectCleaner`**: Runs on logout.
    - **Logic**: Uses `ProjectResetter` to wipe **Forms** and **Cache**, but preserves **Instances** (filled forms) to allow sync.
    - **Thread Safety**: Operations run on `Dispatchers.IO` to prevent Main Thread crashes.

## 4. Offline Resilience
- **Grace Period**: Tokens remain valid for **offline use** for ~6 hours after expiry.
- **Soft Expiry**: If the token expires but the server is reachable, the app prompts for re-auth without blocking the user's current workflow.

## 5. Local Development
- **DNS Mapping**: Debug builds map `central.local` to `10.0.2.2` (Emulator Loopback).
- **SSL**: Debug builds trust all certificates to allow local dev without valid certs.

## 6. Preference Storage
The module uses a dedicated SharedPreference file: `aiims_auth_prefs`.

### Key Preferences
**Authentication (`AiimsConstants`)**
-   `auth_token`: The active JWT Bearer Token.
-   `token_expiry`: Timestamp (ms) when token expires.
-   `active_project_id`: ID of the currently logged-in project (to support multi-project token switching).

**PIN Security (`PinManager`)**
-   `user_pin`: The stored PIN (hashed/salted).
-   `pin_attempts`: Counter for failed attempts (Resets on success, Wipes on 3).
-   `last_pin_attempt`: Timestamp of last attempt to enforce back-off (if applicable).

**Offline Revocation (`TokenRevocationManager`)**
-   `pending_revoke_auth_token`: Token waiting to be revoked on server.
-   `pending_revoke_reason`: Audit reason for the logout.

## 7. Critical Classes
-   **`AiimsAuthManager`**: The "Brain". Manages state transitions (`LoggedIn` -> `GracePeriod` -> `Expired`).
-   **`ProjectCleaner`**: The "Janitor". Wipes `forms.db` and `/forms/` dir on logout.
-   **`AiimsAppLock`**: The "Gatekeeper". Intercepts `onActivityStarted` to show `PinEntryActivity`.
-   **`TokenProvider`**: The "Bridge". Anonymous function injected into ODK logic to fetch `auth_token` from `aiims_auth_prefs`.
