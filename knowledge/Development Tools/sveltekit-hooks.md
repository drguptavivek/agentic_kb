---
title: SvelteKit Hooks
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - hooks
  - server
  - errors
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Hooks

## Files

- `src/hooks.server.js`: server-only hooks
- `src/hooks.client.js`: client-only hooks
- `src/hooks.js`: shared hooks (client and server) <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/20-hooks.md>

## Server Hooks

- `handle`: intercepts every request and calls `resolve`.
- `handleFetch`: intercepts server-side `event.fetch` calls.
- `handleValidationError`: customizes validation errors for remote functions. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/20-hooks.md>

`handle` can also control `transformPageChunk`, `filterSerializedResponseHeaders`, and `preload` via the second argument to `resolve`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/20-hooks.md>

## Shared Hooks

- `handleError`: handles unexpected errors, logs, and customizes `$page.error`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/20-hooks.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/20-hooks.md>

## Related

- [[sveltekit-errors]]
