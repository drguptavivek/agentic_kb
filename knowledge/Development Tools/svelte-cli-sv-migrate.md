---
title: Svelte CLI sv migrate
type: reference
domain: Development Tools
tags:
  - svelte
  - cli
  - sv
  - migration
  - sveltekit
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Svelte CLI sv migrate

## Overview

`sv migrate` runs Svelte/SvelteKit migrations via `svelte-migrate`. It may add `@migration` TODOs. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/40-sv-migrate.md>

## Usage

```bash
npx sv migrate
npx sv migrate [migration]
```

## Migrations

- `app-state`: `$app/stores` -> `$app/state`
- `svelte-5`: Svelte 4 -> Svelte 5 (runes)
- `self-closing-tags`
- `svelte-4`
- `sveltekit-2`
- `package` (svelte-package v1 -> v2)
- `routes` (pre-release routing to filesystem routing) <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/40-sv-migrate.md>

## References

- <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/40-sv-migrate.md>

## Related

- [[svelte-cli-sv-check]]
