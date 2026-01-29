---
title: Keycloak User Consent and Application Access Management
domain: Keycloak
type: howto
status: draft
tags: [keycloak, consent, oauth, oidc, user-management, security]
created: 2026-01-29
related: [[keycloak-overview]], [[keycloak-concepts]], [[keycloak-roles-groups]], [[keycloak-protocol-mappers]]
---

# Keycloak User Consent and Application Access Management

## Overview

Keycloak provides comprehensive user consent management capabilities that allow data principals (users) to:
- **See** which applications have access to their data and profile
- **Revoke** access to applications they no longer trust
- **Manage** consent preferences for each application

This guide covers configuration and usage of user consent features in Keycloak 26.5.0.

## Key Concepts

### User Consent

User consent is the process where users explicitly grant permission to client applications to access their data and resources. Keycloak implements consent according to OpenID Connect and OAuth 2.0 specifications.

### Client Scopes

Client scopes define what claims (user data) can be included in tokens issued to clients. Scopes can be:
- **Default**: Automatically included in tokens
- **Optional**: User can choose whether to grant
- **Required**: Must be granted for access

### Account Console

The user-facing interface where users can:
- View their profile and security settings
- See connected applications
- Revoke application access
- Manage consent

## Configuration

### 1. Enable Consent for Clients

#### Via Admin Console

1. Navigate to **Clients** → Select your client
2. Under **Settings**, find **Consent** section:
   - **Consent Required**: Enable to require user consent
   - **Display on consent screen**: Which scopes to show

```bash
# Via CLI (kcadm.sh)
kcadm.sh update clients/CLIENT_ID -r myrealm -s 'consentRequired=true'
```

#### Client Consent Options

| Setting | Description |
|---------|-------------|
| `Consent Required` | Forces user to consent on every login if enabled |
| `Display on consent screen` | Controls which client scopes appear in consent screen |
| `Standard Flow Enabled` | Required for OIDC authorization code flow with consent |
| `Implicit Flow Enabled` | Not recommended; use authorization code flow instead |

### 2. Configure Client Scopes

#### Create Client Scopes

1. Navigate to **Client Scopes** → **Create client scope**
2. Define scope name and protocol (OIDC or SAML)
3. Add protocol mappers to include specific claims

#### Configure Scope Consent Behavior

For each client scope:

1. Navigate to **Client Scopes** → Select scope → **Settings**
2. Set **Consent Screen Text**: Description shown to user
3. Choose consent behavior:
   - **Not configured**: Scope behavior depends on client settings
   - **Yes**: User must explicitly consent
   - **No**: Scope granted without user consent

#### Link Scopes to Clients

1. Navigate to **Clients** → Select client → **Client Scopes**
2. Add **Default Client Scopes**: Always included
3. Add **Optional Client Scopes**: User can choose

### 3. Configure Fine-Grained Consent

Keycloak supports fine-grained consent management allowing users to:
- Grant required scopes
- Optionally add optional scopes
- Revoke optional scopes later

```bash
# Example: Configure optional scopes for a third-party app
kcadm.sh create clients/CLIENT_ID/protocol-mappers/models -r myrealm \
  -s 'name=email' \
  -s 'protocol=openid-connect' \
  -s 'protocolMapper=oidc-usermodel-attribute-mapper' \
  -s 'consentRequired=true' \
  -s 'consentText=Email address for notifications'
```

## User Experience

### Account Console - Applications Page

Users can access their connected applications at:
```
http://your-keycloak/realms/YOUR_REALM/account/#/applications
```

#### What Users See

For each authorized application:
- **Application Name**: Client name configured in Keycloak
- **Granted Permissions**: List of scopes/permissions granted
- **Last Access**: When the app was last used
- **Revoke Button**: To remove app access

#### Revoking Access

Users can revoke application access by:
1. Clicking the **Revoke** button next to an application
2. Confirming the revocation
3. Refresh tokens for that app are immediately invalidated

### Consent Screen

When a user authenticates to a new application:

1. **First-time consent**: User sees all requested scopes
2. **Subsequent logins**: Consent screen may be skipped (unless consent required)
3. **Scope changes**: User re-consents if new scopes are requested

#### Consent Screen Flow

```
┌─────────────────┐
│ User initiates  │
│ login to app    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Authenticate    │
│ (username/PW)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Consent Screen? │
│ - New client?   │
│ - New scopes?   │
│ - Consent req?  │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Yes     │ No
    ▼         ▼
┌─────────┐ ┌─────────────┐
│ Show    │ │ Redirect to │
│ Consent │ │ application │
│ Screen  │ │ (with token)│
└────┬────┘ └─────────────┘
     │
     ▼
┌─────────────────┐
│ User grants/    │
│ denies consent  │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Grant   │ Deny
    ▼         ▼
┌─────────┐ ┌─────────────┐
│ Issue   │ │ Show error  │
│ Tokens  │ │ (no access) │
└─────────┘ └─────────────┘
```

## API Reference

### Admin API: Check User Consents

