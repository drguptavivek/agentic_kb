---
title: Svelte CLI sv check
type: reference
domain: Development Tools
tags:
  - svelte
  - cli
  - sv
  - diagnostics
  - svelte-check
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Svelte CLI sv check

## Overview

`sv check` runs diagnostics (CSS, a11y, JS/TS) and requires Node 16+ with `svelte-check` installed. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/30-sv-check.md>

## Usage

```bash
npx sv check
```

## Common Options

- `--workspace <path>`
- `--output <human|human-verbose|machine|machine-verbose>`
- `--watch`, `--preserveWatchOutput`
- `--tsconfig <path>` / `--no-tsconfig`
- `--ignore "dist,build"`
- `--fail-on-warnings`
- `--compiler-warnings "code:behaviour"` <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/30-sv-check.md>

## Machine Output

`machine` and `machine-verbose` emit line-based output suited for CI. `machine-verbose` emits NDJSON diagnostics. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/30-sv-check.md>

## References

- <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/30-sv-check.md>

## Related

- [[svelte-cli-sv-migrate]]
