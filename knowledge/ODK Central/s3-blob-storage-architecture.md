---
title: S3 Blob Storage Architecture
type: reference
domain: ODK Central
tags:
  - s3
  - blob-storage
  - minio
  - garage
  - rustfs
  - storage
  - architecture
status: approved
created: 2026-01-03
updated: 2026-01-03
---

# S3 Blob Storage Architecture

## Quickstart: Local S3 with Garage (5 Minutes)

Complete setup to run ODK Central with local S3-compatible storage using Garage.

### Step 1: Create `docker-compose-garage.yml`

```yaml
version: '3.8'

services:
  garage:
    image: dxflrs/garage:v1.0.1
    container_name: odk-garage
    command: ["./garage", "server"]
    ports:
      - "3900:3900"  # S3 API
      - "3903:3903"  # Web UI
    volumes:
      - garage_data:/data
    environment:
      - RUST_LOG=info
    networks:
      - odk-net

  # Uncomment to recreate service container with S3 env vars
  # service:
  #   container_name: odk-service
  #   environment:
  #     - S3_SERVER=http://garage:3900
  #     - S3_ACCESS_KEY=${GARAGE_ACCESS_KEY}
  #     - S3_SECRET_KEY=${GARAGE_SECRET_KEY}
  #     - S3_BUCKET_NAME=odk-central
  #   networks:
  #     - odk-net

volumes:
  garage_data:

networks:
  odk-net:
    driver: bridge
```

### Step 2: Start Garage

```bash
docker compose -f docker-compose-garage.yml up -d garage

# Wait for Garage to start
docker logs -f odk-garage
# Press Ctrl+C when you see "server started"
```

### Step 3: Configure Garage and Create Bucket

```bash
# Enter the Garage container
docker exec -it odk-garage garage CLI

# Inside Garage CLI:
# 1. Initialize the cluster layout
garage layout assign -z dc1 -c garage1 10G

# 2. Apply the layout
garage layout apply

# 3. Create a bucket
garage bucket create odk-central

# 4. Create an API key for ODK Central
garage key create --name odk-central

# 5. Note the output - you'll need these values:
#    Key ID: GKxxxx...       <- Save this as GARAGE_ACCESS_KEY
#    Secret key: xxxxx...    <- Save this as GARAGE_SECRET_KEY

# 6. Allow the key to read/write the bucket
garage bucket allow odk-central --read --write --key <key-id-from-above>

# Exit CLI
exit
```

### Step 4: Create `.garage.env`

Create a `.garage.env` file in your ODK Central directory:

```bash
# Garage S3 Configuration
GARAGE_ACCESS_KEY=GKxxxx...
GARAGE_SECRET_KEY=xxxxx...
S3_SERVER=http://garage:3900
S3_BUCKET_NAME=odk-central
```

### Step 5: Update ODK Central `.env`

Add to your existing `.env` file or `docker-compose.yml`:

**Option A: Via .env file**
```bash
# Add to existing .env
S3_SERVER=http://garage:3900
S3_ACCESS_KEY=GKxxxx...
S3_SECRET_KEY=xxxxx...
S3_BUCKET_NAME=odk-central
```

**Option B: Via docker-compose override**
Create or update `docker-compose.override.yml`:
```yaml
services:
  service:
    environment:
      - S3_SERVER=http://garage:3900
      - S3_ACCESS_KEY=GKxxxx...
      - S3_SECRET_KEY=xxxxx...
      - S3_BUCKET_NAME=odk-central
    networks:
      - odk-net
    depends_on:
      - garage
```

### Step 6: Restart ODK Central Service

```bash
# Restart only the service container
docker compose up -d service

# Or if using docker-compose.override.yml:
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d service

# Verify S3 connection
docker logs -f odk-service | grep -i s3
# Press Ctrl+C to stop following logs
```

### Step 7: Verify

```bash
# 1. Check Garage is running
docker ps | grep garage

# 2. Check Garage bucket
docker exec -it odk-garage garage bucket list

# 3. Check ODK Central logs
docker logs odk-service --tail=50 | grep -i s3

# 4. Upload a test attachment via ODK Central web UI
#    and verify it appears in S3 (not in database)
docker exec -it odk-postgres14-1 psql -U odk -d odk -c "
  SELECT id, s3_status, length(content)
  FROM blobs
  ORDER BY id DESC
  LIMIT 5;
"
# s3_status should be 'uploaded' and content should be NULL
```

