---
title: Keycloak Advanced Configuration
type: reference
domain: Keycloak
tags:
  - keycloak
  - configuration
  - advanced
  - production
  - tuning
  - performance
  - settings
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Advanced Configuration

## Overview

This guide covers advanced Keycloak configuration options for production deployment, performance tuning, security hardening, and complex scenarios.

## Server Configuration

### Hostname and Port

**Static configuration:**
```bash
# Set hostname and port
bin/kc.sh start \
  --hostname=keycloak.example.com \
  --hostname-strict=false \
  --hostname-strict-https=true \
  --http-enabled=true \
  --http-port=8080 \
  --https-port=8443
```

**Options:**
- `--hostname` - Server hostname
- `--hostname-strict` - Enforce hostname matching (default: true)
- `--hostname-strict-https` - Enforce HTTPS in strict mode (default: false)
- `--http-enabled` - Enable HTTP port (default: false in production)
- `--http-port` - HTTP port (default: 8080)
- `https-port` - HTTPS port (default: 8443)

**Best practices:**
- Always set hostname in production
- Use strict hostname enforcement
- Disable HTTP in production (use HTTPS only)
- Use standard ports (80/443) with reverse proxy

### Proxy Configuration

**Behind reverse proxy:**

```bash
# Behind proxy
bin/kc.sh start \
  --hostname=keycloak.example.com \
  --proxy=edge \
  --http-enabled=true \
  --http-port=8080
```

**Proxy headers:**
```
--proxy-protocol=edge
--proxy-address-forwarding=true
```

**Available proxy modes:**
- `edge` - X-Forwarded-For header (standard)
- `reencrypt` - TLS termination and re-encryption
- `passthrough` - Pass through TLS

**Nginx configuration:**
```nginx
location / {
    proxy_pass http://keycloak:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### SPI Configuration

**Service Provider Interface options:**

**Format:**
```bash
spi-<spi-id>--<provider-id>--<property>=<value>
```

**Examples:**
```bash
# HttpClient SPI
spi-connections-http-client--default--connection-pool-size=20
spi-connections-http-client--default--connection-pool-max-size=50
spi-connections-http-client--default--connection-pool-max-queued=100
spi-connections-http-client--default--connection-timeout-millis=5000
spi-connections-http-client--default--socket-timeout-millis=30000