```bash
# List all consents for a user
GET /admin/realms/{realm}/users/{id}/consents

# Response example
[
  {
    "clientId": "my-app",
    "createdDate": 1643723400000,
    "lastUpdatedDate": 1643723400000,
    "gr Client Scopes": [
      {
        "id": "scope-id",
        "name": "profile"
      }
    ]
  }
]
```

### Admin API: Revoke User Consent

```bash
# Revoke consent for a specific client
DELETE /admin/realms/{realm}/users/{id}/consents/{client}

# Example
curl -X DELETE \
  http://localhost:8080/admin/realms/myrealm/users/user-id/consents/my-app \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Token Revocation Endpoint

```bash
# Revoke a specific refresh token
POST /realms/{realm}/protocol/openid-connect/revoke
Content-Type: application/x-www-form-urlencoded

token=REFRESH_TOKEN
token_type_hint=refresh_token
client_id=CLIENT_ID
client_secret=CLIENT_SECRET
```

## Best Practices

### 1. Consent Required Policy

**When to enable consent:**
- Third-party applications accessing user data
- Applications requesting sensitive scopes (email, profile, address)
- Regulatory requirements (GDPR, CCPA)

**When consent may be optional:**
- First-party applications you control
- Internal tools
- Service accounts (machine-to-machine)

### 2. Scope Design

- **Default scopes**: Basic profile information
- **Optional scopes**: Extended attributes like phone, address
- **Required scopes**: Only for essential functionality

### 3. User Communication

- **Clear scope descriptions**: Explain why each scope is needed
- **Privacy policy links**: Include in consent screen
- **Granular control**: Allow users to grant/revoke individual scopes

### 4. Security Considerations

```javascript
// Client-side: Check for consent_required error
async function login() {
  try {
    await keycloak.login();
  } catch (error) {
    if (error === 'consent_required') {
      // Redirect to consent screen
      keycloak.login({ prompt: 'consent' });
    }
  }
}
```

### 5. Monitoring and Auditing

Track consent events for security and compliance:

```sql
-- Keycloak stores consent in USER_CONSENT table
SELECT c.client_id,
       c.created_date,
       c.last_updated_date,
       u.username
FROM USER_CONSENT c
JOIN USER_ENTITY u ON c.user_id = u.id
WHERE c.realm_id = 'myrealm'
ORDER BY c.last_updated_date DESC;
```

## Compliance Considerations

### GDPR (General Data Protection Regulation)

- **Right to erasure**: Users can delete their account, removing all consents
- **Right to access**: Users can see all applications with access via Account Console
- **Right to rectification**: Users can update profile data that apps access
- **Right to be forgotten**: User deletion propagates to all connected applications

### CCPA (California Consumer Privacy Act)

- **Right to know**: Users see all data processing via consent screen
- **Right to delete**: Account deletion removes all consent and data
- **Right to opt-out**: Users can revoke specific app access

## Troubleshooting

### Issue: Applications not showing in Account Console

**Solution**: Verify client configuration:
1. **Base URL** must be set in client settings
2. **Front-channel logout** URL should be configured
3. **Root URL** helps with application discovery

```bash
kcadm.sh update clients/CLIENT_ID -r myrealm \
  -s 'rootUrl=https://myapp.example.com' \
  -s 'baseUrl=https://myapp.example.com/callback' \
  -s 'adminUrl=https://myapp.example.com/admin'
```

### Issue: Consent screen not appearing

**Check:**
- Client has `Consent Required` enabled
- Client scopes have `Display on consent screen` enabled
- User hasn't previously granted persistent consent

### Issue: Revoked consent still allows access

**Causes:**
- Application is using cached access tokens (wait for expiration)
- Application has long-lived refresh tokens (consider shorter TTL)
- Application is using service account (user consent doesn't apply)

## Related Topics

- [[keycloak-overview]]: Keycloak architecture overview
- [[keycloak-concepts]]: Realms, clients, users, roles
- [[keycloak-protocol-mappers]]: Adding claims to tokens
- [[keycloak-roles-groups]]: Authorization using roles and groups
- [[keycloak-sessions]]: Session and token management
- [[keycloak-security]]: Security best practices

## Additional Resources

- [Server Administration Guide - Consents](https://www.keycloak.org/docs/latest/server_admin/index.html#_consents)
- [Server Administration Guide - Client Scopes](https://www.keycloak.org/docs/latest/server_admin/index.html#_client_scopes)
- [Account Console - Applications](https://www.keycloak.org/docs/latest/server_admin/index.html#_account-console)
- [Authorization Services Guide](https://www.keycloak.org/docs/latest/authorization_services/index.html)
- [GDPR Compliance](https://www.keycloak.org/docs/latest/server_admin/index.html#_gdpr)

## Summary

Keycloak's user consent and application access management features enable:
- **Transparency**: Users see which apps access their data
- **Control**: Users can revoke access anytime
- **Compliance**: GDPR, CCPA, and other privacy regulations
- **Security**: Principle of least privilege through scoped consent

Proper configuration of client scopes, consent requirements, and the account console provides a complete solution for user-driven data access management.