### Web UI

Access Garage web UI at: http://localhost:3903
- Login: not required for local dev
- View buckets and objects

---

## Overview

ODK Central supports storing binary blobs (attachments, form media files) in S3-compatible object storage instead of the database. This is implemented using the Minio Node.js client library and provides a **simple, key/endpoint-based implementation** rather than advanced S3 features.

## Architecture

```
┌─────────────────┐
│   Web Browser   │
└────────┬────────┘
         │ Upload attachment/Submit form
         ▼
┌─────────────────┐
│  ODK Central    │
│   (service)     │
└────────┬────────┘
         │ PUT / GET objects
         │ (via Minio client)
         ▼
┌─────────────────┐
│  S3-Compatible  │
│   Object Store  │
│  (AWS S3, MinIO,│
│   Garage, etc.) │
└─────────────────┘
```

## Implementation Characteristics

### Simple Key/Endpoint Based

**Configuration Required**:
```json
{
  "server": "https://s3.amazonaws.com",  // S3 endpoint URL
  "accessKey": "AKIAIOSFODNN7EXAMPLE",   // Access key ID
  "secretKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",  // Secret key
  "bucketName": "odk-central-bucket",    // Bucket name
  "requestTimeout": 60000,                // Optional: timeout in ms
  "objectPrefix": "optional-prefix/"      // Optional: prefix for all objects
}
```

**No Advanced Features Used**:
- ❌ No IAM roles (uses access key/secret key)
- ❌ No bucket policies managed by Central
- ❌ No lifecycle configurations
- ❌ No event notifications
- ❌ No versioning
- ❌ No multipart uploads (single PUT only)
- ❌ No server-side encryption (relies on transport security)
- ❌ No cross-origin resource sharing (CORS) configuration

### What It Does Use

| Feature | Implementation |
|---------|----------------|
| **Authentication** | Access key + secret key (HMAC-SHA signatures) |
| **Transport** | HTTP/HTTPS with configurable SSL |
| **Operations** | PUT, GET, DELETE objects only |
| **URLs** | Presigned URLs (temporary, signed) |
| **Timeouts** | Custom request timeout handling |
| **Connection Pooling** | Node.js native HTTP/HTTPS agent |

## Code Analysis

### Configuration: `server/lib/external/s3.js`

**Key Parameters**:
```javascript
const { server, accessKey, secretKey, bucketName, requestTimeout, objectPrefix } = config;
```

**Validation**:
```javascript
if (!(server && accessKey && secretKey && bucketName)) return disabled;
```

If any required parameter is missing, S3 storage is disabled and blobs fall back to database storage.

### Minio Client Initialization

```javascript
const url = new URL(server);
const useSSL = url.protocol === 'https:';
const endPoint = (url.hostname + url.pathname).replace(/\/$/, '');
const port = parseInt(url.port, 10);

const clientConfig = {
  endPoint,           // e.g., "s3.amazonaws.com" or "localhost:9000"
  port,               // e.g., 443 or 9000
  useSSL,             // true for HTTPS
  accessKey,
  secretKey,
  transport: { request }  // Custom request handler with timeout
};

return new Minio.Client(clientConfig);
```

### Object Naming Strategy

**Critical for avoiding collisions**:

```javascript
const objectNameFor = ({ id, sha }) => {
  // Format: "blob-{id}-{sha}"
  // Example: "blob-12345-a1b2c3d4e5f6..."
  return `${objectPrefix ?? ''}blob-${id}-${sha}`;
};
```

**Why this design**:
- **Blob ID**: Correlates with PostgreSQL `blobs` table
- **SHA sum**: Prevents collisions if multiple Central instances use the same bucket:
  - Testing/training resets
  - Staging & prod sharing a bucket
  - PostgreSQL data loss scenarios

### Core Operations

#### Upload

```javascript
async function uploadFromBlob(blob) {
  const { length, md5, sha, content } = blob;

  // Skip zero-length blobs (breaks minio-js)
  if (!length) return;

  const objectName = objectNameFor(blob);

  // Create readable stream from buffer
  const stream = new Readable();
  stream.push(content);
  stream.push(null);

  await minioClient.putObject(bucketName, objectName, stream);
  return true;
}
```