# Infinispan SPI
spi-connections-infinispan-quarkus-site-name=default
spi-connections-infinispan-quarkus-public-hostname=keycloak.example.com
spi-connections-infinispan-quarkus-stack=prod
```

**See:** [[keycloak-spi]]

## Client Advanced Settings

### Client Session Settings

**Per-client configuration:**

**Admin Console:** Clients → Select client → **Advanced** tab

**Settings:**
- **Client Session Idle** - Idle timeout for client sessions
  - Default: Inherit from realm SSO Session Idle
  - Example: `300` (5 minutes)

- **Client Session Max** - Maximum lifetime for client sessions
  - Default: Inherit from realm SSO Session Max
  - Example: `3600` (1 hour)

- **Offline Session Max** - Maximum offline session lifetime
  - Default: Inherit from realm setting
  - Example: `2592000` (30 days)

**Use cases:**
- **Admin console** - Shorter sessions for security
- **Mobile apps** - Longer sessions with refresh tokens
- **API clients** - Token-based, session not used

### Fine-Grained OpenID Connect Configuration

**Per-client OIDC settings:**

**Admin Console:** Clients → Select client → **Advanced** tab → **Fine-Grained OpenID Connect Configuration**

**Settings:**

**Logout settings:**
- **Backchannel Logout** - Enable backchannel logout
- **Frontchannel Logout** - Enable frontchannel logout
- **Backchannel Logout URL** - Custom logout URL
- **Backchannel Logout Session Required** - Require session for logout
- **Frontchannel Logout URL** - Custom frontchannel logout URL

**Token settings:**
- **Access Token Lifespan** - Override realm default
  - Example: `300` (5 minutes)
  - Format: Integer (seconds)

- **Client Session Idle** - Override realm default
  - Example: `1800` (30 minutes)

- **Client Session Max** - Override realm default
  - Example: `3600` (1 hour)

**ID token settings:**
- **ID Token Lifespan** - Override realm default

**Code challenge settings:**
- **Proof Key for Code Exchange (PKCE)** - Force PKCE usage
- **Code Challenge Method** - PKCE method (S256 or plain)

**Assertion settings:**
- **Include Claim in Token Response** - Include full JWT in introspection response

### Client Policies

**Enforce client behavior:**

**Admin Console:** Clients → Select client → **Advanced** tab → **Client Policies**

**Available policies:**
- **Disable Consented Required Actions** - Skip required actions for this client
- **Exclude Session State From Authentication Response** - Remove session state from auth response
- **Use Refresh Tokens** - Allow refresh token usage
- **Use Resource Owner Password Credentials** - Allow direct grant

## Session Configuration

### SSO Session Settings

**Admin Console:** Realm Settings → Sessions

**Settings:**

**SSO Session Idle:**
- Default: 30 minutes
- Description: Maximum time without activity before session expires
- Production recommendation: 15-30 minutes
- High-security: 5-10 minutes

**SSO Session Max:**
- Default: 10 hours
- Description: Maximum session lifetime regardless of activity
- Production recommendation: 8-12 hours
- High-security: 1-2 hours

**SSO Session Max Remember Me:**
- Default: Unlimited
- Description: Maximum lifetime for "remember me" sessions
- Production recommendation: 30 days
- High-security: 7 days or disabled

### Client Session Settings

**Per-client overrides:**

**Admin Console:** Clients → Select client → **Settings** → **Advanced** → **Access Token Lifespan**

**Access Token Lifespan:**
- Default: 1 minute
- Production recommendation: 1-5 minutes
- High-security: 30 seconds

**Client Session Idle:**
- Default: Inherit from realm
- Description: Client-specific idle timeout

**Client Session Max:**
- Default: Inherit from realm
- Description: Client-specific maximum lifetime

### Cookie Settings

**Cookie configuration:**

**Admin Console:** Realm Settings → **Login** → **Cookies**

**Settings:**

**SameSite:**
- Options: `Strict`, `Lax`, `None`
- Default: `Lax`
- Recommendation: `Lax` or `Strict`

**Secure:**
- Options: Always enabled
- Description: Only send over HTTPS

**HttpOnly:**
- Options: Always enabled
- Description: Not accessible via JavaScript

**Path:**
- Default: `/realm/{realm}`

## Token Configuration

### Access Token Configuration

**Realm Settings:** Tokens → **Access Token Lifespan**

**Settings:**
- **Lifespan** - Token validity duration
  - Default: 1 minute
  - Recommendation: 1-5 minutes
  - High-security: 30 seconds

### Refresh Token Configuration

**Realm Settings:** Tokens → **Refresh Token**

**Settings:**
- **Max Age** - Maximum refresh token age
  - Default: Unlimited
  - Recommendation: 30 days (web), 90 days (mobile)
  - High-security: 1-7 days

- **Max Reuse** - Number of times refresh token can be reused
  - Default: 0 (no reuse)
  - Recommendation: 0 (no reuse) or 1
  - Reason: Security vs. performance

- **Reuse Limit for Offline Token** - Offline token reuse limit

### ID Token Configuration

**Realm Settings:** Tokens → **ID Token Lifespan**

**Settings:**
- **Lifespan** - ID token validity
  - Default: Same as access token
  - Recommendation: Same as access token

## Caching Configuration

### Infinispan Cache Settings

**Built-in caches:**
- `authenticationSessions`
- `userSessions`
- `clientSessions`
- `offlineSessions`
- `loginFailures`
- `actionTokens`

**Configuration:**
```bash
# Cache configuration
--cache-embedded-user-sessions-enabled=true
--cache-embedded-user-sessions-max-count=10000
--cache-embedded-user-sessions-lifespan=3600000
--cache-embedded-user-sessions-idle-timeout=300000
```

**Performance tuning:**
```bash
# Larger caches for high-traffic deployments
--cache-embedded-user-sessions-max-count=50000
--cache-embedded-client-sessions-max-count=50000

