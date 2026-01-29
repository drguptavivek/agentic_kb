---
title: Keycloak Hostname Configuration (v2)
domain: Keycloak
type: howto
status: draft
tags: [keycloak, hostname, proxy, tls, configuration]
created: 2026-01-29
related: [[keycloak-server-configuration-guide]], [[keycloak-reverse-proxy]], [[keycloak-security]]
---

# Keycloak Hostname Configuration (v2)

## Overview

Keycloak requires explicit hostname configuration for security reasons. This prevents attackers from manipulating URLs in emails, redirects, and tokens.

**Why hostname is required:**
- OIDC Discovery endpoint exposes server URLs
- Password reset emails contain links
- Action tokens must reference valid issuer
- Prevents fraudulent token issuance

## Basic Configuration

### Simple Hostname

```bash
bin/kc.sh start --hostname my.keycloak.org
```

**Result:** Accessible at `https://my.keycloak.org:8443`

### Full URL with Port

```bash
bin/kc.sh start --hostname https://my.keycloak.org
```

**Result:** Accessible at `https://my.keycloak.org` (default HTTPS port 443)

### Full URL with Context Path

```bash
bin/kc.sh start --hostname https://my.keycloak.org:123/auth
```

**Result:** Accessible at `https://my.keycloak.org:123/auth`

## Endpoint Types

Keycloak exposes three endpoint groups:

```
┌─────────────────────────────────────────────────────────────┐
│                     Keycloak Endpoints                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │   Frontend     │  │   Backend      │  │ Administration  │ │
│  │                │  │                │  │                │ │
│  │ - Login pages  │  │ - Token endpoint│  │ - Admin Console│ │
│  │ - Registration │  │ - Introspection │  │ - Admin REST API│ │
│  │ - Account UI   │  │ - UserInfo     │  │ - Management UI │ │
│  │ - Password     │  │ - JWKS         │  │                │ │
│  │   reset        │  │ - Backchannel  │  │                │ │
│  │                │  │   auth         │  │                │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│                                                               │
│  Publicly accessible   Private/Public    Separate network    │
│                       communication     or restricted        │
└─────────────────────────────────────────────────────────────┘
```

### Frontend Endpoints

Public browser-based flows:
- Login page access
- Password reset links
- Account console
- Registration flows

**Configuration:**
```bash
bin/kc.sh start --hostname https://my.keycloak.org
```

### Backend Endpoints

Direct client-to-Keycloak communication:
- Token endpoint
- Token introspection
- UserInfo endpoint
- JWKS endpoint
- Backchannel authentication

**Dynamic backchannel for private network:**
```bash
bin/kc.sh start \
  --hostname https://my.keycloak.org \
  --hostname-backchannel-dynamic=true
```

This allows:
- Frontend: Public URL `https://my.keycloak.org`
- Backend: Dynamically resolved from request headers (private network)

### Administration Endpoints

Admin console and management APIs:
- Admin Console UI
- Admin REST API
- Management interface

**Separate admin hostname:**
```bash
bin/kc.sh start \
  --hostname https://my.keycloak.org \
  --hostname-admin https://admin.my.keycloak.org:8443
```

**Important:** Using `hostname-admin` doesn't block admin API access via frontend URL. Configure reverse proxy to restrict access.

## URL Resolution Sources

```
┌─────────────────────────────────────────────────────────────┐
│                    URL Resolution Priority                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Server-wide config (hostname, hostname-admin)            │
│  2. Realm frontend URL configuration                         │
│  3. Dynamic from request:                                    │
│     - Host header                                            │
│     - Forwarded header (RFC 7239)                            │
│     - X-Forwarded-* headers                                  │
│     - Scheme, server port, context path                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Proxy Configuration

### Edge TLS Termination

Proxy terminates TLS, forwards HTTP to Keycloak:

```bash
bin/kc.sh start \
  --hostname https://my.keycloak.org \
  --http-enabled=true
```

```
Internet → Proxy (HTTPS) → Keycloak (HTTP:8080)
```

### Re-encrypted TLS

Proxy terminates TLS, creates new TLS to Keycloak:

```bash
bin/kc.sh start \
  --hostname https://my.keycloak.org \
  --proxy-headers=forwarded
```

```
Internet → Proxy (HTTPS) → Keycloak (HTTPS:8443)
```

### Dynamic URL Resolution

Allow proxy to set hostname via headers:

**Fully dynamic:**
```bash
bin/kc.sh start \
  --hostname-strict=false \
  --proxy-headers=forwarded
```

**Partially dynamic (hostname fixed):**
```bash
bin/kc.sh start \
  --hostname my.keycloak.org \
  --proxy-headers=xforwarded
```

Scheme and port resolved from `X-Forwarded-*` headers, hostname fixed.

**Fixed URLs with origin checking:**
```bash
bin/kc.sh start \
  --hostname https://my.keycloak.org \
  --proxy-headers=xforwarded