**Key Points**:
- Single PUT operation (no multipart)
- Zero-length blobs skipped (known issue)
- MD5/SHA logged but not verified by S3

#### Download via Presigned URL

```javascript
async function urlForBlob(filename, blob) {
  const expiry = 60;  // seconds

  const objectName = objectNameFor(blob);
  const respHeaders = {
    'response-content-disposition': contentDisposition(filename),
    'response-content-type': blob.contentType || 'null'
  };

  // Returns temporary signed URL
  return minioClient.presignedGetObject(bucketName, objectName, expiry, respHeaders);
}
```

**URL Example**:
```
https://s3.amazonaws.com/bucket/blob-12345-a1b2c3d4?
X-Amz-Algorithm=AWS4-HMAC-SHA256&
X-Amz-Credential=...&
X-Amz-Date=20260103T120000Z&
X-Amz-Expires=60&
X-Amz-SignedHeaders=host&
X-Amz-Signature=...
```

**Why Presigned URLs**:
- No need to proxy downloads through Central
- Direct client-to-S3 transfer (faster, less server load)
- Temporary access (60 seconds = secure)
- Can set content disposition (download filename) and content type

#### Direct Get (Server-side)

```javascript
async function getContentFor(blob) {
  const stream = await minioClient.getObject(bucketName, objectNameFor(blob));
  const [buf] = await pipethroughAndBuffer(stream);
  return buf;
}
```

Used when server needs to process the blob (not just serve to client).

#### Delete

```javascript
async function deleteObjsFor(blobs) {
  // Batch delete
  return await minioClient.removeObjects(bucketName,
    blobs.map(blob => objectNameFor(blob))
  );
}
```

## Advanced Features Handled

### Custom Timeout Handling

**Problem**: Minio-js doesn't handle large uploads well with default timeouts.

**Solution**: Custom request handler with dual timeout strategy:

```javascript
const MAX_REQ_TIMEOUT = 120000;  // 2 minutes absolute
const SMALL_REQ_TIMEOUT = MAX_REQ_TIMEOUT - 1000;  // 1:59 for socket timeout

const request = (_options, callback) => {
  const req = (useSSL ? https : http).request(options, callback);

  // Socket timeout (initial connection + data transfer)
  req.setTimeout(SMALL_REQ_TIMEOUT);

  // Absolute timeout (entire request)
  const globalTimeoutHandler = setTimeout(() =>
    req.destroy(new Error('Request timed out.'))
  , MAX_REQ_TIMEOUT);

  req.once('close', () => {
    clearTimeout(globalTimeoutHandler);
  });

  return req;
};
```

### Graceful Shutdown

**Tracks in-flight requests** and aborts them on shutdown:

```javascript
const inflight = new Set();

function destroy() {
  destroyed = true;
  return new Promise(resolve => {
    if (!inflight.size) return resolve();

    // Wait for all requests to complete or abort them
    for (const req of inflight) {
      req.destroy(new Error('Aborted by request'));
    }
  });
}
```

This prevents orphaned connections during container restarts.

### Error Handling

**Wrapped errors with context**:

```javascript
const isErrAccess = err => err.name === 'S3Error' && err.code === 'AccessDenied';
const isErrUpstream = err => err.name === 'S3Error' && err.code === 'InternalError';

const wrappedOrUnhandled = (err, operation, blobOrBlobs) => {
  const details = {
    amzRequestId: err.requestid,  // AWS request ID for support
    operation
  };

  if (isErrUpstream(err)) {
    return Problem.internal.s3upstreamError(details);
  } else if (isErrAccess(err)) {
    details.reason = err.message;
    return Problem.internal.s3accessDenied(details);
  } else {
    return err;
  }
};
```

## Configuration Examples

### AWS S3

```json
{
  "external": {
    "s3blobStore": {
      "server": "https://s3.amazonaws.com",
      "accessKey": "AKIAIOSFODNN7EXAMPLE",
      "secretKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      "bucketName": "my-odk-central",
      "requestTimeout": 120000
    }
  }
}
```

### MinIO (Self-hosted)

```json
{
  "external": {
    "s3blobStore": {
      "server": "https://minio.example.com",
      "accessKey": "minioadmin",
      "secretKey": "minioadmin",
      "bucketName": "odk-central",
      "requestTimeout": 60000
    }
  }
}
```

