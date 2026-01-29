---
title: Better Auth Installation & Configuration
type: howto
domain: Development Tools
tags:
  - auth
  - better-auth
  - installation
  - env
  - database
  - configuration
status: approved
created: 2025-12-25
updated: 2025-01-29
---

# Better Auth Installation & Configuration

## Overview

Better Auth is a framework-agnostic, universal authentication and authorization framework for TypeScript. It provides comprehensive features out of the box with a plugin ecosystem for advanced functionalities. <https://www.better-auth.com/docs>

**Key Features:**
- Framework agnostic (React, Vue, Svelte, Solid, Next.js, Nuxt, Remix, etc.)
- Email & Password authentication
- Social sign-on providers
- Account & Session management
- Built-in rate limiter
- Automatic database management
- Organization & Access control
- Two Factor Authentication
- Extensive plugin ecosystem

## Quick Start

### 1. Install the Package

```bash
npm install better-auth
```

If you're using separate client and server packages, install in both.

### 2. Set Environment Variables

Create a `.env` file in your project root:

```bash
# Generate with: openssl rand -base64 32
BETTER_AUTH_SECRET=your-secret-key-at-least-32-chars

# Base URL of your app
BETTER_AUTH_URL=http://localhost:3000
```

**Important:** The secret must be at least 32 characters with high entropy.

### 3. Create Auth Instance

Create `auth.ts` in one of these locations:
- Project root
- `lib/` folder
- `utils/` folder
- Nested under `src/`, `app/`, or `server/`

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth";

export const auth = betterAuth({
  // configuration options
});
```

**Important:** Export as `auth` or as default export.

### 4. Configure Database

Better Auth requires a database. Supported options:

#### Direct Database Connection

```typescript
// SQLite
import Database from "better-sqlite3";

export const auth = betterAuth({
  database: new Database("./sqlite.db"),
});

// PostgreSQL
import { Pool } from "pg";

export const auth = betterAuth({
  database: new Pool({
    host: "localhost",
    user: "user",
    password: "password",
    database: "dbname",
  }),
});

// MySQL
import { createPool } from "mysql2/promise";

export const auth = betterAuth({
  database: createPool({
    host: "localhost",
    user: "user",
    password: "password",
    database: "dbname",
  }),
});
```

#### ORM Adapters

```typescript
// Drizzle
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { db } from "@/db";

export const auth = betterAuth({
  database: drizzleAdapter(db, {
    provider: "pg", // "mysql" | "sqlite"
  }),
});

// Prisma
import { prismaAdapter } from "better-auth/adapters/prisma";
import { PrismaClient } from "@/generated/prisma/client";

const prisma = new PrismaClient();
export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "sqlite", // "mysql" | "postgresql"
  }),
});

// MongoDB
import { mongodbAdapter } from "better-auth/adapters/mongodb";
import { client } from "@/db";

export const auth = betterAuth({
  database: mongodbAdapter(client),
});
```

**Stateless Mode:** Available without database, but most plugins require a database.

### 5. Create Database Tables

Better Auth includes a CLI tool for schema management:

```bash
# Generate ORM schema or SQL migration file
npx @better-auth/cli generate