```

URLs fixed, but headers used for origin validation.

## Proxy Headers

### Forwarded Header (RFC 7239)

```bash
bin/kc.sh start --proxy-headers=forwarded
```

**Proxy should set:**
```
Forwarded: for=192.0.2.1;host=my.keycloak.org;proto=https
```

### X-Forwarded-* Headers

```bash
bin/kc.sh start --proxy-headers=xforwarded
```

**Proxy should set:**
```
X-Forwarded-For: 192.0.2.1
X-Forwarded-Host: my.keycloak.org
X-Forwarded-Proto: https
X-Forwarded-Port: 443
```

### Trusted Proxies

Limit which proxies can set headers:

```bash
bin/kc.sh start \
  --proxy-headers=forwarded \
  --proxy-trusted-addresses=192.168.1.0/24,10.0.0.0/8
```

## Configuration Options

### hostname

**Type:** String
**Default:** Required in production

Address at which server is exposed. Can be full URL or hostname.

```bash
--hostname my.keycloak.org           # Hostname only
--hostname https://my.keycloak.org   # Full URL
--hostname https://my.keycloak.org/auth  # With context path
```

### hostname-admin

**Type:** String
**Default:** None

Address for admin console. Use different hostname than public.

```bash
--hostname-admin https://admin.keycloak.org
```

### hostname-strict

**Type:** Boolean
**Default:** `true`

Disables dynamic hostname resolution from headers.

```bash
--hostname-strict=true   # Production recommended
--hostname-strict=false  # Allow dynamic resolution
```

### hostname-backchannel-dynamic

**Type:** Boolean
**Default:** `false`

Enables dynamic backend URL resolution for private network access.

```bash
--hostname-backchannel-dynamic=true
```

**Requirements:**
- `hostname` must be full URL (scheme + hostname)
- Apps access Keycloak via private network
- Proxy sets appropriate headers

### hostname-debug

**Type:** Boolean
**Default:** `false`

Enables hostname debug page at `/realms/master/hostname-debug`.

```bash
--hostname-debug=true
```

## Validation Rules

### Production Mode (`kc.sh start`)

- `--hostname` OR `--hostname-strict=false` MUST be set
- `hostname` URL must include scheme and hostname
- Port optional (defaults to 80 or 443)
- If `hostname-admin` set, `hostname` must be full URL
- If `hostname-backchannel-dynamic=true`, `hostname` must be full URL

### Development Mode (`kc.sh start-dev`)

- `--hostname-strict=false` is default
- No hostname required

## Troubleshooting

### Debug Page

Enable debug endpoint:

```bash
bin/kc.sh start --hostname=my.keycloak --hostname-debug=true
```

Access at: `http://my.keycloak:8080/realms/<realm>/hostname-debug`

Shows:
- Current hostname configuration
- URL resolution results
- Header values from request
- Frontend/backend/admin URLs

### Common Issues

**Issue:** 403 Forbidden responses
```
Solution: Set --proxy-headers option correctly
```

**Issue:** Incorrect URLs in emails
```
Solution: Verify hostname is set to full URL with scheme
```

**Issue:** Clients can't connect via private network
```
Solution: Enable --hostname-backchannel-dynamic=true
```

**Issue:** Admin console not loading resources
```
Solution: Set --hostname-admin to full URL
```

## Example Configurations

### Simple Deployment

```bash
bin/kc.sh start \
  --hostname auth.example.com \
  --https-certificate-file=/path/to/cert.pem \
  --https-certificate-key-file=/path/to/key.pem
```

### With Reverse Proxy

```bash
bin/kc.sh start \
  --hostname https://auth.example.com \
  --http-enabled=true \
  --proxy-headers=xforwarded
```

### Separate Admin Interface

```bash
bin/kc.sh start \
  --hostname https://auth.example.com \
  --hostname-admin https://admin-auth.example.com \
  --http-enabled=true
```

### Private Network Backend

```bash
bin/kc.sh start \
  --hostname https://public.example.com \
  --hostname-backchannel-dynamic=true \
  --proxy-headers=forwarded \
  --proxy-trusted-addresses=10.0.0.0/8
```

### Custom Context Path

```bash
bin/kc.sh start \
  --hostname https://example.com/auth \
  --http-enabled=true
```

## Best Practices

1. **Always set hostname explicitly** in production
2. **Use full URL** with scheme and hostname
3. **Separate admin hostname** for security
4. **Restrict trusted proxies** when using dynamic resolution
5. **Enable debug page** during setup, disable in production
6. **Test URL resolution** after configuration
7. **Use HTTPS** for production deployments
8. **Configure proxy headers** correctly
9. **Validate emails contain correct URLs**
10. **Monitor for hostname mismatches** in logs

## Related Topics

- [[keycloak-reverse-proxy]] - Detailed reverse proxy configuration
- [[keycloak-server-configuration-guide]] - General server configuration
- [[keycloak-security]] - Security best practices
- [[keycloak-tls-configuration]] - TLS/HTTPS setup

## Additional Resources

- [Configuring the Hostname (v2)](https://www.keycloak.org/docs/latest/server/hostname)
- [Configuring a Reverse Proxy](https://www.keycloak.org/docs/latest/server/reverseproxy)
