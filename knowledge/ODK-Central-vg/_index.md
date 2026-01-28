---
title: ODK Central VG Fork Knowledge Index
type: reference
domain: ODK-Central-vg
tags:
  - odk-central
  - vg-fork
  - index
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# ODK Central VG Fork — Index

**VG Fork**: Security-hardened fork of ODK Central with password-based authentication for app users.

**Repositories**:
- Server: `drguptavivek/central-backend`
- Client: `drguptavivek/central-frontend`
- Meta: `drguptavivek/central` (with client/server as submodules)

**Branch**: `vg-work`

## Getting Started

- [[odk-central-vg-overview]] - High-level overview of VG fork features and key changes

## Server Documentation

### Architecture & Patterns
- [[vg-customization-patterns]] - Modularity conventions for maintaining VG fork (rebasing, namespace, file organization)

### API Reference
- [[app-user-api]] - Complete API endpoints for app user authentication and management
- [[authentication-patterns]] - All authentication methods (Cookie, Bearer, Field Key, Basic Auth)

### Features & Implementation
- [[security-controls]] - Password policy, session management, lockouts, rate limiting, audit events
- [[app-user-auth]] - App user authentication implementation details
- [[app-user-sessions]] - Session lifecycle, TTL, cap enforcement, metadata tracking
- [[telemetry]] - Device telemetry collection from app users
- [[vg-rate-limiting-design]] - Rate limiting strategy and implementation

### Configuration
- [[settings]] - VG settings hierarchy and configuration options

### Development & Testing
- [[implementation]] - Database schema and core modules
- [[testing]] - Test inventory (173 tests) and commands
- [[installation]] - Setup and installation guide

### Security
- [[web-user-lockout-implementation]] - Web user lockout policy implementation
- [[vg-web-login-hardening]] - Web login security hardening measures

## Client Documentation

- [[client-overview]] - Frontend changes summary
- [[vg-client-customizations]] - Vue.js UI patterns and component conventions
- [[app-user-ui]] - App user management UI components (vg-list, vg-new, vg-qr-panel, etc.)
- [[enketo-status-ui]] - Enketo management interface

## Specific Topics

- [[admin-pw-qr-integration]] - System-wide admin password in QR code payloads
- [[app-user-session-date-handling]] - Date/timestamp handling with Slonik
- [[troubleshooting-vg-issues]] - Common issues and solutions from commit history

## User Behavior

See the original documentation for expected user workflows and behaviors.
