---
title: SvelteKit Service Workers
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - service-workers
  - pwa
  - caching
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Service Workers

## Basics

If `src/service-worker.js` (or `src/service-worker/index.js`) exists, it is bundled and auto-registered. You can disable auto-registration and handle it manually. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/40-service-workers.md>

## $service-worker Module

Use `$service-worker` to access `build`, `files`, `prerendered`, `version`, and `base` for caching strategies. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/40-service-workers.md>

## Development

Service workers are not bundled in dev; register with `{ type: 'module' }` if needed. `build` and `prerendered` are empty in dev. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/40-service-workers.md>

## Alternatives

Workbox or Vite PWA plugin can be used instead of the built-in approach. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/40-service-workers.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/40-service-workers.md>

## Related

- [[sveltekit-performance-best-practices]]
