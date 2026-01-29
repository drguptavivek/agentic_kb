---
title: SvelteKit Hooks
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - hooks
  - middleware
  - server
  - client
  - errors
  - authentication
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# SvelteKit Hooks

## Overview

Hooks are app-wide functions that SvelteKit calls in response to specific events, giving you fine-grained control over the framework's behavior. They're useful for authentication, logging, error tracking, request modification, and more. <https://svelte.dev/docs/kit/hooks>

## Hook Files

There are three optional hooks files:

| File | Runs On | Purpose |
|------|---------|---------|
| `src/hooks.server.js` | Server only | Server-side middleware, authentication, API requests |
| `src/hooks.client.js` | Browser only | Client-side error handling, initialization |
| `src/hooks.js` | Both | Shared hooks, URL rerouting, custom type transport |

**Note:** Code in these modules runs when the application starts up, making them useful for initializing database connections and other one-time setup.

## Server Hooks

### handle

The `handle` hook runs every time the SvelteKit server receives a request (during app runtime or prerendering). It receives an `event` object and a `resolve` function.

```javascript
/// file: src/hooks.server.js
/** @type {import('@sveltejs/kit').Handle} */
export async function handle({ event, resolve }) {
  // Custom routing
  if (event.url.pathname.startsWith('/custom')) {
    return new Response('custom response');
  }

  // Let SvelteKit handle the request
  const response = await resolve(event);
  return response;
}
```

**Default:** `({ event, resolve }) => resolve(event)`

**Important:** Requests for static assets (including prerendered pages) are NOT handled by SvelteKit and won't trigger `handle`.

### Using locals

To pass custom data through the request chain, populate `event.locals`:

```javascript
/// file: src/hooks.server.js
// @filename: ambient.d.ts
type User = {
  name: string;
}

declare namespace App {
  interface Locals {
    user: User;
  }
}

// @filename: index.js
// ---cut---
/** @type {import('@sveltejs/kit').Handle} */
export async function handle({ event, resolve }) {
  // Add custom data
  event.locals.user = await getUserInformation(event.cookies.get('sessionid'));

  const response = await resolve(event);

  // Modify response headers
  // Note: Response.headers may be immutable (e.g., from Response.redirect())
  // Clone the response if needed
  response.headers.set('x-custom-header', 'value');

  return response;
}
```

**Access in load functions:**
```javascript
// +page.server.js
export async function load({ locals }) {
  const user = locals.user; // Typed as User
  return { user };
}
```

### resolve Options

The `resolve` function accepts an optional second parameter for advanced control:

```javascript
/** @type {import('@sveltejs/kit').Handle} */
export async function handle({ event, resolve }) {
  const response = await resolve(event, {
    // Transform HTML chunks during SSR
    transformPageChunk: ({ html, done }) => {
      return html.replace('old', 'new');
    },

    // Control which headers are included in serialized responses
    filterSerializedResponseHeaders: (name) => {
      return name.startsWith('x-');
    },

    // Control preloading of assets
    preload: ({ type, path }) => {
      return type === 'js' || path.includes('/important/');
    }
  });

  return response;
}
```

