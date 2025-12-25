---
title: SvelteKit Accessibility Best Practices
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - accessibility
  - a11y
  - navigation
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Accessibility Best Practices

## Route Announcements

SvelteKit injects a live region to announce page changes during client-side navigation. Ensure each page has a unique `<title>` in `<svelte:head>`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/10-accessibility.md>

## Focus Management

After navigation and enhanced form submission, SvelteKit focuses the `<body>` unless an element with `autofocus` is present. Use `afterNavigate` or `goto({ keepFocus: true })` if you need custom focus behavior. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/10-accessibility.md>

## lang Attribute

Set the correct `lang` on `<html>` in `src/app.html`. For multi-language sites, set a placeholder and replace it in `handle` with `transformPageChunk`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/10-accessibility.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/10-accessibility.md>

## Related

- [[sveltekit-seo-best-practices]]
