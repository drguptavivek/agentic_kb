---
title: Keycloak Workflows Use Cases and Rollout Plan for AIIMS SSO
type: howto
domain: Keycloak
tags:
  - keycloak
  - workflows
  - aiims
  - iga
  - user-lifecycle
  - jml
  - automation
status: draft
created: 2026-02-25
updated: 2026-02-25
---

# Keycloak Workflows Use Cases and Rollout Plan for AIIMS SSO

## Overview

This note maps Keycloak Workflows capabilities to practical use cases for the `aiims-new-delhi` realm and provides a rollout sequence that fits this repository.

## Why This Matters in This Repo

The current repository already implements foundational controls:

- Step-up authentication (`Step_12_browser_login_flow_stepup.md`)
- Phone OTP custom authenticator (`Step_4_PhoneSMSOTP.md`)
- Account expiry enforcement (`Step_5_Account_expiry.md`)
- Group/claims shaping (`Step_3_custom-group-attr-mapper_andCLAIMS.md`)

Workflows add lifecycle automation on top of these controls so policy execution becomes consistent and less dependent on manual admin operations.

## Recommended Workflow Use Cases

| Use case | Trigger (`on`) | Key condition (`if`) | Main steps | Primary outcome |
|---|---|---|---|---|
| Onboarding baseline | `user_created` | `not has-role('realm-admin')` | `notify-user`, `set-user-required-action` | Secure first login and user guidance |
| Joiner-Mover-Leaver (JML) | `user_group_membership_added('/...')` and `user_group_membership_removed('/...')` | Group-specific | notify and role hygiene actions | Role drift reduction |
| Inactivity control | `user_authenticated` + `schedule` | Exclude admins/service users | warning emails, then `disable-user` | Least-privilege enforcement over time |
| Contractor expiry | `schedule` | `has-user-attribute('employment_type','contract')` | warning email, then `disable-user` | Time-bound access governance |
| Federated unlink response | `user_federated_identity_removed('idp-alias')` | none | `set-user-required-action`, notify | Fast recovery from broken IdP links |

## YAML Starter Examples

### Onboarding New Users

```yaml
name: AIIMS onboarding baseline
on: user_created
if: not has-role('realm-admin')
steps:
  - uses: notify-user
    with:
      subject: "Welcome to AIIMS SSO"
      message: |
        <p>Welcome ${user.firstName}.</p>
        <p>Please complete password update and MFA setup.</p>
  - uses: set-user-required-action
    with:
      action: UPDATE_PASSWORD
  - uses: set-user-required-action
    with:
      action: CONFIGURE_TOTP
```

### Inactive User Disablement

```yaml
name: AIIMS inactive user control
on: user_authenticated
if: not has-role('realm-admin')
concurrency: restart-in-progress
steps:
  - uses: notify-user
    after: 180d
    with:
      subject: "AIIMS account inactivity notice"
      message: "Please sign in to keep your account active."
  - uses: notify-user
    after: 60d
    with:
      subject: "AIIMS account final warning"
      message: "Your account will be disabled in ${workflow.daysUntilNextStep} days."
  - uses: disable-user
    after: 7d
```

### Scheduled Contractor Review

```yaml
name: AIIMS contractor account review
schedule:
  after: 24h
  batch-size: 100
if: has-user-attribute('employment_type', 'contract')
steps:
  - uses: notify-user
    with:
      subject: "Contract account review"
      message: "Your account is under periodic access review."
```

## Rollout Plan (Phased)

1. Establish workflow runtime configuration in dev (`--features=workflows`, shorter step-runner interval for testing).
2. Implement onboarding and inactivity workflows first because they provide the highest security value with low coupling.
3. Validate workflow behavior with test users (`doctor1`, non-admin, admin) and confirm admin exclusions.
4. Add schedule-based contractor and cleanup workflows after baseline event-driven flows are stable.
5. Move to production intervals and monitor logs/metrics before enabling destructive actions such as delete.

## Guardrails

- Prefer `disable-user` before any deletion logic.
- Exclude realm admins and automation/service users from lifecycle workflows.
- Keep `enabled: false` during dry-runs until behavior is verified.
- Use shorter test delays in dev (`30s`, `2m`) and long durations only in production.

## Validation Checklist

- [ ] Workflow events use underscore format (for example, `user_created`).
- [ ] All workflows include explicit admin/service account exclusion conditions.
- [ ] Scheduled interval and timeout are tuned for expected load.
- [ ] Notifications are validated with configured SMTP settings.
- [ ] Realm admin confirms results in Admin Console workflow execution history.

## References

- [Keycloak Server Administration: Managing Workflows](https://www.keycloak.org/docs/latest/server_admin/index.html#_managing_workflows)

## Related

- [[keycloak-workflows]]
- [[keycloak-authentication-flows]]
- [[keycloak-browser-flow-step-up-loa-for-aiims]]
- [[keycloak-otp-totp-authentication]]
