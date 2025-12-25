---
title: SvelteKit Adapter Vercel
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - vercel
  - adapter
  - deploy
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Vercel

## Overview

`adapter-vercel` deploys to Vercel and supports route-level deployment configuration. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/90-adapter-vercel.md>

## Usage

Install `@sveltejs/adapter-vercel` and configure in `svelte.config.js`. Use `export const config` in routes to set `split`, `runtime`, `regions`, etc. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/90-adapter-vercel.md>

## Image Optimization

Configure `images` in adapter options to control formats, sizes, and cache TTL. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/90-adapter-vercel.md>

## ISR

Use `config.isr` with `expiration` (required) and optional `bypassToken`/`allowQuery`. ISR applies only to non-prerendered routes. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/90-adapter-vercel.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/90-adapter-vercel.md>

## Related

- [[sveltekit-adapters]]