### Wasabi

```json
{
  "external": {
    "s3blobStore": {
      "server": "https://s3.wasabisys.com",
      "accessKey": "ABCDEF123456",
      "secretKey": "1234567890ABCDEF",
      "bucketName": "odk-central-bucket",
      "requestTimeout": 60000
    }
  }
}
```

### Local Development (MinIO in Docker)

From `server/config/s3-dev.json`:

```json
{
  "external": {
    "s3blobStore": {
      "server": "http://localhost:9000",
      "accessKey": "odk-central-dev",
      "secretKey": "topSecret123",
      "bucketName": "odk-central-bucket",
      "requestTimeout": 60000
    }
  }
}
```

### Garage (Self-Hosted Alternative to MinIO)

**Garage** is a lightweight S3-compatible object storage system written in Rust. It's a simpler alternative to MinIO for local development and self-hosted deployments.

**Docker Compose setup**:

```yaml
services:
  garage:
    image: dxflrs/garage:v1.0.1
    command: ["./garage", "server"]
    ports:
      - "3900:3900"  # S3 API
      - "3903:3903"  # Web UI (optional)
    volumes:
      - garage_data:/data
    environment:
      - RUST_LOG=info
    networks:
      - default

volumes:
  garage_data:

networks:
  default:
    name: odk-network
```

**Initial Garage setup** (run once):

```bash
# Enter the container
docker exec -it central-garage-1 sh

# Generate configuration
garage layout assign -z dc1 -c <node_id> 10G

# Create the S3 API key
garage key create --name odk-central

# Output will show:
# Access key: <access_key>
# Secret key: <secret_key>

# Create bucket
garage bucket create odk-central-bucket

# Allow key to access bucket
garage bucket allow odk-central-bucket --read --write --key <key_id>
```

**ODK Central configuration for Garage**:

```json
{
  "external": {
    "s3blobStore": {
      "server": "http://garage:3900",
      "accessKey": "your-garage-access-key",
      "secretKey": "your-garage-secret-key",
      "bucketName": "odk-central-bucket",
      "requestTimeout": 60000
    }
  }
}
```

**Local development with Garage**:

```json
{
  "external": {
    "s3blobStore": {
      "server": "http://localhost:3900",
      "accessKey": "GK<access_key>",
      "secretKey": "<secret_key>",
      "bucketName": "odk-central-bucket",
      "requestTimeout": 60000
    }
  }
}
```

### RustFS (High-Performance S3-Compatible Storage)

**RustFS** is a high-performance, 100% S3-compatible distributed object storage system written in Rust. It offers an alternative to MinIO with better performance characteristics.

**Docker Compose setup**:

```yaml
services:
  rustfs:
    image: rustfs/rustfs:latest
    command: ["/data"]
    ports:
      - "9000:9000"  # S3 API
      - "9001:9001"  # Console UI
    volumes:
      - rustfs_data:/data
    environment:
      - RUSTFS_ACCESS_KEY=rustfsadmin
      - RUSTFS_SECRET_KEY=rustfsadmin
      - RUSTFS_CONSOLE_ENABLE=true
    networks:
      - default

volumes:
  rustfs_data:

networks:
  default:
    name: odk-network
```

**Quick start** (simple single-node deployment):

```bash
docker run -d \
  --name rustfs_local \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /mnt/rustfs/data:/data \
  -e RUSTFS_ACCESS_KEY=rustfsadmin \
  -e RUSTFS_SECRET_KEY=rustfsadmin \
  -e RUSTFS_CONSOLE_ENABLE=true \
  rustfs/rustfs:latest \
  /data
```

**Bucket creation** (via UI, mc client, or API):

1. **Via Web UI**:
   - Navigate to `http://localhost:9001`
   - Login with `rustfsadmin` / `rustfsadmin`
   - Click "Create Bucket" and enter bucket name

2. **Via MinIO Client (mc)**:
   ```bash
   # Install mc first
   mc alias set rustfs http://localhost:9000 rustfsadmin rustfsadmin
   mc mb rustfs/odk-central-bucket
   mc ls rustfs
   ```

3. **Via API**:
   ```bash
   curl --location --request PUT 'http://localhost:9000/odk-central-bucket' \
     --header 'X-Amz-Content-Sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
   ```

**ODK Central configuration for RustFS**:

