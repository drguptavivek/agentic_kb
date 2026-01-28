---
title: MEDRES Customization Index
type: reference
domain: MEDRES-Collect-Customization
tags:
  - index
  - medres
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# MEDRES Customization Index

This domain covers the custom authentication, security, and telemetry systems implemented for the MEDRES flavor of ODK Collect.

## Core Documentation
- [[medres-architectural-boundaries]]: Technical isolation and module dependencies.
- [[medres-authentication-architecture]]: Token lifecycle and state machine.
- [[medres-persistence-and-preferences]]: Tiered storage and preference mapping.
- [[medres-data-isolation-and-security]]: Encryption, storage tiers, and cleanup (Option B).
- [[medres-multiuser-persistence-strategy]]: Shared device support and project reuse.
- [[medres-qr-workflow-and-settings-import]]: Payload format and behavioral changes.
- [[medres-telemetry-and-logging]]: Offline-first event tracking and diagnostic logging.

## Knowledge Captured
- Auth token lifecycle (3-day TTL, 6h grace).
- Encrypted storage for sensitive metadata.
- Shared-device data preservation logic.
- Idempotent telemetry submissions.
