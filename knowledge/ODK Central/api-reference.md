---
title: ODK Central API Reference
type: reference
domain: ODK Central
tags:
  - odk-central
  - api
  - authentication
  - rest
status: approved
created: 2026-01-28
updated: 2026-01-28
---

# ODK Central API Reference

This document covers the core ODK Central API endpoints for authentication, projects, forms, submissions, and attachments.

## Base URL

All ODK Central API endpoints use the `/v1/` prefix:

```
https://your-central-server/v1/
```

## Authentication

### Getting a Session Token

**Endpoint:** `POST /v1/sessions`

Obtain a bearer token by providing email and password credentials.

### Request

```bash
curl -X POST https://your-central-server/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "email": "my.email.address@getodk.org",
    "password": "my.super.secure.password"
  }'
```

**Request Body Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `email` | string | User's full email address |
| `password` | string | User's password |

### Response

**HTTP Status:** `200 OK`

```json
{
  "createdAt": "2018-04-18T03:04:51.695Z",
  "expiresAt": "2018-04-19T03:04:51.695Z",
  "token": "lSpAIeksRu1CNZs7!qjAot2T17dPzkrw9B4iTtpj7OoIJBmXvnHM8z8Ka4QPEjR7"
}
```

**Response Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `createdAt` | string | ISO date format - Session creation timestamp |
| `expiresAt` | string | ISO date format - Session expiration (24 hours after creation) |
| `token` | string | Bearer token for authenticated requests |

### Error Response

**HTTP Status:** `401 Unauthorized`

```json
{
  "code": 401.2,
  "message": "Could not authenticate with the provided credentials."
}
```

### Using the Token

Include the bearer token in the `Authorization` header for all subsequent requests:

```bash
-H "Authorization: Bearer lSpAIeksRu1CNZs7!qjAot2T17dPzkrw9B4iTtpj7OoIJBmXvnHM8z8Ka4QPEjR7"
```

### Logging Out

**Endpoint:** `DELETE /v1/sessions/current`

Revokes the current session token.

```bash
curl -X DELETE https://your-central-server/v1/sessions/current \
  -H "Authorization: Bearer YOUR_TOKEN"
```

> **Note**
> Sessions expire automatically after 24 hours. Logging out is optional but recommended for security.

## Projects

### Listing Projects

**Endpoint:** `GET /v1/projects`

Returns all projects the authenticated actor is allowed to see.

### Request

```bash
curl -X GET https://your-central-server/v1/projects \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Optional Extended Metadata

Add the `X-Extended-Metadata` header to retrieve additional metadata:

```bash
curl -X GET https://your-central-server/v1/projects \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "X-Extended-Metadata: true"
```

### Response

**HTTP Status:** `200 OK`

**Basic Response:**

```json
[
  {
    "id": 1,
    "name": "Default Project",
    "description": "Description of this Project to show on Central.",
    "keyId": 3,
    "archived": false
  }
]
```

**Extended Response:**

```json
[
  {
    "id": 1,
    "name": "Default Project",
    "description": "Description of this Project to show on Central.",
    "keyId": 3,
    "archived": false,
    "appUsers": 4,
    "forms": 7,
    "lastSubmission": "2018-04-18T03:04:51.695Z",
    "datasets": 2,
    "lastEntity": "2023-04-18T03:04:51.695Z"
  }
]
```

**Response Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Numerical ID of the Project |
| `name` | string | Name of the Project |
| `description` | string | Project description (rendered as Markdown in frontend) |
| `keyId` | number | ID of encryption key (if managed encryption enabled) |
| `archived` | boolean | Whether project is archived |
| `appUsers` | number | (Extended only) Count of App Users |
| `forms` | number | (Extended only) Count of Forms |
| `lastSubmission` | string | (Extended only) Timestamp of latest submission |
| `datasets` | number | (Extended only) Count of Datasets |
| `lastEntity` | string | (Extended only) Timestamp of latest entity |

### Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `forms` | boolean | If `true`, returns forms nested under `formList` | `true` |
| `datasets` | boolean | If `true`, returns datasets nested under `datasetList` | `true` |

## Forms

### Listing Forms in a Project

**Endpoint:** `GET /v1/projects/{projectId}/forms`

Returns all forms the authenticated actor is allowed to see within a project.

### Request

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Path Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `projectId` | number | Numeric ID of the Project | `16` |

### Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `deleted` | boolean | If `true`, returns only deleted Forms with their IDs | `true` |

### Optional Extended Metadata

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "X-Extended-Metadata: true"
```