```json
{
  "external": {
    "s3blobStore": {
      "server": "http://rustfs:9000",
      "accessKey": "rustfsadmin",
      "secretKey": "rustfsadmin",
      "bucketName": "odk-central-bucket",
      "requestTimeout": 60000
    }
  }
}
```

**Local development with RustFS**:

```json
{
  "external": {
    "s3blobStore": {
      "server": "http://localhost:9000",
      "accessKey": "rustfsadmin",
      "secretKey": "rustfsadmin",
      "bucketName": "odk-central-bucket",
      "requestTimeout": 60000
    }
  }
}
```

### Nginx Reverse Proxy for RustFS

For production deployments, use Nginx as a reverse proxy for load balancing, logging, and custom URL handling:

```nginx
upstream rustfs {
   least_conn;
   server 127.0.0.1:9000;
}

server {
   listen       8000;
   listen  [::]:8000;
   server_name  _;

   # Allow special characters in headers
   ignore_invalid_headers off;
   # Allow any size file to be uploaded
   client_max_body_size 0;
   # Disable buffering
   proxy_buffering off;
   proxy_request_buffering off;

   location / {
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;

      proxy_connect_timeout 300;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
      chunked_transfer_encoding off;

      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";

      proxy_pass http://rustfs;
   }
}
```

**Multi-machine load balancing**:

```nginx
upstream rustfs {
   least_conn;
   server 10.0.0.1:9000;
   server 10.0.0.2:9000;
   server 10.0.0.3:9000;
}
```

### Environment Variable Configuration (.env)

ODK Central supports configuring S3 via environment variables in `.env` or docker-compose.yml:

```bash
# .env file for S3 configuration
S3_SERVER=http://localhost:9000
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_BUCKET_NAME=odk-central-bucket
```

**Docker Compose example**:

```yaml
services:
  service:
    environment:
      - S3_SERVER=${S3_SERVER}
      - S3_ACCESS_KEY=${S3_ACCESS_KEY}
      - S3_SECRET_KEY=${S3_SECRET_KEY}
      - S3_BUCKET_NAME=${S3_BUCKET_NAME}
```

**Environment variable mapping**:

| JSON Config | Environment Variable | Example |
|-------------|---------------------|---------|
| `server` | `S3_SERVER` | `http://localhost:9000` |
| `accessKey` | `S3_ACCESS_KEY` | `rustfsadmin` |
| `secretKey` | `S3_SECRET_KEY` | `your-secret-key` |
| `bucketName` | `S3_BUCKET_NAME` | `odk-central-bucket` |

**Complete .env examples**:

```bash
# MinIO
S3_SERVER=http://minio:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET_NAME=odk-central

# Garage
S3_SERVER=http://garage:3900
S3_ACCESS_KEY=GKyour-key
S3_SECRET_KEY=your-secret
S3_BUCKET_NAME=odk-central

# RustFS
S3_SERVER=http://rustfs:9000
S3_ACCESS_KEY=rustfsadmin
S3_SECRET_KEY=rustfsadmin
S3_BUCKET_NAME=odk-central

# AWS S3
S3_SERVER=https://s3.amazonaws.com
S3_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
S3_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
S3_BUCKET_NAME=my-odk-central
```

**Note**: Environment variables take precedence over JSON configuration files.

## S3-Compatible Services

Tested and compatible with:

| Service | Endpoint Format | Notes |
|---------|----------------|-------|
| **AWS S3** | `https://s3.amazonaws.com` | Full compatibility |
| **MinIO** | `http://localhost:9000` | Self-hosted, dev/staging |
| **Garage** | `http://localhost:3900` | Lightweight, Rust-based |
| **RustFS** | `http://localhost:9000` | High-performance, Rust-based |
| **Wasabi** | `https://s3.wasabisys.com` | Hot cloud storage |
| **DigitalOcean Spaces** | `https://nyc3.digitaloceanspaces.com` | Region-specific endpoint |
| **Backblaze B2** | `https://s3.us-west-002.backblazeb2.com` | S3-compatible endpoint |

## S3-Compatible Storage Comparison

