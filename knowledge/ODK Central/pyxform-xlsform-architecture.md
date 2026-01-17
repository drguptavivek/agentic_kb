---
title: PyXForm / XLSForm Conversion Service
type: reference
domain: ODK Central
tags:
  - pyxform
  - xlsform
  - form-conversion
  - docker
  - architecture
status: approved
created: 2026-01-03
updated: 2026-01-03
---

# PyXForm / XLSForm Conversion Service

## Overview

PyXForm is an HTTP service that converts XLSForm files (Excel `.xlsx` or `.xls`) into XForm XML. ODK Central uses PyXForm to allow form designers to create forms using the more user-friendly spreadsheet format instead of writing XML directly.

## Architecture

```
┌─────────────────┐
│   Web Browser   │
└────────┬────────┘
         │ Upload XLSX file
         ▼
┌─────────────────┐
│  ODK Central    │
│   (service)     │
└────────┬────────┘
         │ POST /api/v1/convert
         │ (stream XLSX binary)
         ▼
┌─────────────────┐
│  PyXForm        │
│  (pyxform)      │
│  Port: 80 (internal)│
└────────┬────────┘
         │ Returns XML + itemsets + warnings
         ▼
┌─────────────────┐
│   PostgreSQL    │
│  (forms table)  │
└─────────────────┘
```

## Docker Configuration

### Production Configuration

From `docker-compose.yml`:

```yaml
pyxform:
  image: 'ghcr.io/getodk/pyxform-http:v4.1.0'
  restart: always
```

### Development Configuration

From `docker-compose.vg-dev.yml`:

```yaml
pyxform:
  ports:
    - 5001:80  # Exposed on localhost:5001 for dev
```

**Note**: In production, PyXForm is only accessible internally (port 80). In dev, it's exposed on port 5001 for local testing.

## Server Configuration

### Config Files

**Development** (`server/config/local.json`):
```json
{
  "xlsform": {
    "host": "pyxform",
    "port": 80
  }
}
```

**Default** (`server/config/default.json`):
```json
{
  "xlsform": {
    "host": "localhost",
    "port": 5001
  }
}
```

### Backend Integration

The PyXForm client is in `server/lib/external/xlsform.js`:

```javascript
const convert = (host, port) => (stream, formIdFallback = '') => new Promise((resolve, reject) => {
  const headers = { 'X-XlsForm-FormId-Fallback': formIdFallback };
  const req = request({
    host,
    port,
    headers,
    method: 'POST',
    path: '/api/v1/convert'
  }, (res) => {
    // Parse response
    if (res.statusCode === 200)
      resolve({
        xml: body.result,          // XForm XML
        itemsets: body.itemsets,   // External itemset CSV data
        warnings: body.warnings    // Conversion warnings
      });
    else
      reject(Problem.user.xlsformNotValid({ error: body.error, warnings: body.warnings }));
  });

  pipeline(stream, req, rejectIfError(reject));
});
```

## Form Conversion Flow

### 1. Upload XLSForm

When a user uploads an XLSX file through the web UI or API:

**Endpoint**: `POST /v1/projects/:id/forms`

**Content-Type Detection**:
```javascript
// server/lib/resources/forms.js
if (isExcel(input.headers['content-type']))
  Forms.fromXls(input, input.headers['content-type'],
                input.headers['x-xlsform-formid-fallback'],
                isTrue(input.query.ignoreWarnings))
```

### 2. Conversion Process

**Code**: `server/lib/model/query/forms.js:fromXls`

```javascript
const fromXls = (stream, contentType, formIdFallback, ignoreWarnings) =>
  // Split stream into two:
  // 1. Send to PyXForm for conversion
  // 2. Store original XLSX file as blob
  splitStream(stream,
    (s) => xlsform(s, formIdFallback),      // Convert to XML
    (s) => Blob.fromStream(s, contentType)) // Store XLSX
  .then(([ { xml, itemsets, warnings }, blob ]) => {
    // If warnings exist and not ignored, store them
    if (warnings.length > 0 && !ignoreWarnings) {
      context.transitoryData.set('xlsFormWarnings', warnings);
    }

    // Parse XML and create form record
    return Promise.all([
      Form.fromXml(xml),
      Blobs.ensure(blob)
    ])
    .then(([ partial, xlsBlobId ]) =>
      partial.withAux('xls', { xlsBlobId, itemsets })
    );
  });
```

### 3. Response

**Success** (HTTP 200):
```json
{
  "result": "<xforms>...</xforms>",      // XForm XML
  "itemsets": "a,b,c\n1,2,3\n4,5,6",   // External itemsets CSV
  "warnings": [                          // Conversion warnings
    "warning 1",
    "warning 2"
  ]
}
```

**Error** (HTTP 4xx/5xx):
```json
{
  "error": "Error message from PyXForm",
  "warnings": []
}
```

## API Endpoints