### Response

**HTTP Status:** `200 OK`

**Basic Response:**

```json
[
  {
    "id": 1,
    "projectId": 1,
    "xmlFormId": "simple",
    "name": "Simple",
    "version": "2023.1",
    "enketoId": "xyz123",
    "hash": "abc123...",
    "keyId": null,
    "state": "open",
    "createdAt": "2018-01-19T23:58:03.395Z",
    "updatedAt": "2018-03-21T12:45:02.312Z",
    "publishedAt": "2018-01-21T00:04:11.153Z"
  }
]
```

**Extended Response:**

```json
[
  {
    "id": 1,
    "projectId": 1,
    "xmlFormId": "simple",
    "name": "Simple",
    "version": "2023.1",
    "enketoId": "xyz123",
    "hash": "abc123...",
    "keyId": null,
    "state": "open",
    "createdAt": "2018-01-19T23:58:03.395Z",
    "updatedAt": "2018-03-21T12:45:02.312Z",
    "publishedAt": "2018-01-21T00:04:11.153Z",
    "submissions": 10,
    "reviewStates": {
      "received": 3,
      "hasIssues": 2,
      "edited": 1
    },
    "lastSubmission": "2024-01-15T10:30:00.000Z",
    "createdBy": {
      "id": 1,
      "name": "Admin User"
    }
  }
]
```

**Response Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Numerical ID of the Form |
| `projectId` | number | Parent Project ID |
| `xmlFormId` | string | Form ID from XForms XML definition |
| `name` | string | Human-readable form name |
| `version` | string | Form version string |
| `enketoId` | string | Enketo form identifier |
| `hash` | string | Form content hash |
| `keyId` | number | Encryption key ID (if encrypted) |
| `state` | string | Form state: `open`, `closing`, `closed` |
| `createdAt` | string | ISO date format - Creation timestamp |
| `updatedAt` | string | ISO date format - Last update timestamp |
| `publishedAt` | string | ISO date format - Publication timestamp (null if unpublished) |
| `submissions` | number | (Extended only) Count of submissions |
| `reviewStates` | object | (Extended only) Submission review state counts |
| `lastSubmission` | string | (Extended only) Timestamp of latest submission |
| `createdBy` | object | (Extended only) Creator actor information |

## Submissions

### Listing Submissions for a Form

**Endpoint:** `GET /v1/projects/{projectId}/forms/{xmlFormId}/submissions`

Returns all submissions for a specific form.

### Request

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms/simple/submissions" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Path Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `projectId` | number | Numeric ID of the Project | `1` |
| `xmlFormId` | string | Form ID from XForms XML definition | `simple` |

### Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `deleted` | boolean | If `true`, includes deleted submissions | `true` |

### Response

**HTTP Status:** `200 OK`

```json
[
  {
    "instanceId": "uuid:12345678-1234-1234-1234-123456789abc",
    "submitterId": 5,
    "createdAt": "2018-01-21T00:04:11.153Z",
    "updatedAt": "2018-01-21T00:04:11.153Z",
    "reviewState": "received"
  }
]
```

**Response Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `instanceId` | string | Unique submission identifier (UUID) |
| `submitterId` | number | ID of the actor who submitted |
| `createdAt` | string | ISO date format - Submission timestamp |
| `updatedAt` | string | ISO date format - Last update timestamp |
| `reviewState` | string | Review state: `received`, `hasIssues`, `edited` |

### Getting a Single Submission

**Endpoint:** `GET /v1/projects/{projectId}/forms/{xmlFormId}/submissions/{instanceId}`

Retrieves full details of a specific submission including submission data.

### Request

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms/simple/submissions/uuid:12345678-1234-1234-1234-123456789abc" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Path Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `projectId` | number | Numeric ID of the Project | `1` |
| `xmlFormId` | string | Form ID from XForms XML definition | `simple` |
| `instanceId` | string | Submission instance ID (UUID) | `uuid:12345678-1234-1234-1234-123456789abc` |

