---
title: SvelteKit State Management
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - state
  - ssr
  - hydration
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit State Management

## Overview

State must be handled carefully across server and client. Servers are shared and long-lived, so avoid shared module state that can leak between users. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## Avoid Shared State on the Server

Do not store per-user data in module-level variables on the server. Use cookies + database storage instead. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## No Side Effects in load

`load` functions should be pure. Return data and pass it through props or `page.data` rather than mutating global stores. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## Context for App State

Use Svelte’s context API to pass state down the component tree. This avoids shared server state and keeps data tied to a request. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## Client vs Server Differences

State changes during SSR do not propagate upward because parents have already rendered. On the client, state updates flow as usual. Prefer passing state down to avoid hydration flashes. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## State in URL and Snapshots

Persist navigational state in the URL when appropriate, and use snapshots for ephemeral state that should survive navigation history. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/20-core-concepts/50-state-management.md>

## Related

- [[sveltekit-loading-data]]
