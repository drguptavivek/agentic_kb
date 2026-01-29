---
title: Keycloak Server Administration
type: reference
domain: Keycloak
tags:
  - keycloak
  - administration
  - roles
  - groups
  - permissions
  - users
  - clients
  - realms
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Server Administration

## Overview

Keycloak server administration involves managing users, roles, groups, clients, permissions, and realm settings through the Admin Console, Admin REST API, or CLI tools.

## Administration Interfaces

### Admin Console

Web-based administration interface at `http://localhost:8080/`.

**Features:**
- User management
- Client configuration
- Role and group management
- Realm settings
- Identity provider configuration
- Event logging
- Fine-grained permissions

### Admin REST API

Full administrative control via REST API.

**Base URL:**
```
http://localhost:8080/admin/realms/{realm}
```

**Authentication:**
- Client credentials (service account)
- Admin username/password

**Documentation:**
- Admin REST API docs at `/docs/`

### kcadm.sh CLI

Command-line administration tool.

**Basic usage:**
```bash
# Authenticate
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin

# Get users
kcadm.sh get users \
  --realm myrealm

# Create user
kcadm.sh create users \
  -r myrealm \
  -s username=testuser \
  -s enabled=true
```

## Realms

### Creating a Realm

**Admin Console:**
1. Click realm dropdown (top-left)
2. Click "Create realm"
3. Enter realm name
4. Click "Create"

**CLI:**
```bash
kcadm.sh create realms \
  -s realm=myrealm \
  -s enabled=true
```

### Realm Settings

**Settings categories:**
- **General** - Name, display name, HTML display name
- **Login** - Theme, locale, remember me, registration
- **Sessions** - SSO session limits, idle timeout
- **Tokens** - Token lifespan, refresh token settings
- **Security Defenses** - Brute force, headers
- **Email** - SMTP settings
- **Themes** - Login, account console themes
- **Localization** - Default locale, supported locales
- **Internationalization** - Message bundles
- **Keys** - Cryptographic keys, certificates
- **OIDC** - Claims, client session settings
- **SAML** - Assertions, signatures
- **Sessions** - SSO max sessions, timeout
- **Par** - Pushed Authorization Requests
- **CIBA** - Client Initiated Backchannel Authentication

### Switching Realms

**Admin Console:** Click realm dropdown (top-left) → Select realm

**CLI:** Use `-r` or `--realm` parameter:
```bash
kcadm.sh get users -r myrealm
```

## Users

### Creating Users

**Admin Console:**
1. Users → Add user
2. Enter details:
   - Username (required)
   - Email
   - First name
   - Last name
3. Click "Create"

### User Credentials

**Setting initial password:**
1. Go to user → Credentials tab
2. Set password:
   - Password type (password, password-generated)
   - Password value
   - Temporary (user must change on first login)

**Credential providers:**
- Password
- OTP (One-Time Password)
- WebAuthn/Passkey

### User Attributes

**Built-in attributes:**
- username
- email
- firstName
- lastName
- locale
- zoneOffset (from timezone)

**Custom attributes:**
1. Go to user → Attributes tab
2. Add key-value pairs
3. Click "Add"

### Required Actions

Actions user must complete before accessing applications:

**Built-in actions:**
- UPDATE_PASSWORD
- CONFIGURE_TOTP
- UPDATE_PROFILE
- VERIFY_EMAIL
- TERMS_AND_CONDITIONS
- UPDATE_USER_LOCALE
- mobile-delete-account

**Setting required actions:**
1. Go to user → Required Actions tab
2. Select actions from dropdown
3. Click "Add"

### User Federation

Users can be federated from external sources:
- LDAP / Active Directory
- Kerberos
- SSSD

**Configuration:** Realm Settings → User Federation

## Groups

### Creating Groups

**Admin Console:**
1. Groups → Create group
2. Enter name
3. Click "Create"

### Nested Groups

Groups can contain sub-groups for hierarchical organization.

**Adding sub-group:**
1. Go to parent group
2. Click "Create sub-group"
3. Enter name
4. Click "Create"

### Group Attributes

Groups can have custom attributes similar to users.

**Adding attributes:**
1. Go to group → Attributes tab
2. Add key-value pairs

### Group Role Mapping

Assign roles to groups instead of individual users.

**Adding roles:**
1. Go to group → Role mapping tab
2. Click "Assign role"
3. Select role
4. Click "Assign"

**Benefits:**
- Simplified permission management
- Bulk user updates
- Consistent permissions

### Adding Users to Groups

**Admin Console:**
1. Go to user → Groups tab
2. Join group(s)
3. Click "Join"

**CLI:**
```bash
kcadm.sh update users/{id}/groups/{groupId}
```

## Roles

### Role Types

**Realm Roles:**
- Available across entire realm
- Managed in Realm roles

**Client Roles:**
- Scoped to specific client
- Managed in Clients → {client} → Roles

### Creating Roles