### Response

**HTTP Status:** `200 OK`

```json
{
  "instanceId": "uuid:12345678-1234-1234-1234-123456789abc",
  "submitterId": 5,
  "createdAt": "2018-01-21T00:04:11.153Z",
  "updatedAt": "2018-01-21T00:04:11.153Z",
  "reviewState": "received",
  "deviceId": "collect123",
  "submission": {
    "name": "John Doe",
    "age": "30",
    "location": "40.7128 -74.0060 0.0 0.0"
  }
}
```

**Response Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `instanceId` | string | Unique submission identifier (UUID) |
| `submitterId` | number | ID of the actor who submitted |
| `createdAt` | string | ISO date format - Submission timestamp |
| `updatedAt` | string | ISO date format - Last update timestamp |
| `reviewState` | string | Review state: `received`, `hasIssues`, `edited` |
| `deviceId` | string | Device identifier from ODK Collect |
| `submission` | object | Form field names and values |

### Submission Metadata Fields

The following metadata fields are available for each submission:

**Identity Metadata:**

| Field | Type | Description |
|-------|------|-------------|
| `instanceId` | string | Unique submission identifier (UUID format) |
| `submitterId` | number | ID of the actor (user/app user) who submitted |
| `deviceId` | string | Device identifier from ODK Collect (if applicable) |

**Timestamp Metadata:**

| Field | Type | Description |
|-------|------|-------------|
| `createdAt` | string | ISO 8601 timestamp when submission was created |
| `updatedAt` | string | ISO 8601 timestamp when submission was last updated |
| `submitTime` | string | (Deprecated) Legacy submission timestamp |

**Review State Metadata:**

| State | Description |
|-------|-------------|
| `received` | New submission, not yet reviewed |
| `hasIssues` | Submission has been flagged with issues |
| `edited` | Submission has been edited after submission |

**Additional Metadata (may be present):**

| Field | Type | Description |
|-------|------|-------------|
| `team` | string | Team associated with submission (if teams enabled) |
| `geolocation` | object | Submission GPS coordinates (from device) |
| `duration` | number | Time spent filling form (in seconds) |
| `finished` | boolean | Whether form was marked as complete |

**Submission Data Object:**

The `submission` object contains the actual form field responses:

```json
{
  "submission": {
    "question1": "response value",
    "question2": "another response",
    "repeat_group": [
      {
        "item": "value 1"
      },
      {
        "item": "value 2"
      }
    ]
  }
}
```

### Extended Metadata for Submissions

