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

## Related Content
- [[medres-authentication-architecture]]
- [[medres-multiuser-persistence-strategy]]
- [[medres-persistence-and-preferences]]
