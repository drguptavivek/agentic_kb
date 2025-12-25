---
title: SvelteKit Observability (Experimental)
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - observability
  - opentelemetry
  - experimental
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Observability (Experimental)

## Overview

SvelteKit can emit OpenTelemetry spans for server `handle`, `load`, form actions, and remote functions. Available since 2.31 and experimental. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/68-observability.md>

## Enablement

Opt in via `kit.experimental.tracing.server` and `kit.experimental.instrumentation.server` in `svelte.config.js`. Add `src/instrumentation.server.ts` for setup. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/68-observability.md>

## Augmenting Spans

Use `event.tracing.root` and `event.tracing.current` to add attributes. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/68-observability.md>

## Dependencies

Tracing uses `@opentelemetry/api` (optional peer dependency); install an SDK or the API directly if needed. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/68-observability.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/30-advanced/68-observability.md>

## Related

- [[sveltekit-performance-best-practices]]
