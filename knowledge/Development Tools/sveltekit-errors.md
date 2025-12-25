---
title: SvelteKit Errors
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - errors
  - hooks
  - types
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Errors

## Expected vs Unexpected

- Expected errors are created with `error(status, data)` from `@sveltejs/kit` and render `+error.svelte`.
- Unexpected errors are any other exceptions; they surface through `handleError` with a generic message. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/25-errors.md>

## Responses and Fallback

Errors in `handle` or `+server.js` return JSON or a fallback HTML page depending on `Accept` headers. Customize the fallback with `src/error.html`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/25-errors.md>

## Type Safety

Extend `App.Error` in `src/app.d.ts` to add properties like `code` or `id`; `message: string` is always required. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/25-errors.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/25-errors.md>

## Related

- [[sveltekit-hooks]]
