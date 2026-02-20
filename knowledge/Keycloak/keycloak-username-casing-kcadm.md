---
title: Keycloak Username Casing with kcadm
type: note
domain: Keycloak
tags:
  - keycloak
  - kcadm
  - users
  - troubleshooting
status: approved
created: 2026-02-20
updated: 2026-02-20
related:
  - "[[keycloak-admin-cli]]"
  - "[[keycloak-server-administration]]"
---

# Keycloak Username Casing with kcadm

## Symptom

After creating a user with mixed-case username, `kcadm.sh set-password` fails with:

`User not found for username: <MixedCaseName>`

But listing users shows a lowercase username (for example `permrealmadmin`).

## Why It Happens

In this setup, username creation ended up stored/lowered as lowercase, while later command used mixed-case lookup.

`kcadm` username lookup is effectively case-sensitive against stored value in this workflow.

## Fix

Use the exact stored username from `get users` output:

```bash
kcadm.sh get users -r master --fields username --config .kcadm.config
kcadm.sh set-password -r master --username permrealmadmin --new-password 'StrongPerm@123' --config .kcadm.config
```

## Best Practice

- Always create usernames in lowercase.
- Use copy-paste from `kcadm.sh get users` output before role/password operations.
