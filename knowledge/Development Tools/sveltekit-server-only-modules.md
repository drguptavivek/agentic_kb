---
title: SvelteKit Server-Only Modules
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - server-only
  - security
  - env
  - private
  - secrets
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# SvelteKit Server-Only Modules

## Overview

Server-only modules prevent sensitive data (like API keys, database credentials, secrets) from accidentally leaking into client-side JavaScript. SvelteKit enforces this at build time by throwing an error when client code imports server-only modules. <https://svelte.dev/docs/kit/server-only-modules>

## Built-in Server-Only Modules

### Private Environment Variables

The `$env` modules provide controlled access to environment variables:

| Module | Where It Can Be Imported | What It Contains |
|--------|------------------------|-------------------|
| `$env/static/private` | Server-only | Build-time private env vars (API keys, secrets) |
| `$env/dynamic/private` | Server-only | Runtime private env vars (database URLs) |
| `$env/static/public` | Anywhere | Public env vars (site URL, feature flags) |
| `$env/dynamic/public` | Anywhere | Runtime public env vars |

**Usage:**
```typescript
// ✅ OK - In +page.server.js
import { SECRET_KEY } from '$env/static/private';

// ✅ OK - In hooks.server.js
import { DATABASE_URL } from '$env/dynamic/private';

// ❌ ERROR - In +page.svelte
import { SECRET_KEY } from '$env/static/private';
// Error: Cannot import $env/static/private into code that runs in the browser
```

### Server Utilities

The `$app/server` module contains utilities that only work on the server:

```typescript
import { read } from '$app/server';

// Read files from filesystem
const content = await read('./file.txt');
```

## Making Your Own Modules Server-Only

You can mark your own modules as server-only in two ways:

### Method 1: `.server` File Extension

Add `.server` before the file extension:

```
src/lib/
  ├── secrets.server.ts     ✅ Server-only
  ├── database.server.ts    ✅ Server-only
  └── utils.ts              ❌ Public (can be imported anywhere)
```

### Method 2: `$lib/server` Directory

Place files in a `server` subdirectory:

```
src/lib/
  ├── server/
  │   ├── secrets.ts        ✅ Server-only
  │   └── database.ts       ✅ Server-only
  └── utils.ts              ❌ Public
```

**Both methods work the same way** - choose based on your preference:
- `.server` extension - Good for mixed directories
- `$lib/server` directory - Good for organizing many server modules

## How It Works

SvelteKit tracks the import chain and throws an error if **any** public-facing code (directly or indirectly) imports server-only code.

### Import Chain Example

```typescript
// $lib/server/secrets.ts
export const API_KEY = 'sk-live-...';  // ✅ Server-only

// src/routes/utils.ts
export { API_KEY } from '$lib/server/secrets.ts';  // ❌ Imports server-only
export const add = (a, b) => a + b;

// src/routes/+page.svelte
<script>
  import { add } from './utils.js';  // ❌ Error!
  // Even though we only use `add`, the import chain includes server-only code
</script>
```

**Error Message:**
```
Cannot import $lib/server/secrets.ts into code that runs in the browser,
as this could leak sensitive information.

src/routes/+page.svelte imports
  src/routes/utils.js imports
     $lib/server/secrets.ts

If you're only using the import as a type, change it to `import type`.
```

### Dynamic Imports

Server-only enforcement works with dynamic imports too:

```svelte
<script>
  // ❌ ERROR - Even dynamic imports are checked
  const module = await import(`./${name}.js`);
</script>
```

## Type-Only Imports

If you only need the type (not the value), use `import type`:

```typescript
// ✅ OK - Type-only import
import type { User } from '$lib/server/types.server.ts';

// ❌ ERROR - Value import
import { User } from '$lib/server/types.server.ts';
```

This is commonly used for shared type definitions:

```typescript
/// file: $lib/server/types.server.ts
export interface User {
  id: string;
  name: string;
}

/// file: +page.svelte
<script>
  // ✅ OK - Only importing the type
  import type { User } from '$lib/server/types.server.ts';

  let users: User[] = [];
</script>
```

## Common Patterns

### Database Client

```typescript
/// file: $lib/server/database.server.ts
import { drizzle } from 'drizzle-orm/postgres-js';
import { env } from '$env/dynamic/private';

const client = drizzle({ url: env.DATABASE_URL });

export { client };

/// file: +page.server.js
import { client } from '$lib/server/database.server.js';  // ✅ OK

export async function load() {
  const users = await client.query.users.findMany();
  return { users };
}
```

### API Client with Secrets

```typescript
/// file: $lib/server/api.server.ts
import { env } from '$env/static/private';

export async function fetchFromAPI() {
  const response = await fetch('https://api.example.com', {
    headers: {
      'Authorization': `Bearer ${env.API_KEY}`
    }
  });

  return response.json();
}

/// file: +page.server.js
import { fetchFromAPI } from '$lib/server/api.server.js';  // ✅ OK

export async function load() {
  const data = await fetchFromAPI();
  return { data };
}
```

### Utility Functions

```typescript
/// file: $lib/server/hash.server.ts
import { createHash } from 'crypto';

export function hashPassword(password: string): string {
  return createHash('sha256').update(password).digest('hex');
}

/// file: hooks.server.js
import { hashPassword } from '$lib/server/hash.server.js';  // ✅ OK

export async function handle({ event, resolve }) {
  // Use hashPassword
}
```

