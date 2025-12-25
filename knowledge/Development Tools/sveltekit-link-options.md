---
title: SvelteKit Link Options
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - navigation
  - preload
  - routing
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Link Options

## Preload Data

`data-sveltekit-preload-data="hover|tap"` controls when to preload page data. Default templates apply `hover` on `<body>`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/30-link-options.md>

## Preload Code

`data-sveltekit-preload-code="eager|viewport|hover|tap"` preloads only code. It must be more eager than any preload-data setting to take effect. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/30-link-options.md>

## Navigation Behavior

- `data-sveltekit-reload`: full page load
- `data-sveltekit-replacestate`: replace history entry
- `data-sveltekit-keepfocus`: keep focus after navigation
- `data-sveltekit-noscroll`: do not scroll to top <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/30-link-options.md>

## Disabling

Set any option to `"false"` within a subtree to disable inherited behavior. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/30-link-options.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/30-link-options.md>

## Related

- [[sveltekit-routing]]