# Create tables directly in database (Kysely adapter only)
npx @better-auth/cli migrate
```

For manual schema creation, see the database section of the docs.

### 6. Configure Authentication Methods

```typescript
export const auth = betterAuth({
  emailAndPassword: {
    enabled: true,
    // sendResetPassword: async ({ user, url }) => {
    //   await sendEmail(user.email, url);
    // },
    // sendVerificationEmail: async ({ user, url }) => {
    //   await sendEmail(user.email, url);
    // },
  },
  socialProviders: {
    github: {
      clientId: process.env.GITHUB_CLIENT_ID as string,
      clientSecret: process.env.GITHUB_CLIENT_SECRET as string,
    },
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID as string,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
    },
  },
});
```

### 7. Mount Handler

Create a catch-all route for `/api/auth/*` (or your configured base path).

#### SvelteKit

```typescript
// hooks.server.ts
import { auth } from "$lib/auth";
import { svelteKitHandler } from "better-auth/svelte-kit";
import { building } from '$app/environment';

export async function handle({ event, resolve }) {
  return svelteKitHandler({ event, resolve, auth, building });
}
```

#### Next.js App Router

```typescript
// app/api/auth/[...all]/route.ts
import { auth } from "@/lib/auth";
import { toNextJsHandler } from "better-auth/next-js";

export const { POST, GET } = toNextJsHandler(auth);
```

#### Next.js Pages Router

```typescript
// pages/api/auth/[...all].ts
import { auth } from "@/lib/auth";
import { toNodeHandler } from "better-auth/node";

export const config = { api: { bodyParser: false } };
export default toNodeHandler(auth.handler);
```

#### Nuxt

```typescript
// server/api/auth/[...all].ts
import { auth } from "~/utils/auth";

export default defineEventHandler((event) => {
  return auth.handler(toWebRequest(event));
});
```

#### Remix

```typescript
// app/routes/api.auth.$.ts
import { auth } from '~/lib/auth.server';
import type { LoaderFunctionArgs, ActionFunctionArgs } from "@remix-run/node";

export async function loader({ request }: LoaderFunctionArgs) {
  return auth.handler(request);
}

export async function action({ request }: ActionFunctionArgs) {
  return auth.handler(request);
}
```

#### Cloudflare Workers

**Important:** Add to `wrangler.toml` for AsyncLocalStorage support:

```toml
compatibility_flags = ["nodejs_compat"]
compatibility_date = "2024-09-23"
```

```typescript
// src/index.ts
import { auth } from "./auth";

export default {
  async fetch(request: Request) {
    const url = new URL(request.url);

    if (url.pathname.startsWith("/api/auth")) {
      return auth.handler(request);
    }

    return new Response("Not found", { status: 404 });
  },
};
```

#### Express v5

**Important:** Express v5 uses named wildcard syntax:

```typescript
import express from "express";
import { toNodeHandler } from "better-auth/node";
import { auth } from "./auth";

const app = express();

app.all("/api/auth/{*any}", toNodeHandler(auth));

// Mount express json middleware after Better Auth handler
app.use(express.json());

app.listen(8000);
```

#### Astro

```typescript
// pages/api/auth/[...all].ts
import type { APIRoute } from "astro";
import { auth } from "@/auth";

export const GET: APIRoute = async (ctx) => {
  return auth.handler(ctx.request);
};

export const POST: APIRoute = async (ctx) => {
  return auth.handler(ctx.request);
};
```

### 8. Create Client Instance

#### React

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  baseURL: "http://localhost:3000", // optional if same domain
});
```

#### Vue

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/vue";

export const authClient = createAuthClient({
  baseURL: "http://localhost:3000",
});
```

#### Svelte

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/svelte";

export const authClient = createAuthClient({
  baseURL: "http://localhost:3000",
});
```

#### Solid

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/solid";

export const authClient = createAuthClient({
  baseURL: "http://localhost:3000",
});
```

#### Vanilla

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/client";

export const authClient = createAuthClient({
  baseURL: "http://localhost:3000",
});
```

**Alternative - Export specific methods:**

```typescript
export const { signIn, signUp, useSession } = createAuthClient();
```

## Configuration Options

### Advanced Configuration

```typescript
export const auth = betterAuth({
  // Database
  database: drizzleAdapter(db),

  // Base configuration
  baseURL: "http://localhost:3000",
  baseURL: "/api/auth", // Custom base path

  // Security
  secret: process.env.BETTER_AUTH_SECRET,
  trustedOrigins: ["http://localhost:3000"],

  // Session management
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 days
    updateAge: 60 * 60 * 24, // 1 day
    cookieCache: {
      enabled: true,
      maxAge: 5 * 60, // 5 minutes
    },
  },

  // Advanced
  advanced: {
    generateId: () => crypto.randomUUID(),
    cookiePrefix: "better-auth",
    crossSubDomainCookies: {
      enabled: true,
    },
  },

  // Email & Password
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: false,
    sendResetPassword: async ({ user, url }) => {
      // Send password reset email
    },
    sendVerificationEmail: async ({ user, url }) => {
      // Send verification email
    },
    password: {
      min: 8,
      max: 32,
      requireNumbers: true,
      requireSpecialChar: true,
    },
  },

  // Social providers
  socialProviders: {
    github: {
      clientId: process.env.GITHUB_CLIENT_ID as string,
      clientSecret: process.env.GITHUB_CLIENT_SECRET as string,
    },
  },

  // Rate limiting
  rateLimit: {
    window: 10, // seconds
    max: 100, // requests per window
    standardMiddleware: true,
  },

  // Plugins
  plugins: [
    // Add plugins here
  ],
});
```

## Advanced Features

### Trusted Origins

Configure trusted origins for security:

```typescript
export const auth = betterAuth({
  trustedOrigins: [
    "http://localhost:3000",
    "https://yourdomain.com",
  ],
});
```

### Custom Cookie Configuration

```typescript
export const auth = betterAuth({
  session: {
    cookie: {
      name: "session",
      attributes: {
        secure: true,
        sameSite: "lax",
        httpOnly: true,
      },
    },
  },
});
```

### Secondary Storage

For edge deployments with limited cookie size:

```typescript
export const auth = betterAuth({
  secondaryStorage: {
    enabled: true,
    provider: "database", // or "redis"
    redisOptions: {
      host: "localhost",
      port: 6379,
    },
  },
});
```

## Development Tools

### CLI Commands

```bash
# Generate schema
npx @better-auth/cli generate

# Run migrations
npx @better-auth/cli migrate

# Add MCP server for AI integration
npx @better-auth/cli mcp --cursor
npx @better-auth/cli mcp --claude-code
npx @better-auth/cli mcp --manual
```

### Drizzle Studio

```bash
# Open Drizzle Studio to view database
npx drizzle-kit studio
```

## Best Practices

1. **Environment Variables:** Always use environment variables for sensitive data
2. **HTTPS:** Use HTTPS in production for secure cookie handling
3. **Trusted Origins:** Configure trusted origins to prevent CSRF attacks
4. **Rate Limiting:** Enable rate limiting to prevent abuse
5. **Email Verification:** Require email verification for production apps
6. **Session Management:** Configure appropriate session expiration
7. **Plugin Order:** Keep cookie-related plugins as the last plugin
8. **Secret Generation:** Use `openssl rand -base64 32` for secure secret generation

## Migration from Auth.js

Better Auth provides a migration guide for Auth.js users: <https://authjs.dev/getting-started/migrate-to-better-auth>

## References

- <https://www.better-auth.com/docs/installation>
- <https://www.better-auth.com/docs>

## Related

- [[better-auth-sveltekit-integration]]
- [[better-auth-plugins]]
- [[sveltekit-auth-best-practices]]
