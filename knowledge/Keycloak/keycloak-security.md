---
title: Keycloak Security Best Practices
type: reference
domain: Keycloak
tags:
  - keycloak
  - security
  - hardening
  - tls
  - authentication
  - authorization
  - threats
  - mitigation
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Security Best Practices

## Overview

Keycloak provides comprehensive security features to protect applications and user data. This guide covers security best practices for deploying Keycloak in production.

## TLS and HTTPS

### Always Use HTTPS in Production

**Never expose Keycloak over HTTP in production.**

**Enabling HTTPS:**

**Option 1: TLS in Keycloak**
```bash
./kc.sh start \
  --https-certificate-file=/path/to/cert.pem \
  --https-certificate-key-file=/path/to/key.pem \
  --https-port=8443
```

**Option 2: Reverse Proxy (Recommended)**
Use a reverse proxy (nginx, Apache, Caddy) with TLS termination.

**Proxy Headers:**
```bash
--proxy-protocol-enabled=true
--proxy=x-forwarded-for
```

**Trusted proxies:**
```bash
--http-enabled=true
--http-host=mykeycloak.example.com
--http-port=8080
--http-relative-path=/auth
```

### TLS Configuration

**Default:** Keycloak uses TLSv1.3 by default.

**Configure protocols:**
```bash
--https-protocols=TLSv1.3,TLSv1.2
```

**Configure cipher suites:**
```bash
--https-cipher-suites=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
```

**Certificate requirements:**
- Valid certificate from trusted CA
- Not self-signed (except for development)
- Match hostname
- Not expired

### Client Certificate Authentication

**Enabling mutual TLS:**
```bash
--client-auth=need
--truststore=/path/to/truststore.jks
--truststore-password=changeit
```

**RFC 9440 Client Certificate Lookup:**
- Native support for Caddy and compliant reverse proxies
- Configure in Realm Settings → Client Certificate Lookup

## Password Policies

### Configuring Password Policies

**Admin Console:**
1. Realm Settings → Password Policy
2. Add policies from dropdown:
   - **Hash iterations** - Number of PBKDF2 iterations (default 27,500)
   - **Length** - Minimum password length (recommended 12+)
   - **Digits** - Require digits
   - **Lower case** - Require lowercase letters
   - **Upper case** - Require uppercase letters
   - **Special characters** - Require special chars
   - **Not username** - Password cannot contain username
   - **Not email** - Password cannot contain email
   - **Password history** - Prevent reuse (last N passwords)
   - **Expires** - Password expiration in days
   - **Force expired password change** - Users must change expired passwords

**Best practices:**
- Minimum 12 characters
- Mix of character types
- No dictionary words
- No personal information
- Regular expiration (90-180 days)
- History of 5-10 previous passwords

**CLI:**
```bash
kcadm.sh update realms/{realm} \
  -s "passwordPolicy=hashIterations(27500) and length(12) and digits(1) and lowerCase(1) and upperCase(1) and specialChars(1) and notUsername(undefined) and notEmail(undefined)"
```

## Brute Force Protection

### Enabling Brute Force Protection

**Admin Console:**
1. Realm Settings → Security Defenses
2. **Brute Force Protection** tab
3. Enable:
   - **Permanent Lockout** - Lock until admin resets
   - **Max Login Failures** - Before lockout (default: 30)
   - **Wait Increment** - Seconds to wait after each failure (default: 1 min)
   - **Quick Login Check Milliseconds** - Time to record failure (default: 1000ms)
   - **Minimum Quick Login Wait** - Minimum wait time (default: 1 minute)
   - **Max Failure Wait** - Maximum wait time (default: 15 minutes)
   - **Failure Reset Time** - Time before counter resets (default: 12 hours)

**Best practices:**
- Max failures: 5-10
- Wait increment: 30-60 seconds
- Permanent lockout after repeated offenses
- Monitor lockout events

**Resetting locked user:**
1. Users → Select user
2. **Credentials** tab
3. **Unlock user**

## Session Management

### SSO Session Configuration

**Admin Console:**
1. Realm Settings → Sessions
2. Configure:
   - **SSO Session Idle** - Idle timeout (default: 30 minutes)
   - **SSO Session Max** - Maximum session length (default: 10 hours)
   - **SSO Session Max Remember Me** - For "remember me" sessions

**Best practices:**
- Idle: 15-30 minutes
- Max: 8-12 hours
- Remember me: 7-30 days

### User Session Limits

**Admin Console:**
1. Realm Settings → Sessions
2. Configure:
   - **Max sessions** per user (default: unlimited)
   - **Strategy when max reached**:
     - **Current session** - Keep current, drop oldest
     - **Oldest session** - Drop oldest session

### Client Session Settings

**Per-client configuration:**
1. Clients → Select client → Settings
2. **Advanced settings**:
   - **Client Session Idle** - Idle timeout
   - **Client Session Max** - Maximum lifetime
   - **Offline Session Max** - For refresh tokens

## Redirect URI Security

### Valid Redirect URIs

