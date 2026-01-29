---
title: Svelte Hydratable Data
type: reference
domain: Development Tools
tags:
  - svelte
  - hydration
  - ssr
  - hydratable
  - performance
  - remote-functions
  - security
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Svelte Hydratable Data

## Overview

`hydratable` is a low-level Svelte API that solves the performance problem of redoing asynchronous work during client-side hydration. When you `await` data in a component during SSR, Svelte normally has to redo that async work on the client, blocking hydration. `hydratable` allows you to serialize and stash the result on the server, then retrieve it during hydration instead of redoing the work. <https://svelte.dev/docs/svelte/hydratable>

This is a **library author API** - most developers will use it indirectly through data-fetching libraries like SvelteKit remote functions.

## Basic Usage

### Problem: Double Data Fetching

```svelte
<script>
  import { getUser } from 'my-database-library';

  // This fetches user on server AND again on client
  // Hydration is blocked until the second fetch completes
  const user = await getUser();
</script>

<h1>{user.name}</h1>
```

### Solution: Using `hydratable`

```svelte
<script>
  import { hydratable } from 'svelte';
  import { getUser } from 'my-database-library';

  // Fetches on server, serializes result, bakes into <head>
  // During hydration, retrieves serialized data instead of refetching
  const user = await hydratable('user', () => getUser());
</script>

<h1>{user.name}</h1>
```

## How It Works

### Server-Side (SSR)

1. Function executes and produces a result
2. Result is serialized using `devalue` (supports Map, Set, URL, BigInt, Promises)
3. Serialized data is associated with the provided key
4. Data is baked into an inline `<script>` tag in the `<head>` of the HTML
5. Script includes the serialized payload and the key to identify it

### Client-Side (Hydration)

1. Component renders and calls the `hydratable` function
2. Svelte checks for stashed data by key in the `<head>`
3. If found, deserializes the data and returns it immediately (no async work)
4. If not found (post-hydration), the function executes normally

### Post-Hydration

After hydration completes, subsequent calls to the `hydratable` function will invoke the function directly (normal behavior).

## Real-World Use Cases

### 1. SvelteKit Remote Functions

This is the primary use case for `hydratable` in SvelteKit:

```typescript
// src/lib/remote/users.remote.ts
import { query } from '$app/server';
import { db } from '$lib/db';
import { users } from '$lib/schema';

export const getUser = query(async ({ id }: { id: string }) => {
  return await db.select().from(users).where(eq(users.id, id)).get();
});
```

The `query` function automatically wraps the fetch in a `hydratable` call, so:
- Server: Fetches from DB, serializes result, includes in response
- Client: Deserializes result directly from the response, no DB call

### 2. Stable Random/Time-Based Values

Generate values that are stable between server and hydration:

```svelte
<script>
  import { hydratable } from 'svelte';

  // Random number that doesn't change on hydration
  const randomId = hydratable('randomId', () => Math.random().toString(36));
</script>

<p>Your ID: {randomId}</p>
```

### 3. Stable Timestamps

```svelte
<script>
  import { hydratable } from 'svelte';

  const timestamp = hydratable('timestamp', () => Date.now());
</script>

<p>Generated at: {new Date(timestamp).toISOString()}</p>
```

### 4. Multiple Promises

You can fearlessly use promises - Svelte handles them with `devalue`:

```svelte
<script>
  import { hydratable } from 'svelte';

  const promises = hydratable('data', () => {
    return {
      one: Promise.resolve(1),
      two: Promise.resolve(2),
    };
  });
</script>

{#await promises.one}
{#await promises.two}
```

## Serialization

`hydratable` uses Svelte's `devalue` serializer under the hood. Supported types:

### Primitive Types
- `string`, `number`, `boolean`, `null`, `undefined`
- `BigInt`, `Date`

### Data Structures
- `Array`, `Set`, `Map`, `TypedArray`
- `Object` (including nested structures)

### Special Types
- `URL` instances
- `RegExp` instances
- `Error` instances
- `Promise` (all settled promises are serialized)
- Custom classes (if serializable by `devalue`)

**Important:** All data must be serializable. If you have non-serializable data (e.g., functions, closures), they will be lost.

## Security Considerations

### CVE-2025-15265: XSS via hydratable (PATCHED)

**Versions Affected:** Svelte 5.46.0 - 5.46.3
**Patched Version:** 5.46.4

**The Vulnerability:**
- Using `hydratable` with **unsanitized, user-controlled strings** as keys
- If an attacker can inject controlled keys into `hydratable`, they can XSS other users
- The serialized data includes the keys, so malicious keys returned to another user are vulnerable

**Example Vulnerable Code:**

```svelte
<!-- DON'T DO THIS - VULNERABLE TO XSS -->
<script>
  import { hydratable } from 'svelte';
  import { getUser } from './api';

  // User-controlled key - VULNERABLE!
  const user = await hydratable(userId, () => getUser(userId));
</script>
```

**Safe Usage:**
```svelte
<!-- DO THIS - Use library-provided, prefixed keys -->
<script>
  import { hydratable } from 'svelte';
  import { getUser } from './api';

  // Library-controlled, safe key
  const user = await hydratable('user:myapp:v1', () => getUser());
</script>
```

