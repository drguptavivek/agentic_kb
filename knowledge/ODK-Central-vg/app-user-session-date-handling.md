---
title: App User Session Date Handling in ODK Central Server
type: reference
domain: ODK-Central-vg
tags:
  - odk-central
  - vg-fork
  - app-users
  - sessions
  - slonik
  - date-handling
  - nodejs
status: approved
created: 2025-12-26
updated: 2025-12-26
---

# App User Session Date Handling

## Context

ODK Central server uses Slonik (PostgreSQL client) for database operations. When creating app user sessions (used for authentication from ODK Collect Android app), date/timestamp values must be handled carefully.

## Session Creation Flow

### 1. Session Object Creation

When user logs in, a session is created via `Sessions.create()`:

```javascript
const session = await Sessions.create({ id: record.actorId }, expiresAt);
// Returns: { token, createdAt (Date), expiresAt (Date) }
```

The `Sessions.create()` method returns:
- `token`: string (unique session identifier)
- `createdAt`: JavaScript Date object (when session was created)
- `expiresAt`: JavaScript Date object (when session expires)

### 2. Recording Session to Database

The session is recorded to `vg_app_user_sessions` table:

```javascript
await VgAppUserAuth.recordSession({
  token: session.token,
  actorId: record.actorId,
  ip,
  userAgent,
  deviceId,
  comments,
  createdAt: session.createdAt,  // ⚠️ Date object
  expiresAt: session.expiresAt    // ⚠️ Date object
});
```

## The Problem

Slonik cannot directly serialize JavaScript `Date` objects in SQL template literals. This causes:

```
TypeError: Unexpected value expression
```

## The Solution

In `recordSession()` query function:

1. **Omit `createdAt`** - Let database use DEFAULT value of `now()`
2. **Convert `expiresAt` to ISO string** - Before passing to SQL

### Implementation

```javascript
const recordSession = ({
  token,
  actorId,
  ip = null,
  userAgent = null,
  deviceId = null,
  comments = null,
  createdAt = null,
  expiresAt = null
}) => ({ run }) => {
  // Normalize undefined to null
  const normalizedIp = ip ?? null;
  const normalizedUserAgent = userAgent ?? null;
  const normalizedDeviceId = deviceId ?? null;
  const normalizedComments = comments ?? null;

  // ✓ Convert Date to ISO string for Slonik
  const normalizedExpiresAt = (expiresAt instanceof Date)
    ? expiresAt.toISOString()
    : (expiresAt ?? null);

  return run(sql`
    INSERT INTO vg_app_user_sessions (token, "actorId", ip, user_agent, device_id, comments, expires_at)
    VALUES (${token}, ${actorId}, ${normalizedIp}, ${normalizedUserAgent}, ${normalizedDeviceId}, ${normalizedComments}, ${normalizedExpiresAt})
    ON CONFLICT (token) DO UPDATE
      SET "actorId" = EXCLUDED."actorId",
          ip = EXCLUDED.ip,
          user_agent = EXCLUDED.user_agent,
          device_id = EXCLUDED.device_id,
          comments = EXCLUDED.comments,
          expires_at = EXCLUDED.expires_at
  `);
};
```

## Database Schema

The `vg_app_user_sessions` table expects:

```sql
CREATE TABLE vg_app_user_sessions (
  id bigserial PRIMARY KEY,
  token text NOT NULL UNIQUE,
  "actorId" integer NOT NULL REFERENCES actors(id) ON DELETE CASCADE,
  ip text NULL,
  user_agent text NULL,
  device_id text NULL,
  comments text NULL,
  "createdAt" timestamptz NOT NULL DEFAULT now(),  -- ✓ Has DEFAULT
  expires_at timestamptz NULL                       -- ✓ Accepts NULL or ISO string
);
```

## Key Points

### createdAt Column

- Has **DEFAULT value** of `now()`
- We **omit it** from INSERT statement
- Database automatically sets to current timestamp
- **Don't pass** from application code

### expiresAt Column

- No DEFAULT value
- **Must be provided** by application
- **Convert Date to ISO string**: `date.toISOString()`
- ISO format example: `"2025-12-29T07:43:40.944Z"`
- PostgreSQL `timestamptz` accepts ISO strings

### IP Address

- Column type is `text` (not `inet` for simplicity)
- Accept IP as string from request headers
- Example: `"::ffff:172.25.0.9"` (IPv6-mapped IPv4)

### Comments Field

- Stores JSON metadata as text
- Example: `'{"manufacturer":"Google","model":"sdk_gphone64_arm64"}'`
- Store as string, parse on retrieval

## Android App Integration

When ODK Collect logs in, it provides:

```javascript
{
  username: string,
  password: string,
  ip: "::ffff:172.25.0.9",          // From request headers
  userAgent: "okhttp/5.1.0",        // From User-Agent header
  deviceId: "collect:pNh0SZK7UZWNYSS7",
  comments: '{"manufacturer":"Google",...}',
  projectId: number (optional)
}
```

All these values are **strings or null** - no Date objects from the client.

## Testing

### Login Success Response

HTTP 200 with session token:

```json
{
  "id": 16,
  "token": "XAOiE7wOmuXn3LEWOebEm4g0FyV7UV4mGGRDo0yXs5FUyOJZsE3mXzIqopGmLpZo",
  "projectId": 1,
  "expiresAt": "2025-12-29T07:43:40.944Z"
}
```

### Session Database Record

```
id        | 42
token     | XAOiE7wOmuXn3LEWOebEm4g0FyV7UV4mGGRDo0yXs5FUyOJZsE3mXzIqopGmLpZo
actorId   | 16
ip        | ::ffff:172.25.0.9
user_agent| okhttp/5.1.0
device_id | collect:pNh0SZK7UZWNYSS7
createdAt | 2025-12-26 07:43:40.944+00 (set by DEFAULT now())
expires_at| 2025-12-29 07:43:40.944+00 (from normalized ISO string)
```

## Related

- [[ODK-Central-vg/app-user-api]] - Session management API endpoints
- [[ODK-Central-vg/implementation]] - VG app user auth implementation
