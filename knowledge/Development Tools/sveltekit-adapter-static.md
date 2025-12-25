---
title: SvelteKit Adapter Static
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - adapter-static
  - ssg
  - deploy
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Static

## Overview

`adapter-static` prerenders your site as static files. Use it when all (or most) routes can be prerendered. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/50-adapter-static.md>

## Usage

Install `@sveltejs/adapter-static`, configure in `svelte.config.js`, and set `export const prerender = true` in the root layout. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/50-adapter-static.md>

## Options

Key options: `pages`, `assets`, `fallback`, `precompress`, `strict`. SPA fallback has SEO/perf costs. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/50-adapter-static.md>

## GitHub Pages

Set `paths.base` to the repo name and consider a `404.html` fallback. Use `.nojekyll` in `static` if needed. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/50-adapter-static.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/50-adapter-static.md>

## Related

- [[sveltekit-single-page-apps]]
