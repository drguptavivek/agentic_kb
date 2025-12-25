---
title: SvelteKit Form Actions
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - forms
  - actions
  - server
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Form Actions

## Overview

`+page.server.js` can export `actions` that handle `POST` submissions from `<form>` elements. Actions are the preferred way to write data to the server from the browser. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## Default vs Named Actions

- `default`: invoked by `<form method="POST">` with no action suffix.
- Named actions: invoked with `action="?/name"` or `action="/route?/name"`.
- Do not mix `default` with named actions unless you always redirect; the query parameter can persist. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## Validation Errors

Use `fail(status, data)` to return validation errors and repopulate form state. Returned data is available via the `form` prop and `page.form`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## Redirects and Errors

`redirect(...)` and `error(...)` behave the same as in `load` and throw immediately. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## Progressive Enhancement

Use `use:enhance` from `$app/forms` to avoid full-page reloads while preserving native `<form>` behavior. For custom behavior, use `applyAction` or handle the submit with `fetch` and `deserialize`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## Posting with fetch

If both `+page.server.js` actions and `+server.js` endpoints exist, `fetch` will target `+server.js` by default. To post to actions, include the `x-sveltekit-action: true` header. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## GET vs POST

Actions only handle `POST`. `GET` forms trigger navigation and rerun `load` without invoking actions. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/30-form-actions.md>

## Related

- [[sveltekit-loading-data]]
- [[sveltekit-routing]]
