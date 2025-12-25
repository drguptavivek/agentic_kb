---
title: Writing SvelteKit Adapters
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - adapters
  - deploy
  - tooling
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Writing SvelteKit Adapters

## Adapter API

Adapters export a function that returns an `Adapter` with `name` and `adapt`. Optional `emulate` and `supports` hooks can provide platform emulation and feature checks. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/99-writing-adapters.md>

## adapt Responsibilities

Clear build output, write client/server/prerendered output, create a server that calls `server.respond`, expose `platform` info, and shim `fetch` if needed. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/99-writing-adapters.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/99-writing-adapters.md>

## Related

- [[sveltekit-adapters]]