| Aspect | MinIO | Garage | RustFS |
|--------|-------|--------|--------|
| **Language** | Go | Rust | Rust |
| **License** | AGPL (commercial license required) | Dual-licensed: AGPL + commercial | AGPL (open-source) |
| **Complexity** | More features, more complex | Focused on core S3 functionality | High-performance, enterprise features |
| **Resource Usage** | Higher memory footprint | Lower memory footprint | Optimized for performance |
| **Setup** | Easy with Docker | Slightly more setup required | Quick start with Docker |
| **Maturity** | Very mature, widely adopted | Newer, less widely adopted | Newer, rapidly developing |
| **Use Case** | Production-like, full MinIO features | Lightweight dev, simple S3 | High-performance scenarios |
| **S3 API Coverage** | Nearly complete | Core operations (sufficient) | Core operations (sufficient) |
| **Default Port** | 9000 | 3900 | 9000 |
| **Console UI** | Yes (port 9001) | Yes (port 3903) | Yes (port 9001) |
| **Default Credentials** | minioadmin/minioadmin | Generated on setup | rustfsadmin/rustfsadmin |

**Recommendation for Local Development**:

- **Use MinIO if**: You want production-like parity with minimal changes, most widely used
- **Use Garage if**: You want a lighter-weight alternative or prefer simpler setup
- **Use RustFS if**: You need high-performance storage or prefer Rust-based tools with UI console
- **Use Database** (default): For most development, database storage is sufficient

**Note**: ODK Central only uses basic S3 operations (PUT, GET, DELETE), so any of these solutions' focused feature sets are perfectly adequate.

## Troubleshooting

### S3 Storage Not Enabled

**Symptom**: Blobs stored in database despite S3 configuration

**Check**:
```bash
# Verify all required parameters are set
docker exec central-service-1 node -e "
const config = require('./config/default.json').default.external.s3blobStore;
console.log(config);
"
```

**Solution**: Ensure all required fields are present:
- `server`
- `accessKey`
- `secretKey`
- `bucketName`

### Access Denied Errors

**Symptom**: Logs show `S3Error: AccessDenied`

**Checks**:
```bash
# Verify credentials
docker exec central-service-1 node -e "
const Minio = require('minio');
const client = new Minio.Client({
  endPoint: 's3.amazonaws.com',
  accessKey: 'YOUR_KEY',
  secretKey: 'YOUR_SECRET'
});
client.listBuckets().then(console.log).catch(console.error);
"
```

**Common Causes**:
- Wrong access key or secret key
- IAM user lacks `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject` permissions
- Bucket policy denies access

### Upload Timeouts

**Symptom**: Large attachment uploads fail with timeout

**Solution**: Increase `requestTimeout`:

```json
{
  "s3blobStore": {
    "requestTimeout": 300000  // 5 minutes
  }
}
```

### Zero-Length Blob Errors

**Symptom**: Empty attachments cause upload failures

**Note**: This is a known minio-js issue. ODK Central skips zero-length blobs intentionally.

See: `server/lib/external/s3.js:188`

## Testing

### Unit Tests

```javascript
// Mock S3 client
const s3Mock = {
  enabled: true,
  putObject: async () => {},
  getObject: async () => createReadStream('test.txt'),
  removeObjects: async () => {},
  presignedGetObject: async () => 'https://s3.amazonaws.com/...'
};
```

### Integration Tests

```javascript
it('should upload and retrieve blob from S3', testService(async (service) => {
  const blobData = Buffer.from('test data');

  // Upload
  await service.post('/v1/blobs', blobData, {
    'content-type': 'text/plain'
  });

  // Retrieve via presigned URL
  const urlResult = await service.get('/v1/blobs/1/url');
  const response = await axios.get(urlResult.url);
  expect(response.data).toEqual(blobData);
}));
```

### Manual Testing

```bash
# Upload test file
curl -X POST http://localhost:8383/v1/blobs \
  --data-binary @test.jpg \
  -H "Content-Type: image/jpeg"

# Get presigned URL and download
curl http://localhost:8383/v1/blobs/1/url | jq -r .url | xargs curl -O
```

## Performance Considerations

### Presigned URL Expiry

**Current**: 60 seconds

**Trade-offs**:
- Too short (30s): Users with slow connections may fail
- Too long (3600s): Security risk if URL is shared

**AWS Behavior**: Downloads continue if started before expiry, even if expiry passes during download.

### Connection Pooling

Uses Node.js default HTTP agent:
- Max 5 sockets per host
- Keep-alive enabled
- No custom pool configuration

