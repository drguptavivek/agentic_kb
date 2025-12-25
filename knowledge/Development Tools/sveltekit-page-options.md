---
title: SvelteKit Page Options
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - prerender
  - ssr
  - csr
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Page Options

## Overview

Page options are exported from `+page(.server).js` or `+layout(.server).js` to control rendering behavior (`prerender`, `ssr`, `csr`, `trailingSlash`, and `config`). Child layouts and pages override parent defaults. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## prerender

`export const prerender = true | false | 'auto'` controls static generation. It also applies to `+server.js` endpoints. Pages with actions cannot be prerendered, and `url.searchParams` cannot be accessed during prerender. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## entries

Dynamic routes can export `entries()` to tell the prerenderer which params to build. This is an alternative to `config.kit.prerender.entries`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## ssr / csr

- `ssr = false` disables server rendering for a route (client-only shell).
- `csr = false` disables client-side rendering (no hydration). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## trailingSlash

Controls URL canonicalization for routes (`always`, `never`, or `ignore`). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## config

Adapter-specific configuration can be provided via `export const config = { ... }` in routes or layouts. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/40-page-options.md>

## Related

- [[sveltekit-loading-data]]
- [[sveltekit-routing]]
