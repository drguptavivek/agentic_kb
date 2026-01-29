---
title: Keycloak Container Deployment Guide
domain: Keycloak
type: howto
status: draft
tags: [keycloak, containers, docker, kubernetes, deployment]
created: 2026-01-29
related: [[keycloak-server-configuration-guide]], [[keycloak-database-configuration]], [[keycloak-security]]
---

# Keycloak Container Deployment Guide

## Overview

Keycloak provides official container images for deployment. This guide covers building optimized images, configuration, and deployment patterns.

## Official Image

```bash
# Pull latest image
docker pull quay.io/keycloak/keycloak:latest

# Pull specific version
docker pull quay.io/keycloak/keycloak:26.5.0
```

## Quick Start (Development)

```bash
docker run -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=change_me \
  quay.io/keycloak/keycloak:latest \
  start-dev
```

**Not for production use**

## Production Deployment

### Building Optimized Image

**Why optimize:**
- Faster startup (~5-10x faster)
- Smaller runtime footprint
- Pre-built providers
- Production-ready configuration

### Containerfile Example

```dockerfile
FROM quay.io/keycloak/keycloak:latest AS builder

# Build-time options
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres

# Generate HTTPS certificate for demonstration
# Use proper certificates in production
RUN keytool -genkeypair \
  -storepass password \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 2048 \
  -dname "CN=server" \
  -alias server \
  -ext "SAN=c=DNS:localhost,IP:127.0.0.1" \
  -keystore conf/server.keystore

# Build optimized image
RUN /opt/keycloak/bin/kc.sh build

# Final stage
FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Runtime configuration
ENV KC_DB=postgres
ENV KC_DB_URL=<DBURL>
ENV KC_DB_USERNAME=<DBUSERNAME>
ENV KC_DB_PASSWORD=<DBPASSWORD>
ENV KC_HOSTNAME=localhost

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

### Build and Run

```bash
# Build image
podman build -t mykeycloak -f Containerfile .

# Run optimized image
podman run --name mykeycloak \
  -p 8443:8443 -p 9000:9000 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=change_me \
  mykeycloak \
  start --optimized --hostname=localhost
```

## Environment Variables

### Database Configuration

```yaml
environment:
  KC_DB: postgres
  KC_DB_URL_HOST: postgres
  KC_DB_DATABASE: keycloak
  KC_DB_USERNAME: keycloak
  KC_DB_PASSWORD: change_me
```

### Hostname Configuration

```yaml
environment:
  KC_HOSTNAME: auth.example.com
  KC_HTTP_ENABLED: "false"
```

### Admin Credentials

```yaml
environment:
  KC_BOOTSTRAP_ADMIN_USERNAME: admin
  KC_BOOTSTRAP_ADMIN_PASSWORD: change_me
```

### Features

```yaml
environment:
  KC_FEATURES: "token-exchange,preview"
```

### Build Options

```yaml
# Build stage
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
RUN /opt/keycloak/bin/kc.sh build
```

## Custom Providers

### Adding Provider JARs

```dockerfile
FROM quay.io/keycloak/keycloak:latest AS builder

# Add provider before build
ADD --chown=keycloak:keycloak --chmod=644 \
  https://repo1.maven.org/maven2/com/example/custom-provider/1.0.0/custom-provider-1.0.0.jar \
  /opt/keycloak/providers/

# Build with provider
RUN /opt/keycloak/bin/kc.sh build
```

### Oracle Database Driver

```dockerfile
FROM quay.io/keycloak/keycloak:latest

# Add Oracle drivers
ADD --chown=keycloak:keycloak --chmod=644 \
  https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc17/23.6.0.24.10/ojdbc17-23.6.0.24.10.jar \
  /opt/keycloak/providers/ojdbc17.jar

ADD --chown=keycloak:keycloak --chmod=644 \
  https://repo1.maven.org/maven2/com/oracle/database/nls/orai18n/23.6.0.24.10/orai18n-23.6.0.24.10.jar \
  /opt/keycloak/providers/orai18n.jar

ENV KC_DB=oracle
RUN /opt/keycloak/bin/kc.sh build
```

### Custom Themes

```dockerfile
FROM quay.io/keycloak/keycloak:latest

# Copy custom theme
COPY --chown=keycloak:keycloak my-theme/ /opt/keycloak/themes/my-theme/

# Build with theme
RUN /opt/keycloak/bin/kc.sh build
```

## Memory Configuration

### Container Memory Limits

**Default JVM settings:**
- `-XX:MaxRAMPercentage=70` (70% of container memory)
- `-XX:InitialRAMPercentage=50` (50% of container memory)

**Important:** Always set memory limit!

```yaml
# docker-compose.yml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    mem_limit: 2g
    environment:
      - KC_BOOTSTRAP_ADMIN_USERNAME=admin
      - KC_BOOTSTRAP_ADMIN_PASSWORD=change_me
```

### Custom Heap Settings

```yaml
environment:
  JAVA_OPTS_KC_HEAP: "-XX:MaxHeapFreeRatio=30 -XX:MaxRAMPercentage=65"
