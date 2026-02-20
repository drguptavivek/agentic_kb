---
title: Keycloak Theme Variants and Realm Branding (AIIMS Pattern)
type: howto
domain: Keycloak
tags:
  - keycloak
  - themes
  - branding
  - realms
  - admin-console
  - login
status: approved
created: 2026-02-19
updated: 2026-02-19
related:
  - "[[keycloak-themes]]"
  - "[[keycloak-server-administration]]"
---

# Keycloak Theme Variants and Realm Branding (AIIMS Pattern)

## Goal

Maintain separate branded themes per realm (example: `aiims` and `aiims-master`) and apply them safely using `kcadm`.

## Working Structure

```text
theme/
  aiims/
    login/
    admin/
    account/
  aiims-master/
    login/
    admin/
    account/
```

Also keep a runtime copy under:

```text
keycloak-26.5.3/themes/
  aiims/
  aiims-master/
```

## Realm Theme Apply Commands

```bash
./kcadm.sh update realms/aiims-new-delhi -s loginTheme=aiims -s adminTheme=aiims -s accountTheme=aiims --config .kcadm.config
./kcadm.sh update realms/master -s loginTheme=aiims-master -s adminTheme=aiims-master -s accountTheme=aiims-master --config .kcadm.config
```

Verify:

```bash
./kcadm.sh get realms/master --fields realm,loginTheme,adminTheme,accountTheme --config .kcadm.config
```

## Login Theme Notes

- Login pages are server-rendered theme pages (not React routing).
- Use static CSS/JS in `login/resources`.
- If adding click behavior on logo, parse realm from URL path (`/realms/{realm}/...`) and build dynamic redirect target.

## Admin Console Branding Notes

- Admin console is SPA-based and can still consume theme CSS/assets, but not all icons are straightforward overrides.
- In practice, welcome icon may still reference `/resources/<hash>/admin/icon.svg` and return `404` depending on bundling/path behavior.
- Reliable workaround: hide `img.keycloak__dashboard_icon` and inject custom image via CSS pseudo-element on empty-state container.

## Common Gotchas

1. Theme asset cache can mask changes.
```bash
./kc.sh start-dev --spi-theme-cache-themes=false --spi-theme-cache-templates=false --spi-theme-static-max-age=-1
```

2. File permissions can break asset serving (`rw-------` on copied images).
```bash
chmod 644 keycloak-26.5.3/themes/aiims-master/login/resources/img/logo.png
```

3. Hardcoded realm links break when realm name changes.
Use URL-derived realm detection in theme JS instead.

## Sync Between Runtime and Source Theme Folders

Runtime -> source:

```bash
rsync -a --delete keycloak-26.5.3/themes/aiims/ theme/aiims/
rsync -a --delete keycloak-26.5.3/themes/aiims-master/ theme/aiims-master/
```

Source -> runtime:

```bash
rsync -a --delete theme/aiims/ keycloak-26.5.3/themes/aiims/
rsync -a --delete theme/aiims-master/ keycloak-26.5.3/themes/aiims-master/
```