**Options:**
- `transformPageChunk` - Modify HTML during SSR (chunks aren't guaranteed well-formed)
- `filterSerializedResponseHeaders` - Control headers in `fetch` responses during SSR
- `preload` - Control asset preloading in `<head>` (build-time only, not dev)

### Chaining handle Functions

Use the `sequence` helper to chain multiple `handle` functions:

```javascript
import { sequence } from '@sveltejs/kit/hooks';

import { authentication } from '$lib/server/hooks/auth';
import { logging } from '$lib/server/hooks/logging';
import { cors } from '$lib/server/hooks/cors';

export const handle = sequence(authentication, logging, cors);
```

**Example: Auth Hook**
```javascript
/// file: src/lib/server/hooks/auth.js
/** @type {import('@sveltejs/kit').Handle} */
export const authentication = async ({ event, resolve }) => {
  // Skip auth for public routes
  if (event.url.pathname.startsWith('/api/public')) {
    return resolve(event);
  }

  // Check authentication
  const session = event.cookies.get('session');
  if (!session) {
    return new Response('Unauthorized', { status: 401 });
  }

  event.locals.user = await getUser(session);
  return resolve(event);
};
```

### handleFetch

Intercepts `event.fetch` calls on the server (or during prerendering). Useful for API proxying, cookie forwarding, or request modification.

```javascript
/** @type {import('@sveltejs/kit').HandleFetch} */
export async function handleFetch({ request, fetch }) {
  // Proxy API requests during SSR
  if (request.url.startsWith('https://api.example.com/')) {
    // Clone and modify request
    request = new Request(
      request.url.replace('https://api.example.com/', 'http://localhost:9999/'),
      request
    );
  }

  return fetch(request);
}
```

**Cookie Forwarding for Sibling Subdomains:**

```javascript
/** @type {import('@sveltejs/kit').HandleFetch} */
export async function handleFetch({ event, request, fetch }) {
  // Forward cookies to sibling subdomain
  if (request.url.startsWith('https://api.my-domain.com/')) {
    request.headers.set('cookie', event.request.headers.get('cookie'));
  }

  return fetch(request);
}
```

**Note:** SvelteKit automatically forwards cookies for same-origin and subdomain requests (e.g., `my-domain.com` → `api.my-domain.com`), but not for sibling subdomains (e.g., `www.my-domain.com` → `api.my-domain.com`).

### handleValidationError

Called when a remote function receives invalid arguments (doesn't match the provided Standard Schema). Must return an object matching `App.Error`.

```javascript
/// file: src/hooks.server.js
/** @type {import('@sveltejs/kit').HandleValidationError} */
export function handleValidationError({ issues }) {
  return {
    message: 'Validation failed',
    // Don't expose detailed errors to potential attackers
  };
}
```

**Be thoughtful** about what information you expose, as validation failures often indicate malicious requests.

**Example with custom error ID:**
```javascript
/** @type {import('@sveltejs/kit').HandleValidationError} */
export function handleValidationError({ issues }) {
  const errorId = crypto.randomUUID();

  // Log for debugging (but don't return details to client)
  console.error(`Validation error ${errorId}:`, issues);

  return {
    message: 'Invalid request data',
    errorId
  };
}
```

## Shared Hooks

These hooks can be added to BOTH `hooks.server.js` and `hooks.client.js`.

### handleError

Called when an **unexpected error** is thrown during loading, rendering, or from an endpoint. Use it for:
- Logging errors
- Generating custom error representations safe for users
- Adding tracking IDs for support

```javascript
/// file: src/hooks.server.js
/** @type {import('@sveltejs/kit').HandleServerError} */
export async function handleError({ error, event, status, message }) {
  const errorId = crypto.randomUUID();

  // Log error (Sentry, etc.)
  console.error('Error:', errorId, error);

  // Return custom error representation
  return {
    message: 'Something went wrong',
    errorId
  };
}
```

```javascript
/// file: src/hooks.client.js
/** @type {import('@sveltejs/kit').HandleClientError} */
export async function handleError({ error, event, status, message }) {
  const errorId = crypto.randomUUID();

  // Client-side error logging
  console.error('Client error:', errorId, error);

  return {
    message: 'Something went wrong',
    errorId
  };
}
```

**Important:**
- Called for **unexpected errors** only (not `error()` from `@sveltejs/kit`)
- `status` is typically 500, `message` is "Internal Error" (safe for users)
- `error.message` may contain sensitive info - don't expose directly
- **Never throw** from `handleError`

**Custom Error Type:**

```typescript
/// file: src/app.d.ts
declare global {
  namespace App {
    interface Error {
      message: string;
      errorId: string;
    }
  }
}

export {};
```

**Access in components:**
```svelte
<script>
  import { page } from '$app/state';
</script>

{#if page.error}
  <p>Error: {page.error.message}</p>
  <p>Error ID: {page.error.errorId}</p>
{/if}
```

**Note:** In development, syntax errors include a `frame` property highlighting the error location.

### init

Runs once when the server is created or the app starts in the browser. Useful for async initialization work.

```javascript
/// file: src/hooks.server.js
import * as db from '$lib/server/database';

/** @type {import('@sveltejs/kit').ServerInit} */
export async function init() {
  await db.connect();
}
```

```javascript
/// file: src/hooks.client.js
/** @type {import('@sveltejs/kit').ClientInit} */
export async function init() {
  // Client-side initialization
  await initAnalytics();
}
```

**Note:** If using top-level await (supported in most environments), `init` is equivalent to top-level module code. However, Safari and some environments don't support top-level await, making `init` more portable.

**In the browser**, async work in `init` delays hydration, so keep it minimal.

## Universal Hooks

Added to `src/hooks.js`, these run on BOTH server and client.

### reroute

Runs before `handle` and allows URL-to-route translation. Changes how URLs map to routes without changing the browser's address bar.

```javascript
/// file: src/hooks.js
/** @type {import('@sveltejs/kit').Reroute} */
export function reroute({ url }) {
  // Language-based routing
  if (url.pathname === '/en/about') return '/en/about';
  if (url.pathname === '/de/ueber-uns') return '/de/about';
  if (url.pathname === '/fr/a-propos') return '/fr/about';
}
```

**Async reroute** (2.18+): Use carefully - delays navigation!

```javascript
/** @type {import('@sveltejs/kit').Reroute} */
export async function reroute({ url, fetch }) {
  // Ask backend where to route
  if (url.pathname === '/api/reroute') return;

  const api = new URL('/api/reroute', url);
  api.searchParams.set('pathname', url.pathname);

  const result = await fetch(api).then(r => r.json());
  return result.pathname;
}
```

**Properties:**
- `url` - The original URL
- `fetch` - SvelteKit's fetch (same benefits as load functions')
- Must be pure and idempotent (cached per unique URL on client)
- Does NOT change `event.url` or browser address bar

### transport

Allows custom types from `load` and form actions to be serialized across server/client boundary.

```javascript
/// file: src/hooks.js
import { Vector } from '$lib/math';

/** @type {import('@sveltejs/kit').Transport} */
export const transport = {
  Vector: {
    encode: (value) => value instanceof Vector && [value.x, value.y],
    decode: ([x, y]) => new Vector(x, y)
  }
};
```

**Usage:**
```javascript
// +page.server.js
export async function load() {
  return {
    vector: new Vector(10, 20) // Automatically transported
  };
}
```

```svelte
<!-- +page.svelte -->
<script>
  let { data } = $props();
  // data.vector is a Vector instance, not an array
</script>
```

## Common Patterns

### Authentication Hook

```javascript
/// file: src/hooks.server.js
import { redirect } from '@sveltejs/kit';

/** @type {import('@sveltejs/kit').Handle} */
export const handle = async ({ event, resolve }) => {
  const session = event.cookies.get('session');

  // Protected routes
  if (event.url.pathname.startsWith('/dashboard')) {
    if (!session) {
      redirect(302, '/login');
    }
  }

  event.locals.user = await getUser(session);
  return resolve(event);
};
```

### Logging Hook

```javascript
/// file: src/hooks.server.js
/** @type {import('@sveltejs/kit').Handle} */
export const handle = async ({ event, resolve }) => {
  const start = performance.now();

  const response = await resolve(event);

  const duration = performance.now() - start;
  console.log(`${event.request.method} ${event.url.pathname} - ${response.status} (${duration.toFixed(2)}ms)`);

  return response;
};
```

### CORS Hook

```javascript
/// file: src/hooks.server.js
/** @type {import('@sveltejs/kit').Handle} */
export const handle = async ({ event, resolve }) => {
  // Apply CORS to API routes
  if (event.url.pathname.startsWith('/api/')) {
    // Handle OPTIONS preflight
    if (event.request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        }
      });
    }

    const response = await resolve(event);

    return new Response(response.body, response, {
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      }
    });
  }

  return resolve(event);
};
```

### Sentry Integration

```javascript
/// file: src/hooks.server.js
import * as Sentry from '@sentry/sveltekit';

Sentry.init({
  dsn: 'your-dsn',
  tracesSampleRate: 1.0,
});

/** @type {import('@sveltejs/kit').HandleServerError} */
export async function handleError({ error, event, status }) {
  Sentry.captureException(error, { extra: { event, status } });

  return {
    message: 'Internal Error'
  };
}
```

### CSRF Protection

```javascript
/// file: src/hooks.server.js
import { csrf } from '$lib/server/csrf';

/** @type {import('@sveltejs/kit').Handle} */
export const handle = async ({ event, resolve }) => {
  // Protect mutating requests
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(event.request.method)) {
    const token = event.request.headers.get('x-csrf-token');
    const cookie = event.cookies.get('csrf-token');

    if (!token || !cookie || token !== cookie) {
      return new Response('Invalid CSRF token', { status: 403 });
    }
  }

  return resolve(event);
};
```

## Hook Execution Order

1. **Universal `reroute`** (if applicable)
2. **Server `handle`**
3. **Route resolution**
4. **`load` functions / form actions**
5. **Response generation**
6. **Server `handleError`** (if error thrown)

## References

- <https://svelte.dev/docs/kit/hooks>
- <https://svelte.dev/docs/kit/errors>

## Related

- [[sveltekit-errors]]
- [[sveltekit-auth-best-practices]]
- [[sveltekit-loading-data]]
- [[sveltekit-remote-functions]]
