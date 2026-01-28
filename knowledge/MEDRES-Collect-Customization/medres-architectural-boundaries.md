---
title: MEDRES vs Standard ODK Architectural Boundaries
type: reference
domain: MEDRES-Collect-Customization
tags:
  - architecture
  - medres
  - odk-collect
  - module-boundaries
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES vs Standard ODK Architectural Boundaries

## Overview
This document defines the architectural boundaries between the MEDRES customization and the standard ODK Collect codebase. The goal is to ensure that MEDRES-specific logic is isolated, making it easier to sync with upstream ODK updates and preventing custom logic from inadvertently affecting standard ODK behavior.

## 1. Module Boundaries

### open-rosa (Standard)
- **Rule**: **Zero custom code.**
- **Purpose**: Implements the OpenRosa protocol (form discovery, submission, etc.).
- **Boundary**: This module must remain identical to the upstream version. Any networking requirement from the MEDRES layer must be satisfied via implementation of interfaces (e.g., `TokenProvider`) or configuration, never by modifying the library's classes.

### medres-auth-module (Custom)
- **Rule**: Contains all MEDRES-specific logic.
- **Purpose**: Authentication (Bearer Token), Security (PIN, App Lock), Telemetry, and MEDRES API clients.
- **Boundary**: Functions as a standalone library that the main app depends on. It does not know about ODK's form management or database structures.

### collect_app (Integration Layer)
- **Purpose**: The "glue" that connects standard ODK modules with the MEDRES Auth module.
- **Boundary**: Uses Dagger/Hilt to inject MEDRES implementations into ODK interfaces.
  - **Example**: Injecting an MEDRES `TokenProvider` into ODK's `OkHttpConnection`.

## 2. Networking Boundary

| Feature | Standard ODK / OpenRosa | MEDRES Customization |
|---------|-------------------------|---------------------|
| **Protocol** | `OpenRosaHttpInterface` | `RealAuthClient` (Retrofit) |
| **Auth** | Basic Auth (supported by ODK) | Bearer Token (MEDRES-only) |
| **401 Handling**| Propagates error to ODK Core | `AuthInterceptor` + blocking re-auth |
| **Target APIs** | `/formList`, `/submission` | `/telemetry`, `/login`, `/revoke` |

> [!IMPORTANT]
> **Interception Boundary**: 401 interception and automatic retry is strictly limited to MEDRES-specific API calls (`RealAuthClient`). Standard ODK network calls for form management are **not** intercepted and do not trigger MEDRES re-authentication flows automatically.

## 3. UI & Security Boundary

- **Pre-menu Security**: MEDRES-specific activities (`MedresLoginActivity`, `PinEntryActivity`) guard the entry points to the standard ODK `MainMenuActivity`.
- **Lifecycle Monitoring**: `MedresAppLock` monitors activity lifecycle to re-trigger the PIN screen.

## 4. Persistence & Preference Boundary
 
MEDRES uses a tiered storage architecture to separate sensitive authentication data from standard application settings. (See [[medres-persistence-and-preferences]] for details).

### The "Materialization" Boundary
A key boundary exists during the login/setup phase:
- **Staged State**: Before login, MEDRES logic stores target configuration (Base URL, PID) in `medres_auth_prefs`.
- **Project Materialization**: Upon successful login, MEDRES logic "materializes" the config into ODK by creating an ODK Project and setting the `server_url`.

## 5. Cleanup Rules & Shared Device Boundary

- **Logout**: MEDRES logic clears MEDRES-specific tokens, PIN, and user metadata.
- **Data Retention**: Standard ODK *forms*, *instances*, and *settings* are **preserved** to support shared device scenarios.

## 6. Summary of Integration Points

| Integration Point | Mechanism | Implementation |
|-------------------|-----------|----------------|
| **Dependency Injection** | Dagger `AppDependencyModule` | Injects MEDRES components into ODK interfaces |
| **Networking** | `TokenProvider` | Provides MEDRES Bearer Token to OpenRosa client |
| **Lifecycle** | `ActivityLifecycleCallbacks` | `MedresAppLock` manages PIN/Auth state checks |
| **Project Setup** | `MedresLoginActivity` | Populates ODK `ProjectsRepository` with Central details |

## Related Content
- [[medres-authentication-architecture]]
- [[medres-persistence-and-preferences]]
- [[medres-telemetry-and-logging]]
