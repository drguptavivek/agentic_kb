---
title: Svelte CLI sv create
type: reference
domain: Development Tools
tags:
  - svelte
  - cli
  - sv
  - scaffolding
  - sveltekit
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Svelte CLI sv create

## Overview

`sv create` scaffolds a new SvelteKit project and can add official add-ons during creation. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/10-sv-create.md>

## Usage

```bash
npx sv create [options] [path]
```

## Key Options

- `--from-playground <url>`: generate from a Svelte playground URL
- `--template <name>`: `minimal`, `demo`, or `library`
- `--types <ts|jsdoc>` / `--no-types`
- `--add [add-ons...]` / `--no-add-ons`
- `--install <npm|pnpm|yarn|bun|deno>` / `--no-install`
- `--no-dir-check` <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/10-sv-create.md>

## References

- <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/20-commands/10-sv-create.md>

## Related

- [[svelte-cli-sv-add]]
