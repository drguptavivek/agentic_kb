---
title: ODK Central Server Architecture Patterns
type: reference
domain: ODK Central
tags:
  - odk-central
  - architecture
  - backend
  - nodejs
  - postgresql
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# ODK Central Server Architecture Patterns

This document describes the standard architecture patterns used in ODK Central backend (`central-backend` / `server` submodule).

## Overview

ODK Central backend is a Node.js RESTful API server built on:
- **Language**: Node.js (JavaScript)
- **Database**: PostgreSQL
- **HTTP Framework**: Custom service layer using dependency injection
- **SQL Query Builder**: Slonik (raw SQL with tagged templates)
- **Data Layer**: Three-tier architecture (Resources → Domain → Query)

## Three-Tier Architecture Pattern

### Layer 1: Resources (`lib/resources/*.js`)

**Purpose**: HTTP endpoint definitions and request/response handling

**Responsibilities**:
- Define HTTP routes (GET, POST, PATCH, DELETE, etc.)
- Parse request parameters, query strings, and body
- Perform authentication checks (`auth.canOrReject()`)
- Call domain layer functions
- Format responses (JSON serialization)
- Set HTTP headers (e.g., `X-Extended-Metadata`, `X-Total-Count`)

**Pattern**:
```javascript
module.exports = (service, endpoint, anonymousEndpoint) => {
  service.get('/path/:id', endpoint(
    ({ DomainModule, QueryModule }, { auth, params, queryOptions }, __, response) =>
      QueryModule.getById(params.id)
        .then(getOrNotFound)
        .then((entity) => auth.canOrReject('verb.action', entity))
        .then((entity) => entity.forApi())
  ));
};
```

**Key Patterns**:
- `service.get/post/patch/delete()` defines routes
- `endpoint()` wrapper provides DI container and request context
- `anonymousEndpoint()` for unauthenticated routes
- Promise chains for async operations
- `getOrNotFound` utility converts `Option.none()` to HTTP 404

### Layer 2: Domain (`lib/domain/*.js`)

**Purpose**: Business logic orchestration (optional layer)

**Responsibilities**:
- Coordinate complex multi-step operations
- Enforce business rules and policies
- Emit audit logs
- Validate domain-specific constraints
- Call multiple query modules if needed

**Pattern**:
```javascript
const createEntity = async (container, data, createdBy) => {
  const { EntityQuery, AuditQuery } = container;

  // Validation
  if (!data.name) throw Problem.user.missingParameter({ field: 'name' });

  // Business logic
  const entity = await EntityQuery.create(data);
  await AuditQuery.log('entity.create', createdBy, { data: entity });

  return entity;
};

module.exports = { createEntity };
```

**Key Patterns**:
- Async/await preferred for clarity
- Container object provides query modules
- Throws `Problem.*` errors for user-facing issues
- Returns domain objects or primitives

### Layer 3: Query (`lib/model/query/*.js`)

**Purpose**: Database access and raw SQL queries

**Responsibilities**:
- Execute SQL queries using Slonik
- Map database rows to domain objects (Frames)
- Handle transactions
- Define audit logging hooks

**Pattern**:
```javascript
const { sql } = require('slonik');
const { Entity } = require('../frames');

const create = (entity) => ({ run, one }) =>
  one(sql`
    INSERT INTO entities (name, "createdAt")
    VALUES (${entity.name}, NOW())
    RETURNING *
  `).then(construct(Entity));

create.audit = (entity) => (log) => log('entity.create', entity.actor, { data: entity });
create.audit.withResult = true;

module.exports = { create };
```

**Key Patterns**:
- Functions accept DI container `({ run, one, all, maybeOne })`
- `sql` tagged template for safe query building
- Audit hooks via `function.audit` property
- Return Promises resolving to Frames or primitives

## Database Patterns

### Naming Conventions

**Code Style (from database.md)**:
- **Table names**: lowercase snake_case, pluralized (`users`, `field_keys`, `form_defs`)
- **Column names**: camelCase (`actorId`, `createdAt`, `displayName`)
- **Primary keys**: auto-incrementing `serial4` (except composite keys)
- **Datetime columns**: millisecond precision `timestamptz(3)`

### Core Tables

**Actors System**:
- `actors`: Generic actor (user, field_key, public_link, singleUse)
- `users`: User accounts (email, password)
- `field_keys`: App users (project-scoped)
- `sessions`: HTTP sessions (bearer tokens)

**Access Control**:
- `actees`: UUIDs for objects that can have permissions (projects, forms, users)
- `roles`: Permission sets (admin, manager, formfill, app-user)
- `assignments`: Actor ↔ Role ↔ Actee relationships

**Forms and Submissions**:
- `forms`: Form metadata
- `form_defs`: Form versions (XML)
- `submissions`: Submission metadata
- `submission_defs`: Submission versions (XML)

### Frames Pattern

**Purpose**: Object-relational mapping via `lib/model/frames.js`

**Pattern**:
```javascript
const { Frame, readable, writable } = require('./frame');

const Entity = Frame.define(
  readable('id', 'createdAt'),
  writable('name', 'description')
);

Entity.fromApi = (data) => new Entity({ name: data.name, description: data.description });
Entity.forApi = function() { return { id: this.id, name: this.name }; };

module.exports = { Entity };
```