**Realm role:**
1. Realm roles → Add role
2. Enter name and description
3. Click "Save"

**Client role:**
1. Clients → Select client
2. Roles → Add role
3. Enter name and description
4. Click "Save"

### Composite Roles

Roles that contain other roles (inheritance).

**Creating composite role:**
1. Go to role
2. Click "Add composite roles"
3. Select roles to include
4. Click "Add selected"

**Benefits:**
- Role hierarchy
- Reusable permission sets
- Easier management

### Role Mapping

**Map roles to users:**
1. Go to user → Role mapping tab
2. Click "Assign role"
3. Select role (realm or client)
4. Click "Assign"

**Map roles to groups:**
1. Go to group → Role mapping tab
2. Click "Assign role"
3. Select role
4. Click "Assign"

**Effective role computation:**
- User's direct roles
- User's group roles
- Composite role hierarchy
- Client scope mappings

## Clients

### Client Types

**Confidential:**
- Can securely store secrets
- Server-side applications
- Requires client authentication

**Public:**
- Cannot securely store secrets
- SPA, mobile apps, native apps
- No client authentication

**Bearer-only:**
- Services that only validate tokens
- No direct user login
- No redirect URI

### Creating OIDC Clients

**Admin Console:**
1. Clients → Create client
2. Select **Client type** → OpenID Connect
3. Configure:
   - **Client ID** (required)
   - **Client authentication** (confidential clients)
   - **Authorization flow** (standard flow, direct access grants)
   - **Valid redirect URIs** (required for web apps)
   - **Web origins** (for CORS)
   - **Valid post logout redirect URIs**
   - **Root URL**

**Client Capability Config:**
- **Standard flow enabled** - Authorization code flow
- **Direct access grants enabled** - Resource owner password
- **Implicit flow enabled** - Implicit flow (not recommended)
- **Service accounts enabled** - Client credentials
- **Authorization enabled** - Authorization services

**Advanced settings:**
- **Access Token Lifespan** - Token expiration
- **Client Session Idle** - Session timeout
- **Client Session Max** - Maximum session lifetime
- **Fine Grain OpenID Connect Configuration**

### Creating SAML Clients

**Admin Console:**
1. Clients → Create client
2. Select **Client type** → SAML
3. Configure:
   - **Client ID** (required, used as entity ID)
   - **Entity ID**
   - **Assertion consumer service POST binding URL**
   - **Assertions signed**
   - **Assertions encrypted**

### Client Scopes

Client scopes define which claims and roles are included in tokens.

**Built-in client scopes:**
- **profile** - Basic profile info
- **email** - Email address, verified status
- **address** - Postal address
- **phone** - Phone number
- **offline_access** - Refresh tokens
- **roles** - User roles

**Creating custom scope:**
1. Client scopes → Create client scope
2. Enter name and protocol
3. Click "Create"
4. Add mappers (protocol mappers)

**Adding scope to client:**
1. Go to client → Client scopes tab
2. Add default or optional client scope
3. Click "Add selected"

### Protocol Mappers

Protocol mappers add claims to tokens.

**Common OIDC mappers:**
- **User Property** - Map user attribute to claim
- **User Attribute** - Map custom attribute
- **Group Membership** - Add group information
- **Audience** - Add audience claim
- **Client IP** - Add client IP address

**Common SAML mappers:**
- **User Attribute** - Map user attribute to SAML attribute
- **Group list** - Add group membership
- **Role list** - Add role information

**Adding mapper:**
1. Go to client/client scope → Mappers tab
2. Click "Add mapper"
3. Select mapper type
4. Configure mapper settings
5. Click "Save"

## Permissions

### Fine-Grained Admin Permissions (FGAP)

Granular permissions for administrative operations instead of all-or-nothing admin role.

**Enabling FGAP:**
1. Realm Settings → Admin Permissions
2. Switch to "Fine-grained admin permissions" → Enabled
3. Click "Save"

**Permissions sections:**
- **Users** - Manage users
- **Clients** - Manage clients
- **Groups** - Manage groups
- **Roles** - Manage roles
- **Identity Providers** - Manage IdPs
- **Admin** - Manage admin permissions

**Creating permission:**
1. Go to resource (e.g., Users)
2. Click "Permissions" tab
3. Click "Add permission"
4. Select permission type:
   - **User** - Grant to specific user
   - **Role** - Grant to users with role
5. Configure permission:
   - View, Create, Delete, Manage, etc.
   - Scope (all resources or specific)
6. Click "Save"

**Best practices:**
- Use groups for permission assignment
- Use role-based permissions
- Grant minimum required permissions
- Regular audit of permissions

### Authorization Services

Keycloak provides Resource-Based Authorization Services (UMA).

**Enabling authorization:**
1. Go to client
2. **Authorization** tab → Enable
3. Click "Save"

