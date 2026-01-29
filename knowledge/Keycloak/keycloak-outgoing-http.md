---
title: Keycloak Outgoing HTTP Client Configuration
domain: Keycloak
type: reference
status: draft
tags: [keycloak, http-client, proxy, tls, connections]
created: 2026-01-29
related: [[keycloak-tls-configuration]], [[keycloak-server-configuration-guide]], [[keycloak-security]]
---

# Keycloak Outgoing HTTP Client Configuration

## Overview

Keycloak makes outgoing HTTP requests to:
- Identity providers during federation
- External services and APIs
- Backends for token introspection
- Email servers for notifications

All outgoing connections use a configurable HTTP client with connection pooling, proxy support, and TLS configuration.

## HTTP Client Configuration

### Configuration Format

```
spi-connections-http-client--default--<option>=<value>
```

### Command-Line Examples

```bash
# Set connection pool size
bin/kc.sh start \
  --spi-connections-http-client--default--connection-pool-size=50

# Set socket timeout
bin/kc.sh start \
  --spi-connections-http-client--default--socket-timeout-millis=10000

# Multiple options
bin/kc.sh start \
  --spi-connections-http-client--default--connection-pool-size=50 \
  --spi-connections-http-client--default--socket-timeout-millis=10000 \
  --spi-connections-http-client--default--max-pooled-per-route=25
```

### Configuration File

```properties
# conf/keycloak.conf
spi-connections-http-client-default-connection-pool-size=50
spi-connections-http-client-default-socket-timeout-millis=10000
```

## Configuration Options

### Connection Pool Settings

| Option | Description | Default |
|--------|-------------|---------|
| `connection-pool-size` | Total pool size | 128 |
| `max-pooled-per-route` | Per-host pool size | 64 |
| `connection-pool-min-size` | Minimum pool size | (not set) |
| `connection-ttl-millis` | Max connection TTL | (not set) |
| `max-connection-idle-time-millis` | Idle timeout | 900000 |
| `establish-connection-timeout-millis` | Connection timeout | (not set) |

### Timeout Settings

| Option | Description | Default |
|--------|-------------|---------|
| `socket-timeout-millis` | Inactivity timeout | 5000ms |
| `establish-connection-timeout-millis` | Connection timeout | Not set |

### Cookie Management

| Option | Description | Default |
|--------|-------------|---------|
| `disable-cookies` | Disable cookie caching | true |

### mTLS Configuration

| Option | Description |
|--------|-------------|
| `client-keystore` | Path to client keystore |
| `client-keystore-password` | Keystore password |
| `client-key-password` | Private key password |

### Proxy Configuration

| Option | Description |
|--------|-------------|
| `proxy-mappings` | Proxy mapping rules |
| `disable-trust-manager` | Disable cert verification (NEVER in production) |

## Connection Pool Tuning

### Pool Size Calculation

```
Total Connections = Max Concurrent Requests × Average Request Duration (seconds)

Example:
100 concurrent requests × 0.5 seconds = 50 connections
```

### Recommended Settings

| Deployment | Pool Size | Per-Route |
|------------|-----------|-----------|
| Small | 20-50 | 10-25 |
| Medium | 50-100 | 25-50 |
| Large | 100-200 | 50-100 |

### Example Configuration

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--connection-pool-size=100 \
  --spi-connections-http-client--default--max-pooled-per-route=20 \
  --spi-connections-http-client--default--connection-pool-min-size=10
```

## Timeout Configuration

### Recommended Timeouts

| Scenario | Connection Timeout | Socket Timeout |
|----------|-------------------|----------------|
| Local services | 1000ms | 5000ms |
| Same region | 3000ms | 10000ms |
| Cross-region | 5000ms | 30000ms |
| Unreliable network | 10000ms | 60000ms |

### Example Configuration

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--establish-connection-timeout-millis=5000 \
  --spi-connections-http-client--default--socket-timeout-millis=30000
```

## Proxy Configuration

### Environment Variables

```bash
# Set proxy for all HTTPS requests
export HTTPS_PROXY=https://proxy.example.com:8080

# Exclude specific hosts
export NO_PROXY=localhost,127.0.0.1,.internal.com

# Lowercase takes precedence
export https_proxy=http://proxy.example.com:8080
export https_proxy=192.168.1.1:8080  # This is used
```