**Key Patterns**:
- `readable()`: Read-only fields (set by DB)
- `writable()`: User-settable fields
- `Frame.define()`: Creates immutable class
- `.with()`: Returns new instance with updated fields
- `.fromApi()`: Parse API request body
- `.forApi()`: Serialize for API response

## Dependency Injection Container

**Location**: `lib/model/container.js`

**Pattern**:
```javascript
const withDefaults = (base, queries) => {
  const defaultQueries = {
    Actors: require('./query/actors'),
    Users: require('./query/users'),
    Sessions: require('./query/sessions'),
    // ...
  };
  return injector(base, mergeRight(defaultQueries, queries));
};
```

**Usage in Endpoints**:
- DI container passed as first parameter to endpoint handlers
- Destructure needed modules: `({ Users, Sessions }, { auth, body })`
- Enables testing via mock injection

## Authentication and Authorization

### Authentication Flow

1. Client sends `Authorization: Bearer <token>` header
2. Middleware calls `Sessions.getByBearerToken(token)`
3. Token validated against `sessions` table (expiry checked)
4. Actor loaded and attached to `auth` context

### Authorization Pattern

**Resources Layer**:
```javascript
auth.canOrReject('verb.action', targetObject)
  .then(() => /* proceed */)
```

**Verbs Examples**:
- `user.create`, `user.update`, `user.password.reset`
- `project.create`, `project.update`, `project.delete`
- `form.create`, `form.update`, `submission.create`
- `config.read`, `config.set`

**Species System**:
- Each domain object has a "species" (e.g., `User.species`, `Project.species`)
- Used for system-wide permission checks (not tied to specific instance)

## Audit Logging

### Audit Hook Pattern

**Query Layer**:
```javascript
const createUser = (user) => ({ Actors }) => Actors.createSubtype(user);
createUser.audit = (user) => (log) => log('user.create', user.actor, { data: user });
createUser.audit.withResult = true;
```

**Audit Log Fields**:
- `action`: String identifier (e.g., `'user.create'`, `'form.update'`)
- `actorId`: Who performed the action
- `acteeId`: What was acted upon
- `details`: JSON payload with additional context

**Audit Table**: `audits`

## HTTP Response Patterns

### Success Response

```javascript
const { success } = require('../util/http');

return Promise.resolve(/* operation */).then(success);
// Returns: { success: true }
```

### Extended Metadata Pattern

**Client Request**:
```
X-Extended-Metadata: true
```

**Server Response**:
```javascript
service.get('/entities', endpoint(({ Entities }, { queryOptions }) => {
  const extended = queryOptions.extended;
  return Entities.getAll(queryOptions)
    .then((entities) => entities.map((e) => extended ? e.forApiExtended() : e.forApi()));
}));
```

### Pagination Headers

**Response Headers**:
- `X-Total-Count`: Total number of results matching filter (for pagination)

**Query Parameters**:
- `limit`: Number of results per page
- `offset`: Starting position

**Implementation**:
```javascript
const { page } = require('../../util/db');

const getAll = (options) => ({ all }) =>
  all(sql`SELECT * FROM entities ${page(options)}`);
```

## Error Handling

### Problem Objects

**Location**: `lib/util/problem.js`

**Pattern**:
```javascript
const Problem = require('../util/problem');

// User errors (400-level)
throw Problem.user.missingParameter({ field: 'email' });
throw Problem.user.invalidDataTypeOfParameter({ field: 'age', expected: 'integer' });
throw Problem.user.insufficientRights();

// Internal errors (500-level)
throw Problem.internal.unknown({ message: 'Database connection failed' });
```

**HTTP Status Codes**:
- `400.*`: Client validation errors
- `401.*`: Authentication failures
- `403.*`: Authorization failures
- `404.*`: Resource not found
- `500.*`: Server errors

## Standard File Structure

```
server/
├── lib/
│   ├── resources/           # HTTP endpoints
│   │   ├── users.js
│   │   ├── projects.js
│   │   └── forms.js
│   ├── model/
│   │   ├── frames.js        # Domain objects
│   │   ├── container.js     # DI setup
│   │   └── query/           # Database access
│   │       ├── users.js
│   │       ├── sessions.js
│   │       └── actors.js
│   ├── domain/              # Business logic (optional)
│   │   └── *.js
│   ├── http/
│   │   └── service.js       # Route registration
│   └── util/
│       ├── db.js            # Query helpers
│       ├── problem.js       # Error definitions
│       └── promise.js       # Promise utilities
├── test/
│   └── integration/
│       └── api/             # API tests
└── docs/                    # Documentation
```

## Migration Pattern

**Location**: `lib/model/migrations/*.js`

**Pattern**:
```javascript
exports.up = (db) =>
  db.raw(`
    CREATE TABLE entities (
      id serial PRIMARY KEY,
      name text NOT NULL,
      "createdAt" timestamptz(3) NOT NULL DEFAULT NOW()
    );
  `);

exports.down = (db) =>
  db.raw('DROP TABLE entities;');
```

**Conventions**:
- Migrations managed by Knex.js
- Files named: `YYYYMMDD-NN.revision-description.js`
- Use raw SQL for schema changes

## Related

- [[vg-customization-patterns]] - VG fork-specific patterns
- [[testing-patterns]] - Testing conventions for ODK Central

## References

- server/docs/database.md - Official database design documentation
- server/docs/standard_users_api.md - Standard API patterns
- server/lib/http/service.js - Route registration
- server/lib/model/container.js - DI container setup
