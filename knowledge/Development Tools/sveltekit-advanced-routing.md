---
title: SvelteKit Advanced Routing
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - routing
  - params
  - layouts
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Advanced Routing

## Rest and Optional Parameters

- Rest params `[...rest]` capture an unknown number of segments.
- Optional params `[[param]]` allow `param` to be omitted. Optional params cannot follow rest params. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/10-advanced-routing.md>

## Matchers

Use custom matchers in `src/params` and route syntax like `[id=matcher]` to validate params and avoid unintended matches. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/10-advanced-routing.md>

## Route Sorting

More specific routes win; matchers beat plain params; optional/rest at the end have lowest priority; ties are alphabetical. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/10-advanced-routing.md>

## Encoding

Use `[x+nn]` or `[u+nnnn]` escapes to include characters that are not filesystem-safe in route names. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/10-advanced-routing.md>

## Advanced Layouts

Use `(group)` folders to group routes without affecting the URL path. This enables layout groups and breaking out of common layouts. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/10-advanced-routing.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/10-advanced-routing.md>

## Related

- [[sveltekit-routing]]
