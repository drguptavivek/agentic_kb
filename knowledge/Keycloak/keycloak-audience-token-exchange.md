---
title: Keycloak Audience and Token Exchange
type: reference
domain: Keycloak
tags:
  - keycloak
  - audience
  - token-exchange
  - oidc
  - token-broker
  - cross-client
  - delegation
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Audience and Token Exchange

## Overview

Audience claims and token exchange enable secure token sharing between Keycloak clients. This allows applications to obtain tokens for other applications, facilitating microservices architecture, API gateways, and delegated access patterns.

## Audience Claims

### What is an Audience Claim?

The `aud` (audience) claim in a token identifies the intended recipients (audiences) of the token.

**Purpose:**
- Prevent token misuse
- Enable token validation by multiple services
- Control which services can accept the token

**Standard (RFC 7519):**
```
aud: ARRAY<STRING>
```

**Example:**
```json
{
  "aud": ["myapp", "api-service"]
}
```

### Why Use Multiple Audiences?

**Use cases:**
- **API gateway pattern** - Frontend token valid for backend APIs
- **Microservices** - One token for multiple services
- **Delegation** - Act on behalf of user for another service
- **Token exchange** - Exchange token for different audience

### Single vs Multiple Audiences

**Single audience (traditional):**
```
Token issued to: myapp
Valid for: myapp only
```

**Multiple audiences (modern):**
```
Token issued to: myapp
Valid for: myapp, api-service, user-service
```

**Benefits:**
- Fewer token requests
- Simpler client code
- Better performance
- Unified authentication

## Configuring Audience Support

### Using Audience Mapper

**Per-client configuration:**

**Admin Console:**
1. Clients → Select client
2. **Client scopes** tab
3. **Add client scope** → Select scope with audience mapper
4. Or add directly to client

**Create dedicated scope:**
1. Client Scopes → Create client scope
2. Name: `api-access`
3. Protocol: `openid-connect`
4. **Add mapper** → Audience Mapper
5. Configure:
   - **Name:** Add API audience
   - **Included Client Audience:** `api-service`
   - **Add to access token:** ON

### Client Scope vs Direct Mapper

**Client Scope approach (recommended):**
- ✅ Reusable across clients
- ✅ Consistent configuration
- ✅ Easier to manage
- ✅ Supports optional scopes

**Direct mapper:**
- ✅ Client-specific
- ❌ Not reusable
- ❌ Harder to manage

**Recommendation:** Use client scopes for audience configuration

## Token Exchange

### What is Token Exchange?

**Token exchange** (RFC 8693) allows a client to exchange an existing token for a new token with different permissions or audience.

**Use cases:**
- **Downscope permissions** - Request fewer scopes than original
- **Change audience** - Get token for different service
- **Act on behalf** - Service-to-service delegation
- **Domain crossover** - Cross-realm token exchange

### Token Exchange Types

### External to Internal Token Exchange

**Use case:** Exchange external token for internal Keycloak token

**Flow:**
1. Client has token from external IdP (e.g., Azure AD)
2. Exchange with Keycloak for internal token
3. Use internal token to access services

**Alternative: JWT Authorization Grant (Recommended)**
- More secure
- Standard-based (RFC 7523)
- Better than Token Exchange V1

**See:** [[keycloak-jwt-authorization-grant]]

### Internal to Internal Token Exchange

**Use case:** Exchange token for different audience or scopes

**Flow:**
1. Client has token for `client-a`
2. Exchange for token for `client-b`
3. Use new token to access `client-b`

**This is the **Standard Token Exchange**** pattern.**

### Standard Token Exchange

**Keycloak 26.2+** introduces supported standard token exchange with:
- **Downscope enforcement** - Cannot get more permissions than original
- **Chain of exchanges** - Limited to prevent abuse
- **Improved security** - Better than Token Exchange V1

**Configuration:**
```
Realm Settings → Token Exchange
```

**Enable:**
- **Downscope enforcement** - Prevents permission escalation
- **Chain limit** - Maximum exchange depth (default: 5)

## Token Exchange Configuration

### Enable Token Exchange for Client

**Admin Console:**
1. Clients → Select client
2. **Advanced** tab
3. **Access Token Lifespan** section
4. Configure token exchange settings

**Settings:**
- **Client Credentials** - Can do token exchange
- **Standard Token Exchange Enabled** - Use standard exchange (recommended)
- **External to Internal Token Exchange Enabled** - Exchange external tokens
- **Token Exchange Permitted** - Which clients can exchange

### Per-Client Exchange Permissions

**Configure which clients can exchange tokens:**

**Admin Console:**
1. Clients → Select client
2. **Advanced** tab
3. **Token Exchange** section
4. **Token Exchange Permitted** - Add allowed clients

**Example:**
```
myapp-client can exchange to:
├── api-service
├── user-service
└── admin-service
```

