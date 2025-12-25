---
title: SvelteKit Adapter Cloudflare Workers (Deprecated)
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - cloudflare
  - adapter
  - deprecated
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Cloudflare Workers (Deprecated)

## Overview

`adapter-cloudflare-workers` targets Cloudflare Workers Sites and is deprecated. Use `adapter-cloudflare` instead. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/70-adapter-cloudflare-workers.md>

## Usage

Install `@sveltejs/adapter-cloudflare-workers` and configure in `svelte.config.js` if you must target Workers Sites. Requires Wrangler config with `site.bucket`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/70-adapter-cloudflare-workers.md>

## Platform APIs

`event.platform` includes `env`, `ctx`, `caches`, and `cf`. Prefer `$env` modules for env vars when possible. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/70-adapter-cloudflare-workers.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/70-adapter-cloudflare-workers.md>

## Related

- [[sveltekit-adapter-cloudflare]]
