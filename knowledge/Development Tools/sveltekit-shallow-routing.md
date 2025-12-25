---
title: SvelteKit Shallow Routing
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - navigation
  - history
  - state
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Shallow Routing

## Overview

Use `pushState` and `replaceState` from `$app/navigation` to create history entries without navigating. State is available at `page.state`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/67-shallow-routing.md>

## Data Loading

Use `preloadData(href)` to run `load` and reuse any in-flight preloads when rendering a route inside a modal or overlay. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/67-shallow-routing.md>

## Caveats

`page.state` is empty during SSR and on initial load; state is only applied after navigation. Shallow routing requires JavaScript, so provide sensible fallbacks. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/67-shallow-routing.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/67-shallow-routing.md>

## Related

- [[sveltekit-link-options]]
