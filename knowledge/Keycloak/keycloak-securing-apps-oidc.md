---
title: Keycloak Securing Applications with OpenID Connect
type: reference
domain: Keycloak
tags:
  - keycloak
  - oidc
  - openid-connect
  - oauth2
  - authentication
  - authorization
  - sso
  - security
  - jwt
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Securing Applications with OpenID Connect

## Overview

Keycloak is a fully-compliant OpenID Connect Provider implementation that exposes endpoints for authenticating and authorizing users. Applications can secure themselves by leveraging existing OpenID Connect support from their ecosystem or by using Keycloak Client Adapters as a last resort. <https://www.keycloak.org/securing-apps/oidc-layers>

## OpenID Connect Endpoints

### Well-Known Configuration Endpoint

The most important endpoint for discovering all available endpoints:

```
/realms/{realm-name}/.well-known/openid-configuration
```

**Example:**
```
http://localhost:8080/realms/myrealm/.well-known/openid-configuration
```

Some RP (Relying Party) libraries automatically retrieve all required endpoints from this endpoint.

### Authorization Endpoint

Performs authentication of the end-user by redirecting the user agent:

```
/realms/{realm-name}/protocol/openid-connect/auth
```

### Token Endpoint

Used to obtain tokens by exchanging authorization codes or supplying credentials:

```
/realms/{realm-name}/protocol/openid-connect/token
```

Also used to obtain new access tokens when they expire.

### Userinfo Endpoint

Returns standard claims about the authenticated user (protected by bearer token):

```
/realms/{realm-name}/protocol/openid-connect/userinfo
```

### Logout Endpoint

Logs out the authenticated user:

```
/realms/{realm-name}/protocol/openid-connect/logout
```

**RP-Initiated Logout:** Redirect user agent to this endpoint to logout and redirect back to application.

**Direct Invocation (Not Recommended):** Can be invoked directly with refresh token, but this is non-standard legacy format. Use OIDC/SAML standard logout, Admin console, or Account console instead.

### Certificate Endpoint

Returns public keys enabled by the realm as JSON Web Key (JWK):

```
/realms/{realm-name}/protocol/openid-connect/certs
```

### Introspection Endpoint

Retrieves the active state of a token (validate access/refresh tokens):

```
/realms/{realm-name}/protocol/openid-connect/token/introspect
```

**Only confidential clients can invoke this endpoint.**

**JWT Response:** Invoke with `Accept: application/jwt` header to receive full JWT access token in response (requires "Support JWT claim in Introspection Response" enabled on client).

### Dynamic Client Registration Endpoint

Dynamically register clients:

```
/realms/{realm-name}/clients-registrations/openid-connect
```

### Token Revocation Endpoint

Revoke tokens (refresh or access):

```
/realms/{realm-name}/protocol/openid-connect/revoke
```

Revoking refresh token also revokes user consent.

### Device Authorization Endpoint

Obtain device code and user code for limited input devices:

```
/realms/{realm-name}/protocol/openid-connect/auth/device
```

### Backchannel Authentication Endpoint

Obtain auth_req_id for CIBA flow:

```
/realms/{realm-name}/protocol/openid-connect/ext/ciba/auth
```

**Only confidential clients can invoke this endpoint.**

## Supported Grant Types

### Authorization Code Flow (Recommended)

**Best for:** Web applications, native apps, mobile apps with embedded user agent

**Flow:**
1. User agent redirected to Keycloak
2. User authenticates with Keycloak
3. Authorization Code created and user agent redirected back
4. Application exchanges code + credentials for tokens

**Tokens returned:** Access Token, Refresh Token, ID Token

### Implicit Flow (Deprecated)

**⚠️ Per RFC 9700 Best Current Practice, this flow SHOULD NOT be used. Removed from OAuth 2.1.**

**Flow:** Returns Access Token and ID Token directly (no Authorization Code)

**Issues:**
- No Refresh Token
- Security risks (tokens leaked via logs/history)
- Requires long-lived tokens or frequent redirects