**Best Practices:**
1. **Never use user input as keys** - always use static strings
2. **Prefix your keys** with your library/app name to avoid collisions
3. **Validate and sanitize** any data that will be serialized
4. **Keep keys simple** - use alphanumeric characters and hyphens
5. **Use versioned keys** (e.g., `user:v1`, `user:v2`) when structure changes

### Key Naming

```typescript
// GOOD - Library-prefixed, versioned keys
hydratable('myapp:user:v1', () => getUser(userId));

// GOOD - Static, descriptive keys
hydratable('currentUser', () => getCurrentUser());

// BAD - User-controlled key (XSS vulnerable)
hydratable(userId, () => getUser(userId)); // ❌ Vulnerable!

// BAD - Dynamic keys from untrusted source
hydratable(`user:${userId}`, () => getUser(userId)); // ❌ Vulnerable!
```

## CSP (Content Security Policy)

The `hydratable` feature adds an inline `<script>` to the `<head>`. If you use CSP, provide a nonce or hash.

### Using CSP with render() (Svelte 5.46+)

**Latest Approach (Recommended):**

```typescript
import { render } from 'svelte/server';

const nonce = crypto.randomUUID();

const { head, body } = render(App, {
  props: { /* ... */ },
  csp: {
    nonce,
  },
});

// Add nonce to CSP header
const cspHeader = `script-src 'nonce-${nonce}'`;
```

**Using Hashes (Static HTML):**

```typescript
const { head, body, hashes } = render(App, {
  csp: {
    hash: true,
  },
});

// hashes.script will be like ["sha256-abcd1234..."]
const cspHeader = `script-src ${hashes.script.map(h => `'${h}'`).join(' ')}`;
```

**Note:** Nonce is preferred over hash for dynamic SSR. Hashes are only for static builds.

### Using Nonce (Legacy)

`hydratable` adds an inline `<script>` to the `<head>`. If you use CSP, provide a nonce:

```typescript
// Server-side
import { render } from 'svelte/server';

const nonce = crypto.randomUUID();

const { head, body } = render(App, {
  csp: {
    nonce,
  },
});

// Add nonce to CSP header
const cspHeader = `script-src 'nonce-${nonce}'`;
```

### Using Hashes (Static HTML)

For pre-rendered static HTML, use hashes instead:

```typescript
const { head, body, hashes } = render(App, {
  csp: {
    hash: true, // or an object with specific hash options
  },
});

// hashes.script will be like ["sha256-abcd1234..."]
const cspHeader = `script-src ${hashes.script.map(h => `'${h}'`).join(' ')}`;
```

**Note:** Nonce is preferred over hash for dynamic SSR. Hashes are only for static builds.

## Library Author Guidelines

If you're building a library on top of Svelte and using `hydratable`:

1. **Always prefix your keys** with your library name
2. **Version your keys** when data structure changes
3. **Document the key format** for users
4. **Validate all data** before serializing
5. **Use stable serialization** - document what can/can't be serialized
6. **Consider CSP implications** - document nonce/hash requirements

```typescript
// Library example
const fetchUser = hydratable('mylib:user:v2', async (id: string) => {
  // Validation
  if (!/^[a-zA-Z0-9-]+$/.test(id)) {
    throw new Error('Invalid user ID');
  }

  const user = await getUser(id);

  // Sanitize before returning
  return {
    id: user.id,
    name: user.name.replace(/<script>/g, ''),
  };
});
```

## Advanced Patterns

### Nested Hydratable Data

```svelte
<script>
  import { hydratable } from 'svelte';

  const userData = hydratable('userData', async () => {
    const [user, posts] = await Promise.all([
      getUser(),
      getPosts(),
    ]);

    return { user, posts };
  });
</script>
```

### Conditional Hydration

```svelte
<script>
  import { hydratable } from 'svelte';

  // Only expensive operation if needed
  const data = hydratable('expensiveData', async () => {
    if (featureFlagEnabled()) {
      return await expensiveOperation();
    }
    return { data: 'default' };
  });
</script>
```

### Type Inference

`hydratable` preserves type information:

```typescript
const user = await hydratable('user', () => {
  return getUser();
});

// user is typed as the return type of getUser()
const name = user.name; // Fully typed
```

## Performance Benefits

Using `hydratable` provides significant performance improvements:

1. **Reduced hydration time** - No redundant async operations
2. **Faster time to interactive** - Data available immediately
3. **Reduced server load** - Fewer duplicate API calls
4. **Better UX** - No loading states during hydration

## Limitations

1. **Serialization overhead** - Large datasets may increase HTML size
2. **Scope limited to request** - Data only available for current request
3. **Memory usage** - Serialized data stored in DOM until consumed
4. **Browser limits** - Very large payloads may hit `<script>` size limits

## References

- <https://svelte.dev/docs/svelte/hydratable>
- SvelteKit Remote Functions documentation
- devalue serialization documentation

## Related

- [[sveltekit-remote-functions]]
- [[sveltekit-fullstack-features]]
- [[sveltekit-security-advisories]]
