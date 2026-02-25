---
title: Keycloak Session Management
type: reference
domain: Keycloak
tags:
  - keycloak
  - sessions
  - sso
  - token-lifetime
  - session-limits
  - authentication
  - cookies
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Session Management

## Overview

Keycloak manages multiple types of sessions for authentication and authorization. Understanding session configuration is critical for security, user experience, and resource management.

## Session Types

### Authentication Session

**Purpose:** Track authentication flow in progress

**Duration:** Short-lived (typically 5-10 minutes)
**Created:** When user starts login flow
**Destroyed:** After authentication completes

**Storage:** Infinispan cache (authenticationSessions)
**Cookie:** `AUTH_SESSION_ID`

**Use cases:**
- Multi-step authentication
- Required actions
- Social login flow
- Identity brokering

### User Session

**Purpose:** Track authenticated user across the realm

**Duration:** Configurable (default: 10 hours max)
**Created:** When user successfully authenticates
**Destroyed:** Logout, expiration, or session limit reached

**Storage:** Database (persistent if enabled) + Infinispan cache
**Cookie:** `KEYCLOAK_SESSION`

**Contains:**
- User identity
- Authentication time
- Client sessions
- Remember me status

**Session data:**
```
User ID: 12345678-1234-1234-1234-123456789abc
Started: 2025-01-29 10:00:00
Last Refresh: 2025-01-29 14:30:00
IP Address: 192.168.1.100
```

### Client Session

**Purpose:** Track user session per application/client

**Duration:** Can be shorter than user session
**Created:** When user accesses a client
**Destroyed:**
- User logs out of client
- Client session expires
- User session destroyed

**Storage:** Infinispan cache
**Cookie:** Client-specific

**Contains:**
- Client ID
- Authenticated time
- Granted scopes
- Redirect URI

## Session Configuration

### SSO Session Settings

**Admin Console:** Realm Settings → Sessions

**SSO Session Idle:**
```
Default: 30 minutes
Range: 1 minute to unlimited
```

**Description:** Maximum time without activity before session expires

**Best practices:**
- Internal apps: 15-30 minutes
- Public apps: 10-15 minutes
- High-security: 5-10 minutes
- Remember me: 7-30 days

**SSO Session Max:**
```
Default: 10 hours
Range: 1 minute to unlimited
```

**Description:** Maximum lifetime regardless of activity

**Best practices:**
- Internal apps: 8-12 hours
- Public apps: 1-4 hours
- High-security: 1-2 hours

**SSO Session Max Remember Me:**
```
Default: Unlimited
Range: 1 minute to unlimited
```

**Description:** Maximum lifetime for "remember me" sessions

**Best practices:**
- Personal devices: 30 days
- Shared devices: 1-7 days
- High-security: Disabled

### Client Session Settings

**Per-client configuration:**

**Client Session Idle:**
```
Default: Inherit from realm
Location: Client → Settings → Advanced
```

**Description:** Client-specific idle timeout

**Client Session Max:**
```
Default: Inherit from realm
Location: Client → Settings → Advanced
```

**Description:** Client-specific maximum lifetime

### Offline Session Settings

**Realm Settings:** Sessions → Offline Session

**Offline Session Max:**
```
Default: Unlimited
Range: 1 minute to unlimited
```

**Description:** Maximum lifetime for offline tokens (refresh tokens)

**Best practices:**
- Mobile apps: 30-90 days
- Desktop apps: 14-30 days
- High-security: 7 days or disabled

**Offline Session Idle:**
```
Default: Inherit from online settings
```

## User Session Limits

### What are Session Limits?

Restrict the number of concurrent sessions per user.

**Use cases:**
- Licensing restrictions
- Security policies
- Resource management
- Compliance requirements
- Preventing account sharing

### Configuring Session Limits

**Admin Console:** Realm Settings → Sessions

**Max sessions limit per user:**
```
Default: Unlimited
Options: 1, 2, 5, 10, 25, 50, Unlimited
```

