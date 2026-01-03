---
title: Garage S3-Compatible Storage
type: reference
domain: DevOps
tags:
  - garage
  - s3
  - storage
  - docker
  - self-hosted
status: approved
created: 2026-01-03
updated: 2026-01-03
---

# Garage S3-Compatible Storage

Garage is an S3-compatible object storage server, ideal for self-hosted applications needing blob storage. Lighter than MinIO, designed for multi-node deployments but works well in single-node setups.

## Problem / Context

Self-hosted applications (like ODK Central) need S3-compatible blob storage for:
- File uploads and attachments
- Backup storage
- Static asset hosting

Options include MinIO (heavy, complex) or Garage (lightweight, S3-compatible).

## Recommended Approach

Use Garage v2+ with Docker Compose for a lightweight S3-compatible storage backend.

### Installation

#### Docker Compose Setup

```yaml
# docker-compose-garage.yml
services:
  garage:
    image: dxflrs/garage:v2.1.0
    container_name: odk-garage
    command:
    - ./garage
    - server
    ports:
    - 127.0.0.1:3900:3900  # S3 API
    - 127.0.0.1:3903:3903  # S3 Web (public access)
    volumes:
    - garage_data:/data
    - ./garage/garage.toml:/etc/garage.toml:ro
    environment:
      RUST_LOG: info
    networks:
    - default

volumes:
  garage_data: {}

networks: {}
```

#### Configuration

Create `garage/garage.toml`:

```toml
metadata_dir = "/data/meta"
data_dir = "/data/data"
db_engine = "lmdb"

replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_secret = "<generate-random-secret-here>"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.yourdomain.com"  # For subdomain-style access

[s3_web]
bind_addr = "[::]:3903"
root_domain = ".s3.yourdomain.com"
index = "index.html"
```

### Key Settings Explained

| Setting | Purpose |
|---------|---------|
| `rpc_secret` | Secret key for cluster RPC communication - generate with: `openssl rand -hex 32` |
| `replication_factor` | Number of copies of each data (1 for single-node, 3 for production) |
| `s3_api.api_bind_addr` | Port for S3 API operations (PUT, GET, DELETE, LIST) |
| `s3_web.bind_addr` | Port for public read-only web access |
| `root_domain` | Base domain for virtual host-style access (bucket.s3.yourdomain.com) |

### DNS and SSL Certificate Requirements

**IMPORTANT**: Garage uses **virtual-hosted-style S3 access** (like AWS S3):
```
https://<bucket-name>.s3.yourdomain.com/<object>
```

This means your DNS and SSL certificates must account for each bucket.

#### DNS Entries

| Type | Entry | Points To |
|------|-------|-----------|
| A | `s3.yourdomain.com` | Your server IP |
| A | `odk-central.s3.yourdomain.com` | Your server IP |
| CNAME | `*.s3.yourdomain.com` | `s3.yourdomain.com` (wildcard) |

#### SSL Certificate Options

**Option 1: Specific Certificates (Recommended - Easier)**
- Add SAN for each bucket: `odk-central.s3.yourdomain.com`
- Use Let's Encrypt with `EXTRA_SERVER_NAME`
- Add new bucket domains as you create buckets

**Option 2: Wildcard Certificate**
- Single cert: `*.s3.yourdomain.com`
- Covers all current and future buckets
- Requires DNS validation for Let's Encrypt

#### Local Development

For local testing, add to `/etc/hosts`:
```
127.0.0.1  odk-central.s3.central.local
127.0.0.1  central.local
```

## Initial Setup

### Steps

#### 1. Start Garage

```bash
docker compose -f docker-compose-garage.yml up -d
```

#### 2. Check Status and Get Node ID

```bash
docker exec odk-garage ./garage status
```

Output shows node ID, e.g.:
```
ID                Hostname      Address           Tags  Zone  Capacity
990cecb32339f9b2  7c622c8b3827  172.25.0.10:3901              NO ROLE ASSIGNED
```

#### 3. Set Up Cluster Layout