**Critical for preventing open redirects and unauthorized access.**

**Best practices:**
- Be as specific as possible
- Use exact paths when possible
- Always use HTTPS in production
- Never use `http://*` or `*` in production

**Valid examples:**
```
https://myapp.example.com/callback
https://myapp.example.com/*
https://myapp.example.com/callback?*
http://127.0.0.1:*
```

**Invalid examples (NEVER use in production):**
```
*
http://*
https://*
http://localhost:*
```

### Web Origins

**Configure for CORS:**
1. Clients → Select client → Settings
2. **Valid Web Origins**
3. Add allowed origins

**Best practices:**
- Be specific with origins
- Use exact URLs
- No wildcards in production

## CORS Configuration

### Global CORS

**SPI option:**
```bash
--spi-cors--default--allowed-headers=Accept,Content-Type,Authorization
--spi-cors--default--allowed-methods=GET,POST,PUT,DELETE
--spi-cors--default--allowed-origins=https://myapp.example.com
--spi-cors--default--exposed-headers=WWW-Authenticate
--spi-cors--default--allow-credentials=true
--spi-cors--default--max-age=3600
```

### Per-Client CORS

**Dynamic Client Registration:**
Configure via client registration access policies.

## Header Security

### Security Headers

**X-Frame-Options:** Prevent clickjacking
```
X-Frame-Options: DENY
```

**Content-Security-Policy:** Prevent XSS
```
Content-Security-Policy: default-src 'self'
```

**X-Content-Type-Options:** Prevent MIME sniffing
```
X-Content-Type-Options: nosniff
```

**Strict-Transport-Security:** Enforce HTTPS
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

**Configure via reverse proxy** or enable in Keycloak:
```bash
--http-frame-max-age=31536000
--http-frame-options=DENY
--http-content-type-options=nosniff
```

## Token Security

### Access Token Lifespan

**Realm setting:**
1. Realm Settings → Tokens
2. **Access Token Lifespan** (default: 1 minute)

**Best practices:**
- Short-lived (1-5 minutes)
- Use refresh tokens for long-lived access
- Consider performance vs. security tradeoff

### Refresh Token Settings

**Configuration:**
1. Realm Settings → Tokens
2. **Refresh Token Max Reuse** - Reuse refresh token (default: 0)
3. **Refresh Token Max Age** - Maximum refresh token age (unlimited by default)

**Best practices:**
- Set max age (30 days recommended)
- Disable reuse for high-security applications
- Use with offline access

### Token Revocation

**Introspection endpoint:**
```bash
POST /realms/{realm}/protocol/openid-connect/token/introspect
Content-Type: application/x-www-form-urlencoded

token=<access_token>
client_id=<client_id>
client_secret=<client_secret>
```

**Revocation endpoint:**
```bash
POST /realms/{realm}/protocol/openid-connect/revoke
Content-Type: application/x-www-form-urlencoded

token=<refresh_token>
client_id=<client_id>
client_secret=<client_secret>
```

## Event Logging and Monitoring

### Enable Security Events

**Admin Console:**
1. Realm Settings → Events
2. **Login events settings**
3. **Save events** - Enable
4. **Events expiration** - Set retention period

**Critical events to monitor:**
- **LOGIN** - Successful logins
- **LOGIN_ERROR** - Failed logins
- **LOGOUT** - User logout
- **REGISTER** - New user registration
- **UPDATE_PASSWORD** - Password changes
- **UPDATE_TOTP** - TOTP changes
- **REMOVE_TOTP** - TOTP disabled
- **SEND_VERIFY_EMAIL** - Email verification

**Admin events:**
- **CREATE** / **UPDATE** / **DELETE** operations
- User, client, role, group management
- Configuration changes

### Log Analysis

**Regular security audit:**
- Failed login attempts
- Unusual access patterns
- Privilege escalations
- Configuration changes
- Token issuance patterns

## Fine-Grained Admin Permissions (FGAP)

### Why Use FGAP

**Default admin role issues:**
- All-or-nothing access
- Over-privileged accounts
- No audit trail of specific actions

**FGAP benefits:**
- Granular permissions
- Principle of least privilege
- Detailed audit trail
- Role-based access control

### Enabling FGAP

1. Realm Settings → Admin Permissions
2. Switch to "Fine-grained admin permissions" → Enabled
3. Click "Save"

### Permission Strategy

**Best practices:**
1. **Create admin groups** for different functions:
   - User administrators
   - Client administrators
   - Group administrators
   - Read-only auditors

2. **Assign permissions to groups** not individual users

3. **Use role-based permissions**:
   - Grant `view` for read-only access
   - Grant `manage` for full CRUD
   - Grant specific permissions (create, delete, etc.)

4. **Regular permission audits**

### Example: User Administrator

**Create user administrator:**
1. Create group: `user-admins`
2. Realm Settings → Users → Permissions tab
3. Click "Add permission" → "Role"
4. Select role: `user-admins`
5. Permissions:
   - ✅ View users
   - ✅ Manage users
   - ✅ Impersonate (if needed)
   - ✅ Manage group membership
   - ❌ Delete users (optional - require additional approval)