### Convert XLSForm

**Request**:
```
POST /api/v1/convert
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
X-XlsForm-FormId-Fallback: my_form

<binary XLSX data>
```

**Response**: See above

## Headers

### X-XlsForm-FormId-Fallback

Optional header sent to PyXForm. Provides a fallback form ID if the XLSForm doesn't have a `form_id` column in the settings sheet.

## Warnings Handling

PyXForm returns warnings for non-critical issues during conversion:

- **Missing translations**: Fields without labels in all languages
- **Calculation issues**: Invalid calculations in `calculation` column
- **Choice filter warnings**: Invalid choice filter expressions

### Server Behavior

1. **Warnings present** → Store warnings in context, require confirmation to proceed
2. **`ignoreWarnings=true` query parameter** → Accept form despite warnings
3. **Fatal errors** → Reject form upload entirely

## Itemsets

External itemsets are returned as CSV data in the `itemsets` field:

```csv
name,label
fruit,Apple
fruit,Banana
vegetable,Carrot
```

This data is stored separately from the form XML and loaded dynamically.

## Troubleshooting

### PyXForm Not Available

**Symptom**: Form upload fails with "xlsform not available"

**Checks**:
```bash
# Check PyXForm container is running
docker ps | grep pyxform

# Check service logs
docker logs central-pyxform-1 --tail=50

# Test connectivity from service container
docker exec central-service-1 wget -O- http://pyxform:80/api/v1/convert

# In dev, test locally
curl -X POST http://localhost:5001/api/v1/convert \
  --data-binary @form.xlsx
```

### Conversion Warnings

**Symptom**: Form upload returns warnings and requires confirmation

**Check**:
- Inspect warnings in response
- Fix issues in XLSX and re-upload
- Or use `ignoreWarnings=true` query parameter to accept

### Invalid XLSForm

**Symptom**: HTTP 400/500 with error details

**Common Issues**:
- Missing `form_id` in settings sheet
- Invalid `type` column values
- Circular dependencies in `select_from` with `choice_filter`
- Invalid calculation expressions

**Debug**:
```bash
# Test PyXForm directly
docker exec central-service-1 npm test -- test/integration/api/forms/forms.js
```

### Port Conflicts

**Development only**: If port 5001 is already in use:

```yaml
# Change in docker-compose.vg-dev.yml
pyxform:
  ports:
    - 5002:80  # Use different port
```

And update `server/config/local.json`:
```json
{
  "xlsform": {
    "host": "localhost",
    "port": 5002
  }
}
```

## Testing

### Unit Tests

Mock PyXForm service: `server/test/util/xlsform.js`

```javascript
// Set test state before test
global.xlsformTest = 'success';
global.xlsformForm = 'simple2';

// Reset after test
global.xlsformTest = null;
global.xlsformForm = null;
```

### Integration Tests

Form upload with XLSForm: `server/test/integration/api/forms/draft.js`

```javascript
// Test XLSX upload
it('should create a form from XLSX', testService(async (service) => {
  const xlsxStream = fs.createReadStream('test/fixtures/simple.xlsx');
  await service.login('alice', (await TestAccounts.create()).password);
  const result = await service.post('/v1/projects/1/forms', xlsxStream, {
    'content-type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  });
  // Assertions...
}));
```

### Manual Testing

```bash
# Test PyXForm directly (dev only)
curl -X POST http://localhost:5001/api/v1/convert \
  --data-binary @path/to/form.xlsx \
  -H "X-XlsForm-FormId-Fallback: test_form" \
  -H "Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
```

## Version Management

### Current Version

- **Image**: `ghcr.io/getodk/pyxform-http:v4.1.0`
- **Released**: 2024
- **PyXForm Python Version**: Based on PyXForm Python library

### Upgrading

To upgrade PyXForm:

1. Update image tag in `docker-compose.yml`:
   ```yaml
   pyxform:
     image: 'ghcr.io/getodk/pyxform-http:vX.Y.Z'
   ```

2. Redeploy:
   ```bash
   docker compose up -d pyxform
   ```

3. Test form upload with existing XLSForms

**Caution**: Different PyXForm versions may produce slightly different XML or have different validation rules. Always test thoroughly after upgrading.

## Related Services

| Service | Purpose | Port |
|---------|---------|------|
| **PyXForm** | XLS → XML conversion | 80 (internal) |
| **Enketo** | Web form rendering | 8005 |
| **Service** | ODK Central backend | 80 |

## Related

- [[enketo-redis-secrets-architecture]] - How Enketo integrates with ODK Central
- [[server-architecture-patterns]] - Backend architecture overview
- [[vg-customization-patterns]] - VG-specific customizations

## External Resources

- [XLSForm specification](https://xlsform.org/)
- [PyXForm GitHub repository](https://github.com/XLSForm/pyxform-http)
- [ODK XForm specification](https://getodk.github.io/xforms-spec/)
