---
title: SvelteKit Adapters
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - adapters
  - deploy
  - platform
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapters

## Overview

Adapters take the built app and generate deployment output for a target platform. Set the adapter in `svelte.config.js`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/20-adapters.md>

## Official Adapters

- `@sveltejs/adapter-node`
- `@sveltejs/adapter-static`
- `@sveltejs/adapter-vercel`
- `@sveltejs/adapter-netlify`
- `@sveltejs/adapter-cloudflare` <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/20-adapters.md>

## Platform Context

Adapters can supply platform-specific data via `event.platform`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/20-adapters.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/20-adapters.md>

## Related

- [[sveltekit-adapter-auto]]