## Token Exchange Examples

### Example 1: Get Token for API Service

**Scenario:** Frontend `myapp` needs token for `api-service`

**Request:**
```bash
POST /realms/myrealm/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:token-exchange&
subject_token=eyJhbG...&
subject_token_type=urn:ietf:params:oauth:token-type:access_token&
audience=api-service
```

**Response:**
```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "eyJ...",
  "expires_in": 300,
  "token_type": "Bearer",
  "aud": "api-service"
}
```

### Example 2: Downscope Permissions

**Scenario:** Exchange admin token for read-only token

**Request:**
```bash
POST /realms/myrealm/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:token-exchange&
subject_token=eyJhbG...&
subject_token_type=urn:ietf:params:oauth:token-type:access_token&
scope=read-only&
requested_token_type=urn:ietf:params:oauth:token-type:access_token
```

**Original token:** `admin` role (full access)
**New token:** `read-only` role (limited access)

### Example 3: Cross-Realm Token Exchange

**Scenario:** Exchange token from `realm-a` for `realm-b`

**Prerequisites:**
- Both realms exist
- User linked across realms
- Token exchange enabled

**Request:**
```bash
POST /realms/realm-b/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:token-exchange&
subject_token=eyJhbG...&
subject_token_type=urn:ietf:params:oauth:token-type:access_token&
subject_issuer=http://localhost:8080/realms/realm-a&
audience=api-service
```

## Client Configuration Patterns

### Pattern 1: Frontend to Backend

**Scenario:** SPA needs to access API

**Configuration:**

**Frontend client (myapp):**
```
Client ID: myapp
Access Type: public
Valid Redirect URIs: http://localhost:3000/*
```

**API client (api-service):**
```
Client ID: api-service
Access Type: confidential
Client Scopes: api-access (with audience mapper)
```

**Client Scope: api-access**
```
Name: api-access
Include in token: OFF (optional scope)
Protocol Mapper: Audience Mapper
└─ Included Client Audience: api-service
```

**Flow:**
1. User logs into frontend
2. Frontend receives token for `myapp`
3. Frontend exchanges token for `api-service`
4. API validates token with `api-service` audience
5. API processes request

### Pattern 2: Microservices Architecture

**Scenario:** Multiple services need to authenticate each other

**Configuration:**

**Client Scope: service-access**
```
Name: service-access
Protocol Mapper: Audience Mapper
Included Client Audience:
├── service-a
├── service-b
└── service-c
```

**Apply to all service clients:**
- service-a
- service-b
- service-c

**Flow:**
1. Service A gets token for `service-a`
2. Service A exchanges for `service-b` audience
3. Service B validates token
4. Service B processes request

### Pattern 3: Delegated Access

**Scenario:** Service acts on behalf of user for another service

**Configuration:**

**Primary client:**
```
Client ID: primary-service
Token Exchange Permitted:
  - delegated-service
```

**Delegated client:**
```
Client ID: delegated-service
Access Type: confidential
Allowed audiences: primary-service
```

**Flow:**
1. Primary service receives request
2. Primary service exchanges token for `delegated-service`
3. Delegated service validates token
4. Delegated service acts on behalf of user
5. Returns response to primary service

## Security Considerations

### Downscope Enforcement

**Critical security feature:**

**Problem:** Client with limited permissions exchanging for broader permissions

**Solution:** Keycloak enforces that exchanged token cannot have more scopes than original

**Example:**
```
Original token: read profile
Requested scopes: read, write, delete

Result: Only read, profile granted (write, delete denied)
```

**Enable:**
```
Realm Settings → Token Exchange → Downscope enforcement
```

### Token Lifetime

**Considerations:**
- Exchanged tokens have same expiration as original
- Short-lived original tokens = short-lived exchanged tokens
- Refresh tokens not issued during exchange

**Best practice:**
- Use short-lived access tokens (1-5 minutes)
- Use refresh tokens sparingly
- Implement token refresh flow

### Client Permission

**Control which clients can exchange:**

**Settings:**
```
Client → Advanced → Token Exchange Permitted
```

**Best practice:**
- Only allow trusted clients
- Limit exchange permissions
- Monitor exchange requests
- Audit exchange patterns

## Implementation Examples

### SPA Using Token Exchange

**Frontend code:**
```javascript
// Login with Keycloak
const kc = new Keycloak({
  url: 'http://localhost:8080',
  realm: 'myrealm',
  clientId: 'myapp'
});

await kc.login();

// Exchange token for API
const exchangeParams = new URLSearchParams();
exchangeParams.append('grant_type', 'urn:ietf:params:oauth:grant-type:token-exchange');
exchangeParams.append('subject_token', kc.token);
exchangeParams.append('subject_token_type', 'urn:ietf:params:oauth:token-type:access_token');
exchangeParams.append('audience', 'api-service');

const response = await fetch('http://localhost:8080/realms/myrealm/protocol/openid-connect/token', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded'
  },
  body: exchangeParams
});

const { access_token } = await response.json();

// Use API token
const apiResponse = await fetch('http://localhost:8081/api/data', {
  headers: {
    'Authorization': `Bearer ${access_token}`
  }
});
```

