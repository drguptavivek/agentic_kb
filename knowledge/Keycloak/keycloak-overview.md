---
title: Keycloak Overview
type: reference
domain: Keycloak
tags:
  - keycloak
  - sso
  - identity-management
  - authentication
  - authorization
  - oidc
  - saml
  - overview
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Overview

## What is Keycloak?

Keycloak is an open-source identity and access management (IAM) solution oriented towards applications and services. It provides:
- **Single Sign-On (SSO)** - Log in once, access multiple applications
- **Identity Brokering** - Integration with external identity providers
- **User Federation** - Connect to existing LDAP/Active Directory
- **Admin Console** - Web-based administration interface
- **Account Console** - User self-service portal
- **Standards-based** - OAuth 2.0, OpenID Connect, SAML 2.0

**Project Status:** CNCF (Cloud Native Computing Foundation) Incubation Project

## Key Features (26.5.0)

### New Features in 26.5.0

**Workflows (Preview)**
- Automate administrative tasks within a realm
- Identity Governance and Administration (IGA) capabilities
- Event-driven automation

**JWT Authorization Grant (Preview)**
- RFC 7523 support for JWT bearer tokens
- Alternative to external-to-internal token exchange
- Cross-domain and cross-realm authentication

**Model Context Protocol (MCP) Integration**
- Use Keycloak as authorization server for MCP servers
- Documentation guide available

**Kubernetes Service Account Authentication**
- Authenticate clients with K8s service account tokens
- Avoid static client secrets

**OpenTelemetry Support**
- Centralized logs, metrics, and traces
- Preview logs support, experimental metrics support

**Organization Invitation Management**
- View, resend, delete invitations
- Persistent database storage
- Status tracking (Pending, Expired)

**HTTP Performance Enhancements**
- ~5% throughput improvement with `http-optimized-serializers` feature

### Security Enhancements

**CORS Improvements**
- Environment-specific header support
- Client registration access policy CORS headers

**Logout Confirmation Page**
- Optional "You are logged out" confirmation

**Hidden OIDC Scopes**
- Prevent scope discovery via public APIs

**PostgreSQL 18 Support**
- Enhanced database compatibility

### Observability

**OpenTelemetry Logs (Preview)**
- Export logs to OTel collectors
- Centralized log management

**OpenTelemetry Metrics (Experimental)**
- Micrometer-to-OpenTelemetry bridge
- Unified observability stack

**MDC Logging (Supported)**
- Enrich logs with context (realm, client, user ID, IP)
- Promoted from preview to supported

### Performance

**Session Cache Affinity**
- Reduced response times with sticky sessions
- Authentication sessions created on respective nodes

**Batch Session Deletion**
- Improved response times with many sessions
- Small batch deletes instead of table-wide

**ppc64le Architecture Support**
- PowerPC 64-bit Little Endian containers

## Supported Protocols

### OpenID Connect (OIDC) / OAuth 2.0

**Endpoints:**
- Authorization Endpoint
- Token Endpoint
- Userinfo Endpoint
- Logout Endpoint
- Introspection Endpoint
- Revocation Endpoint
- Device Authorization
- Backchannel Authentication (CIBA)
- Dynamic Client Registration

**Grant Types:**
- Authorization Code (recommended)
- Implicit (deprecated)
- Resource Owner Password (Direct Grant, not recommended)
- Client Credentials
- Device Authorization Grant
- Client Initiated Backchannel Authentication (CIBA)
- JWT Authorization Grant (preview)

**Features:**
- Financial-grade API (FAPI) 1.0 and 2.0 support
- OAuth 2.1 support (draft)
- DPoP (Demonstration of Proof-of-Possession)
- Pushed Authorization Requests (PAR)

### SAML 2.0

**Roles:**
- Identity Provider (IdP) - Users authenticate in Keycloak
- Service Provider (SP) - Application trusts Keycloak

**Features:**
- SAML 2.0 IdP and SP support
- Identity brokering with external SAML IdPs
- SAML client adapters

## Core Concepts

### Realms

A **realm** is a isolated workspace containing:
- Users
- Applications (clients)
- Roles
- Groups
- Identity providers
- User federation

**Master Realm:** Special realm for administering Keycloak itself.

**Example:** Different realms for different organizations or environments (dev, staging, prod).

### Clients

A **client** is an application or service that requests authentication from Keycloak.

**Client Types:**
- **Confidential** - Can securely store secrets (server-side apps)
- **Public** - Cannot securely store secrets (SPA, mobile apps, native apps)
- **Bearer-only** - Services that only validate tokens (no direct user login)

**Client Authentication:**
- Client Secret
- JWT Signed by Client
- None (public clients)

### Users

**Users** represent the people who log in to your applications.

**User Attributes:**
- Basic info: username, email, first name, last name
- Custom attributes (extensible)
- Required actions (password reset, TOTP setup, etc.)
- Credentials (password, OTP, passkeys)
- Groups membership
- Role mappings
- Federated identities (linked external accounts)

### Roles

**Roles** are a type of permission that can be assigned to users or groups.

**Role Types:**
- **Realm Roles** - Available across the entire realm
- **Client Roles** - Scoped to a specific client

