---
title: Keycloak JWT Authorization Grant (RFC 7523)
type: reference
domain: Keycloak
tags:
  - keycloak
  - jwt
  - oauth2
  - rfc7523
  - rfc7521
  - authorization-grant
  - token-exchange
  - cross-domain
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak JWT Authorization Grant (RFC 7523)

## Overview

JWT Authorization Grant allows clients to send a JWT assertion to request an access token using an existing trust relationship without direct user-approval at the authorization server. The assertion is validated through JWT claims and signature. <https://www.keycloak.org/securing-apps/jwt-authorization-grant>

**Status:** Preview Feature (disabled by default)

**Enable with:**
```bash
--features=preview
# or
--features=jwt-authorization-grant
```

## Specifications

Based on two RFCs:
- **RFC 7521** - Assertion Framework for OAuth 2.0 Client Authentication and Authorization Grants
- **RFC 7523** - JSON Web Token (JWT) Profile for OAuth 2.0 Client Authentication and Authorization Grants

## Use Cases

- Cross-domain or cross-realm access token exchange
- External to internal token exchange (alternative to Token Exchange V1)
- Trust relationship between Identity Providers
- Federation between different OIDC servers

## How It Works

1. Client sends JWT assertion to token endpoint
2. `grant_type` must be `urn:ietf:params:oauth:grant-type:jwt-bearer`
3. `assertion` parameter contains signed JWT
4. Keycloak validates JWT claims and signature
5. Access token returned without user interaction

## Trust Relationship Setup

Trust relationship defined by Identity Provider in Keycloak. Two IDP types support JWT authorization grants:

### 1. OpenID Connect v1.0 / Keycloak OpenID Connect

**Best for:** Trust relationship with external OpenID Provider (OP)

**Configuration:** Uses provider settings to validate JWT claims and signature

### 2. JWT Authorization Grant (New)

**Best for:** Generic trust relationship

**Configuration:** Similar validation for assertion to obtain access token

## JWT Validation Process

Keycloak performs these validations (per RFC 7521/7523):

1. **Client enabled** - Client configured to allow JWT authorization grants
2. **`iss` claim** - Identifies the Identity Provider (matches `issuer` config)
3. **IDP enabled** - Identity Provider allows JWT auth grants, client allowed to exchange
4. **`sub` claim** - User identifier in external provider, user must be linked to IDP in Keycloak
5. **`aud` claim** - Identifies Keycloak server (issuer or token endpoint URL)
6. **`exp` claim** - Expiration must be present and valid
7. **Optional claims** - `nbf` (not before), `iat` (issued at), `jti` (JWT ID)
8. **Signature** - JWT must be signed, verified with IDP's keys

## Client Configuration

**Only confidential clients can request JWT authorization grant.**

### Admin Console Steps

**Clients → Select Client → Settings tab → Capability config**

1. Enable **JWT Authorization Grant** capability
2. In **Allowed Identity Providers for JWT Authorization Grant**, select IDPs this client can use

