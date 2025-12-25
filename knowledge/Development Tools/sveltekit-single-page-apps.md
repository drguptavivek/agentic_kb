---
title: SvelteKit Single-Page Apps
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - spa
  - prerender
  - deploy
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Single-Page Apps

## Overview

SPA mode serves a fallback HTML page for routes that are not prerendered. It has major performance and SEO costs and should be avoided unless necessary. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/55-single-page-apps.md>

## Usage

Disable SSR with `export const ssr = false` and configure `adapter-static` with a `fallback` page (e.g., `200.html`). Avoid `index.html` as a fallback. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/55-single-page-apps.md>

## Prerender Selectively

Re-enable `prerender` and `ssr` for pages that can be fully static. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/55-single-page-apps.md>

## Apache

Use an `.htaccess` rewrite to route requests to the fallback page. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/55-single-page-apps.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/55-single-page-apps.md>

## Related

- [[sveltekit-adapter-static]]
