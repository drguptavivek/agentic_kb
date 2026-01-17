---
title: Enketo, Redis, and Secrets Architecture
type: reference
domain: ODK Central
tags:
  - enketo
  - redis
  - secrets
  - docker
  - security
status: approved
created: 2026-01-03
updated: 2026-01-03
---

# Enketo, Redis, and Secrets Architecture

## Overview

ODK Central uses Enketo for web form rendering. Understanding how secrets, Redis, and containers interact is critical for debugging form access issues and maintaining system security.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Volume: secrets                    │
│  ├─ enketo-secret          (64 chars, main signing key)     │
│  ├─ enketo-less-secret     (32 chars, secondary key)        │
│  └─ enketo-api-key         (128 chars, API authentication)  │
└─────────────────────────────────────────────────────────────┘
         ↑                          ↑
         │                          │
    ┌────┴─────┐              ┌─────┴────┐
    │  service │              │  enketo  │
    │ (backend)│              │ (frontend)│
    └──────────┘              └──────────┘
         │                          │
         └────────────┬─────────────┘
                      │
         ┌────────────▼────────────────┐
         │            Redis             │
         │  ┌───────────────────────┐  │
         │  │ enketo_redis_main     │  │
         │  │ (port 6379)           │  │
         │  │ - Stores form data    │  │
         │  │ - Session info        │  │
         │  └───────────────────────┘  │
         │                              │
         │  ┌───────────────────────┐  │
         │  │ enketo_redis_cache    │  │
         │  │ (port 6380)           │  │
         │  │ - XSLT transforms     │  │
         │  │ - Form caching        │  │
         │  └───────────────────────┘  │
         └──────────────────────────────┘
```

## Secret Generation

### Production Environment

The `secrets` container generates random keys at startup if they don't exist. Script location: `files/enketo/generate-secrets.sh`

```bash
#!/bin/bash -eu

# Main signing key (64 alphanumeric characters)
if [ ! -f /etc/secrets/enketo-secret ]; then
  head -c1024 /dev/urandom | LC_ALL=C tr -dc '[:alnum:]' | head -c64  > /etc/secrets/enketo-secret
fi

# Secondary key (32 alphanumeric characters)
if [ ! -f /etc/secrets/enketo-less-secret ]; then
  head -c512  /dev/urandom | LC_ALL=C tr -dc '[:alnum:]' | head -c32  > /etc/secrets/enketo-less-secret
fi

# API authentication key (128 alphanumeric characters)
if [ ! -f /etc/secrets/enketo-api-key ]; then
  head -c2048 /dev/urandom | LC_ALL=C tr -dc '[:alnum:]' | head -c128 > /etc/secrets/enketo-api-key
fi
```

### Development Environment

**WARNING**: Development setup uses hardcoded insecure secrets. From `docker-compose.vg-dev.yml:43`:

```bash
echo "s0m3v3rys3cr3tk3y" > enketo-secret
echo "this $3cr3t key is crackable" > enketo-less-secret
echo "cRliFU6qVD0NyXaVd52BkdFdS7kvGcvWgBnM0IFBkksmzawz7HGPwghcJN5AADQq6oBeGFfgqE0q92kxBTAX5ZaQw9HtFYTWtKFHmAMuBp419BtxPjA9sYaXENhOdqUV" > enketo-api-key
```

These secrets are reset on container rebuild.

## How Secrets Are Used

### Container Mount Configuration

Both `service` and `enketo` containers mount the same secrets volume:

```yaml
# From docker-compose.yml
volumes:
  - secrets:/etc/secrets
