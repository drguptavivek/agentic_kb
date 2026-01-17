---
title: Docker Architecture - Container Connections and Proxying
type: reference
domain: ODK Central
tags:
  - docker
  - nginx
  - architecture
  - containers
  - proxying
  - modsecurity
status: approved
created: 2026-01-14
updated: 2026-01-14
---

# Docker Architecture - Container Connections and Proxying

**Version:** ODK Central v2025.4.1
**Purpose:** Comprehensive reference for container connections, nginx proxying, initialization, and inter-service communication

---

## Quick Reference: Container Overview

| Container | Port | Purpose | Built/Generated |
|-----------|------|---------|-----------------|
| `nginx` | 80, 443 | Single entry point, SSL termination, routing | Built: Frontend assets, Config templates |
| `service` | 8383 | Node.js/Express backend API | Built: Dependencies, source code |
| `enketo` | 8005 | Form filling engine | Built: Config templates |
| `postgres14` | 5432 | PostgreSQL database | Generated: Database data |
| `pyxform` | 80 | XLSForm → XForm conversion | External: Upstream image |
| `mail` | 25 | SMTP email delivery | External: Upstream image |
| `secrets` | - | Generate shared secrets | Generated: Secret files |
| `enketo_redis_main` | 6379 | Enketo session storage | Generated: Redis data |
| `enketo_redis_cache` | 6380 | Enketo caching | Generated: Redis data |

---

## Nginx Container Deep Dive

### Build Process

```dockerfile
# Stage 1: Build Frontend
FROM node:22.21.1-slim AS intermediate
  └── Write version.txt (git describe)
  └── Build frontend: npm ci && npm run build
      └── Output: client/dist/ → /usr/share/nginx/html

# Stage 2: Final Nginx Image
FROM ${NGINX_BASE_IMAGE}
  └── Install: netcat-openbsd (healthcheck)
  └── Create directories for configs and logs
  └── Copy templates and built frontend
  └── ENTRYPOINT: /scripts/setup-odk.sh
```

### Runtime Generation (ENTRYPOINT)

The `setup-odk.sh` script generates:

1. **`client-config.json`** - Frontend configuration
2. **SSL certificates** - Self-signed or letsencrypt
3. **DH parameters** - `/etc/dh/nginx.pem`
4. **`odk.conf`** - Main nginx config from template
5. **`redirector.conf`** - HTTP→HTTPS redirect

### Request Routing

```
Incoming Request (HTTPS:443)
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ Nginx Server Block (DOMAIN)                                │
├─────────────────────────────────────────────────────────────┤
│ 1. SSL Termination                                         │
│ 2. Modsecurity inspection (WAF)                            │
│ 3. Route by location:                                      │
│                                                              │
│ /-/single/*      → 301 → /f/* (Web Forms redirect)         │
│ /-/preview/*    → 301 → /f/*/preview                       │
│ /-/*            → Proxy → enketo:8005 (Form engine)        │
│ /v1/*           → Proxy → service:8383 (API)               │
│ /oidc/callback  → Proxy → service:8383 (SSO)              │
│ /csp-report     → Proxy → Sentry (security reports)        │
│ /               → Serve SPA (built-in assets)              │
└─────────────────────────────────────────────────────────────┘
```

### Location Blocks Explained

**Frontend SPA:**
```nginx
location / {
  root /usr/share/nginx/html;
  try_files $uri $uri/ /index.html;
}
```

**API Proxy:**
```nginx
location ~ ^/v\d {
  include /usr/share/odk/nginx/backend.conf;
  # proxy_pass http://service:8383;
}
```

**Enketo Proxy:**
```nginx
location ~ ^/(?:-|enketo-passthrough)(?:/|$) {
  proxy_pass http://enketo:8005;
}
```

---

## Service Container Deep Dive

### Initialization Process

```bash
start-odk.sh:
1. Generate config/local.json (env substitution)
2. Set Sentry release/tags
3. Run database migrations
4. Log server upgrade
5. Start cron daemon
6. Determine worker count (1-4 based on memory)
7. Start PM2 runtime
```

### Cron Jobs

```
*/5 * * * *  process-backlog      # Background tasks
*/5 * * * *  upload-blobs         # OData/S3 uploads
*/5 * * * *  reap-sessions         # Session cleanup
0 3 * * *    purge                 # Data retention
0 4 * * *    run-analytics         # Analytics aggregation
```

### Worker Scaling

- Memory >1.1GB: 4 workers
- Memory ≤1.1GB: 1 worker
- PM2 cluster mode for load balancing

---

## Inter-Container Communication

### Network Topology

All containers on `default` Docker bridge network:
- DNS resolution: `<service-name>:<port>`
- Example: `http://service:8383`, `postgres14:5432`

### Communication Matrix

| From | To | Port | Purpose |
|------|-----|------|---------|
| Browser | Nginx | 443 | All external traffic |
| Nginx | Service | 8383 | API calls |
| Nginx | Enketo | 8005 | Form rendering |
| Service | Postgres14 | 5432 | Database queries |
| Service | Pyxform | 80 | XLSForm conversion |
| Service | Mail | 25 | Email sending |
| Service | Enketo | 8005 | Form management |
| Enketo | Redis Main | 6379 | Session storage |
| Enketo | Redis Cache | 6380 | Caching |

