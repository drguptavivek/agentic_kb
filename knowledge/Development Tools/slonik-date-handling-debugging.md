---
title: Debugging Slonik SQL Errors with Undefined Values and Date Objects
type: howto
domain: Development Tools
tags:
  - slonik
  - postgresql
  - nodejs
  - sql
  - debugging
  - error-handling
status: approved
created: 2025-12-26
updated: 2025-12-26
---

# Debugging Slonik SQL Errors

## Problem: "TypeError: Unexpected value expression"

When using Slonik (PostgreSQL client for Node.js) with SQL template literals, you may encounter:

```
TypeError: Unexpected value expression.
    at sql (/usr/odk/node_modules/slonik/dist/src/factories/createSqlTag.js:44:19)
```

This error occurs when Slonik encounters a value it cannot serialize into SQL.

## Common Causes

### 1. Undefined Values

Slonik does **NOT** accept `undefined` in SQL template literals. It only accepts:
- `null`
- Primitive types: `string`, `number`, `boolean`
- Arrays of primitives

**Symptom**: Function called with missing optional parameters

**Fix**: Convert `undefined` to `null` using nullish coalescing:

```javascript
const normalizedValue = value ?? null;
```

**Pattern**:
```javascript
const insertRecord = (value = null) => ({ run }) => {
  const normalized = value ?? null; // Converts undefined → null
  return run(sql`INSERT INTO table (column) VALUES (${normalized})`);
};
```

### 2. Date Objects

Slonik does **NOT** accept JavaScript `Date` objects directly in SQL template literals.

**Symptom**: Passing `new Date()` or a Date from `Sessions.create()` fails

**Fix**: Convert Date to ISO string before passing to SQL:

```javascript
const normalizedDate = (date instanceof Date) ? date.toISOString() : (date ?? null);
```

**Pattern**:
```javascript
const recordSession = ({ expiresAt = null }) => ({ run }) => {
  // Convert Date object to ISO string (e.g., "2025-12-29T07:43:40.944Z")
  const normalizedExpiresAt = (expiresAt instanceof Date)
    ? expiresAt.toISOString()
    : (expiresAt ?? null);

  return run(sql`
    INSERT INTO sessions (expires_at)
    VALUES (${normalizedExpiresAt})
  `);
};
```

### 3. Object Values

Any JavaScript object (not a primitive) will cause the error.

**Common culprits**:
- Date objects
- Custom class instances
- Nested objects/arrays (unless Slonik has specific support)

## Debugging Approach

### Step 1: Add Logging

Insert logging to inspect parameter types:

```javascript
console.log('Function called with:', {
  param: typeof param,
  paramValue: param,
  isDate: param instanceof Date,
  isUndefined: param === undefined,
});
```

### Step 2: Check Type Output

Look for `typeof` results that indicate objects:
- `'object'` → likely a Date or needs conversion
- `'undefined'` → needs to become `null`
- Primitive types `'string'`, `'number'`, `'boolean'` → OK

### Step 3: Normalize Before SQL

Always normalize optional/dynamic parameters **before** the `sql` template literal:

```javascript
const normalizedIp = ip ?? null;
const normalizedUserAgent = userAgent ?? null;
const normalizedExpiresAt = (expiresAt instanceof Date)
  ? expiresAt.toISOString()
  : (expiresAt ?? null);

return run(sql`
  INSERT INTO table (ip, user_agent, expires_at)
  VALUES (${normalizedIp}, ${normalizedUserAgent}, ${normalizedExpiresAt})
`);
```

## Best Practices

### 1. Validate Required Fields

```javascript
if (token == null) throw new Error('token is required');
if (actorId == null) throw new Error('actorId is required');
```

### 2. Omit Fields with Database Defaults

If a column has a DEFAULT value (like `createdAt DEFAULT now()`), omit it from the INSERT:

```javascript
// DON'T pass createdAt - let database use DEFAULT now()
return run(sql`
  INSERT INTO sessions (token, "actorId", expires_at)
  VALUES (${token}, ${actorId}, ${expiresAt})
  -- createdAt column will use DEFAULT now()
`);
```

### 3. Use Database Functions When Possible

Instead of passing timestamps from JavaScript, use PostgreSQL functions:

```javascript
// Use clock_timestamp() instead of Date object
return run(sql`
  INSERT INTO submissions ("createdAt")
  VALUES (clock_timestamp())
`);
```

### 4. Avoid Complex PostgreSQL Types

In development, prefer simple types:
- Use `text` instead of `inet` for IP addresses
- Use `text` instead of custom types
- Simplifies handling and avoids type casting issues

## Complete Example

```javascript
const recordSession = ({
  token,
  actorId,
  ip = null,
  userAgent = null,
  expiresAt = null
}) => ({ run }) => {
  // Validate required fields
  if (token == null) throw new Error('recordSession: token is required');
  if (actorId == null) throw new Error('recordSession: actorId is required');

  // Normalize optional parameters
  const normalizedIp = ip ?? null;
  const normalizedUserAgent = userAgent ?? null;
  // Convert Date to ISO string - CRITICAL FIX
  const normalizedExpiresAt = (expiresAt instanceof Date)
    ? expiresAt.toISOString()
    : (expiresAt ?? null);

  // Now safe to use in SQL
  return run(sql`
    INSERT INTO app_sessions (token, "actorId", ip, user_agent, expires_at)
    VALUES (${token}, ${actorId}, ${normalizedIp}, ${normalizedUserAgent}, ${normalizedExpiresAt})
    ON CONFLICT (token) DO UPDATE
      SET "actorId" = EXCLUDED."actorId",
          ip = EXCLUDED.ip,
          expires_at = EXCLUDED.expires_at
  `);
};
```

## Related

- [[slonik-parameter-types]]
- [[postgresql-default-values]]
- [[date-handling-nodejs]]