# Shorter lifespan for more frequent refreshes
--cache-embedded-user-sessions-lifespan=1800000
```

### Persistent Sessions

**Enable persistent sessions:**
```bash
# Enable for session survival across restarts
--cache-embedded-user-sessions-enabled=true \
--spi-connections-infinispan-quarkus-site-name=default \
--spi-connections-infinispan-quarkus-public-hostname=keycloak.example.com \
--spi-connections-infinispan-quarkus-stack=prod
```

**Database persistence:**
```bash
# Enable persistent sessions
--spi-persistence-jpa-quarkus-database=postgres \
--spi-persistence-jpa-quarkus-persistence-unit=default \
--spi-persistence-jpa-quarkus-host=localhost \
--spi-persistence-jpa-quarkus-port=5432 \
--spi-persistence-jpa-quarkus-database=keycloak \
--spi-persistence-jpa-quarkus-username=keycloak \
--spi-persistence-jpa-quarkus-password=password
```

## Database Configuration

### PostgreSQL Configuration

```bash
# PostgreSQL connection
--db=postgres \
--db-url=jdbc:postgresql://localhost:5432/keycloak \
--db-pool-min-size=5 \
--db-pool-max-size=20 \
--db-pool-initial-size=10
```

### MySQL/MariaDB Configuration

```bash
# MySQL connection
--db=mysql \
--db-url=jdbc:mysql://localhost:3306/keycloak?useSSL=false&characterEncoding=UTF-8 \
--db-pool-min-size=5 \
--db-pool-max-size=20 \
--db-pool-initial-size=10
```

### Transaction Isolation

**Recommended settings:**

**PostgreSQL:**
```bash
# Recommended: Read Committed
--spi-persistence-jpa-quarkus-database=postgres \
--spi-persistence-jpa-quarkis-persistence-unit=default
```

**SQL Server:**
```bash
# Recommended: Read Committed
--spi-persistence-jpa-quarkks-database=mssql
```

## Performance Tuning

### HTTP Performance

**Enable optimized serializers (preview):**
```bash
--feature-http-optimized-serializers-enabled=true
```

**Benefits:**
- ~5% throughput improvement
- Stabilized response times
- Reduced system resource usage

### Connection Pooling

**Database connection pool:**
```bash
--db-pool-min-size=10
--db-pool-max-size=50
--db-pool-initial-size=20
```

**HTTP client pool:**
```bash
spi-connections-http-client--default--connection-pool-size=50
spi-connections-http-client--default--connection-pool-max-size=100
spi-connections-http-client--default--connection-pool-max-queued=200
```

### JVM Settings

**Memory settings:**
```bash
export JAVA_OPTS="-Xms2048m -Xmx2048m"
bin/kc.sh start
```

**Garbage collection:**
```bash
export JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200"
bin/kc.sh start
```

### Cluster Configuration

**Node affinity:**
```bash
# Enable sticky sessions
--spi-connections-infinispan-quarkus-client-intelligence=basic
```

**Cross-site replication:**
```bash
--spi-connections-infinispan-quarkus-sites=site1,site2
--spi-connections-infinispan-quarkus-site-name=site1
```

## Security Configuration

### TLS/HTTPS

**Enable TLS:**
```bash
--https-certificate-file=/path/to/cert.pem \
--https-certificate-key-file=/path/to/key.pem \
--https-protocols=TLSv1.3,TLSv1.2 \
--https-cipher-suites=TLS_AES_256_GCM_SHA384,TLS_AES_128_GCM_SHA256
```

### Headers

**Security headers:**
```bash
--http-frame-max-age=31536000
--http-frame-options=DENY
--http-content-type-options=nosniff
--http-strict-transport-security=max-age=31536000;includeSubDomains
```

### Brute Force Protection

**Realm Settings:** Security Defenses

**Settings:**
- **Permanent Lockout** - Lock until admin resets
- **Max Login Failures** - Before lockout (default: 30)
- **Wait Increment** - Seconds to wait after failures (default: 1 min)
- **Quick Login Check Milliseconds** - (default: 1000ms)
- **Minimum Quick Login Wait** - (default: 1 minute)
- **Max Failure Wait** - (default: 15 minutes)
- **Failure Reset Time** - (default: 12 hours)

## Observability

### Metrics

**Enable metrics endpoint:**
```bash
# Metrics endpoint
http://localhost:8080/metrics

# Health checks
http://localhost:8080/health/live
http://localhost:8080/health/ready
```

**Prometheus metrics:**
```bash
# Scrape config for Prometheus
- job_name: 'keycloak'
  metrics_path: '/metrics'
  static_configs:
  - targets: ['keycloak:8080']