### Proxy Mappings

**Format:** `hostname-pattern;proxy-uri`

```bash
# Regex-based pattern matching
bin/kc.sh start \
  --spi-connections-http-client--default--proxy-mappings='.*\\.google\\.com;http://proxy:8080'
```

### Multiple Proxy Mappings

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--proxy-mappings='.*\\.google\\.com;http://proxy1:8080,.*\\.example\\.com;http://proxy2:8080,.*;http://fallback:8080'
```

### Proxy with Authentication

```
.*\\.example\\.com;http://user:password@proxy.example.com:8080
```

### NO_PROXY Example

```bash
# Bypass proxy for specific domains
export NO_PROXY=google.com,.facebook.com,localhost
```

Results in:
- `google.com` - no proxy
- `auth.google.com` - no proxy (subdomain)
- `api.facebook.com` - no proxy
- `groups.facebook.com` - uses proxy (not a subdomain)

## mTLS for Outgoing Requests

When Keycloak connects to services requiring client certificates:

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--client-keystore=/path/to/client.p12 \
  --spi-connections-http-client--default--client-keystore-password=keystorepass \
  --spi-connections-http-client--default--client-key-password=keypass
```

### Use Cases

- Brokered identity provider with mTLS
- External token validation with mutual TLS
- Secure backend API calls

## Troubleshooting

### Enable HTTP Client Debug Logging

```bash
bin/kc.sh start \
  --log-level=debug,org.keycloak.connections.http
```

### Enable Wire Logging

```bash
export JAVA_OPTS_APPEND="-Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.SimpleLog -Dorg.apache.commons.logging.simplelog.showdatetime=true -Dorg.apache.commons.logging.simplelog.log.org.apache.http=DEBUG"
```

### Common Issues

**Connection pool exhausted:**
```
Symptom: Requests hang or timeout
Solution: Increase connection-pool-size
```

**Slow connections:**
```
Symptom: High latency
Solution: Check timeouts, consider keep-alive
```

**Proxy connection refused:**
```
Symptom: Can't reach external services
Solution: Verify proxy settings and NO_PROXY
```

## Truststore for Outgoing Connections

Configure trusted certificates for outgoing HTTPS:

```bash
bin/kc.sh start \
  --truststore-paths=/etc/certs/internal.pem,/etc/certs/external
```

### Disable Certificate Verification (Development Only)

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--disable-trust-manager=true
```

**NEVER use in production**

## Best Practices

### Connection Pool

- [ ] Set appropriate pool size for expected load
- [ ] Configure per-route limits for fairness
- [ ] Monitor pool metrics
- [ ] Consider burst capacity

### Timeouts

- [ ] Set connection timeout based on network
- [ ] Set socket timeout based on expected response time
- [ ] Don't set timeouts too low (false failures)
- [ ] Don't set timeouts too high (hung connections)

### Proxy

- [ ] Use NO_PROXY for internal services
- [ ] Secure proxy authentication credentials
- [ ] Test proxy configuration
- [ ] Monitor proxy performance

### Security

- [ ] Always validate certificates in production
- [ ] Use secure proxy protocols
- [ ] Rotate client certificates
- [ ] Monitor for certificate expiration

## Monitoring

### Connection Pool Metrics

Enable metrics to monitor HTTP client:

```bash
bin/kc.sh start \
  --metrics-enabled=true \
  --cache-metrics-histograms-enabled=true
```

### Key Metrics

- `http_client_connections_pool_active` - Active connections
- `http_client_connections_pool_max` - Max pool size
- `http_client_connections_pending` - Pending requests
- `http_client_requests_total` - Total requests
- `http_client_request_duration_seconds` - Request duration

## Related Topics

- [[keycloak-tls-configuration]] - Certificate and truststore setup
- [[keycloak-server-configuration-guide]] - General configuration
- [[keycloak-security]] - Security considerations

## Additional Resources

- [Configuring Outgoing HTTP Requests](https://www.keycloak.org/docs/latest/server/outgoinghttp)
- [Configuring Trusted Certificates](https://www.keycloak.org/docs/latest/server/keycloak-truststore)
