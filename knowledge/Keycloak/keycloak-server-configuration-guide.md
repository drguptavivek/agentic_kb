---
title: Keycloak Server Configuration Guide
domain: Keycloak
type: reference
status: draft
tags: [keycloak, configuration, server, production, quarkus]
created: 2026-01-29
related: [[keycloak-overview]], [[keycloak-concepts]], [[keycloak-advanced-configuration]], [[keycloak-security]]
---

# Keycloak Server Configuration Guide

## Overview

Keycloak 26.5.0 runs on Quarkus and uses a unified configuration format across different sources. This guide covers the fundamental aspects of configuring Keycloak for production.

## Configuration Architecture

Keycloak uses **unified-per-source** configuration format:

| Source | Format | Example |
|--------|--------|---------|
| Command-line | `--<key-with-dashes>=<value>` | `--db-url-host=mykeycloakdb` |
| Environment Variable | `KC_<KEY_WITH_UNDERSCORES>=<value>` | `KC_DB_URL_HOST=mykeycloakdb` |
| Configuration File | `<key-with-dashes>=<value>` | `db-url-host=mykeycloakdb` |
| KeyStore | `kc.<key-with-dashes>` | `kc.db-password` (stored in keystore) |

### Configuration File

Default location: `conf/keycloak.conf`

```bash
# Specify custom config file
bin/kc.sh start --config-file=/path/to/myconfig.conf
```

### Environment Variable Substitution

In `keycloak.conf`, reference environment variables:

```properties
# Basic substitution
db-url-host=${MY_DB_HOST}

# With fallback value
db-url-host=${MY_DB_HOST:mydb}
```

### Special Characters

Escape special characters in configuration values:

```bash
# For $$ in password values, use \$
--db-password='my\\$\\$password'  # bash single quotes
--db-password="my\\\\$\\\\$password"  # bash double quotes

# Windows paths - escape backslashes or use forward slashes
db-url=C:\\\\\\\path\\\\\\to\\\\\\file
db-url=C:/path/to/file  # preferred
```

## Directory Structure

```
keycloak-26.5.0/
├── bin/                 # Shell scripts (kc.sh, kcadm.sh, kcreg.sh)
├── conf/                # Configuration files
│   ├── keycloak.conf    # Main configuration
│   ├── truststores/     # Default truststore path
│   └── cache-ispn.xml   # Cache configuration
├── data/                # Runtime data
│   ├── logs/            # File logging output
│   └── transaction-logs/ # XA transaction logs
├── lib/                 # Internal libraries
├── providers/           # Custom provider JARs
└── themes/              # Custom themes
```

## Server Commands

### Development Mode

```bash
bin/kc.sh start-dev
```

**Characteristics:**
- Fast startup
- HTTP enabled
- Local caches only
- Insecure defaults
- **NOT for production**

### Production Mode

```bash
bin/kc.sh start
```

**Characteristics:**
- HTTPS required
- Distributed caching enabled
- Optimized for performance
- Secure defaults

### Build Command

```bash
bin/kc.sh build
```

Creates an optimized image with:
- Build-time options set
- Providers registered
- Runtime optimizations applied

### Optimized Start

```bash
bin/kc.sh start --optimized
```

Skips build checks, assumes previous `build` command was run.

## Startup Options

### Bootstrap Admin User

```bash
# Environment variables
export KC_BOOTSTRAP_ADMIN_USERNAME=admin
export KC_BOOTSTRAP_ADMIN_PASSWORD=change_me

# Command line
bin/kc.sh start --bootstrap-admin-username=admin --bootstrap-admin-password=change_me
```

### Import Realm on Startup

```bash
# Place realm files in data/import/
bin/kc.sh start --import-realm
```

## HTTP/HTTPS Configuration

### Enable HTTP

```bash
bin/kc.sh start --http-enabled=true
```

### HTTPS Configuration

```bash
bin/kc.sh start \
  --https-certificate-file=/path/to/cert.pem \
  --https-certificate-key-file=/path/to/key.pem \
  --https-port=8443
```

### Using a KeyStore

```bash
bin/kc.sh start \
  --https-key-store-file=/path/to/keystore.p12 \
  --https-key-store-password=change_me \
  --https-key-store-type=PKCS12
```

## Hostname Configuration (v2)

### Basic Hostname

```bash
bin/kc.sh start --hostname=auth.example.com
```

### Full URL with Context Path

```bash
bin/kc.sh start --hostname=https://auth.example.com/auth
```

### Separate Admin Hostname

```bash
bin/kc.sh start \
  --hostname=auth.example.com \
  --hostname-admin=admin.example.com
```