![Client configuration](https://www.keycloak.org/resources/images/guides/jwt-authorization-grant-client-config.png)

## Identity Provider Configuration

**Identity Providers → Select OIDC or JWT provider → Settings tab → Authorization Grant Settings**

1. Enable **JWT Authorization Grant** switch
2. Configure options:

| Option | Description | Default |
|--------|-------------|---------|
| **Allow assertion reuse** | Allow one-time assertions (requires `jti` claim) | Off (one-time only) |
| **Max allowed assertion expiration** | Maximum assertion expiration in seconds | 5 minutes |
| **Assertion signature algorithm** | Valid signature algorithm (any if not specified) | Any |
| **Allowed clock skew** | Clock skew tolerance in seconds | 0 |
| **Limit access token expiration** | Limit token lifespan to assertion expiration if shorter | Off |

![IDP configuration](https://www.keycloak.org/resources/images/guides/jwt-authorization-grant-oidc-provider-config.png)

### Basic Configuration Options

Both OIDC and JWT IDP types need:

| Option | Description |
|--------|-------------|
| **Issuer** | Issuer for the assertion (required) |
| **Use JWKS URL** | Use JWKS endpoint to fetch keys (recommended: On) |
| **JWKS URL** | URL for downloading signing keys (required if JWKS enabled) |
| **Validating public key id** | Fixed `kid` for assertion signatures (if JWKS disabled) |
| **Validating public key** | Public key in PEM or JWKS format (if JWKS disabled) |

**Important:** With OIDC Identity Provider, JWT assertion signatures are always validated. The "Validate Signatures" option is ignored for JWT Authorization Grant (it only applies to user authentication flow).

## Example Request

### Token Endpoint Request

```http
POST /realms/demo/protocol/openid-connect/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Accept: application/json

client_id=test-client&
client_secret=XXXXX&
grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&
assertion=eyJhbGci[...redacted...].eyJpc3Mi[...redacted...].J9l-ZhwP[...redacted...]
```

### JWT Claims Set Example

```json
{
  "jti": "abcd1234-5678-efgh-ijkl-9012mnopqrst",
  "iss": "https://jwt-idp.example.com",
  "sub": "b3588c7e-14cb-46a9-9387-28adfd82f7a4",
  "aud": "https://keycloak.server/realms/demo",
  "iat": 1764839065,
  "exp": 1764839365,
  "other-claim": true
}
```

**Claims:**
- `iss` - Identity Provider identifier
- `sub` - User ID in external system (linked to Keycloak user via IDP)
- `aud` - Keycloak issuer or token endpoint
- `jti` - Guarantees one-time use
- `exp` - Mandatory expiration
- Other claims can be added

### JWT Header Example

```json
{
  "alg": "ES256",
  "kid": "2AOACLJmd5dQ8HPrDxwpkS-83yBhrzaLWSny9wmnYcY"
}
```

The key must be configured in Identity Provider (via JWKS URL or manually) to validate signature.

### Token Response

```json
{
  "access_token": "eyJhbG[...redacted...].eyJleH[...redacted...].RFnNEv[...redacted...]",
  "expires_in": 300,
  "refresh_expires_in": 0,
  "token_type": "Bearer",
  "not-before-policy": 0,
  "scope": "email profile"
}
```

**Important:** Per spec recommendation:
- Never issues refresh token
- Always creates transient session
- Access token valid until expired or explicitly revoked

## Cross-Realm Setup (Keycloak to Keycloak)

When both sides are Keycloak realms:

### DomainA (External IDP) Configuration

1. **Create client representing DomainB:**
   - Client ID: `http://localhost:8080/realms/domainb` (DomainB issuer)
   - Name: `domainb`

2. **Create client scope `access-domainb`:**
   - Name: `access-domainb`
   - Type: `None`
   - Only enable "Include in token scope"
   - Add Audience mapper:
     - Type: `Audience`
     - Name: `domainb-audience`
     - Included Client Audience: `http://localhost:8080/realms/domainb`
     - Add to access token: `On`

3. **Assign scope to client:**
   - Add `access-domainb` as optional scope to client used for token exchange

### Token Exchange in DomainA

```http
POST /realms/domaina/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

client_id=clienta&
client_secret=XXXXX&
grant_type=urn:ietf:params:oauth:grant-type:token-exchange&
subject_token_type=urn:ietf:params:oauth:token-type:access_token&
requested_token_type=urn:ietf:params:oauth:token-type:access_token&
scope=access-domainb&
audience=http://localhost:8080/realms/domainb&
subject_token=$SUBJECT_TOKEN
```

Resulting token is valid JWT assertion for DomainB.

### JWT Authorization Grant in DomainB

```http
POST /realms/domainb/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

client_id=clientb&
client_secret=YYYYYY&
grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&
scope=scope1 scope2&
assertion=$ASSERTION_TOKEN
```

## Client Policies Integration

New conditions and executors for JWT Authorization Grant:

### Conditions

**`identity-provider-alias`**
- Selects requests involving specific IDP alias
- Evaluates to `true` if one of listed IDPs present
- Currently manages JWT Authorization Grant (extensible for future)

### Executors

**`downscope-assertion-grant-enforcer`**
- Enforces requested scopes don't exceed assertion's scopes
- Checks `scope` claim in JWT
- Prevents privilege escalation (only downscoping permitted)
- Works with JWT Authorization Grant (`assertion`) and Token Exchange (`subject_token`)

**`jwt-claim-enforcer`**
- Configures extra requirements for JWT claims
- Example: Require `iat` claim or custom claim with specific value
- Uses regex pattern matching
- Request fails if claim doesn't match regex
- Works with JWT Authorization Grant and Token Exchange

## Obtaining Initial JWT Assertion

The JWT Authorization Grant requires an existing JWT assertion. How the client gets this assertion depends entirely on the external Identity Provider (not Keycloak).

**If external IDP is another Keycloak:**
- Use Standard Token Exchange to obtain assertion
- Configure audience and client scopes appropriately
- Exchange subject token for cross-domain token

## Security Considerations

- **Preview feature** - Not fully supported, may change
- **Confidential clients only** - Public clients not supported
- **One-time assertions** - Recommended to prevent replay attacks
- **Clock skew** - Configure appropriate tolerance for time differences
- **Signature validation** - Always use JWKS URL or properly configured keys
- **User linking** - Users must be linked to Identity Provider in Keycloak

## Differences from Token Exchange V1

| Feature | JWT Authorization Grant | Token Exchange V1 |
|---------|------------------------|-------------------|
| Specification | RFC 7523 (standard) | Keycloak-specific |
| Trust model | JWT assertion (claims + signature) | External/internal token |
| User approval | Not required | Not required |
| Refresh token | Never issued | Can be issued |
| Session | Transient only | Can be persistent |

**Recommendation:** JWT Authorization Grant is recommended as alternative to External to Internal Token Exchange V1.

## References

- <https://www.keycloak.org/securing-apps/jwt-authorization-grant>
- RFC 7521 - Assertion Framework for OAuth 2.0
- RFC 7523 - JWT Profile for OAuth 2.0
- Keycloak Token Exchange Documentation

## Related

- [[keycloak-securing-apps-oidc]]
- [[keycloak-token-exchange]]
- [[keycloak-server-administration]]
- [[oauth2-token-introspection]]
