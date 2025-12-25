---
title: Better Auth SvelteKit Integration
type: howto
domain: Development Tools
tags:
  - auth
  - better-auth
  - sveltekit
  - server-hooks
  - cookies
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Better Auth SvelteKit Integration

## Prerequisite

Have a Better Auth instance configured first. <https://www.better-auth.com/docs/integrations/svelte-kit>

## Mount the Handler (hooks.server)

Use `svelteKitHandler` in your `handle` hook:

```ts
import { auth } from "$lib/auth";
import { svelteKitHandler } from "better-auth/svelte-kit";
import { building } from "$app/environment";

export async function handle({ event, resolve }) {
  return svelteKitHandler({ event, resolve, auth, building });
}
```

## Populate event.locals (Session/User)

`svelteKitHandler` does not populate `event.locals.user` or `event.locals.session`. Fetch the session and populate locals in `handle` if you need them in server code:

```ts
import { auth } from "$lib/auth";
import { svelteKitHandler } from "better-auth/svelte-kit";
import { building } from "$app/environment";

export async function handle({ event, resolve }) {
  const session = await auth.api.getSession({
    headers: event.request.headers
  });

  if (session) {
    event.locals.session = session.session;
    event.locals.user = session.user;
  }

  return svelteKitHandler({ event, resolve, auth, building });
}
```

## Server Action Cookies

For server actions (e.g., `signInEmail`, `signUpEmail`), use the `sveltekitCookies` plugin so cookies are set correctly. This requires SvelteKit 2.20+ (`getRequestEvent`): <https://www.better-auth.com/docs/integrations/svelte-kit>

```ts
import { betterAuth } from "better-auth";
import { sveltekitCookies } from "better-auth/svelte-kit";
import { getRequestEvent } from "$app/server";

export const auth = betterAuth({
  // ... config
  plugins: [sveltekitCookies(getRequestEvent)] // keep as last plugin
});
```

## Create a Client

Use the Svelte client from `better-auth/svelte`:

```ts
import { createAuthClient } from "better-auth/svelte";

export const authClient = createAuthClient({
  // client config
});
```

Client hooks are reactive (nanostore-backed) and update session state as it changes. <https://www.better-auth.com/docs/integrations/svelte-kit>

## References

- <https://www.better-auth.com/docs/integrations/svelte-kit>

## Related

- [[better-auth-installation]]
