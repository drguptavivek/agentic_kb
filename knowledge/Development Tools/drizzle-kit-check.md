---
title: Drizzle Kit check
type: reference
domain: Development Tools
tags:
  - drizzle
  - drizzle-kit
  - migrations
  - cli
  - consistency
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Drizzle Kit check

## Overview

`drizzle-kit check` validates consistency of your generated SQL migration history, useful for teams working on multiple branches. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-check.mdx>

## Requirements

Requires `dialect` and database credentials via `drizzle.config.ts` or CLI flags. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-check.mdx>

## Usage

```bash
npx drizzle-kit check
npx drizzle-kit check --dialect=postgresql
```

## Options

- `dialect` (required): `postgresql`, `mysql`, or `sqlite`
- `out`: migrations folder (default `./drizzle`)
- `config`: config file path (default `drizzle.config.ts`) <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-check.mdx>

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-check.mdx>

## Related

- [[drizzle-kit-generate]]
