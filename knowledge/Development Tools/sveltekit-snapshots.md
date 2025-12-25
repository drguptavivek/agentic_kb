---
title: SvelteKit Snapshots
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - state
  - navigation
  - snapshots
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Snapshots

## Overview

Snapshots preserve ephemeral DOM state (inputs, scroll positions) across navigation history. Export a `snapshot` object with `capture` and `restore` from `+page.svelte` or `+layout.svelte`. Data must be JSON-serializable and is stored in `sessionStorage`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/65-snapshots.md>

## Caveats

Avoid large snapshot payloads since captured data remains in memory for the session and may exceed `sessionStorage` limits. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/65-snapshots.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/65-snapshots.md>

## Related

- [[sveltekit-state-management]]
