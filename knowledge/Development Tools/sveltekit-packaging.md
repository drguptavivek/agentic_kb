---
title: SvelteKit Packaging
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - packaging
  - libraries
  - npm
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Packaging

## Overview

Use `@sveltejs/package` to build component libraries. It packages `src/lib` into `dist` and generates type definitions. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/70-packaging.md>

## package.json Essentials

- `files`: include `dist`
- `exports`: define entry points with `types` and `svelte` conditions
- `svelte`: legacy field for older tooling
- `sideEffects`: mark CSS (and any side-effectful files) for tree-shaking compatibility <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/70-packaging.md>

## TypeScript

If you add subpath exports, ensure TypeScript resolves types using `moduleResolution` (bundler/node16/nodenext) or `typesVersions` mappings. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/70-packaging.md>

## Best Practices

Avoid SvelteKit-specific modules in published libraries unless you target SvelteKit-only consumers. Prefer `svelte.config.js` aliases so `svelte-package` can process them. Manage versioning carefully for breaking changes. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/70-packaging.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/70-packaging.md>

## Related

- [[sveltekit-creating-a-project]]
