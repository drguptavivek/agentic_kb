---
title: MEDRES Data Isolation and Security
type: reference
domain: MEDRES-Collect-Customization
tags:
  - encryption
  - security
  - data-isolation
  - logout
  - wipes
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES Data Isolation and Security

## Overview
The MEDRES customization implements strict data isolation to separate sensitive authentication context from standard ODK project data. This ensures security while maintaining efficiency for shared devices.

## Storage Tiers

1.  **Hardware-Backed Encrypted Storage** (`medres_auth_secure`): Uses Android's `EncryptedSharedPreferences` (AES-256-GCM) to store JWT tokens, PIN hashes, and sensitive metadata.
2.  **Standard Project Metadata** (`medres_auth_prefs`): Stores non-sensitive state and project-to-project mappings.
3.  **ODK Core Storage**: Standard ODK files preserved for business continuity.

## Security Properties
- **AES-256-GCM** for values, **AES-256-SIV** for keys.
- **Android Keystore** with hardware backing where available.
- **No Plaintext Secrets**: Zero sensitive data (JWTs, PINs) stored in standard preferences.

## Security Cleanup (Option B Model)
When a security event occurs (Manual Logout, 3 Failed PIN attempts, or Hard Expiry), the app clears the sensitive security context but preserves project-specific data to support **Shared Device Stability**.

| Category | Item | Action | Rationale |
|----------|------|--------|-----------|
| **Security** | Auth Token (JWT) | ✅ **Wiped** | Prevents unauthorized API access. |
| **Security** | Security PIN | ✅ **Wiped** | Forces next user to set their own PIN. |
| **Security** | Session State | ✅ **Wiped** | Clears authentication flags and active IDs. |
| **Security** | Clock State | ✅ **Wiped** | Resets wall-time anchors to prevent replay attacks. |
| **User Data** | User Profile | ✅ **Wiped** | Clears UID and username. |
| **Project Data** | Blank Forms | ❌ **Preserved** | Saves bandwidth; constant across same project users. |
| **Project Data** | Saved Instances | ❌ **Preserved** | Supports team continuity and shared device drafts. |
| **Project Data** | Submitted History | ❌ **Preserved** | Device audit trail remains intact. |
| **Configuration** | Project URL/Name | ❌ **Preserved** | Simplifies re-login for the next user. |

## Related Content
- [[medres-architectural-boundaries]]
- [[medres-authentication-architecture]]
- [[medres-persistence-and-preferences]]
- [[medres-multiuser-persistence-strategy]]
