---
title: SvelteKit Full-Stack Features
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - fullstack
  - database
  - orm
  - drizzle
  - cloudflare
  - deployment
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# SvelteKit Full-Stack Features

## Overview

SvelteKit is a full-stack framework that combines the reactivity of Svelte with robust server-side rendering, routing, and backend capabilities. It provides end-to-end type safety and seamless integration between client and server code.

## Server-Side Capabilities

### Load Functions

Data fetching happens in `+page.server.ts` or `+layout.server.ts` files:

```typescript
// src/routes/dashboard/+page.server.ts
import { db } from '$lib/server/db';

export async function load({ locals }) {
  if (!locals.user) {
    redirect(302, '/login');
  }

  const users = await db.query.usersTable.findMany();
  return { users };
}
```

### Form Actions

Handle form submissions on the server:

```typescript
// src/routes/dashboard/+page.server.ts
export const actions = {
  register: async ({ request }) => {
    const data = await request.formData();
    const fullName = data.get('fullName');
    const phone = data.get('phone');

    const newUser = await db.insert(usersTable)
      .values({ fullName, phone })
      .returning();

    return { success: true, newUser };
  }
};
```

### Server Endpoints (+server.ts)

Create API endpoints:

```typescript
// src/routes/api/users/+server.ts
import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';

export async function GET() {
  const users = await db.query.usersTable.findMany();
  return json(users);
}

export async function POST({ request }) {
  const data = await request.json();
  const newUser = await db.insert(usersTable).values(data).returning();
  return json(newUser, { status: 201 });
}
```

### Remote Functions (.remote.ts)

Type-safe server calls (experimental, requires opt-in):

```typescript
// src/lib/remote/users.remote.ts
import { query, command } from '$app/server';
import * as z from 'zod';

const GetUserSchema = z.object({
  id: z.number()
});

export const getUser = query(GetUserSchema, async ({ id }) => {
  return await db.query.usersTable.findFirst({
    where: eq(usersTable.id, id)
  });
});

export const updateUser = command(GetUserSchema, async ({ id }) => {
  // Update logic
  return { success: true };
});
```

See [[sveltekit-remote-functions]] for comprehensive guide.

## Database Integration

### Drizzle ORM

Drizzle is the recommended ORM for SvelteKit, providing:
- **Type-safe queries** with TypeScript inference
- **Lightweight** compared to Prisma
- **Edge runtime compatible**
- **First-class SvelteKit integration**

**Installation:**
```bash
npm i drizzle-orm
npm i -D drizzle-kit
```

**Database Drivers:**
```bash
# PostgreSQL
npm i postgres
npm i @types/postgres

# MySQL
npm i mysql2
npm i @types/mysql2

# SQLite
npm i better-sqlite3
npm i @types/better-sqlite3

# Cloudflare D1
npm i @cloudflare/d1

# Neon (serverless Postgres)
npm i @neondatabase/serverless
```

**Schema Definition:**
```typescript
// src/lib/server/schema.ts
import { pgTable, serial, text, varchar } from 'drizzle-orm/pg-core';

export const usersTable = pgTable('users', {
  id: serial('id').primaryKey(),
  fullName: text('full_name'),
  phone: varchar('phone', { length: 256 })
});
```

**Database Connection:**
```typescript
// src/lib/server/db.ts
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { env } from '$env/static/private';

const client = postgres(env.DATABASE_URL);
export const db = drizzle(client);
```

**Drizzle Config:**
```typescript
// drizzle.config.ts
import type { Config } from 'drizzle-kit';
import { env } from '$env/static/private';

export default {
  schema: './src/lib/server/schema.ts',
  out: './drizzle',
  driver: 'pg',
  dbCredentials: {
    host: env.DB_HOST,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    database: env.DB_NAME
  }
} satisfies Config;
```

**Migrations:**
```bash
# Generate migration
npx drizzle-kit generate:pg

# Push to database
npx drizzle-kit push:pg

# Open Drizzle Studio
npx drizzle-kit studio
```

**Router Pattern for Organization:**
```typescript
// src/lib/server/router/users.ts
import { db } from '$lib/server/db';
import * as schema from '$lib/server/schema';

export type User = typeof schema.usersTable.$inferSelect;
export type NewUser = typeof schema.usersTable.$inferInsert;

export async function getAllUsers(): Promise<User[]> {
  return db.query.usersTable.findMany();
}

export async function createNewUser(user: NewUser): Promise<User> {
  const [newUser] = await db.insert(usersTable)
    .values(user)
    .returning();
  return newUser;
}
```

**Usage in Load Functions:**
```typescript
import { getAllUsers, createNewUser } from '$lib/server/router/users';

export async function load() {
  return { users: await getAllUsers() };
}
```

### Cloudflare D1 Integration

Cloudflare D1 is an edge-based SQLite database:

**Setup for Cloudflare Pages/Workers:**
```typescript
// drizzle.config.ts
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/lib/server/schema.ts',
  out: './drizzle',
  driver: 'd1',
  dbCredentials: {
    wranglerConfigPath: 'wrangler.toml',
    dbName: 'your-db-name'
  }
} satisfies Config;
```

**Schema (SQLite):**
```typescript
// src/lib/server/schema.ts
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const usersTable = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  fullName: text('full_name'),
  phone: text('phone')
});
```

**Database Connection (using platform binding):**
```typescript
// src/lib/server/db.ts
import { drizzle } from 'drizzle-orm/d1';

export function createClient(platform: App.Platform) {
  return drizzle(platform.env.DB);
}
```

**Usage in Server Code:**
```typescript
// src/routes/api/users/+server.ts
import { createClient } from '$lib/server/db';

export async function GET({ platform }) {
  const db = createClient(platform);
  const users = await db.query.usersTable.findMany();
  return json(users);
}
```