**Alternative:** Use Hybrid Flow or Authorization Code Flow

### Resource Owner Password Credentials (Direct Grant)

**⚠️ Per RFC 9700, this flow MUST NOT be used. Removed from OAuth 2.1.**

**Limitations:**
- User credentials exposed to application
- Application needs login pages
- No identity brokering or social login
- No support for flows (registration, required actions)

**Security concerns:**
- Involves more than Keycloak in credential handling
- Increased vulnerable surface area

**Example using CURL:**
```bash
curl \
  -d "client_id=myclient" \
  -d "client_secret=40cc097b-2a57-4c17-b36a-8fdf3fc2d578" \
  -d "username=user" \
  -d "password=password" \
  -d "grant_type=password" \
  "http://localhost:8080/realms/master/protocol/openid-connect/token"
```

**Requirement:** Client must have "Direct Access Grants Enabled" option

### Client Credentials

**Best for:** Background services acting on their own behalf (not on behalf of users)

**Authentication:** Client secret or public/private keys

### Device Authorization Grant

**Best for:** Internet-connected devices with limited input or no browser

**Flow:**
1. Application requests device code and user code
2. Keycloak creates codes
3. Application displays user code and verification URI
4. User authenticates on separate device/browser
5. Application polls until authentication complete
6. Application exchanges device code for tokens

### Client Initiated Backchannel Authentication Grant (CIBA)

**Best for:** Clients initiating authentication without browser redirect

**Flow:**
1. Client requests auth_req_id from Keycloak
2. Keycloak creates auth_req_id
3. Client polls token endpoint (or waits for ping mode notification)
4. When user authenticated, client exchanges auth_req_id for tokens

**Ping Mode:** Client waits for notification at Client Notification Endpoint instead of polling.

## Financial-grade API (FAPI) Support

Keycloak supports compliance with these specifications:
- FAPI Security Profile 1.0 - Part 1: Baseline
- FAPI Security Profile 1.0 - Part 2: Advanced
- FAPI Client Initiated Backchannel Authentication Profile
- FAPI 2.0 Security Profile (Final)
- FAPI 2.0 Message Signing (Final)

### FAPI Client Profiles

Configure Client Policies and link to global profiles:
- `fapi-1-baseline` - FAPI 1.0 Baseline compliance
- `fapi-1-advanced` - FAPI 1.0 Advanced compliance
- `fapi-2-security-profile` - FAPI 2.0 Security Profile
- `fapi-2-dpop-security-profile` - FAPI 2.0 with DPoP
- `fapi-2-message-signing` - FAPI 2.0 Message Signing
- `fapi-2-dpop-message-signing` - FAPI 2.0 with DPoP and Message Signing
- `fapi-ciba` - FAPI CIBA compliance

**PAR with FAPI:** Use both `fapi-1-baseline` (contains PKCE enforcer) and `fapi-1-advanced` for PAR requests.

**CIBA with FAPI:** Use both `fapi-1-advanced` and `fapi-ciba` profiles.

### Open Finance Brasil FAPI

Keycloak compliant with Open Finance Brasil FAPI Security Profile 1.0 Implementers Draft 3.

**Stricter requirements:**
- Non-PAR clients: Use encrypted OIDC request objects (`secure-request-object` executor with "Encryption Required")
- JWS algorithm: `PS256`
- JWE algorithm: `RSA-OAEP` with `A256GCM`

### Australia Consumer Data Right (CDR)

Use `fapi-1-advanced` profile as base.

**With PAR:** Apply PKCE using `pkce-enforcer` executor.

### TLS Considerations

All interactions must use TLS (HTTPS). Keycloak uses TLSv1.3 by default.

**Configure ciphers:**
```bash
--https-protocols=TLSv1.3
--https-cipher-suites=<cipher-list>
```

## OAuth 2.1 Support

Keycloak supports compliance with OAuth 2.1 Authorization Framework (draft).

### OAuth 2.1 Client Profiles

