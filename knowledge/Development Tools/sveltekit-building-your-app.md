---
title: SvelteKit Building Your App
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - build
  - vite
  - deploy
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Building Your App

## Build Stages

`vite build` runs in two stages: Vite builds optimized client/server/service worker output, then the adapter tunes it for the target platform. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/10-building-your-app.md>

## build-time execution

SvelteKit loads `+page/layout(.server).js` during the build for analysis. Guard side-effectful code with `building` from `$app/environment`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/10-building-your-app.md>

## Preview

Use `vite preview` (`npm run preview`) to run the built app locally. Adapter-specific platform context does not apply in preview. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/10-building-your-app.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/10-building-your-app.md>

## Related

- [[sveltekit-adapters]]