**Authorization resources:**
- **Resources** - Protected objects (APIs, pages)
- **Scopes** - Permissions on resources
- **Policies** - Rules for granting access
- **Permissions** - Connect policies to resources/scopes

## Identity Providers

### Creating Identity Provider

**Social (Google, GitHub, etc.):**
1. Identity Providers → Add provider
2. Select provider type
3. Configure client ID and secret
4. Configure redirect URI

**SAML 2.0:**
1. Identity Providers → Add provider → SAML v2.0
2. Configure:
   - **Alias** - Internal identifier
   - **Display name** - Show on login page
   - **Entity ID**
   - **SSO URL**
   - **Certificates**

**OpenID Connect v1.0:**
1. Identity Providers → Add provider → OpenID Connect v1.0
2. Configure:
   - **Discovery URL** or manual endpoints
   - **Client ID**
   - **Client Secret**
   - **Scopes**

### Identity Provider Mappers

Map attributes from external IdP to Keycloak user properties.

**Common mappers:**
- **Attribute Importer** - Import attributes
- **User Attribute** - Map to user attribute
- **Group Mapper** - Import groups
- **Role Mapper** - Import roles

**Adding mapper:**
1. Go to IdP → Mappers tab
2. Click "Add mapper"
3. Select mapper type
4. Configure mapping
5. Click "Save"

## Event Logging

### Event Types

**Admin Events:**
- CRUD operations on users, clients, roles, etc.
- Configuration changes
- Administrative actions

**User Events:**
- Login, logout
- Registration
- Password changes
- TOTP events
- Errors

**Stored Events:**
- Persisted to database
- Configurable retention

### Configuring Events

**Admin Console:**
1. Realm Settings → Events
2. Configure:
   - **Login events settings** - Save events, expiration
   - **Admin events settings** - Save events, expiration
   - **Event listeners** - What events to log

**Available listeners:**
- **jboss-logging** - Log to server log
- **email** - Send email notifications
- **event-listener-sysout** - Console output

### Viewing Events

**Admin Events:**
1. Admin → Events
2. Filter by:
   - Date/time range
   - Operation type
   - Resource type
   - Auth type (client, user)

**User Events:**
1. Realm Settings → Events → View all events
2. Filter by:
   - Date/time range
   - Event type
   - User
   - Client

## Workflows (Preview)

**New in 26.5.0**

Automate administrative tasks based on events within a realm.

**Workflow components:**
- **Workflows** - Automated processes
- **Steps** - Individual actions in workflow
- **Conditions** - When to trigger workflow
- **Events** - Triggers for workflows

**Creating workflow:**
1. Realm Settings → Workflows (preview feature must be enabled)
2. Click "Create workflow"
3. Configure:
   - Name
   - Description
   - Triggering events
   - Steps and conditions
4. Click "Create"

**Use cases:**
- Onboarding workflows
- Offboarding workflows
- Permission requests
- Compliance enforcement

**YAML support:** Define workflows using YAML for version control and automation.

## CLI Tools

### kc.sh / kc.bat

Server management commands:

**Start server:**
```bash
# Development
./kc.sh start-dev

# Production
./kc.sh start \
  --hostname=mykeycloak.example.com \
  --https-certificate-file=/path/to/cert \
  --https-certificate-key-file=/path/to/key

# Build for production
./kc.sh build
```

**Export/Import:**
```bash
# Export realm
./kc.sh export \
  --realm myrealm \
  --dir /path/to/export

# Import realm
./kc.sh import \
  --dir /path/to/export
```

**Windows service (26.5+):**
```bash
# Install service
./kc.bat tools windows-service install

# Uninstall service
./kc.bat tools windows-service uninstall
```

### kcadm.sh

Administrative operations:

**Authentication:**
```bash
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin
```

**CRUD operations:**
```bash
# Create
kcadm.sh create users -r myrealm -s username=test

# Read
kcadm.sh get users -r myrealm -q username=test

# Update
kcadm.sh update users/{id} -r myrealm -s enabled=false

# Delete
kcadm.sh delete users/{id} -r myrealm
```

## Best Practices

### Security

1. **Always use HTTPS in production**
2. **Enable FGAP** for granular permissions
3. **Configure password policies**
4. **Enable brute force protection**
5. **Regular audit of permissions**
6. **Use service accounts** instead of admin credentials for automation

### Performance

1. **Enable persistent sessions** for large deployments
2. **Configure cache** properly
3. **Use database connection pooling**
4. **Enable HTTP optimized serializers** (preview)
5. **Monitor metrics** and logs

### High Availability

1. **Use sticky sessions** for load balancers
2. **Enable clustering** with Infinispan
3. **Configure database** for high availability
4. **Use external Infinispan** for cross-site replication

## References

- <https://www.keycloak.org/docs/latest/server_admin/>
- Admin REST API Documentation
- kcadm.sh CLI Reference

## Related

- [[keycloak-overview]]
- [[keycloak-security]]
- [[keycloak-securing-apps-oidc]]