### Shared Types

```typescript
/// file: $lib/server/types.server.ts
export interface User {
  id: string;
  name: string;
  email: string;
}

/// file: $lib/client.ts
// ✅ OK - Type-only import
import type { User } from '$lib/server/types.server.ts';

export function formatUser(user: User): string {
  return `${user.name} (${user.email})`;
}

/// file: +page.svelte
<script>
  import type { User } from '$lib/server/types.server.js';  // ✅ OK
  import { formatUser } from '$lib/client';

  let { data } = $props<{ data: User }>();
</script>
```

## Testing

Server-only enforcement is **disabled during tests** when `process.env.TEST === 'true'`. This allows testing frameworks like Vitest to import modules regardless of their location.

```bash
# Vitest automatically sets TEST=true
vitest
```

```javascript
// vitest.config.js
export default {
  test: {
    env: {
      TEST: 'true'  // Disables server-only checks
    }
  }
};
```

## Migration from Legacy Patterns

### Before: Manual Checking

```typescript
/// file: $lib/secrets.ts
export const API_KEY = 'sk-live-...';

/// file: +page.svelte
<script>
  // Oops! Accidentally imported secrets
  import { API_KEY } from '$lib/secrets';
  console.log(API_KEY);  // LEAKED!
</script>
```

### After: Enforced Safety

```typescript
/// file: $lib/secrets.server.ts
export const API_KEY = 'sk-live-...';

/// file: +page.svelte
<script>
  import { API_KEY } from '$lib/secrets.server.ts';  // ❌ Build error!
</script>
```

```typescript
/// file: +page.server.js
import { API_KEY } from '$lib/secrets.server.ts';  // ✅ OK

export async function load() {
  // Use API_KEY safely
}
```

## Best Practices

### 1. Default to Server-Only for Sensitive Data

When creating modules that handle sensitive data, **always** use `.server` extension or place in `$lib/server`:

```typescript
// ✅ Good - Server-only by default
/// file: $lib/payment.server.ts
import Stripe from 'stripe';

export const stripe = new Stripe(env.STRIPE_SECRET_KEY);
```

### 2. Use Type-Only Imports for Shared Types

Keep type definitions in `.server.ts` files but import with `import type`:

```typescript
/// file: $lib/server/types.server.ts
export interface PaymentIntent {
  amount: number;
  currency: string;
}

/// file: +page.svelte
<script>
  import type { PaymentIntent } from '$lib/server/types.server.ts';
</script>
```

### 3. Organize by Concern

```
src/lib/
├── server/                 # All server-only modules
│   ├── database/
│   │   └── client.ts
│   ├── auth/
│   │   └── session.ts
│   └── api/
│       └── client.ts
├── components/             # Svelte components (can be server-only)
└── utils.ts                # Shared utilities
```

### 4. Document Server-Only Dependencies

If a public module depends on server-only code, document the dependency:

```typescript
/// file: $lib/utils.ts
/**
 * This module MUST only be imported on the server.
 * It imports from $lib/server/database.server.ts
 */

// This will cause build errors if imported from client code
export { query } from './server/database.server';
```

### 5. Use Environment Variables Properly

```typescript
// ✅ Good - Private env in server-only module
/// file: $lib/server/api.server.ts
import { env } from '$env/static/private';
export const API_KEY = env.API_KEY;

// ❌ Bad - Private env in public module
/// file: $lib/api.ts
import { env } from '$env/static/private';  // ERROR!
export const API_KEY = env.API_KEY;
```

## Troubleshooting

### Error: "Cannot import ... into code that runs in the browser"

This means you have an import chain from client code to server-only code:

1. **Find the import chain** in the error message
2. **Check what you actually need** from the server-only module
3. **Move non-sensitive code** to a public module
4. **Use `import type`** if you only need types

### Example Fix

```typescript
// ❌ Before - Error!
/// file: $lib/server.ts
export const SECRET = 'hidden';
export const add = (a, b) => a + b;

/// file: +page.svelte
<script>
  import { add } from '$lib/server';  // ERROR! imports SECRET too
</script>
```

```typescript
// ✅ After - Separated
/// file: $lib/server.server.ts
export const SECRET = 'hidden';

/// file: $lib/math.ts
export const add = (a, b) => a + b;

/// file: +page.svelte
<script>
  import { add } from '$lib/math';  // OK!
</script>
```

## Security Benefits

Server-only modules provide **defense in depth**:

1. **Build-time enforcement** - Can't accidentally leak secrets
2. **Code review safety** - Clear separation of server/client code
3. **Type safety** - TypeScript prevents accidental usage
4. **Documentation** - `.server` suffix clearly marks sensitive code

**Remember:** Server-only modules are a safety net, not a replacement for proper security practices. Always:
- Never log sensitive data
- Use proper secrets management
- Follow principle of least privilege
- Audit your dependencies

## References

- <https://svelte.dev/docs/kit/server-only-modules>
- <https://svelte.dev/docs/kit/environment-variables>

## Related

- [[sveltekit-auth-best-practices]]
- [[sveltekit-hooks]]
- [[sveltekit-loading-data]]
