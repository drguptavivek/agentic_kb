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
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Server-Only Modules

## Private Env Modules

`$env/static/private` and `$env/dynamic/private` can only be imported by server-only code like `hooks.server.js` or `+page.server.js`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/50-server-only-modules.md>

## Server Utilities

`$app/server` (e.g., `read`) is also server-only. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/50-server-only-modules.md>

## Marking Your Modules

Use `.server` in filenames or place them under `$lib/server`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/50-server-only-modules.md>

## Enforcement

If client code imports server-only modules (even indirectly), SvelteKit throws a build error to prevent leaks. This check is disabled during tests. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/50-server-only-modules.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/50-server-only-modules.md>

## Related

- [[sveltekit-auth-best-practices]]