- `oauth-2-1-for-confidential-client` - For confidential clients
- `oauth-2-1-for-public-client` - For public clients

**⚠️ OAuth 2.1 is draft - built-in profiles may change.**

**Public clients:** Use DPoP preview feature to bind tokens to client's key pair.

## Recommendations

### Validating Access Tokens

**Option 1: Introspection Endpoint**
```bash
POST /realms/{realm}/protocol/openid-connect/token/introspect
```
- **Downside:** Network call to Keycloak (slow, can overload server)

**Option 2: Local JWT Validation (Recommended)**
- Access tokens are JWT signed with JWS
- Validate locally using realm's public key
- Get public key from certificate endpoint (cache it)
- Use third-party JWS validation libraries

### Redirect URIs

**Best practices:**
- Be as specific as possible
- Always use `https` for web applications in production
- Never allow redirects to `http` in production

**Special redirect URIs:**

`http://127.0.0.1`
- For native applications
- Allows any port
- Per OAuth 2.0 for Native Apps, use IP literal instead of `localhost`

`urn:ietf:wg:oauth:2.0:oob`
- For devices that can't start web server or have no browser
- Keycloak displays code in title and page
- User copies code manually to application
- Can use different device to obtain code

## Keycloak Specific Errors

**`error=temporarily_unavailable` with `error_description=authentication_expired`**

**Cause:** User authenticated with SSO session, but authentication session expired in current browser tab. Keycloak cannot automatically SSO re-authenticate.

**Solution:** Immediately retry authentication with new OIDC request. SSO session should authenticate user and redirect back successfully.

## Terminology

- **Clients** - Entities that interact with Keycloak to authenticate users and obtain tokens (apps/services)
- **Applications** - Wide range of platform-specific applications for each protocol
- **Client Adapters** - Libraries providing tight integration to platform/framework
- **Creating/Registering a Client** - Same action (Console = "Creating", Registration Service = "Registering")
- **Service Account** - Client that obtains tokens on its own behalf

## Application Ecosystem Support

**Preferred Approach:** Use existing OIDC/SAML support from your programming language/framework to avoid vendor lock-in.

**Keycloak Client Adapters:** Use only as last resort when ecosystem lacks protocol support.

### Recommended Implementations

**OpenID Connect:**

| Platform | Recommended |
|----------|-------------|
| Java | Wildfly Elytron OIDC, Spring Boot |
| JavaScript (client) | Keycloak JS adapter |
| Node.js (server) | Keycloak Node.js adapter |
| C# | OWIN |
| Python | oidc |
| Android | AppAuth |
| iOS | AppAuth |
| Apache HTTP Server | mod_auth_openidc |

**SAML:**

| Platform | Recommended |
|----------|-------------|
| Java | Keycloak SAML Galleon feature pack for WildFly/EAP |
| Apache HTTP Server | mod_auth_mellon |

## Basic Steps to Secure Applications

1. **Register a client** to a realm:
   - Admin Console
   - Client Registration Service
   - CLI

2. **Enable OpenID Connect** in your application:
   - Leverage existing ecosystem support (preferred)
   - Use Keycloak Adapter (last resort)

## Getting Started

The [Keycloak Quickstarts Repository](https://www.keycloak.org/guides) provides examples for different programming languages and frameworks.

## References

- <https://www.keycloak.org/securing-apps/oidc-layers>
- <https://www.keycloak.org/securing-apps/overview>
- <https://openid.net/connect/>
- OAuth 2.0 Specification (RFC 6749)
- OpenID Connect Discovery (RFC 8414)
- OAuth 2.0 Token Introspection (RFC 7662)
- OAuth 2.0 Token Revocation (RFC 7009)
- OAuth 2.0 Device Authorization Grant (RFC 8628)
- FAPI 1.0 Security Profile
- FAPI 2.0 Security Profile

## Related

- [[keycloak-server-administration]]
- [[keycloak-jwt-authorization-grant]]
- [[keycloak-saml]]
- [[oauth2-1-best-practices]]
