---
title: SvelteKit Icons Best Practices
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - icons
  - vite
  - css
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Icons Best Practices

## CSS-First Icons

Prefer CSS-based icon sets like Iconify (including Tailwind/UnoCSS plugins) to avoid per-icon component imports. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/06-icons.md>

## Svelte Icon Libraries

Avoid icon libraries that ship thousands of `.svelte` files (one per icon) because they slow Vite dependency optimization, especially with umbrella and subpath imports. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/06-icons.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/06-icons.md>

## Related

- [[sveltekit-performance-best-practices]]
