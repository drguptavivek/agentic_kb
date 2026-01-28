---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #api #endpoints #app-user #authentication
created: 2026-01-28
---

# ODK Central VG App User API Reference

> **Sources**: `docs/vg/vg-server/routes/app-user-auth.md`, `routes/app-user-sessions.md`, `routes/app-users.md`

## Overview

VG adds new endpoints for app user authentication, session management, and project settings. All endpoints are prefixed with `/v1`.

## Authentication Endpoints

### Login for Short-Lived Token

**POST** `/projects/:projectId/app-users/login`

- **Auth**: Anonymous
- **Request** (JSON):
  ```json
  {
    "username": "collect-user",
    "password": "GoodPass!1X",
    "deviceId": "device-123",
    "comments": "tablet-1"
  }
  ```
- **Response** (200):
  ```json
  {
    "id": 12,
    "token": "abcd1234...tokenchars...",
    "projectId": 1,
    "expiresAt": "2025-12-19T16:00:00.000Z",
    "serverTime": "2025-12-16T16:00:01.000Z"
  }
  ```
- **Validation**:
  - Missing body/username/password → `400.3` `missingParameters`
  - Non-string values → `400.11` `invalidDataTypeOfParameter`
- **Failure**: `401.2` `authenticationFailed`
- **Lockout**: 5 failures/5min per username+IP → 10min lock

### Change Password (Self)

**POST** `/projects/:projectId/app-users/:id/password/change`

- **Auth**: App user bearer token (self)
- **Request** (JSON):
  ```json
  {
    "oldPassword": "GoodPass!1X",
    "newPassword": "NewPass!2Y"
  }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```
- **Behavior**: Terminates all sessions for the actor
- **Validation**:
  - Missing values → `400.3` `missingParameters`
  - Too long (>72) → `400.38` `passwordTooLong`
  - Weak password → `400.20` `passwordWeak`

### Reset Password (Admin)

**POST** `/projects/:projectId/app-users/:id/password/reset`

- **Auth**: Admin/manager on the project
- **Request** (JSON):
  ```json
  { "newPassword": "ResetPass!3Z" }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```
- **Behavior**: Terminates all sessions for the actor

### Revoke Own Sessions

**POST** `/projects/:projectId/app-users/:id/revoke`

- **Auth**: App user bearer token (self)
- **Request** (JSON):
  ```json
  { "deviceId": "device-123" }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```
- **Behavior**: Revokes only the current token

### Revoke Sessions (Admin)

**POST** `/projects/:projectId/app-users/:id/revoke-admin`

- **Auth**: Admin/manager on the project
- **Response** (200):
  ```json
  { "success": true }
  ```

### Deactivate/Reactivate

**POST** `/projects/:projectId/app-users/:id/active`

- **Auth**: Admin/manager on the project
- **Request** (JSON):
  ```json
  { "active": false }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```
- **Behavior**:
  - `false`: Deactivates user and revokes all sessions
  - `true`: Reactivates user

## Session Management Endpoints

### List App User Sessions

**GET** `/projects/:projectId/app-users/:id/sessions`

- **Auth**: Admin/manager on the project
- **Query params**:
  - `limit` (optional): Pagination limit
  - `offset` (optional): Pagination offset
- **Response header**: `X-Total-Count`
- **Response** (200):
  ```json
  [
    {
      "id": 10,
      "createdAt": "2025-12-16T16:00:00.000Z",
      "expiresAt": "2025-12-19T16:00:00.000Z",
      "ip": "127.0.0.1",
      "userAgent": "Collect/1.0",
      "deviceId": "device-123",
      "comments": "tablet-1"
    }
  ]
  ```

### List Project Sessions

**GET** `/projects/:projectId/app-users/sessions`

- **Auth**: Admin/manager on the project
- **Query params**:
  - `appUserId` (optional): Filter by app user
  - `dateFrom` (optional): ISO datetime start
  - `dateTo` (optional): ISO datetime end
  - `limit` (optional): Pagination limit
  - `offset` (optional): Pagination offset