```

### Logging

**Configure log levels:**
```bash
# Log levels
--log-level=INFO,org.keycloak:DEBUG,org.keycloak.services:DEBUG

# Log to file
--log-file=/var/log/keycloak.log
--log-format=text

# JSON logging
--log-format=json
```

**MDC (Mapped Diagnostic Context):**
```bash
# Enable MDC (supported feature)
--feature-log-mdc:v1-enabled=true
```

**MDC includes:**
- Realm name
- Client ID
- User ID
- IP address
- Request ID

### OpenTelemetry

**Enable OpenTelemetry:**
```bash
--feature-opentelemetry-enabled=true \
--feature-opentelemetry-logs-enabled=true \
--feature-opentelemetry-metrics-enabled=true
```

## Feature Flags

### Enable/Disable Features

**Individual features:**
```bash
# Enable feature
--feature-webauthn-enabled=true

# Disable feature
--feature-scripts-enabled=false
```

**Preview features:**
```bash
# Enable preview features
--features=preview
```

### Available Features

**New in 26.5.0:**
- `workflows` - Workflow automation (preview)
- `jwt-authorization-grant` - RFC 7623 JWT grant (preview)
- `http-optimized-serializers` - HTTP performance (preview)
- `opentelemetry` - OpenTelemetry support (preview)

**Stable features:**
- `webauthn` - Passkey/WebAuthn
- `scripts` - Script authenticators
- `docker` - Docker health checks
- `token-exchange` - Standard token exchange

## Production Best Practices

### Configuration Checklist

**Server:**
- [ ] Hostname configured
- [ ] HTTP disabled (HTTPS only)
- [ ] Proxy headers configured
- [ ] Database connection pooled
- [ ] Caches tuned
- [ ] Sticky sessions enabled
- [ ] JVM memory configured

**Security:**
- [ ] TLS enabled with strong ciphers
- [ ] Security headers configured
- [ ] Brute force protection enabled
- [ ] Password policies set
- [ ] FGAP enabled
- [ ] MFA configured for admins

**Sessions:**
- [ ] Appropriate idle timeouts
- [ ] Session limits configured
- [ ] Remember me configured
- [ ] Token lifespans set appropriately

**Performance:**
- [ ] Connection pools sized
- [ ] Cache configured
- [ ] Database indexes created
- [ ] Metrics enabled
- [ ] Logging configured
- [ ] Health checks enabled

**Monitoring:**
- [ ] Metrics endpoint accessible
- [ ] Health checks configured
- [ ] Logging to file
- [ ] Event logging enabled
- [ ] Alerting configured

## Troubleshooting

### Common Issues

**High memory usage:**
- Increase JVM heap: `export JAVA_OPTS="-Xmx4g"`
- Check cache sizes
- Monitor for memory leaks

**Slow response times:**
- Enable sticky sessions
- Check database pool size
- Enable http-optimized-serializers
- Check network latency

**Database connection issues:**
- Verify connection string
- Check pool settings
- Test database connectivity
- Check firewall rules

**Session issues:**
- Verify session timeout settings
- Check sticky session configuration
- Review session limits
- Check browser cookies

## Configuration File

### Using configuration file

**Create `keycloak.conf`:**
```properties
# Database
db=postgres
db-url=jdbc:postgresql://localhost:5432/keycloak
db-pool-min-size=5
db-pool-max-size=20
db-pool-initial-size=10

# Hostname
hostname=keycloak.example.com
https-port=8443
http-enabled=false

# Proxy
proxy=edge
proxy-address-forwarding=true

# Features
feature-webauthn-enabled=true
feature-scripts-enabled=true
feature-opentelemetry-enabled=true

# Logging
log-level=INFO
log-format=json
log-file=/var/log/keycloak.log
```

**Use configuration:**
```bash
bin/kc.sh start --config keycloak.conf
```

## References

- <https://www.keycloak.org/docs/latest/server_admin/#con-advanced-settings>
- <https://www.keycloak.org/docs/latest/configuration>
- Production deployment guide

## Related

- [[keycloak-server-administration]]
- [[keycloak-security]]
- [[keycloak-sessions]]
- [[keycloak-performance]]