**Strategy when max reached:**

**Current session:**
- Keep current session active
- Drop oldest session
- User remains logged in

**Oldest session:**
- Terminate oldest session
- Current login continues
- Previous device logged out

**Example configuration:**
```
Max sessions: 2
Strategy: Oldest session

Result: User can be logged in on 2 devices maximum.
When logging in on 3rd device, oldest session is terminated.
```

### Session Limit Authenticator

**Flow-based session limits:**

1. **Authentication → Flows**
2. **Select flow** (e.g., "Browser" flow)
3. **Add step** → "User Session Limits"
4. **Configure:**
   - **Limit** - Maximum sessions
   - **Strategy** - Current or oldest
   - **Scope** - Realm or client-specific

**Per-client session limits:**

1. **Client → Authentication**
2. **Override flow** → Add "User Session Limits"
3. **Configure** client-specific limits

### Session Events

**USER_SESSION_DELETED:**
- Fired when user session expires
- Published 3-10 minutes after expiration
- Not persisted by default
- Can be enabled for auditing

**Configure:** Realm Settings → Events → Save events

## Session Affinity (Sticky Sessions)

### Why Session Affinity Matters

Keycloak 26.x introduced **session cache affinity** for improved performance.

**Benefits:**
- Reduced response times
- Fewer remote calls
- Better scalability
- Lower database load

**How it works:**
- Authentication/user sessions created on node handling request
- Session stored in local cache
- No remote calls to other nodes for session reads/writes

### Configuring Load Balancer

**Enable sticky sessions:**

**nginx:**
```nginx
upstream keycloak {
    ip_hash;
    server keycloak1:8080;
    server keycloak2:8080;
    server keycloak3:8080;
}
```

**HAProxy:**
```
backend keycloak
    balance leastconn
    stick-table type ip size 200k expire 30m
    stick on src
    server keycloak1 10.0.0.1:8080 check
    server keycloak2 10.0.0.2:8080 check
```

**AWS ALB:**
```
Stickiness:
  Type: Application Cookies
  Cookie Name: AWSALB
  Duration: 3600 seconds
```

## Persistent Sessions

### Enabling Persistent Sessions

**Purpose:** Survive server restarts

**Configuration:**
```bash
bin/kc.sh start \
  --spi-connections-infinispan-quarkus-site-name=default \
  --spi-connections-infinispan-public-hostname=keycloak.example.com \
  --cache-embedded-user-sessions-enabled=true \
  --cache-embedded-user-sheets-users-owner-enabled=true
```

**Benefits:**
- Session survives server restart
- Better scalability
- Cross-datacenter replication

**Trade-offs:**
- Additional database load
- Slower session creation
- More complex setup

### Session Caching

**Infinispan caches:**
- `authenticationSessions` - Auth sessions
- `userSessions` - User sessions
- `clientSessions` - Client sessions
- `offlineSessions` - Offline sessions
- `loginFailures` - Brute force tracking

**Cache configuration:**
```bash
--cache-embedded-user-sessions-max-count=10000
--cache-embedded-user-sessions-lifespan=3600000
--cache-embedded-user-sessions-idle-timeout=300000
```

## Token vs Session

### Relationship

**Sessions are foundation for tokens:**
- Session created on authentication
- Tokens issued based on session
- Token expiration independent of session
- Revoking session revokes tokens

### Token Lifespan Configuration

**Realm Settings:** Tokens

**Access Token Lifespan:**
```
Default: 1 minute
Range: 10 seconds to unlimited
```

**Best practices:**
- High-security: 30 seconds - 2 minutes
- Standard: 1-5 minutes
- Long-lived: 5-15 minutes

**Refresh Token Max Age:**
```
Default: Unlimited
Range: 1 minute to unlimited
```

**Best practices:**
- Web apps: 30 days
- Mobile apps: 90 days
- High-security: 1-7 days

**Refresh Token Max Reuse:**
```
Default: 0 (no reuse)
Range: 0-1000
```