**For high-volume deployments**, consider:
- Increasing agent pool size
- Configuring keep-alive timeout

### Batch Deletes

`removeObjects()` sends delete requests in parallel. For large batch deletes:
- May overwhelm network or S3 API rate limits
- Consider chunking into smaller batches

## Security Considerations

### Credentials in Environment Variables

**Recommended**: Use Docker secrets or environment variables:

```bash
docker compose -f docker-compose.yml \
  -e S3_SERVER="https://s3.amazonaws.com" \
  -e S3_ACCESS_KEY="${S3_ACCESS_KEY}" \
  -e S3_SECRET_KEY="${S3_SECRET_KEY}" \
  -e S3_BUCKET_NAME="${S3_BUCKET_NAME}"
```

### Presigned URL Security

**URLs contain**:
- Signature (HMAC-SHA256)
- Expiry timestamp
- Request ID

**Risks**:
- If URL is shared, recipient has 60-second access
- No user-specific authentication in URL (user must already be authenticated to get URL)

**Mitigation**: Keep expiry short (60s is reasonable).

### HTTPS Enforcement

**Production**: Always use HTTPS endpoints (`https://`)

**Development**: HTTP (`http://`) acceptable for MinIO/Garage on localhost

## Storage Options

ODK Central supports two blob storage options:

| Storage Type | Configuration | Data Location |
|--------------|---------------|---------------|
| **Database** (default) | Don't configure S3 | `blobs.content` column (PostgreSQL binary) |
| **S3-compatible** | Set `s3blobStore` config | External object store |

### Database Storage (Default)

When S3 is **not** configured, blobs are stored directly in PostgreSQL:

```sql
CREATE TABLE blobs (
  id serial PRIMARY KEY,
  sha varchar(40) UNIQUE NOT NULL,
  content binary NOT NULL,      -- ← Blob data stored here
  "contentType" text,
  md5 varchar(32),
  s3_status varchar              -- 'pending', 'uploaded', 'failed', 'skipped'
);
```

**Pros**:
- Zero configuration required
- Works out of the box
- ACID guarantees

**Cons**:
- Database bloat with large files
- Performance degradation with many/large files
- Larger backup sizes

### Filesystem Storage: Not Available

**ODK Central does NOT support local filesystem/blob store**. The only options are:
1. Database storage (default)
2. S3-compatible object storage

There is no built-in option to store blobs as files on disk.

**Why no filesystem support?**
- Docker deployment complexity (mounted volumes, permissions)
- Backup complexity (database + filesystem)
- Scaling challenges (shared filesystem required for multiple instances)

**Workaround**: If you need filesystem-like storage for development, use MinIO or Garage in Docker with a mounted volume. The data will be stored as files but accessible via S3 API.

Example with mounted volume:
```yaml
services:
  garage:
    image: dxflrs/garage:v1.0.1
    volumes:
      - ./garage-data:/data  # ← Files stored on host filesystem
```

## Migration

### From Database to S3

There is no built-in migration tool. To migrate existing blobs:

1. **Configure S3** in `config/local.json`
2. **Restart** service
3. **New blobs** go to S3 automatically
4. **Old blobs** remain in database
5. **Optional**: Write script to:
   - Read blobs from database
   - Upload to S3
   - Update blob records (no change needed, object name is deterministic)

## Related

- [[enketo-redis-secrets-architecture]] - How Enketo integrates with Central
- [[server-architecture-patterns]] - Backend architecture overview
- [[pyxform-xlsform-architecture]] - PyXForm conversion service

## External Resources

- [Minio JavaScript SDK Documentation](https://min.io/docs/minio/linux/developers/javascript/API.html)
- [Garage Documentation](https://garagehq.deuxfleurs.fr/)
- [Garage S3 Compatibility](https://garagehq.deuxfleurs.fr/documentation/reference-manual/s3-compatibility.html)
- [RustFS Documentation](https://docs.rustfs.com/)
- [RustFS Docker Installation](https://docs.rustfs.com/installation/docker/)
- [RustFS Bucket Creation](https://docs.rustfs.com/management/bucket/creation.html)
- [RustFS Nginx Integration](https://docs.rustfs.com/integration/nginx.html)
- [AWS S3 API Reference](https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations.html)
- [AWS S3 Presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html)
