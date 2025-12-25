---
title: SvelteKit Routing
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - routing
  - filesystem
  - endpoints
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Routing

## Overview

SvelteKit uses a filesystem-based router. Routes map to folders under `src/routes`, and files prefixed with `+` define how each route is handled. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/10-routing.md>

## Route Files (Quick Map)

- `+page.svelte`: Page component (SSR on first load, CSR on navigation).
- `+page.js`: Universal `load` for page data (runs on server and client).
- `+page.server.js`: Server-only `load` and `actions`.
- `+layout.svelte`: Layout wrapper shared by descendant routes.
- `+layout.js` / `+layout.server.js`: Layout `load` data (universal or server-only).
- `+error.svelte`: Error boundary for route subtree.
- `+server.js`: Endpoint/handler for HTTP verbs (API routes).
- `$types`: Generated types for `load` and component props.

## Execution Rules

- All files can run on the server.
- All files run on the client except `+server.js`.
- `+layout` and `+error` apply to the directory and all subdirectories. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/10-routing.md>

## Parameters and Dynamic Routes

Folders like `src/routes/blog/[slug]` create a dynamic `slug` parameter. The parameter is available in `load` functions for fetching data based on the URL. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/10-routing.md>

## +server.js Endpoints

`+server.js` exports handlers for HTTP methods (`GET`, `POST`, `PUT`, etc.) and returns a `Response`. For mixed page/endpoint routes, SvelteKit routes `GET`/`POST` requests to `+page` when the `Accept` header prioritizes `text/html`; other methods go to `+server.js`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/10-routing.md>

## Error Boundaries

`+error.svelte` handles errors thrown from `load` and rendering. SvelteKit walks up the tree to find the nearest error boundary; errors thrown from root layout fall back to `src/error.html`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/10-routing.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/10-routing.md>

## Related

- [[sveltekit-loading-data]]
- [[sveltekit-form-actions]]
