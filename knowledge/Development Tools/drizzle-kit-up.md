---
title: Drizzle Kit up
type: reference
domain: Development Tools
tags:
  - drizzle
  - drizzle-kit
  - migrations
  - cli
  - snapshots
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Drizzle Kit up

## Overview

`drizzle-kit up` upgrades Drizzle schema snapshots to newer versions when breaking changes are introduced. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-up.mdx>

## Requirements

Requires `dialect` and DB credentials via `drizzle.config.ts` or CLI. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-up.mdx>

## Usage

```bash
npx drizzle-kit up
npx drizzle-kit up --dialect=postgresql
```

## Options

- `dialect` (required): `postgresql`, `mysql`, `sqlite`
- `out`: migrations folder (default `./drizzle`)
- `config`: config file path (default `drizzle.config.ts`) <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-up.mdx>

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-up.mdx>

## Related

- [[drizzle-kit-generate]]
