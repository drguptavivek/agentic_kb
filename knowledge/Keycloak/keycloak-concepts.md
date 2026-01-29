---
title: Keycloak Concepts and Fundamentals
type: reference
domain: Keycloak
tags:
  - keycloak
  - concepts
  - fundamentals
  - architecture
  - authentication
  - oauth2
  - oidc
  - saml
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Concepts and Fundamentals

## Overview

This guide explains the core concepts and terminology used in Keycloak. Understanding these fundamentals is essential for effectively using and administering Keycloak.

## Core Architecture

### What is Keycloak?

Keycloak is an **identity and access management (IAM)** solution that provides:
- **Single Sign-On (SSO)** - Log in once, access multiple applications
- **Identity Brokering** - Integrate with external identity providers
- **User Federation** - Connect to existing user stores (LDAP, AD)
- **Administration** - Comprehensive management interfaces
- **Standards-based** - OAuth 2.0, OpenID Connect, SAML 2.0

### Deployment Model

**Standalone:**
- Single server instance
- Suitable for development/small deployments
- Can still support clustering

**Clustered:**
- Multiple server instances
- High availability
- Horizontal scaling
- Requires sticky sessions

**Containerized:**
- Docker/Podman images
- Kubernetes/OpenShift operators
- Cloud-native deployment

## Authentication vs Authorization

### Authentication (AuthN)

**Question:** Who are you?

**Purpose:** Verify identity of users/clients

**Methods:**
- Username/password
- Multi-factor (TOTP, WebAuthn)
- External identity providers (social, enterprise)
- Certificate-based

**Output:** Authentication session, tokens

**Keycloak provides:**
- Authentication flows
- Credential management
- Identity brokering
- User federation

### Authorization (AuthZ)

**Question:** What can you do?

**Purpose:** Control access to resources

**Methods:**
- Role-based access control (RBAC)
- Group-based permissions
- Fine-grained authorization services
- Policy-based decisions

**Output:** Permissions, access decisions

**Keycloak provides:**
- Role and group management
- Authorization Services (UMA)
- Fine-grained admin permissions
- Client scopes

## Realms

### What is a Realm?

A **realm** is an isolated workspace that contains:
- Users
- Applications (clients)
- Roles and groups
- Identity providers
- User federation
- Authentication flows
- Policies and permissions

### Realm Isolation

Each realm is:
- **Independent** - No sharing between realms
- **Self-contained** - Complete configuration
- **Isolated** - Users in realm A can't access realm B

### Master Realm

Special realm for:
- Administering Keycloak itself
- Creating other realms
- Global configuration
- Superuser access

**Best practice:**
- Create separate realms for different applications/environments
- Use master realm only for administration
- Never create regular users in master realm

### Realm Use Cases

**By environment:**
- `development` - Dev environment
- `staging` - Staging environment
- `production` - Production environment

**By organization:**
- `acme-corp` - Main organization
- `acme-partners` - Partner portal
- `acme-customers` - Customer portal

**By application:**
- `hr-app` - HR application realm
- `finance-app` - Finance application realm

## Clients

### What is a Client?

A **client** is an application or service that requests authentication or authorization from Keycloak.

### Client Types

**Confidential Client:**
- Can securely store credentials
- Server-side applications
- Can authenticate with client secret or JWT
- Examples: Web apps, REST APIs, backend services

**Public Client:**
- Cannot securely store credentials
- Client-side applications
- No client authentication
- Examples: SPA, mobile apps, native apps

**Bearer-only Client:**
- Services that only validate tokens
- No direct user login
- No redirect URIs
- Examples: REST APIs, microservices

### Client Authentication

**Client Secret:**
- Simple string shared between Keycloak and client
- Used for confidential clients
- Rotate regularly in production

**JWT Signed by Client:**
- Client creates JWT signed with private key
- More secure than client secret
- Supports mutual TLS

**None:**
- Public clients
- No client authentication
- Requires redirect URI validation

### Client Registration

**Admin Console:**
- Manual registration
- Full control over settings
- Suitable for internal apps

**Dynamic Client Registration:**
- OAuth 2.0 Registration endpoint
- Self-service registration
- Suitable for third-party apps

**CLI:**
- Scripted registration
- CI/CD integration
- Infrastructure as code

## Users

### What is a User?

A **user** represents a person who can:
- Log in to applications
- Be assigned roles and groups
- Have federated identities
- Own resources and permissions

### User Attributes

