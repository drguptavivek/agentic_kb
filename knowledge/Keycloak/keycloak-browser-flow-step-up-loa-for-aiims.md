---
title: Keycloak Browser Flow Step-Up (LoA) for AIIMS
type: howto
domain: Keycloak
tags:
  - keycloak
  - step-up
  - loa
  - acr
  - oidc
  - otp
  - authentication-flow
status: draft
created: 2026-02-25
updated: 2026-02-25
---

# Keycloak Browser Flow Step-Up (LoA) for AIIMS

## Overview

This guide documents a browser login flow that supports step-up authentication in Keycloak using `Conditional - Level Of Authentication` conditions. It allows normal sign-in at LoA 1 (username/password) and step-up to LoA 2 (OTP) when requested by the client.

## Preconditions

- Keycloak admin access to the target realm (for example `aiims-new-delhi`)
- OTP authenticator configured for users who will request LoA 2
- Existing browser flow backup or export before changing realm bindings

## Flow Design

- `Cookie` execution is `Alternative` to enable SSO reuse.
- `Auth Flow` subflow is `Alternative`.
- `1st Condition Flow` is `Conditional` with LoA 1 and `Max Age=36000`.
- `2nd Condition Flow` is `Conditional` with LoA 2 and `Max Age=0`.
- Subflows must be ordered from lowest LoA to highest LoA.

## Steps

1. Go to `Authentication` -> `Flows` -> `Create flow`.
2. Name the flow `Browser Incl Step up Mechanism`.
3. Add execution `Cookie` and set requirement to `Alternative`.
4. Add sub-flow `Auth Flow` and set requirement to `Alternative`.
5. Under `Auth Flow`, add sub-flow `1st Condition Flow` and set requirement to `Conditional`.
6. In `1st Condition Flow`, add condition `Conditional - Level Of Authentication` and set requirement to `Required`.
7. Configure the condition:
   - Alias: `Level 1`
   - Level of Authentication: `1`
   - Max Age: `36000`
8. In `1st Condition Flow`, add step `Username Password Form`.
9. Under `Auth Flow`, add sub-flow `2nd Condition Flow` and set requirement to `Conditional`.
10. In `2nd Condition Flow`, add condition `Conditional - Level Of Authentication` and set requirement to `Required`.
11. Configure the condition:
    - Alias: `Level 2`
    - Level of Authentication: `2`
    - Max Age: `0`
12. In `2nd Condition Flow`, add step `OTP Form` and set it to `Required`.
13. Bind the new flow:
    - `Authentication` -> `Action` menu -> `Bind flow`
    - Set `Browser Flow` to `Browser Incl Step up Mechanism`
    - Save

## OIDC Requesting LoA

Use `claims` when `acr` is essential:

```json
{
  "id_token": {
    "acr": {
      "essential": true,
      "values": ["gold"]
    }
  }
}
```

You can also use non-essential `acr_values`:

```text
acr_values=gold
```

Example authorization request pattern:

```text
https://{DOMAIN}/realms/{REALMNAME}/protocol/openid-connect/auth?client_id={CLIENT-ID}&redirect_uri={REDIRECT-URI}&scope=openid&response_type=code&response_mode=query&nonce={NONCE}&claims={URL-ENCODED-JSON}
```

## Runtime Behavior

- If LoA 2 is requested, user completes username/password and OTP.
- If user already has an LoA 1 session, Keycloak asks only for the extra factor needed to reach LoA 2.
- `Max Age=36000` at LoA 1 allows reuse for 10 hours.
- `Max Age=0` at LoA 2 forces fresh step-up for each request needing LoA 2.
- If no `claims` or `acr_values` is sent, Keycloak uses the first LoA condition in flow order.

## Security Notes

- Do not trust URL parameters blindly; users can alter `claims` or `acr_values`.
- Prefer PAR, request objects, or equivalent protections to prevent tampering.
- Always validate returned `acr` in the ID token against expected level.
- If essential `acr` level is requested and cannot be met, authentication fails with error.

## Validation Checklist

- [ ] LoA subflows are ordered `1` then `2`
- [ ] Users requesting LoA 2 are prompted for OTP
- [ ] Users with valid LoA 1 SSO session are not re-prompted for password unless required
- [ ] ID token includes `acr` and client verifies it
- [ ] OTP is required for sensitive operations

## Related

- [[keycloak-authentication-flows]]
- [[keycloak-otp-totp-authentication]]
- [[keycloak-securing-apps-oidc]]
- [[keycloak-stepup-authentication]]