### Backend Token Validation

**Node.js/Express example:**
```javascript
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: 'http://localhost:8080/realms/myrealm/protocol/openid-connect/certs'
});

function validateToken(token, expectedAudience) {
  return new Promise((resolve, reject) => {
    jwt.verify(token, getKey, {
      audience: expectedAudience,
      issuer: 'http://localhost:8080/realms/myrealm'
    }, (err, decoded) => {
      if (err) {
        reject(err);
      } else {
        resolve(decoded);
      }
    });
  });
}

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    callback(err, key.publicKey || key.rsaPublicKey);
  });
}

// Middleware
function requireAudience(audience) {
  return async (req, res, next) => {
    const token = req.headers.authorization?.replace('Bearer ', '');

    try {
      const decoded = await validateToken(token, audience);
      req.user = decoded;
      next();
    } catch (err) {
      res.status(401).json({ error: 'Invalid token' });
    }
  };
}

// Use in route
app.get('/api/data', requireAudience('api-service'), (req, res) => {
  res.json({ data: 'sensitive data' });
});
```

## CLI Examples

### Exchange Token with kcadm

```bash
# Get token for user
export KEYCLOAK_TOKEN="eyJhbG..."

# Exchange token for different audience
curl -X POST http://localhost:8080/realms/myrealm/protocol/openid-connect/token \
  -H "Authorization: Bearer $KEYCLOAK_TOKEN" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  -d "subject_token=$KEYCLOAK_TOKEN" \
  -d "subject_token_type=urn:ietf:params:oauth:token-type:access_token" \
  -d "audience=api-service"
```

### Check Token Audience

```bash
# Decode and inspect token
echo $TOKEN | jq .

# Or use Keycloak introspection
curl -X POST http://localhost:8080/realms/myrealm/protocol/openid-connect/token/introspect \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=$TOKEN" \
  -d "client_id=api-service" \
  -d "client_secret=your-secret"
```

## Best Practices

### Audience Design

**✅ DO:**
- Use meaningful audience names (client IDs)
- Document audience requirements
- Use client scopes for audience configuration
- Limit audiences per token
- Validate audiences on resource server
- Use multiple audiences sparingly

**❌ DON'T:**
- Add all possible audiences to every token
- Use vague audience names
- Skip audience validation
- Mix unrelated services in one token
- Create token bloat
- Forget performance impact

### Token Exchange Design

**✅ DO:**
- Enable downscope enforcement
- Limit token exchange chain depth
- Monitor exchange patterns
- Use standard token exchange (not V1)
- Document exchange flows
- Implement proper error handling
- Consider token lifetime

**❌ DON'T:**
- Allow unlimited downscoping
- Ignore security implications
- Skip permission checks
- Exchange tokens unnecessarily
- Create circular exchange chains
- Forget about token lifetime

### Security

**✅ DO:**
- Enforce downscope
- Validate client permissions
- Monitor exchange requests
- Audit token usage
- Use HTTPS only
- Implement rate limiting
- Log exchange events

**❌ DON'T:**
- Allow permission escalation
- Skip client validation
- Ignore monitoring
- Use HTTP
- Forget about logging
- Allow unlimited exchanges

## Troubleshooting

### Token Exchange Fails

**Error: "Token exchange not permitted"**

**Solutions:**
1. Check token exchange enabled for client
2. Verify client in permitted list
3. Check subject_issuer for cross-realm exchange
4. Verify token not expired

**Error: "Invalid audience"**

**Solutions:**
1. Verify audience mapper configured
2. Check client scope assigned
3. Validate audience name matches

### Audience Not in Token

**Debug steps:**
1. Check mapper enabled
2. Verify "Add to access token" selected
3. Check client scope is default or requested
4. Verify client ID in audience mapper

**CLI debug:**
```bash
# Get client mappers
kcadm.sh get clients/myclient/protocol-mappers/oidc -r myrealm

# Check client scopes
kcadm.sh get clients/myclient/client-scopes -r myrealm
```

## References

- <https://www.keycloak.org/docs/latest/server_admin/#audience-support>
- <https://www.keycloak.org/docs/latest/securing-apps/topics/token-exchange/>
- RFC 8693 - OAuth 2.0 Token Exchange
- RFC 7519 - JSON Web Token (JWT)

## Related

- [[keycloak-securing-apps-oidc]]
- [[keycloak-protocol-mappers]]
- [[keycloak-jwt-authorization-grant]]
- [[keycloak-security]]