```

### Memory Recommendations

| Deployment | Memory Limit | Heap Size |
|------------|--------------|-----------|
| Development | 750MB minimum | ~500MB |
| Small (<1000 users) | 2GB | ~1.4GB |
| Medium (1000-10000 users) | 4GB | ~2.8GB |
| Large (>10000 users) | 8GB+ | ~5.6GB+ |

## Port Configuration

### Default Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Main HTTP (if enabled) |
| 8443 | HTTPS | Main HTTPS |
| 9000 | HTTP | Management (health, metrics) |

### Custom Ports

```bash
# Expose on different port
docker run -p 3000:8443 \
  -e KC_HOSTNAME=https://localhost:3000 \
  quay.io/keycloak/keycloak:latest \
  start --optimized
```

### Health and Metrics

```bash
# Health endpoints available at port 9000
https://localhost:9000/health        # Overall health
https://localhost:9000/health/live   # Liveness
https://localhost:9000/health/ready  # Readiness
https://localhost:9000/metrics       # Prometheus metrics
```

## Volume Mounts

### Configuration File

```yaml
volumes:
  - ./config/keycloak.conf:/opt/keycloak/conf/keycloak.conf:ro
```

### Realm Import

```yaml
volumes:
  - ./realms:/opt/keycloak/data/import
command:
  - start
  - --optimized
  - --import-realm
```

### Custom Truststore

```yaml
volumes:
  - ./truststores:/opt/keycloak/conf/truststores:ro
environment:
  - KC_TRUSTSTORE_PATHS=/opt/keycloak/conf/truststores
```

### Logs

```yaml
volumes:
  - ./logs:/opt/keycloak/data/logs
environment:
  - KC_LOG_FILE=/opt/keycloak/data/logs/keycloak.log
  - KC_LOG_LEVEL=info
```

## Docker Compose Example

```yaml
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.5.0
    container_name: keycloak
    environment:
      KC_DB: postgres
      KC_DB_URL_HOST: postgres
      KC_DB_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: change_me
      KC_HOSTNAME: auth.example.com
      KC_HEALTH_ENABLED: "true"
      KC_METRICS_ENABLED: "true"
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: change_me
    command: start --optimized
    depends_on:
      - postgres
    ports:
      - "8080:8080"
      - "8443:8443"
      - "9000:9000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/health/ready"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 60s

  postgres:
    image: postgres:17
    container_name: postgres
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: change_me
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## Known Docker Issues

### File Limit Issues

```dockerfile
# If dnf install hangs, increase file limit
RUN ulimit -n 1024000 && dnf install --installroot /mnt/rootfs ...
```

### Timestamp Issues with Providers

```dockerfile
# Fix Docker timestamp issues with providers
ADD --chown=keycloak:keycloak provider.jar /opt/keycloak/providers/
RUN touch -m --date=@1743465600 /opt/keycloak/providers/*
RUN /opt/keycloak/bin/kc.sh build
```

## Custom Entrypoint

### Correct Pattern

```bash
#!/bin/bash
# Custom logic here

# Must use exec for signal handling
exec /opt/keycloak/bin/kc.sh start "$@"
```

### Why exec is Required

Without `exec`:
- Shell script becomes PID 1
- Blocks SIGTERM signals
- Prevents graceful shutdown
- Can cause cache inconsistencies

## Security Hardening

### Minimal Base Image

The official image uses:
- Minimal packages
- No package managers
- Security-focused configuration

### Adding Packages (Not Recommended)

```dockerfile
# If absolutely necessary
FROM registry.access.redhat.com/ubi9 AS ubi-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs <packages> --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

FROM quay.io/keycloak/keycloak
COPY --from=ubi-build /mnt/rootfs /
```

**Warning:** Check installed packages carefully, increases attack surface.

## Health Checks

### Docker Health Check

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:9000/health/ready"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 60s
```

### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 9000
  initialDelaySeconds: 60
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /health/ready
    port: 9000
  initialDelaySeconds: 60
  periodSeconds: 30
```

## Best Practices

### Build

- [ ] Use multi-stage builds
- [ ] Run build command in builder stage
- [ ] Copy only necessary files
- [ ] Use `--chown` for file permissions
- [ ] Set appropriate file modes

### Configuration

- [ ] Use environment variables for secrets
- [ ] Mount configuration as read-only
- [ ] Set memory limits
- [ ] Configure health checks
- [ ] Use optimized startup

### Security

- [ ] Run as non-root user (default)
- [ ] Use read-only root filesystem
- [ ] Drop unnecessary capabilities
- [ ] Scan images for vulnerabilities
- [ ] Keep images updated

### Operations

- [ ] Monitor container health
- [ ] Collect metrics
- [ ] Configure logging
- [ ] Test restart behavior
- [ ] Plan for upgrades

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs keycloak

# Check health
docker exec keycloak curl http://localhost:9000/health
```

### Memory Issues

```bash
# Increase memory limit
docker run -m 4g ...

# Or adjust heap percentage
-e JAVA_OPTS_KC_HEAP="-XX:MaxRAMPercentage=60"
```

### Database Connection Issues

```bash
# Verify network
docker exec keycloak ping postgres

# Check environment variables
docker exec keycloak env | grep KC_DB
```

## Related Topics

- [[keycloak-server-configuration-guide]] - Server configuration
- [[keycloak-database-configuration]] - Database setup
- [[keycloak-security]] - Security considerations
- [[keycloak-caching-clustering]] - Cluster configuration

## Additional Resources

- [Running Keycloak in a Container](https://www.keycloak.org/docs/latest/server/containers)
- [Keycloak on Kubernetes](https://www.keycloak.org/operator/)
