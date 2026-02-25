---
title: Keycloak User Session Count Limiter
type: howto
domain: Keycloak
tags:
  - keycloak
  - authentication-flows
  - sessions
  - session-limits
  - ciba
  - identity-brokering
status: approved
created: 2026-02-25
updated: 2026-02-25
---

# Keycloak User Session Count Limiter

## Overview

Keycloak can enforce limits on concurrent user sessions through the `User Session Count Limiter` authenticator. Limits can be enforced:

- Per realm user session count
- Per client session count

The authenticator is flow-based, so placement in authentication flows determines when limits are checked.

## Configure the Limiter in a Flow

### Steps

1. Go to `Authentication -> Flows`.
2. Select the target flow and click `Add step`.
3. Choose `User session count limiter`.
4. Set execution requirement to `REQUIRED`.
5. Open the execution config (gear icon).
6. Configure:
   - Alias
   - Maximum realm sessions per user
   - Maximum client sessions per user
   - Behavior when limit is reached
   - Optional custom error message

## Configuration Fields and Behavior

### Maximum Sessions Per Realm User

- Example: value `2` means each user can have at most 2 SSO sessions in the realm.
- Value `0` disables this check.

### Maximum Sessions Per Client User

- Example: value `2` means each user can have at most 2 sessions for a specific client.
- Value `0` disables this check.

### Combined Limits Rule

If both checks are enabled, keep client limit lower than or equal to realm limit.  
Per-client sessions cannot exceed total allowed SSO sessions.

### Limit-Reached Behavior

- `Deny new session`: authentication is denied when limit is reached.
- `Terminate oldest session`: oldest existing session is removed and new session is created.

### Optional Error Message

A custom message can be shown when authentication is denied due to session limits.

## Where to Add This Authenticator

Add the limiter where the user is already known in the flow, usually near the end of authentication.

Recommended flows:

- Browser flow
- Direct Grant flow
- Reset Credentials flow
- Post Broker Login flow

## Browser Flow Placement Pattern

Avoid placing session-limit checks directly at top level where Cookie authenticator handles SSO re-authentication.

Recommended pattern:

1. Keep `Cookie` at top level.
2. Add an `ALTERNATIVE` subflow at the same level as `Cookie`.
3. Inside that subflow, add a nested `REQUIRED` subflow for real authentication steps.
4. Add `User Session Count Limiter` inside that real-authentication branch.

This avoids re-checking limits during automatic SSO cookie re-authentication for already-existing sessions.

## Post Broker Login Requirement

For identity-provider logins, configure limiter in the `Post Broker Login` flow and ensure identity providers are configured to use that post-broker flow.  
Otherwise brokered logins may bypass session-limit enforcement.

## Consistency Requirement

Administrators must keep limiter configuration consistent across all relevant flows manually.

## Limitation

User session limit feature is not available for CIBA.

## Related

- [[keycloak-sessions]]
- [[keycloak-authentication-flows]]
- [[keycloak-server-administration]]