**Description:** Number of times refresh token can be reused

## Session Cookies

### Cookie Configuration

**Admin Console:** Realm Settings → Login

**Cookie settings:**
```
SameSite: Lax (default)
Secure: Only sent over HTTPS
HttpOnly: Not accessible via JavaScript
Path: /realm/{realm}
```

**SameSite options:**
- **Strict** - Never sent with cross-site requests
- **Lax** - Sent with safe cross-site requests (default)
- **None** - Always sent (requires Secure)

### Front Channel Logout

**Relying Party ID Cookie:**
```
Name: KC_RESTART
Purpose: Track logout requests
```

## Session Monitoring

### Viewing Active Sessions

**Admin Console:**
1. Users → Select user
2. **Sessions** tab
3. View:
   - Started time
   - Last access
   - Client applications
   - IP addresses

**CLI:**
```bash
kcadm.sh get users/{id}/sessions -r myrealm
```

### Session Statistics

**Admin Console:**
1. Realm Settings → Sessions
2. View:
   - Total active sessions
   - Sessions by client
   - Session creation rate

### Session Events

**Enable session events:**
```
Realm Settings → Events → Save events
```

**Monitor:**
- Session creation
- Session expiration
- Logout events
- Session limit enforcement

## Session Best Practices

### Security

**✅ DO:**
- Use short-lived access tokens (1-5 minutes)
- Enable session limits for sensitive apps
- Monitor session events
- Use secure cookies (HttpOnly, Secure)
- Enable persistent sessions for production
- Configure appropriate idle timeouts

**❌ DON'T:**
- Use unlimited session max in production
- Allow unlimited refresh token age
- Disable SameSite cookies
- Ignore session events
- Use long-lived access tokens

### Performance

**✅ DO:**
- Enable sticky sessions
- Use persistent sessions
- Configure cache appropriately
- Monitor cache hit rates
- Tune session limits

**❌ DON'T:**
- Disable caching
- Use small cache sizes
- Ignore memory usage
- Overload database

### User Experience

**✅ DO:**
- Set reasonable idle timeouts (15-30 min)
- Support "remember me" for trusted devices
- Warn before session expiration
- Provide clear logout options
- Support session revival when appropriate

**❌ DON'T:**
- Use very short idle timeouts (< 5 min)
- Force frequent re-authentication
- Lose user work on timeout
- Make logout difficult

## Session Troubleshooting

### Common Issues

**Users logged out unexpectedly:**
- Check session idle timeout
- Check max session lifetime
- Check session limit enforcement
- Verify sticky session configuration
- Check for network issues

**Performance problems:**
- Verify sticky sessions enabled
- Check cache configuration
- Monitor database connections
- Review session limit settings
- Check Infinispan clustering

**Session limit not working:**
- Verify authenticator added to flow
- Check limit and strategy settings
- Verify session events enabled
- Review authentication logs

### Debug Logging

**Enable session logging:**
```bash
bin/kc.sh start-dev \
  --log-level=org.keycloak.sessions:DEBUG \
  --log-level=org.keycloak.models.cache:DEBUG
```

## Session Clustering

### Cross-Datacenter Replication

**Configure sites:**
```bash
--spi-connections-infinispan-quarkus-sites=site1,site2
--spi-connections-infinispan-quarkus-site-name=site1
--spi-connections-infinispan-public-hostname=keycloak1.example.com
```

### State Transfer

**Disable for persistent sessions:**
```bash
--spi-connections-infinispan-quarkus-state-transfer-enabled=false
```

**Benefit:** Faster startup with persistent sessions

## References

- <https://www.keycloak.org/docs/latest/server_admin/#user-session-limits>
- <https://www.keycloak.org/docs/latest/server_admin/#sessions>
- Session configuration best practices

## Related

- [[keycloak-server-administration]]
- [[keycloak-security]]
- [[keycloak-authentication-flows]]
- [[keycloak-user-session-count-limiter]]