Add the `X-Extended-Metadata: true` header to retrieve additional metadata:

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms/simple/submissions" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "X-Extended-Metadata: true"
```

**Extended Response includes:**

| Field | Type | Description |
|-------|------|-------------|
| `submitter` | object | Full actor details (displayName, type) |
| `attachments` | boolean | Whether submission has attachments |
| `reviewStatus` | object | Detailed review status information |

## Attachments

### Listing Attachments for a Submission

**Endpoint:** `GET /v1/projects/{projectId}/forms/{xmlFormId}/submissions/{instanceId}/attachments`

Returns all attachments (files) associated with a specific submission.

### Request

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms/simple/submissions/uuid:12345678-1234-1234-1234-123456789abc/attachments" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Path Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `projectId` | number | Numeric ID of the Project | `1` |
| `xmlFormId` | string | Form ID from XForms XML definition | `simple` |
| `instanceId` | string | Submission instance ID (UUID) | `uuid:12345678-1234-1234-1234-123456789abc` |

### Response

**HTTP Status:** `200 OK`

```json
[
  {
    "name": "photo_1.jpg",
    "type": "image/jpeg",
    "size": 245632
  },
  {
    "name": "audio_recording.m4a",
    "type": "audio/mp4",
    "size": 102400
  }
]
```

**Response Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Attachment filename |
| `type` | string | MIME type of the attachment |
| `size` | number | File size in bytes |

### Downloading an Attachment

**Endpoint:** `GET /v1/projects/{projectId}/forms/{xmlFormId}/submissions/{instanceId}/attachments/{filename}`

Downloads a specific attachment file.

### Request

```bash
curl -X GET "https://your-central-server/v1/projects/1/forms/simple/submissions/uuid:12345678-1234-1234-1234-123456789abc/attachments/photo_1.jpg" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -o photo_1.jpg
```

### Path Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `projectId` | number | Numeric ID of the Project | `1` |
| `xmlFormId` | string | Form ID from XForms XML definition | `simple` |
| `instanceId` | string | Submission instance ID (UUID) | `uuid:12345678-1234-1234-1234-123456789abc` |
| `filename` | string | Name of the attachment file | `photo_1.jpg` |

### Response

**HTTP Status:** `200 OK`

The response body contains the binary file content.

**Headers:**

```
Content-Type: image/jpeg
Content-Disposition: attachment; filename="photo_1.jpg"
Content-Length: 245632
```

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Login | POST | `/v1/sessions` |
| Logout | DELETE | `/v1/sessions/current` |
| List Projects | GET | `/v1/projects` |
| List Forms | GET | `/v1/projects/{projectId}/forms` |
| List Submissions | GET | `/v1/projects/{projectId}/forms/{xmlFormId}/submissions` |
| Get Submission | GET | `/v1/projects/{projectId}/forms/{xmlFormId}/submissions/{instanceId}` |
| List Attachments | GET | `/v1/projects/{projectId}/forms/{xmlFormId}/submissions/{instanceId}/attachments` |
| Download Attachment | GET | `/v1/projects/{projectId}/forms/{xmlFormId}/submissions/{instanceId}/attachments/{filename}` |
| Export (OData) | GET | `/v1/projects/{projectId}/forms/{xmlFormId}.svc/Submissions` |

## Common Patterns

### Iterating Through All Forms

To list all forms across all projects:

```bash
# 1. Login and get token
TOKEN=$(curl -s -X POST https://your-central-server/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  | jq -r '.token')

# 2. Get projects
curl -s https://your-central-server/v1/projects \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[].id' \
  | while read PROJECT_ID; do
      # 3. Get forms for each project
      curl -s "https://your-central-server/v1/projects/$PROJECT_ID/forms" \
        -H "Authorization: Bearer $TOKEN"
    done
```

### Iterating Through All Submissions

To list all submissions for a form:

```bash
FORM_ID="simple"
PROJECT_ID="1"

curl -s "https://your-central-server/v1/projects/$PROJECT_ID/forms/$FORM_ID/submissions" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[].instanceId'
```

### Downloading All Attachments from a Submission

To download all attachment files from a specific submission:

```bash
INSTANCE_ID="uuid:12345678-1234-1234-1234-123456789abc"

# List attachments
curl -s "https://your-central-server/v1/projects/$PROJECT_ID/forms/$FORM_ID/submissions/$INSTANCE_ID/attachments" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[].name' \
  | while read FILENAME; do
      # Download each attachment
      curl -X GET "https://your-central-server/v1/projects/$PROJECT_ID/forms/$FORM_ID/submissions/$INSTANCE_ID/attachments/$FILENAME" \
        -H "Authorization: Bearer $TOKEN" \
        -o "$FILENAME"
      echo "Downloaded: $FILENAME"
    done
```

### Exporting Submission Data to CSV

To get submission data in CSV format, use the OData endpoint (add `.svc` to the form URL):

```bash
curl -X GET "https://your-central-server/v1/projects/$PROJECT_ID/forms/$FORM_ID.svc/Submissions" \
  -H "Authorization: Bearer $TOKEN"
```

This returns OData XML/JSON that can be converted to CSV using tools like `jq` or imported directly into Excel.

## Authentication Notes

> **Important**
> * Sessions expire after **24 hours** - check `expiresAt` field
> * If Single Sign-on (OpenID Connect) is enabled, HTTP Basic Auth and `POST /v1/sessions` are disabled
> * Bearer tokens contain only URL-safe characters - no escaping needed
> * The `Authorization` header format is: `Bearer {token}` (with space after "Bearer")

## Related

- [[client-ui-patterns]] - Frontend API usage patterns
- [[pyxform-xlsform-architecture]] - Form conversion architecture
