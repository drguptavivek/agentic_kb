---
title: MEDRES QR Workflow and Settings Import
type: reference
domain: MEDRES-Collect-Customization
tags:
  - qr-code
  - settings-import
  - authentication
  - configuration
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES QR Workflow and Settings Import

## Overview
QR code scanning in MEDRES ODK Collect is a **core feature change** from default ODK behavior. It is designed to configure project settings without bypassing mandatory authentication.

## QR Payload Structure
The QR code contains a JSON payload (compressed via zlib DEFLATE and Base64 encoded) including:
- **`general`**: Server URL, form update mode (`match_exactly`), automatic updates.
- **`admin`**: Admin password and permissions.
- **`project`**: Project name and ID.

## Behavioral Changes

| Feature | Standard ODK | MEDRES Customization |
|---------|--------------|----------------------|
| **Post-Scan Action** | Navigates to Main Menu | **Returns to Login Screen** |
| **Auth Bypass** | Tokens can be in QR | **Tokens IGNORED**; User must login |
| **Visibility** | Import option in Settings | **HIDDEN** (Force login screen use) |
| **Project Erasure** | Delete project allowed | **HIDDEN** (Managed by cleanup logic) |

## Configuration Change Detection
The app monitors the current configuration and triggers specific actions if a new QR scan changes critical parameters:

- **`server_url` change**: Immediately clears existing auth tokens and forces logout.
- **`username` change**: Immediately clears existing auth tokens and forces logout.
- **Other settings**: Applied immediately without session interruption.

## Project UUID Generation
Internal ODK Project UUIDs are generated using `UUID.randomUUID()` at the moment of first configuration (QR scan). This UUID is essential for file naming in SharedPreferences (`general_prefs{projectUUID}`).

## Security Protections

MEDRES implements defense-in-depth security for all QR codes:

### Payload Size Limits
- **Compressed**: 4KB max (DoS prevention)
- **Decompressed**: 16KB max (decompression bomb prevention)
- **Compression Ratio**: 4:1 maximum

### Key Validation
- **General Settings**: Whitelist validation against `ProjectKeys`
- **Admin Settings**: Whitelist validation against `ProtectedProjectKeys`
- **Invalid Keys**: Logged and rejected (prevents injection)

### Type Safety
- Boolean, String, Integer type checking
- Admin settings must be boolean only
- Type mismatches logged and rejected

### Sensitive Key Protection
Blocked from QR override: `server_url`, `username`, `password`, `protocol`

### Attack Prevention
All QR types (MEDRES, Demo, Standard ODK) are protected against:
- Decompression bombs (4KB → gigabytes)
- Malicious key injection
- Credential theft via QR
- OOM/ANR crashes
- Type confusion attacks

## Related Content
- [[medres-authentication-architecture]]
- [[medres-multiuser-persistence-strategy]]
- [[medres-persistence-and-preferences]]