**Required step** - Garage won't allow bucket creation until layout is configured:

```bash
# Assign role to node (requires zone)
docker exec odk-garage ./garage layout assign 990cecb32339f9b2 --zone local --capacity 1T

# Review staged changes
docker exec odk-garage ./garage layout show

# Apply layout (version will be shown as 1)
docker exec odk-garage ./garage layout apply --version 1
```

#### 4. Create Bucket

```bash
docker exec odk-garage ./garage bucket create my-bucket
```

#### 5. Create API Key

```bash
docker exec odk-garage ./garage key create my-key-name
```

Output:
```
Key ID:              GK73ce79671839ea008af533d5
Key name:            my-key-name
Secret key:          d148c761cd706aab8a95f5df9e6b82631c36d613ac67908eacdaa2c4b0ce735b
```

#### 6. Grant Key Permissions on Bucket

```bash
docker exec odk-garage ./garage bucket allow my-bucket --key GK73ce79671839ea008af533d5 --read --write
```

#### 7. Enable Website Access (Optional)

For public web access to files:

```bash
docker exec odk-garage ./garage bucket website --allow my-bucket
```

## Access Patterns

### Subdomain-Style (Virtual Hosted)

Requires `root_domain` to be set in `garage.toml`.

**API access:** `https://bucket.s3.yourdomain.com/object`
**Web access:** `http://bucket.s3.yourdomain.com:3903/object`

### Path-Style

Works even without `root_domain`, but still uses it for routing.

**API access:** `https://s3.yourdomain.com/bucket/object`
**Web access:** Need to set Host header: `Host: bucket.s3.yourdomain.com`

## Testing with Node.js

### Upload Test

```javascript
const http = require('http');
const crypto = require('crypto');

const accessKey = 'GK73ce79671839ea008af533d5';
const secretKey = 'd148c761cd706aab8a95f5df9e6b82631c36d613ac67908eacdaa2c4b0ce735b';
const bucket = 'my-bucket';
const fileName = 'test.txt';
const fileContent = 'Hello Garage!';
const host = 'garage';  // Docker network name
const port = 3900;
const region = 'garage';

// AWS Signature V4 signing
const service = 's3';
const method = 'PUT';
const uri = `/${bucket}/${fileName}`;
const now = new Date();
const amzDate = now.toISOString().replace(/[:\-]|\.\d+/g, '');
const dateStamp = amzDate.substr(0, 8);

const payloadHash = crypto.createHash('sha256').update(fileContent).digest('hex');
const canonicalHeaders = `host:${host}:${port}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`;
const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
const canonicalRequest = `${method}\n${uri}\n\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;

const algorithm = 'AWS4-HMAC-SHA256';
const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
const stringToSign = `${algorithm}\n${amzDate}\n${credentialScope}\n${crypto.createHash('sha256').update(canonicalRequest).digest('hex')}`;

const kDate = crypto.createHmac('sha256', 'AWS4' + secretKey).update(dateStamp).digest();
const kRegion = crypto.createHmac('sha256', kDate).update(region).digest();
const kService = crypto.createHmac('sha256', kRegion).update(service).digest();
const kSigning = crypto.createHmac('sha256', kService).update('aws4_request').digest();
const signature = crypto.createHmac('sha256', kSigning).update(stringToSign).digest('hex');

const authorization = `${algorithm} Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

const options = {
  hostname: host,
  port: port,
  path: uri,
  method: 'PUT',
  headers: {
    'Host': `${host}:${port}`,
    'X-Amz-Date': amzDate,
    'X-Amz-Content-Sha256': payloadHash,
    'Authorization': authorization,
    'Content-Type': 'text/plain',
    'Content-Length': Buffer.byteLength(fileContent)
  }
};

const req = http.request(options, (res) => {
  console.log('Status:', res.statusCode);
  res.on('data', (d) => process.stdout.write(d));
});
req.on('error', (e) => console.error(e));
req.write(fileContent);
req.end();
```

## Integration with Applications

### Architecture