```

This ensures consistency - same physical files are shared across containers.

### Enketo Configuration

From `files/enketo/config.json.template`:

```json
{
    "encryption key": "${SECRET}",                      // /etc/secrets/enketo-secret
    "less secure encryption key": "${LESS_SECRET}",     // /etc/secrets/enketo-less-secret
    "linked form and data server": {
        "api key": "${API_KEY}"                         // /etc/secrets/enketo-api-key
    },
    "redis": {
        "main": {
            "host": "enketo_redis_main",
            "port": "6379"
        },
        "cache": {
            "host": "enketo_redis_cache",
            "port": "6380"
        }
    }
}
```

## Token Signing and Validation Flow

1. **Service container** reads `/etc/secrets/enketo-secret`
2. **Signs form tokens** with the secret (creates URLs for opening/editing forms)
3. **Enketo container** reads the same secret
4. **Validates tokens** when users open forms
5. **Redis stores** encrypted/signed data (but doesn't know about secrets)

### Important Distinction

Redis does NOT use secrets directly. Redis is dumb storage. Enketo:
- Encrypts/signs data using secrets
- Then stores the encrypted data in Redis
- When retrieving, validates using the same secrets

## What Each Redis Instance Stores

| Redis Instance | Purpose | Data Type | Secret Usage |
|----------------|---------|-----------|--------------|
| **enketo_redis_main** | Persistent storage | Submissions, sessions | Indirect - Enketo encrypts before storing |
| **enketo_redis_cache** | Temporary cache | XSLT transforms, rendered forms | Indirect - Cached data may contain signed tokens |

## Critical Warning: Changing Secrets

**If you change the enketo-secret:**

- All existing form/open/edit tokens become **invalid**
- Users will get "invalid token" errors
- Submissions remain intact in PostgreSQL, but can't be opened via web UI
- Any cached data in Redis with old signatures becomes unusable

**Do NOT change the secret unless:**
- You're okay with breaking all existing form URLs
- You're doing a fresh deployment
- You have a migration plan to re-sign existing tokens

## Form Versioning and Submissions

When a new form draft is published:

1. **Old submissions** remain accessible - they reference the form version (enketoId) that was current when submitted
2. **New submissions** use the newly published version
3. ODK Central tracks which form version was used for each submission
4. Multiple form versions can coexist without issues

**The key point**: Each submission records the specific form definition it was created with, so changing the current version doesn't break old submissions.

## Verification Commands

### Check Secret Consistency Across Containers

```bash
# Both should output identical values
docker exec central-service-1 cat /etc/secrets/enketo-secret
docker exec central-enketo-1 cat /etc/secrets/enketo-secret

# Verify with MD5 hash (should match)
docker exec central-service-1 cat /etc/secrets/enketo-secret | md5sum
docker exec central-enketo-1 cat /etc/secrets/enketo-secret | md5sum
```

### Check Enketo Configuration

```bash
# View Enketo's config (with secrets substituted)
docker exec central-enketo-1 cat /srv/src/enketo/packages/enketo-express/config/config.json | grep '"encryption key"'
```

### Check Redis Data

```bash
# List all keys in main Redis
docker exec central-enketo-redis-main-1 redis-cli KEYS '*'

# List all keys in cache Redis
docker exec central-enketo-redis-cache-1 redis-cli KEYS '*'

# Check Redis connection from Enketo
docker exec central-enketo-1 redis-cli -h enketo_redis_main -p 6379 PING
docker exec central-enketo-1 redis-cli -h enketo_redis_cache -p 6380 PING
```

### Check Secrets Volume Persistence

```bash
# List Docker volumes (look for 'secrets')
docker volume ls

# Inspect secrets volume
docker volume inspect central_secrets

# Check volume mount points in containers
docker inspect central-service-1 | grep -A5 '"secrets"'
docker inspect central-enketo-1 | grep -A5 '"secrets"'
```

## Environment Comparison

| Aspect | Production | Development |
|--------|------------|-------------|
| **Secret Source** | Randomly generated at startup | Hardcoded in docker-compose.vg-dev.yml |
| **Persistence** | Docker volume (persistent across restarts) | Reset on container rebuild |
| **Security** | Cryptographically random | Insecure (for testing only) |
| **Volume Name** | `secrets` | `dev_secrets` |

## Troubleshooting

### Invalid Token Errors

If users see "invalid token" when opening forms:

1. Check if secrets changed recently:
   ```bash
   docker logs central-secrets-1 | tail -20
   ```

2. Verify secret consistency:
   ```bash
   docker exec central-service-1 cat /etc/secrets/enketo-secret | md5sum
   docker exec central-enketo-1 cat /etc/secrets/enketo-secret | md5sum
   ```

3. Check if Redis was cleared (clearing cache doesn't affect main, but may cause temporary issues)

### Forms Not Loading

1. Verify Enketo can reach Redis:
   ```bash
   docker exec central-enketo-1 redis-cli -h enketo_redis_main -p 6379 PING
   docker exec central-enketo-1 redis-cli -h enketo_redis_cache -p 6380 PING
   ```

2. Check Enketo logs:
   ```bash
   docker logs central-enketo-1 --tail=50
   ```

3. Verify secrets volume is mounted:
   ```bash
   docker exec central-enketo-1 ls -la /etc/secrets/
   ```

### After Container Rebuild (Dev Only)

If you rebuilt containers in development and forms break:

1. Secrets may have been reset - clear Redis cache:
   ```bash
   docker exec central-enketo-redis-cache-1 redis-cli FLUSHALL
   ```

2. Restart Enketo to pick up new secrets:
   ```bash
   docker compose restart enketo
   ```

## Related

- [[server-architecture-patterns]] - Backend architecture overview
- [[vg-customization-patterns]] - VG-specific customizations
- [[troubleshooting-vg-issues]] - Common VG troubleshooting steps
