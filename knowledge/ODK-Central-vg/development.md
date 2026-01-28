---
domain: ODK-Central-vg
type: howto
status: approved
tags: #odk #vg-fork #client #development #docker #vite
created: 2026-01-28
---

# ODK Central VG Client Development

> **Source**: `docs/vg/vg-client/vg_client_changes.md`

## Overview

VG adds Dockerized development environment and proxy configuration for local development with `central.local`.

## Dev Container

**File**: `Dockerfile.dev`

**Purpose**: Run Vite dev server with nginx proxy for local development

**Build**:
```bash
docker build -f Dockerfile.dev -t central-client-dev .
```

**Run**:
```bash
docker run -p 8989:8989 central-client-dev
```

## Nginx Proxy Configuration

**File**: `main.nginx.conf`

### Backend Proxy

**Before**:
```nginx
location ~ ^/v\d {
  proxy_pass http://localhost:8383;
}
```

**After**:
```nginx
location ~ ^/v\d {
  # Point to the Dockerized backend
  proxy_pass https://central.local;
  proxy_redirect off;

  # SSL configuration for local dev
  proxy_ssl_verify off;
  proxy_set_header Host central.local;
}
```

### Version Endpoint

**Before**:
```nginx
location /version.txt {
  return 404;
}
```

**After**:
```nginx
location /version.txt {
  default_type text/plain;
  return 200 "development\n";
}
```

## Vite Configuration

**File**: `vite.config.js`

**Changes**:
```javascript
export default {
  server: {
    host: true,                    // Allow remote access
    port: 8989,
    allowedHosts: ['central.local']  // Allow central.local domain
  }
};
```

**Purpose**: Enable access via `https://central.local` with proper SSL

## Dev Server Workflow

### 1. Start Backend

```bash
# From central meta-repo
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vg-dev.yml up -d
```

### 2. Start Client Dev Server

**Option A: Direct (with npm)**
```bash
cd client
npm run dev
```

**Option B: Docker (with nginx proxy)**
```bash
docker build -f Dockerfile.dev -t central-client-dev .
docker run -p 8989:8989 --add-host=central.local:host-gateway central-client-dev
```

### 3. Access

- **Client**: `https://central.local:8989`
- **Backend**: `https://central.local`

## E2E Test Configuration

**File**: `e2e-tests/run-tests.sh`

### Default Domain

**Before**: `central-dev.localhost`
**After**: `central.local`

```bash
ODK_DOMAIN="central.local"
ODK_PORT="8989"
ODK_PROTOCOL="http://"
```

### Dependency Installation

**Before**: Optional `--skip-install` flag
**After**: Always install dependencies

```bash
# Removed --skip-install option
log "Installing npm packages..."
npm ci

log "Installing playwright deps..."
npx mocha playwright install --with-deps
```

### Response Assertions

**Before**: `expect(response).toBeOK()`
**After**: `expect(response.ok()).toBeTruthy()`

**Files affected**:
- `e2e-tests/backend-client.js`
- `e2e-tests/global.setup.js`

### Teardown

**Before**: Early return on missing `PROJECT_ID`
**After**: Always attempt deletion

```javascript
// Before
if (!projectId) return;

// After (removed early return)
const result = await fetch(`${appUrl}/v1/projects/${projectId}`, ...
```

## Contributing Documentation

**File**: `CONTRIBUTING.md`

**Updated**: Default E2E base URL

```markdown
By default, tests run against `http://central.local:8989`, but you can override it
with `--protocol`, `--domain`, and `--port` CLI options.
```

## Project Telemetry

**Route**: `/projects/:projectId/telemetry`

**Component**: `VgProjectTelemetry`

**Features**:
- Filters: Project ID, Device ID, App User ID, Date Range
- Pagination with `X-Total-Count` header
- Displays device metadata, Collect version, location

**Permissions**: `config.read`

## Project Login History

**Route**: `/projects/:projectId/login-history`

**Component**: `VgProjectLoginHistory`

**Features**:
- Filters: App User ID, Date From/To
- Pagination
- Per-session revoke button
- Shows IP, user agent, device ID, comments

**Permissions**: `field_key.list`

## Dev Documentation

**Files added**:
- `docs/dev-server.md` - Dev server instructions
- `docs/walkthrough.md` - Component walkthrough
- `docs/vg-component-short-token-app-users.md` - Technical documentation
- `docs/TASK.md` - Task tracking

## Related Documentation

- [[ODK-Central-vg/client-overview]] - Client changes overview
- [[ODK-Central-vg/testing]] - Test commands
- [[ODK-Central-vg/installation]] - Full setup guide
