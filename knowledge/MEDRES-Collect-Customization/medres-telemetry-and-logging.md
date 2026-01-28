---
title: MEDRES Telemetry and Logging Architecture
type: reference
domain: MEDRES-Collect-Customization
tags:
  - telemetry
  - logging
  - analytics
  - medres
  - work-manager
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES Telemetry and Logging Architecture

## Overview
The telemetry system tracks device location, activity, and application events. It is designed to be offline-first using local persistence.

## Logging Layers

### 1. Local Analytics (MedresAppAnalytics)
- **Purpose**: Immediate diagnostic logging for developers/QA.
- **Scope**: Authentication attempts, network errors, security incidents.
- **Implementation**: Strictly isolated from standard ODK analytics to prevent circular dependencies.

### 2. Server Telemetry (TelemetryWorker)
- **Purpose**: Periodic reporting to the Central Backend.
- **Sync Interval**: 20 minutes (default).
- **Transport**: Persistent Room DB stores events until successfully acknowledged by the server.

## Telemetry Flow
1. **Trigger**: Event occurs in the app.
2. **Submission**: App attempts immediate submission via `MedresAuthManager`.
3. **Queue**: If offline or if a 401 (re-auth required) occurs, data is saved to `TelemetryEntity` (Room).
4. **Sync**: `TelemetryWorker` periodic task flushes the queue when online.

## 401 Handling
The telemetry system integrates with the global `AuthInterceptor`. If a telemetry post returns 401, the interceptor may trigger a re-authentication flow (PIN prompt) before retrying the request.

## Deduplication
The server performs idempotent upserts based on a client-generated stable ID `(appUserId, deviceId, event.id)`, allowing for safe retries without duplication.

## Related Content
- [[medres-architectural-boundaries]]
- [[medres-authentication-architecture]]
- [[medres-persistence-and-preferences]]
