---
title: SvelteKit Auth Best Practices
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - auth
  - sessions
  - jwt
  - hooks
  - locals
status: approved
created: 2025-12-25
updated: 2025-01-29
---

# SvelteKit Auth Best Practices

## Overview

Authentication means verifying that the user is who they say they are based on their provided credentials. Authorization means determining which actions they are allowed to take. <https://svelte.dev/docs/kit/auth>

## Sessions vs Tokens

### Session-based Authentication

- **Storage:** Session IDs are stored in a database
- **Revocation:** Can be revoked immediately
- **Performance:** Requires a database query on each request
- **Use when:** You need immediate revocation (e.g., admin actions, security events)

### Token-based Authentication (JWT)

- **Storage:** Generally not checked against a datastore
- **Revocation:** Cannot be immediately revoked
- **Performance:** Lower latency, reduced load on datastore
- **Use when:** Performance is critical and immediate revocation is not required

## Integration Points

Auth cookies should be validated inside server hooks (`hooks.server.ts`). If a user is found matching the provided credentials, the user information can be stored in `event.locals` for access in:
- Load functions (`+page.server.ts`, `+layout.server.ts`)
- Server endpoints (`+server.ts`)
- Remote functions (`.remote.ts`)
- Form actions (`+page.server.ts`) <https://svelte.dev/docs/kit/auth>

## Basic Hook Pattern

```typescript
// src/hooks.server.ts
import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
  // 1. Get session from cookie
  const session = await getSession(event.cookies.get('sessionid'));

  // 2. Store in locals for downstream use
  if (session) {
    event.locals.user = session.user;
  }

  // 3. Resolve the request
  const response = await resolve(event);

  return response;
};
```

## Common Pitfalls

### Race Conditions in Auth

When implementing authentication, be aware of potential race conditions:

1. **Cookie validation timing:** Ensure the cookie is validated before setting `locals`
2. **Session refresh timing:** Don't create race conditions between session validation and refresh
3. **Redirect loops:** Ensure auth checks don't create infinite redirect loops <https://www.shanechang.com/p/sveltekit-auth-race-condition-debugging/>

### Accessing `locals` in Deeply Nested Functions

When you need to access `event.locals.user` from deeply nested `$lib` functions:

**Option 1: Pass it down** (recommended for most cases)
```typescript
// src/routes/+page.server.ts
export async function load({ locals }) {
  const result = await someDeepFunction(locals.user);
}

// src/lib/deeply/nested/function.ts
export async function someDeepFunction(user: App.Locals['user']) {
  // Use user directly
}
```

**Option 2: Use `getRequestEvent`** (for SvelteKit 2.2+)
```typescript
// src/lib/deeply/nested/function.ts
import { getRequestEvent } from '$app/server';

export async function someDeepFunction() {
  const event = getRequestEvent();
  const user = event?.locals?.user;
  // Use user
}
```

**Option 3: Context pattern** (advanced)
```typescript
// src/lib/auth/context.ts
import { getRequestEvent } from '$app/server';

export function getUser() {
  const event = getRequestEvent();
  if (!event?.locals.user) {
    throw new Error('User not found in locals');
  }
  return event.locals.user;
}
```

## Auth Libraries

### Lucia (Session-based)

Lucia is the reference implementation for session-based web app auth in SvelteKit. It provides:
- Session management
- User authentication
- Database adapters for multiple databases

**Installation:**
```bash
npx sv add lucia  # For existing projects
npx sv create     # For new projects
```

**Why Lucia?**
- Officially recommended by SvelteKit
- SvelteKit-specific guides and examples
- Tightly coupled to web framework patterns
- Avoids multiple web framework dependencies in your project

### Better Auth

Better Auth is a modern auth solution with native Svelte support:
- Framework agnostic
- Native Svelte client with reactive hooks
- Works with SvelteKit remote functions
- Supports multiple auth providers

See [[better-auth-sveltekit-integration]] for detailed setup.

### Auth.js (formerly NextAuth)

Migrate guide available to Better Auth: <https://authjs.dev/getting-started/migrate-to-better-auth>

## Protected Routes Pattern

### Server-side Protection

```typescript
// src/routes/+page.server.ts
import { redirect } from '@sveltejs/kit';

export async function load({ locals }) {
  if (!locals.user) {
    redirect(302, '/login');
  }

  return {
    user: locals.user
  };
}
```

### Layout-based Protection

```typescript
// src/routes/(app)/+layout.server.ts
import { redirect } from '@sveltejs/kit';

export async function load({ locals }) {
  if (!locals.user) {
    redirect(302, '/login');
  }
}
```

### Hook-based Protection

```typescript
// src/hooks.server.ts
import { redirect } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';

const protectedPaths = ['/dashboard', '/settings', '/api/protected'];

const authGuard: Handle = async ({ event, resolve }) => {
  if (protectedPaths.some(path => event.url.pathname.startsWith(path))) {
    if (!event.locals.user) {
      redirect(302, `/login?redirect=${event.url.pathname}`);
    }
  }
  return resolve(event);
};

export const handle = sequence(authGuard, yourOtherHandles);
```

## Type Safety

Define your `locals` type in `app.d.ts`:

```typescript
// src/app.d.ts
import type { User } from '$lib/types';

declare global {
  namespace App {
    interface Locals {
      user?: User;
      session?: Session;
    }
  }
}

export {};
```

## SPA Mode Considerations

When using SvelteKit in SPA mode (`export const ssr = false`), auth patterns differ:
- No server-side hooks execution
- Must use client-side auth patterns
- Consider using auth libraries with SPA support
- Be aware of hydration mismatches

## Best Practices Summary

1. **Use `event.locals`** for storing user/session data across the request lifecycle
2. **Validate in hooks** before any route handlers run
3. **Protect at the right level:** Layout for grouped routes, individual pages for specific access
4. **Handle redirects carefully** to avoid infinite loops
5. **Use session-based auth** when you need immediate revocation
6. **Use JWT** when performance is critical and immediate revocation isn't needed
7. **Choose SvelteKit-specific guides** over generic JS auth libraries to avoid multiple framework dependencies

## References

- <https://svelte.dev/docs/kit/auth>
- <https://svelte.dev/docs/kit/hooks>
- Lucia auth: <https://lucia-auth.com>

## Related

- [[sveltekit-hooks]]
- [[sveltekit-routing]]
- [[better-auth-sveltekit-integration]]
- [[better-auth-installation]]