### HTTP Relative Path

```bash
bin/kc.sh start --http-relative-path=/auth
```

## Configuration Sources Priority

1. **Command-line options** (highest priority)
2. **Environment variables**
3. **Configuration file** (`keycloak.conf`)
4. **KeyStore configuration** (for sensitive values)

### Using Java KeyStore for Secrets

```bash
# Generate keystore with secret
keytool -importpass -alias kc.db-password \
  -keystore keystore.p12 -storepass keystorepass \
  -storetype PKCS12

# Start server using keystore
bin/kc.sh start \
  --config-keystore=/path/to/keystore.p12 \
  --config-keystore-password=keystorepass
```

## JVM Configuration

### Memory Settings

```bash
# Heap size via environment
export JAVA_OPTS_KC_HEAP="-XX:MaxHeapFreeRatio=30 -XX:MaxRAMPercentage=65"

# Additional JVM options
export JAVA_OPTS_APPEND="-Djava.net.preferIPv4Stack=true"
```

### IPv4/IPv6 Configuration

```bash
# IPv4 only
export JAVA_OPTS_APPEND="-Djava.net.preferIPv4Stack=true"

# IPv6 only
export JAVA_OPTS_APPEND="-Djava.net.preferIPv4Stack=false -Djava.net.preferIPv6Addresses=true"
```

## Configuration Providers

### Provider Configuration Format

```
spi-<spi-id>--<provider-id>--<property>=<value>
```

Example:
```bash
bin/kc.sh start \
  --spi-connections-http-client--default--connection-pool-size=20 \
  --spi-sticky-session-encoder--infinispan--should-attach-route=false
```

### Setting Default Provider

```bash
# Build-time
bin/kc.sh build --spi-password-hashing--provider-default=argon2

# Runtime (single provider)
bin/kc.sh build --spi-email-template--provider=mycustomprovider
```

### Enable/Disable Provider

```bash
bin/kc.sh build --spi-email-template--mycustomprovider--enabled=true
```

## Database Configuration

### Basic Configuration

```properties
# keycloak.conf
db=postgres
db-username=keycloak
db-password=change_me
db-url-host=keycloak-postgres
db-url-database=keycloak
```

### Full JDBC URL

```bash
bin/kc.sh start \
  --db=postgres \
  --db-url=jdbc:postgresql://mypostgres/mydatabase
```

### Connection Pool Settings

```bash
--spi-connections-jpa--quarkus--max-pool-size=20
--spi-connections-jpa--quarkus--min-pool-size=5
```

## Logging Configuration

### Log Level

```bash
bin/kc.sh start --log-level=info,org.hibernate:debug
```

### File Logging

```bash
bin/kc.sh start \
  --log-console-output=json \
  --log-file=output.log \
  --log-level=info
```

## Health and Metrics

### Enable Health Checks

```bash
bin/kc.sh start --health-enabled=true
```

Endpoints:
- `http://<host>:9000/health` - Overall health
- `http://<host>:9000/health/live` - Liveness probe
- `http://<host>:9000/health/ready` - Readiness probe

### Enable Metrics

```bash
bin/kc.sh start --metrics-enabled=true
```

Endpoint: `http://<host>:9000/metrics`

## Quarkus Properties

For advanced configuration not covered by Keycloak options:

```properties
# conf/quarkus.properties
quarkus.http.limits.max-body-size=50M
quarkus.application.name=keycloak
```

**Note:** Use sparingly, as Quarkus properties are not officially supported by Keycloak.

## Production Checklist

- [ ] Use production mode (`start` command)
- [ ] Enable HTTPS with proper certificates
- [ ] Configure production-grade database
- [ ] Set up clustered configuration with caching
- [ ] Configure reverse proxy/load balancer
- [ ] Enable health checks and metrics
- [ ] Set appropriate memory limits
- [ ] Configure logging for operations
- [ ] Set hostname and context-path correctly
- [ ] Separate admin interface hostname
- [ ] Use optimized build for containers
- [ ] Enable appropriate features
- [ ] Configure backup strategy

## Related Topics

- [[keycloak-advanced-configuration]] - Advanced production settings
- [[keycloak-security]] - Security best practices
- [[keycloak-database-configuration]] - Database setup
- [[keycloak-caching-clustering]] - Distributed caches
- [[keycloak-containers]] - Container deployment

## Additional Resources

- [Configuring Keycloak](https://www.keycloak.org/docs/latest/server/configuration)
- [Configuring for Production](https://www.keycloak.org/docs/latest/server/configuration-production)
- [Configuration Provider Guide](https://www.keycloak.org/docs/latest/server/configuration-provider)