**IMPORTANT**: Use the **same public URL** for both server uploads and client downloads.

```bash
# Both ODK server uploads AND client downloads use the same URL
S3_SERVER=https://s3.yourdomain.com
```

**Why?** ODK Central generates public URLs for clients to download files (submissions, attachments). If the server uses a different internal URL, the generated URLs won't work for clients.

**Flow:**
1. ODK server uploads to `https://s3.yourdomain.com` (via nginx → Garage)
2. ODK generates download URLs like `https://s3.yourdomain.com/bucket/file.pdf`
3. Clients/browsers download from the same public URL

### Environment Variables

```bash
# Public URL - used for both uploads and downloads
S3_SERVER=https://s3.yourdomain.com
S3_ACCESS_KEY=GK73ce79671839ea008af533d5
S3_SECRET_KEY=d148c761cd706aab8a95f5df9e6b82631c36d613ac67908eacdaa2c4b0ce735b
S3_BUCKET_NAME=my-bucket
S3_REGION=garage
```

### Nginx Proxy Configuration

```nginx
# Proxy S3 API to backend applications
server {
  listen 443 ssl;
  server_name s3.yourdomain.com;

  location / {
    proxy_pass http://garage:3900;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

## Common Commands

```bash
# List buckets
docker exec odk-garage ./garage bucket list

# Get bucket info
docker exec odk-garage ./garage bucket info my-bucket

# List keys
docker exec odk-garage ./garage key list

# Check cluster health
docker exec odk-garage ./garage status

# View bucket objects (inspect)
docker exec odk-garage ./garage bucket inspect-object my-bucket test.txt
```

## Troubleshooting

### "Layout not ready" Error

**Cause:** Cluster layout not configured.

**Fix:** Follow step 3 in Initial Setup to assign node roles and apply layout.

### Nginx S3 Config Not Generated

**Cause:** Nginx container uses `setup-odk.sh` from the baked-in image, not from host files.

**Fix:** Generate S3 config manually in the running nginx container:
```bash
docker compose exec nginx /bin/sh -c '
  export DOMAIN=yourdomain.com &&
  export SSL_TYPE=selfsign &&
  export CERT_DOMAIN=yourdomain.com &&
  /scripts/envsub.awk < /usr/share/odk/nginx/s3.conf.template > /etc/nginx/conf.d/s3.conf &&
  nginx -s reload
'
```

**Long-term solution:** Rebuild nginx image with updated setup-odk.sh or mount the script as a volume.

### 421 Misdirected Request from Nginx

**Cause:** SNI hostname doesn't match any nginx server_name. Common when using prefixed hostnames like `odk-central.s3.domain.com`.

**Fix:** Update nginx `server_name` to accept both variants:
```bash
docker compose exec nginx sed -i \
  's/server_name s3.\${DOMAIN};/server_name s3.\${DOMAIN} odk-central.s3.\${DOMAIN};/' \
  /etc/nginx/conf.d/s3.conf
docker compose exec nginx nginx -s reload
```

### Container Exits Immediately

**Cause:** TOML syntax error, usually missing required `root_domain` in `[s3_web]` section.

**Fix:** Add `root_domain` to both `[s3_api]` and `[s3_web]` sections.

### Port Already in Use

**Cause:** Another process using ports 3900, 3901, or 3903.

**Fix:**
```bash
# Find what's using the port
lsof -i :3900

# Or use different ports in garage.toml and docker-compose.yml
```

### Rebuilding from Scratch

```bash
# Stop and remove volumes
docker compose -f docker-compose-garage.yml down -v
docker volume rm central_garage_data

# Start fresh
docker compose -f docker-compose-garage.yml up -d

# Re-run initial setup
```

## Related

- [[docker-compose-setup]] - For Docker Compose best practices
- [[nginx-reverse-proxy]] - For nginx configuration patterns

## Resources

- Official documentation: https://garagehq.deuxfleurs.fr/
- GitHub: https://git.deuxfleurs.fr/Deuxfleurs/garage
- S3 API compatibility: Supports most AWS S3 operations
