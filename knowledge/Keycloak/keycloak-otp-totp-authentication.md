---
title: Keycloak OTP Policies (TOTP and HOTP)
type: reference
domain: Keycloak
tags:
  - keycloak
  - otp
  - totp
  - hotp
  - mfa
  - authentication
status: draft
created: 2026-02-25
updated: 2026-02-25
related: [[keycloak-authentication-flows]], [[keycloak-security]], [[keycloak-recovery-codes]]
---

# Keycloak OTP Policies (TOTP and HOTP)

## Overview

Keycloak supports one-time password (OTP) policies used by authenticator apps such as FreeOTP and Google Authenticator. OTP settings are managed per realm in the Admin Console:

1. Open **Authentication**
2. Open **Policy**
3. Open **OTP Policy**

The OTP setup QR code shown to users is generated from these policy settings.

## OTP Modes

### TOTP (Time-Based One-Time Password)

TOTP uses current time plus a shared secret. Codes are valid only for a short time window and rotate based on token period.

Key points:
- Better security posture than HOTP in most deployments
- Does not require server-side counter increments per successful login
- Can allow brief replay within valid window unless reusable code is disabled

### HOTP (Counter-Based One-Time Password)

HOTP uses a shared counter plus a shared secret. The server advances counter state after successful OTP validation.

Key points:
- More forgiving for user timing (no strict time window pressure)
- Requires persistent counter updates in the database
- Higher write overhead under load compared with TOTP

## TOTP Policy Options

### OTP Hash Algorithm

Available values:
- `SHA1` (default)
- `SHA256`
- `SHA512`

Recommendation: prefer `SHA256` or `SHA512` when client compatibility is confirmed.

### Number of Digits

Length of generated OTP code.

Tradeoff:
- Fewer digits: easier to type
- More digits: stronger brute-force resistance

### Look Around Window

Number of intervals accepted before/after current interval to handle clock drift.

Typical default: `1`.

Example with 30-second period and window `1`:
- Accepts previous 30s, current 30s, next 30s
- Effective acceptance window is about 90 seconds

Each extra window step adds another previous + next interval.

### OTP Token Period

Interval in seconds for TOTP rollover.

Typical value: `30` seconds.

### Reusable Code

Controls whether a still-valid TOTP can be reused during the same validity window.

Recommended: disabled (`false`) unless there is a specific compatibility requirement.

## HOTP Policy Options

### OTP Hash Algorithm

Same algorithm choices as TOTP:
- `SHA1`
- `SHA256`
- `SHA512`

### Number of Digits

Same digit-length tradeoff as TOTP.

### Look Around Window

Number of counter positions before/after current counter that Keycloak will test to tolerate client/server counter drift.

### Initial Counter

Starting counter value for HOTP tokens.

## Suggested Realm Baseline

For most production realms:
- Type: `totp`
- Algorithm: `SHA256`
- Digits: `6`
- Period: `30`
- Look around window: `1`
- Reusable code: `false`

## kcadm Example

```bash
./kcadm.sh update realms/aiims-new-delhi \
  -s otpPolicyType=totp \
  -s otpPolicyAlgorithm=HmacSHA256 \
  -s otpPolicyDigits=6 \
  -s otpPolicyLookAheadWindow=1 \
  -s otpPolicyPeriod=30 \
  -s otpPolicyCodeReusable=false \
  --config .kcadm.config
```

Note: For the CLI update endpoint, algorithm values are commonly represented as `HmacSHA1`, `HmacSHA256`, `HmacSHA512`.

## Verification

```bash
./kcadm.sh get realms/aiims-new-delhi --config .kcadm.config | jq \
  '.otpPolicyType,.otpPolicyAlgorithm,.otpPolicyDigits,.otpPolicyLookAheadWindow,.otpPolicyPeriod,.otpPolicyCodeReusable,.otpPolicyInitialCounter'
```

