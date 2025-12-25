---
title: SvelteKit Adapter Cloudflare
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - cloudflare
  - adapter
  - deploy
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Cloudflare

## Overview

`adapter-cloudflare` targets Cloudflare Workers and Pages and is the recommended Cloudflare adapter (supports all SvelteKit features). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/60-adapter-cloudflare.md>

## Usage

Install `@sveltejs/adapter-cloudflare` and configure it in `svelte.config.js`. It can emulate `event.platform` locally and supports Cloudflare-specific options. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/60-adapter-cloudflare.md>

## Cloudflare Workers

Requires a Wrangler config with `main` pointing to `.svelte-kit/cloudflare/_worker.js` and `assets` binding. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/60-adapter-cloudflare.md>

## Cloudflare Pages

Use framework preset SvelteKit, build command `npm run build`, output `.svelte-kit/cloudflare`. Customize routes via `_routes.json` options. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/60-adapter-cloudflare.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/60-adapter-cloudflare.md>

## Related

- [[sveltekit-adapter-cloudflare-workers]]