- **Response header**: `X-Total-Count`
- **Response** (200):
  ```json
  [
    {
      "id": 10,
      "appUserId": 12,
      "createdAt": "2025-12-16T16:00:00.000Z",
      "expiresAt": "2025-12-19T16:00:00.000Z",
      "ip": "127.0.0.1",
      "userAgent": "Collect/1.0",
      "deviceId": "device-123",
      "comments": "tablet-1"
    }
  ]
  ```

### Revoke Single Session

**POST** `/projects/:projectId/app-users/sessions/:sessionId/revoke`

- **Auth**: Admin/manager on the project
- **Response** (200):
  ```json
  { "success": true }
  ```

## Settings Endpoints

### Get Project Settings

**GET** `/projects/:projectId/app-users/settings`

- **Auth**: Admin/manager (`project.read`)
- **Response** (200):
  ```json
  {
    "vg_app_user_session_ttl_days": 3,
    "vg_app_user_session_cap": 3,
    "admin_pw": "vg_custom"
  }
  ```

### Update Project Settings

**PUT** `/projects/:projectId/app-users/settings`

- **Auth**: Admin/manager (`project.update`)
- **Request** (JSON) - any of:
  ```json
  {
    "vg_app_user_session_ttl_days": 5,
    "vg_app_user_session_cap": 5,
    "admin_pw": "new_admin_pw"
  }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```

### Get System Settings

**GET** `/system/settings`

- **Auth**: `config.read`
- **Response** (200):
  ```json
  {
    "vg_app_user_session_ttl_days": 3,
    "vg_app_user_session_cap": 3,
    "admin_pw": "vg_custom"
  }
  ```

### Update System Settings

**PUT** `/system/settings`

- **Auth**: `config.set`
- **Request** (JSON) - any of:
  ```json
  {
    "vg_app_user_session_ttl_days": 5,
    "vg_app_user_session_cap": 5,
    "admin_pw": "new_admin_pw"
  }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```

## Telemetry Endpoints

### Submit Telemetry

**POST** `/projects/:projectId/app-users/telemetry`

- **Auth**: App user bearer token
- **Request** (JSON):
  ```json
  {
    "deviceId": "device-123",
    "collectVersion": "Collect/2025.1",
    "deviceDateTime": "2025-12-21T10:00:00.000Z",
    "location": {
      "latitude": 37.7749,
      "longitude": -122.4194,
      "altitude": 10.5,
      "accuracy": 3.2
    },
    "event": {
      "id": "evt-001",
      "type": "form_opened",
      "occurredAt": "2025-12-21T09:59:00.000Z",
      "details": { "formId": "registration" }
    }
  }
  ```
- **Response** (200):
  ```json
  {
    "status": "ok",
    "serverTime": "2025-12-21T10:00:01.000Z"
  }
  ```
- **Idempotency**: Events upserted on `(appUserId, deviceId, event.id)`

### List Telemetry (Admin)

**GET** `/system/app-users/telemetry`

- **Auth**: `config.read`
- **Query params**:
  - `projectId` (optional)
  - `deviceId` (optional)
  - `appUserId` (optional)
  - `dateFrom` (optional)
  - `dateTo` (optional)
  - `limit` (optional)
  - `offset` (optional)
- **Response header**: `X-Total-Count`

## Lockout Endpoints

### Clear Lockout

**POST** `/system/app-users/lockouts/clear`

- **Auth**: `config.set`
- **Request** (JSON):
  ```json
  {
    "username": "collect-user",
    "ip": "127.0.0.1"
  }
  ```
- **Response** (200):
  ```json
  { "success": true }
  ```

## Related Documentation

- [[ODK-Central-vg/odk-central-vg-overview]] - Main overview
- [[ODK-Central-vg/authentication-patterns]] - Auth types
- [[ODK-Central-vg/settings]] - Settings details