**Composite Roles:** Roles that contain other roles (role inheritance).

### Groups

**Groups** organize users and make role assignment easier.

**Benefits:**
- Assign roles to groups instead of individual users
- Nested group hierarchy
- Attribute-based group membership

### Identity Providers

**Identity Providers (IdP)** enable authentication through external systems.

**Types:**
- **Social** - Google, Facebook, GitHub, Twitter, etc.
- **Enterprise** - SAML 2.0, OpenID Connect
- **User Federation** - LDAP, Active Directory, Kerberos

### User Federation

**User Federation** allows Keycloak to authenticate users from external sources.

**Providers:**
- LDAP / Active Directory
- Kerberos
- SSSD (System Security Services Daemon)

**Benefits:**
- Single source of truth for users
- Centralized user management
- No duplicate user accounts

## Getting Started

### Installation

**Container Image (Recommended):**
```bash
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.5.0 \
  start-dev
```

**Download:**
- <https://www.keycloak.org/downloads>

### First Steps

1. **Access Admin Console**
   - URL: `http://localhost:8080/`
   - Username: `admin`
   - Password: (as configured)

2. **Create a Realm**
   - Click realm dropdown → Create realm
   - Enter name (e.g., `myapp`)

3. **Create a User**
   - Users → Add user
   - Enter username, email, etc.
   - Set initial password (Credentials tab)

4. **Create a Client**
   - Clients → Create client
   - Select client type (OIDC or SAML)
   - Configure redirect URIs

5. **Test Login**
   - Use Account Console or your application

### Quickstarts

The [Keycloak Quickstarts Repository](https://github.com/keycloak/keycloak-quickstarts) provides examples for:
- JavaScript
- Node.js
- Spring Boot
- WildFly/EAP
- Other frameworks

## Architecture

### Server Components

**Keycloak Server:**
- Built on Quarkus
- Embedded Infinispan for caching
- Supports clustering and high availability
- Database for persistent storage

### Supported Databases

- PostgreSQL 13+
- MySQL 8.0+
- MariaDB 10.11+
- Oracle Database
- Microsoft SQL Server
- H2 (development only)

### Deployment Options

**Container:**
- Kubernetes (Operator available)
- OpenShift (Operator available)
- Docker / Podman

**Bare Metal:**
- ZIP distribution
- Systemd service
- Windows service (new in 26.5)

### Clustering

Keycloak supports clustering for:
- High availability
- Horizontal scaling
- Load balancing

**Requirements:**
- Sticky sessions recommended (for session cache affinity)
- Shared database
- Infinispan configuration for cross-site replication

## Security Best Practices

### TLS/HTTPS

**Always use HTTPS in production:**
- Keycloak uses TLSv1.3 by default
- Configure proper cipher suites if needed
- Use valid certificates (not self-signed in production)

### Password Policies

Configure password policies in Realm Settings:
- Minimum length
- Special characters
- Uppercase/lowercase requirements
- Password history
- Expiration

### Brute Force Protection

Enable in Realm Settings → Security Defenses:
- Limit failed login attempts
- Temporary lockout
- Permanent lockout after X failures

### Event Logging

Enable events for:
- Login attempts
- Admin operations
- Errors
- Custom events

**Events types:**
- Admin events (administrative actions)
- User events (user actions)
- Stored events (persistent in database)

### Fine-Grained Admin Permissions (FGAP)

Control admin access with permissions instead of just admin role:
- Enable FGAP in Realm Settings
- Define permissions for specific resources
- Use groups and roles for access control

## Administration

### Admin Console

Web-based UI for:
- User management
- Client configuration
- Realm settings
- Identity provider setup
- Audit logging

### Admin REST API

Full administration via REST API:
- CRUD operations for all resources
- Authentication via client credentials or service account
- OpenAPI documentation available

### CLI (kc.sh/kc.bat)

Command-line interface for:
- Starting/stopping server
- Building and running
- Configuration export/import
- Windows service installation (new)

### kcadm.sh

Admin CLI for:
- Batch operations
- Scripting
- Automation
- CI/CD integration

## Monitoring and Observability

### Health Checks

**Endpoints:**
- `/health/ready` - Startup readiness
- `/health/live` - Liveness probe
- `/health/started` - Startup complete

### Metrics

**Available metrics:**
- JVM metrics (memory, GC, threads)
- HTTP server metrics
- Infinispan cache metrics
- Database connection pool metrics

**Export formats:**
- Prometheus (default)
- OpenTelemetry (experimental)

### Logging

**Log levels:**
- INFO (default)
- DEBUG (development)
- ERROR (production issues)

**Categories:**
- Root logging
- Per-package logging
- MDC (Mapped Diagnostic Context) for request correlation

## References

- Official Documentation: <https://www.keycloak.org/documentation>
- Downloads: <https://www.keycloak.org/downloads>
- GitHub: <https://github.com/keycloak/keycloak>
- Community: <https://www.keycloak.org/community>

## Related

- [[keycloak-securing-apps-oidc]]
- [[keycloak-server-administration]]
- [[keycloak-jwt-authorization-grant]]
- [[keycloak-security]]
- [[keycloak-federation]]