## Platform Integrations

### Cloudflare Workers

SvelteKit with Cloudflare Workers adapter provides:
- **Edge execution** for low latency
- **D1 database** for edge-based SQL
- **KV storage** for key-value data
- **R2 storage** for object storage
- **Queues** for background jobs

**Adapter Setup:**
```bash
npm install -D @sveltejs/adapter-cloudflare
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-cloudflare';

export default {
  kit: {
    adapter: adapter({
      platformProxy: {
        configPath: 'wrangler.toml',
        environment: undefined,
        experimental: {},
        persist: false
      }
    })
  }
};
```

**wrangler.toml:**
```toml
name = "your-app"
compatibility_date = "2025-01-29"

[[d1_databases]]
binding = "DB"
database_name = "your-db"
database_id = "your-database-id"

[[r2_buckets]]
binding = "BUCKET"
bucket_name = "your-bucket"
```

### Vercel

```bash
npm install -D @sveltejs/adapter-vercel
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-vercel';

export default {
  kit: {
    adapter: adapter({
      // options
    })
  }
};
```

### Netlify

```bash
npm install -D @sveltejs/adapter-netlify
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-netlify';

export default {
  kit: {
    adapter: adapter({
      edge: false, // or true for edge functions
      split: false
    })
  }
};
```

### Node.js

```bash
npm install -D @sveltejs/adapter-node
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-node';

export default {
  kit: {
    adapter: adapter({
      out: 'build',
      precompress: false,
      env: {
        host: 'HOST',
        port: 'PORT'
      }
    })
  }
};
```

### Static Site Generation

```bash
npm install -D @sveltejs/adapter-static
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-static';

export default {
  kit: {
    adapter: adapter({
      pages: 'build',
      assets: 'build',
      fallback: 'index.html',
      precompress: false,
      strict: true
    })
  }
};
```

## Server Hooks

```typescript
// src/hooks.server.ts
import type { Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';

// Auth guard
const authGuard: Handle = async ({ event, resolve }) => {
  const session = await getSession(event.cookies.get('sessionid'));

  if (session) {
    event.locals.user = session.user;
  }

  return resolve(event);
};

// Logger
const logger: Handle = async ({ event, resolve }) => {
  const startTime = Date.now();
  const response = await resolve(event);
  const duration = Date.now() - startTime;

  console.log(`${event.request.method} ${event.url.pathname} - ${response.status} (${duration}ms)`);

  return response;
};

export const handle = sequence(logger, authGuard);
```

## Error Handling

```typescript
// src/hooks.server.ts
import type { HandleServerError } from '@sveltejs/kit';

export const handleError: HandleServerError = ({ error, event }) => {
  console.error('Error:', error);

  return {
    message: 'An unexpected error occurred',
    code: error?.code || 'UNKNOWN'
  };
};
```

## Type Safety

### App.Locals

```typescript
// src/app.d.ts
import type { User } from '$lib/types';

declare global {
  namespace App {
    interface Locals {
      user?: User;
      session?: Session;
    }
    interface Platform {
      env?: {
        DB: D1Database;
        BUCKET: R2Bucket;
      };
    }
  }
}

export {};
```

### PageData

```typescript
// src/routes/dashboard/+page.server.ts
export async function load() {
  return {
    users: await getAllUsers(),
    timestamp: new Date().toISOString()
  };
}
```

```typescript
// src/routes/dashboard/+page.svelte
<script lang="ts">
  import type { PageData } from './$types';

  export let data: PageData;
  // data.users is typed!
</script>
```

## Best Practices

1. **Use `src/lib/server`** for server-only code (database, API calls)
2. **Organize with router pattern** for large apps
3. **Use environment variables** via `$env/static/private` for secrets
4. **Implement proper error handling** in hooks and endpoints
5. **Use standard schema validation** for all inputs
6. **Leverage type inference** from Drizzle schemas
7. **Keep remote functions guarded** with auth checks
8. **Use migrations** for schema changes, never manual DB edits
9. **Test database interactions** with mock databases in unit tests
10. **Choose the right adapter** for your deployment target

## Common Patterns

### Auth with Database

```typescript
// src/lib/server/auth.ts
import { db } from './db';
import { usersTable } from './schema';
import { eq } from 'drizzle-orm';

export async function getUserByEmail(email: string) {
  const [user] = await db
    .select()
    .from(usersTable)
    .where(eq(usersTable.email, email));
  return user;
}

export async function createUser(data: NewUser) {
  const [user] = await db
    .insert(usersTable)
    .values(data)
    .returning();
  return user;
}
```

### File Upload with R2

```typescript
// src/routes/api/upload/+server.ts
import { json } from '@sveltejs/kit';

export async function POST({ platform, request }) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  await platform.env.BUCKET.put(file.name, file.stream());

  return json({ success: true, url: `/files/${file.name}` });
}
```

## Performance Considerations

1. **Edge execution:** Cloudflare Workers/Edges for lowest latency
2. **Query batching:** Use `query.batch` for multiple queries
3. **Caching:** Leverage SvelteKit's built-in caching
4. **Database connections:** Use connection pooling for Node.js
5. **Prerendering:** For static content, use `export const prerender = true`

## References

- <https://orm.drizzle.team/>
- <https://developers.cloudflare.com/d1/>
- <https://sveltekit.io/blog/drizzle-sveltekit-integration>
- <https://kit.svelte.dev/docs/adapter-cloudflare>

## Related

- [[sveltekit-remote-functions]]
- [[sveltekit-hooks]]
- [[sveltekit-auth-best-practices]]
- [[drizzle-orm-goodies]]
- [[drizzle-orm-migrations]]
- [[standard-schema-validation]]