**Standard attributes:**
- `username` - Unique identifier (required)
- `email` - Email address (required for email verification)
- `firstName` - First name
- `lastName` - Last name
- `emailVerified` - Email verification status

**Custom attributes:**
- Arbitrary key-value pairs
- Application-specific data
- Extension points

**Setting attributes:**
```
phone: +1-555-0123
department: Engineering
employeeId: 12345
```

### User Credentials

**Credential types:**
- `password` - User password
- `otp` - One-time password (TOTP)
- `webauthn` - Passkey/Security key

**Credential features:**
- Password policies
- Password history
- Required actions
- Reset workflows

### Required Actions

Actions user must complete before login:
- `UPDATE_PASSWORD` - Change password
- `CONFIGURE_TOTP` - Setup 2FA
- `UPDATE_PROFILE` - Update profile
- `VERIFY_EMAIL` - Verify email address
- `TERMS_AND_CONDITIONS` - Accept terms

### Federated Identities

Users can have linked identities from:
- Social providers (Google, Facebook)
- Enterprise IdPs (SAML, OIDC)
- LDAP/Active Directory

**Benefit:** Single identity across multiple systems

## Roles

### What is a Role?

A **role** represents a type or category of user that defines:
- Permissions
- Access levels
- Functional capabilities

### Role Types

**Realm Roles:**
- Available across entire realm
- Global scope
- Examples: `admin`, `user`, `manager`

**Client Roles:**
- Scoped to specific client
- Client-specific permissions
- Examples: `billing:admin`, `reports:view`

### Composite Roles

Roles that contain other roles.

**Benefits:**
- Role inheritance
- Reusable permission sets
- Hierarchical organization

**Example:**
```
admin (composite)
├── user-manager
├── client-manager
└── group-manager

Each sub-role has specific permissions.
```

### Role Assignment

**Direct assignment:**
- User → Role mapping
- Explicit permissions

**Indirect assignment:**
- User → Group → Role
- Group-based permissions
- Easier management

**Best practice:**
- Prefer group-based assignment
- Use direct assignment for exceptions
- Document role purpose

## Groups

### What is a Group?

A **group** organizes users for:
- Easier management
- Bulk role assignment
- Hierarchical organization

### Group Hierarchy

Groups can contain sub-groups:
```
Engineering (parent)
├── Frontend (child)
│   ├── React (sub-child)
│   └── Vue (sub-child)
└── Backend (child)
    ├── Java (sub-child)
    └── Python (sub-child)
```

**Benefits:**
- Mirror organizational structure
- Inherit roles from parent groups
- Simplified permission management

### Group Attributes

Groups can have attributes like users:
- Department code
- Location
- Cost center

**Use case:** Attribute-based access control

### Group vs Role

| Groups | Roles |
|--------|-------|
| Organize users | Define permissions |
| Hierarchical | Not hierarchical |
| Can have attributes | No attributes |
| Better for management | Better for permissions |

**Best practice:**
- Assign roles to groups
- Assign users to groups
- Indirect permission model

## Identity Providers

### What is an Identity Provider?

An **identity provider (IdP)** is an external system that authenticates users.

### IdP Types

**Social IdPs:**
- Google, Facebook, GitHub, Twitter
- Quick integration
- User convenience

**Enterprise IdPs:**
- SAML 2.0 (corporate SSO)
- OpenID Connect (federated OIDC)
- Industry standards

**User Federation:**
- LDAP / Active Directory
- Kerberos
- Existing user stores

### Identity Brokering

Keycloak acts as a broker between:
- Applications (service providers)
- External identity providers

**Flow:**
1. Application redirects to Keycloak
2. Keycloak shows login page with IdP options
3. User selects external IdP
4. User authenticates with external IdP
5. External IdP redirects back to Keycloak
6. Keycloak creates user session
7. User redirected to application

### Identity Provider Mappers

Map attributes from external IdP to Keycloak:
- **Attribute Importer** - Import user attributes
- **User Attribute** - Map to specific attribute
- **Group Mapper** - Import group membership
- **Role Mapper** - Import role assignments

## Client Scopes

### What is a Client Scope?

A **client scope** defines what claims and roles are included in tokens issued for a client.

### Built-in Client Scopes

**`profile`:**
```json
{
  "name", "family_name", "given_name", "middle_name",
  "nickname", "preferred_username", "profile",
  "picture", "website", "gender", "birthdate",
  "zoneinfo", "locale", "updated_at"
}
```

