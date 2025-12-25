---
title: SvelteKit Adapter Netlify
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - netlify
  - adapter
  - deploy
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Netlify

## Overview

`adapter-netlify` deploys to Netlify. It is installed by default via `adapter-auto`, but direct use enables Netlify-specific options. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/80-adapter-netlify.md>

## Usage

Install `@sveltejs/adapter-netlify`, configure in `svelte.config.js`, and add `netlify.toml` with `build.publish`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/80-adapter-netlify.md>

## Edge Functions

Set `edge: true` to run SSR in Deno-based Edge Functions. Use `split` to split into multiple functions (not compatible with `edge`). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/80-adapter-netlify.md>

## Netlify-Specific Features

`_headers` and `_redirects` can be used for static assets. Redirect rules are appended to `_redirects`. Netlify forms require prerendered pages. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/80-adapter-netlify.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/80-adapter-netlify.md>

## Related

- [[sveltekit-adapters]]
