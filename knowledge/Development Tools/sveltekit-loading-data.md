---
title: SvelteKit Loading Data
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - load
  - data-fetching
  - routing
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Loading Data

## Overview

Pages and layouts fetch data using `load` functions in `+page(.server).js` and `+layout(.server).js`. The returned data is available to components via the `data` prop (and `page.data`). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Universal vs Server Load

- `+page.js` / `+layout.js`: universal `load` (runs on server for SSR and in browser on navigation).
- `+page.server.js` / `+layout.server.js`: server-only `load` (use for private env vars, DB access).

Server `load` returns must be serializable with `devalue` (JSON plus `Date`, `Map`, `Set`, `BigInt`, etc.). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Fetching Data

Use the provided `fetch` inside `load` to make requests. On the server it inherits cookies and authorization headers from the page request and inlines responses into rendered HTML (headers are only serialized if allowed). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Cookies and Headers

Server `load` can read/write cookies. Both universal and server `load` can call `setHeaders` on the server, but you cannot set `set-cookie` with `setHeaders` (use `cookies.set`). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Parent Data and Reuse

Use `await parent()` to access data from parent layouts, but avoid unnecessary waterfalls by doing independent work before awaiting. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Errors and Redirects

Use `error(status, message)` and `redirect(status, location)` from `@sveltejs/kit`. They throw, so do not wrap in `try`/`catch` unless rethrowing. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Streaming and Parallelism

Server `load` can return promises; results stream to the browser as they resolve. Avoid returning top-level promises from universal `load` when SSR is enabled because they are not streamed. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Rerunning Load

`load` reruns when params or URL change, when dependencies are invalidated (`invalidate`, `invalidateAll`), or when parent `load` reruns. Declare dependencies using `fetch(url)` or `depends(id)` to control invalidation. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/20-load.md>

## Related

- [[sveltekit-routing]]
- [[sveltekit-form-actions]]