**`email`:**
```json
{
  "email", "email_verified"
}
```

**`address`:**
```json
{
  "street_address", "locality", "region",
  "postal_code", "country"
}
```

**`phone`:**
```json
{
  "phone_number", "phone_number_verified"
}
```

**`offline_access`:**
- Enables refresh tokens
- Long-lived access

**`roles`:**
- Includes user roles
- Realm and client roles

### Scope Types

**Default Scope:**
- Automatically included in token request
- User doesn't need to explicitly request

**Optional Scope:**
- User must explicitly request
- Consent may be required

### Protocol Mappers

Protocol mappers add data to tokens.

**Common OIDC mappers:**
- **User Property** - Map user property to claim
- **User Attribute** - Map custom attribute
- **Group Membership** - Add group information
- **Audience** - Add audience claim
- **Client IP** - Add client IP address

**Example: Custom claim mapper**
```
Name: department
Mapper Type: User Attribute
User Attribute: department
Token Claim Name: department
Claim JSON Type: String
```

## Sessions

### Authentication Session

**Purpose:** Track authentication flow

**Duration:** Short-lived (minutes)
**Created:** When user starts login
**Destroyed:** After authentication completes

### User Session

**Purpose:** Track authenticated user

**Duration:** Configurable (default: 10 hours max)
**Created:** When user successfully authenticates
**Destroyed:**
- User logs out
- Session expires
- Max sessions limit reached

**Session limits:**
- **SSO Session Idle** - Idle timeout
- **SSO Session Max** - Maximum lifetime
- **Max sessions** - Per user

### Client Session

**Purpose:** Track user session per client

**Duration:** Can be shorter than user session
**Created:** When user accesses client
**Destroyed:**
- User logs out of client
- Client session expires

## Tokens

### Access Token

**Purpose:** Access protected resources

**Format:** JWT (JSON Web Token)
**Duration:** Short-lived (default: 1 minute)
**Contains:**
- User identity
- Granted scopes
- Client information
- Timestamps

### Refresh Token

**Purpose:** Obtain new access tokens

**Duration:** Long-lived (configurable)
**Used when:**
- Access token expires
- Need to maintain session
**Offline access:** Long-lived refresh tokens

### ID Token

**Purpose:** Authenticate user to client

**Format:** JWT
**Duration:** Same as access token
**Contains:**
- User identity claims
- Authentication details
- Timestamps

## Authentication Flows

### Authorization Code Flow

**Recommended for:** Web apps, mobile apps, native apps

**Flow:**
1. Browser redirects to Keycloak
2. User authenticates
3. Keycloak redirects back with authorization code
4. Application exchanges code for tokens
5. Application uses access token

### Implicit Flow

**⚠️ Deprecated - Do not use**

**Issues:**
- No refresh token
- Security concerns
- Removed from OAuth 2.1

### Client Credentials Flow

**For:** Service-to-service communication

**Flow:**
1. Client authenticates with credentials
2. Keycloak issues access token
3. Service uses token to access APIs

### Resource Owner Password Flow

**⚠️ Not recommended - Use only if necessary**

**Limitations:**
- Exposes user credentials
- No identity brokering
- No social login

### Device Authorization Flow

**For:** Devices with limited input/no browser

**Flow:**
1. Device requests device/user codes
2. User visits verification URI on different device
3. User enters code and authenticates
4. Device polls for authentication completion
5. Device exchanges code for tokens

## Terminology Quick Reference

| Term | Definition |
|------|------------|
| **Realm** | Isolated workspace for users, clients, roles |
| **Client** | Application/service requesting authentication |
| **User** | Person who can authenticate |
| **Role** | Type of user with specific permissions |
| **Group** | Collection of users for organization |
| **IdP** | External authentication system |
| **Federation** - Connect to external user stores |
| **Session** - Temporary interaction state |
| **Token** - Credentials for accessing resources |
| **Flow** - Sequence of authentication steps |
| **Scope** - Permissions requested by client |
| **Claim** - Piece of information about user |

## References

- <https://www.keycloak.org/docs/latest/server_admin/#keycloak-features-and-concepts>
- Keycloak Documentation
- OAuth 2.0 Specification
- OpenID Connect Specification
- SAML 2.0 Specification

## Related

- [[keycloak-overview]]
- [[keycloak-server-administration]]
- [[keycloak-securing-apps-oidc]]
- [[keycloak-authorization-services]]
