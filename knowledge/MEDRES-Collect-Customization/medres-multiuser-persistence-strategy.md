---
title: MEDRES Multi-User Persistence Strategy
type: reference
domain: MEDRES-Collect-Customization
tags:
  - shared-device
  - persistence
  - multi-project
  - data-loss-prevention
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES Multi-User Persistence Strategy

## Objective
Enable multi-user support on a single shared device by preserving project-specific data (forms, instances, settings) when switching between different projects or users.

## "Find or Create" Pattern
To prevent data loss during project switching, the MEDRES logic implements a non-destructive pattern for project configuration:

1.  **Detection**: When a new project is configured (via QR scan or manual input), the app searches for an existing ODK project matching the target Server URL and Project ID.
2.  **Mapping**: Uses the `central_to_odk_$pid` key in `medres_auth_prefs` to link a Central Project ID to an internal ODK Project UUID.
3.  **Reuse**: If a match is found, the existing ODK project is reused, preserving all downloaded forms and saved drafts.
4.  **Creation**: A new ODK project is created only if no existing match is found.

## Performance & Bandwidth
By preserving ODK projects on disk instead of wiping them on every logout/switch, bandwidth is saved as forms do not need to be re-downloaded. This is critical for field teams with limited connectivity.

## Single-Project Visibility
While multiple projects may exist on disk, MEDRES enforces **Single-Project Visibility**. Only the "currently active" (authenticated) project is visible in the main menu context, maintaining the security boundary.

## Related Content
- [[medres-data-isolation-and-security]]
- [[medres-persistence-and-preferences]]
- [[medres-qr-workflow-and-settings-import]]