## Multi-Factor Authentication (MFA)

### TOTP (Time-based OTP)

**Enabling for realm:**
1. Realm Settings → Authentication
2. **Required Actions**
3. Add "CONFIGURE_TOTP" to required actions

**User setup:**
- Must configure TOTP during login
- Compatible with Google Authenticator, Authy, etc.
- Backup codes available

### WebAuthn / Passkeys

**Enabling:**
```bash
--features=webauthn
```

**Configuration:**
1. Realm Settings → Authentication → WebAuthn
2. Configure:
   - **Signature algorithms** - ES256, RS256, etc.
   - **Attestation conveyance** - none, direct, indirect, enterprise
   - **Authenticator attachment** - platform, cross-platform
   - **User verification requirement** - required, preferred

**Benefits:**
- Passwordless authentication
- Hardware security key support
- Phishing-resistant

### Conditional 2FA

**Require 2FA based on conditions:**
- User role/group membership
- Client accessing from
- Resource being accessed
- Risk score

**Configuration:**
1. Realm Settings → Authentication
2. **Workflows** (preview) or **Conditional 2FA** policies

## Identity Provider Security

### SAML Security

**Assertions:**
- **Sign assertions** - Always enabled
- **Encrypt assertions** - Recommended
- **Signature algorithm** - RSA_SHA256 or better
- **Assertion lifespan** - Short (5 minutes or less)

**Encryption:**
- Use strong algorithms (RSA-OAEP)
- Proper key management

### OIDC IdP Security

**Client authentication:**
- Use confidential clients
- Rotate client secrets
- Use JWT assertion for client auth

**Token validation:**
- **Validate signatures** - Always enabled
- **Use JWKS URL** - For key discovery
- **Algorithm whitelist** - Restrict allowed algorithms

## User Federation Security

### LDAP / Active Directory

**Connection security:**
- Use LDAPS (LDAP over SSL)
- StartTLS as alternative
- Validate certificates

**Bind credentials:**
- Use service account with minimal permissions
- Rotate credentials regularly
- Never use admin credentials

**Password policies:**
- Sync with LDAP password policies
- Handle password expiration

## Cross-Site Request Forgery (CSRF) Protection

**Keycloak provides built-in CSRF protection:**

- CSRF tokens for state-changing operations
- SameSite cookie attribute
- Origin header validation

**Ensure:**
- Use official Keycloak adapters
- Don't disable CSRF checks
- Configure proper origins

## SQL Injection Prevention

**Keycloak uses prepared statements:**
- All database queries use parameterized queries
- No direct SQL injection risk

**Best practices:**
- Keep Keycloak updated
- Use supported database drivers
- Follow database hardening guides

## XSS Prevention

**Built-in protections:**
- Output encoding in templates
- Content-Security-Policy headers
- Input sanitization

**Custom themes:**
- Follow OWASP XSS prevention
- Use template engine auto-escaping
- Don't disable protections

## Security Headers Checklist

**Production deployment headers:**

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'self'
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## Regular Security Audits

### Checklist

**Configuration:**
- [ ] HTTPS enabled everywhere
- [ ] Strong password policies
- [ ] Brute force protection enabled
- [ ] FGAP enabled
- [ ] Short token lifespans
- [ ] Event logging enabled
- [ ] MFA enabled for sensitive access

**Monitoring:**
- [ ] Review failed login attempts
- [ ] Check for locked accounts
- [ ] Audit permission changes
- [ ] Review new client registrations
- [ ] Monitor token issuance patterns
- [ ] Check for unusual admin activities

**Updates:**
- [ ] Keep Keycloak updated
- [ ] Review release notes for security fixes
- [ ] Test upgrades in non-production
- [ ] Update dependencies

## Vulnerability Management

**Reporting vulnerabilities:**
- Private security disclosure: https://github.com/keycloak/keycloak/security/advisories
- CVEs published on Keycloak blog
- Subscribe to security announcements

**Response process:**
1. Assess vulnerability impact
2. Check if your deployment is affected
3. Apply patch or upgrade
4. Review and rotate credentials if needed
5. Audit logs for exploitation attempts

## Compliance Considerations

### GDPR / Data Protection

- User consent management
- Right to erasure (delete user)
- Data export capabilities
- Event logging for audit trails

### SOC 2 / ISO 27001

- Access controls (FGAP)
- Event logging and monitoring
- Change management
- Incident response procedures

### PCI DSS

- Strong authentication (MFA)
- Token security
- Regular security audits
- Secure transmission (TLS)

## References

- <https://www.keycloak.org/docs/latest/server_admin/#mitigating-security-threats>
- OWASP Top 10
- NIST Digital Identity Guidelines
- OAuth 2.0 Security Best Current Practice (RFC 9700)

## Related

- [[keycloak-overview]]
- [[keycloak-server-administration]]
- [[keycloak-hardening-guide]]