---

## Secrets Management

### Secret Generation

One-time generation by `secrets` container:

```bash
/etc/secrets/enketo-secret       # 64 chars (main encryption)
/etc/secrets/enketo-less-secret  # 32 chars (less secure)
/etc/secrets/enketo-api-key      # 128 chars (API authentication)
```

### Shared Volume

Named volume `secrets` mounted to:
- `service:/etc/secrets` - Read API key
- `enketo:/etc/secrets` - Read all secrets

### Lifecycle

1. `secrets` container starts
2. Generates secrets if not exist
3. Container exits (one-time job)
4. Secrets persist in named volume
5. Other containers read from volume

---

## Configuration Template Flow

All configs use `envsub.awk` for variable substitution:

```
${VARNAME}           → environment variable
${VARNAME:-default}  → environment variable with default
```

| Template | Generated | Location | Consumer |
|----------|-----------|----------|----------|
| `client-config.json.template` | ✅ | `/usr/share/nginx/html/` | Frontend |
| `odk.conf.template` | ✅ | `/etc/nginx/conf.d/` | Nginx |
| `config.json.template` | ✅ | `/usr/odk/config/` | Service |
| `config.json.template` | ✅ | Enketo config | Enketo |

---

## Startup Order

```
1. secrets     → Generate secrets (one-time)
2. postgres14  → Start database
3. postgres    → Run upgrade (one-time)
4. redis*      → Start Redis instances
5. pyxform     → Start conversion service
6. mail        → Start email service
7. enketo      → Start form engine
8. service     → wait-for-it postgres:5432 → start
9. nginx       → Start proxy
```

---

## Build-Time vs Runtime

### Build-Time (Baked Into Image)

**Nginx:**
- Frontend assets (`client/dist/`)
- Version.txt
- Configuration templates

**Service:**
- Node.js dependencies
- Application source code
- Git version tags

### Runtime (Generated at Startup)

**Nginx:**
- `client-config.json`
- SSL certificates
- DH parameters
- `odk.conf`

**Service:**
- `config/local.json`
- Database migrations
- Worker count determination

**All Containers:**
- Environment variable substitution

---

## Volumes and Persistence

### Named Volumes

| Volume | Data | Lifetime |
|--------|------|----------|
| `secrets` | Secret keys | Persistent |
| `postgres14` | Database | Persistent |
| `enketo_redis_main` | Enketo sessions | Persistent |
| `enketo_redis_cache` | Enketo cache | Persistent |

### Bind Mounts

| Path | Purpose |
|------|---------|
| `/data/transfer` | OData/S3 staging |
| `./files/local/customssl/` | Custom SSL certificates |
| `./logs/nginx/` | Nginx logs |
| `./logs/modsecurity/` | WAF audit logs |

---

## Modsecurity Integration (VG)

### Additional Components

1. **Custom Nginx Base Image:** `drguptavivek/central-nginx-vg-base:6.0.1`
   - Compiled with Modsecurity v3.x

2. **Volume Mounts:**
   - `./files/vg-nginx/*.conf` - Modsecurity configs
   - `./crs/` - OWASP CRS v4.21.0 rules
   - `./crs_custom/` - Custom CRS exclusions
   - `./logs/modsecurity/` - Audit logs

3. **Nginx Config Additions:**
   ```nginx
   modsecurity on;
   modsecurity_rules_file /etc/modsecurity/modsecurity-odk.conf;

   location ~ ^/v\d {
     modsecurity_rules 'SecRuleRemoveById 911100 949110 949111';
   }
   ```

---

## Development vs Production

### Production
```bash
docker compose up
```
- Frontend baked in
- SSL enabled
- No exposed internal ports
- Proper secrets

### Development
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml up -d
```
- Exposed ports (5432, 5001, 8005, 6379, 6380)
- Pre-generated dev secrets
- `SKIP_FRONTEND_BUILD=1`
- `ENV=DEV` for enketo

---

## Troubleshooting Commands

```bash
# Check all containers
docker compose ps

# Service logs
docker compose logs service -f --tail=50

# Test inter-container communication
docker compose exec service ping postgres14
docker compose exec service curl http://service:8383

# Check secrets
docker compose exec service cat /etc/secrets/enketo-api-key

# Database connection
docker compose exec service psql -U odk -d odk -c "SELECT 1"

# Redis
docker compose exec enketo_redis_main redis-cli ping
```

---

## Related

- [[enketo-redis-secrets-architecture]] - Enketo and Redis deep dive
- [[pyxform-xlsform-architecture]] - XLSForm conversion flow
- [[s3-blob-storage-architecture]] - Blob storage architecture
- [[server-architecture-patterns]] - Backend patterns
- [[vg-customization-patterns]] - VG-specific modifications

---

## Source

Based on ODK Central v2025.4.1 docker compose configuration.
Updated: 2026-01-14
