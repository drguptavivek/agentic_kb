---
title: Drizzle Kit push
type: reference
domain: Development Tools
tags:
  - drizzle
  - drizzle-kit
  - migrations
  - cli
  - schema
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Drizzle Kit push

## Overview

`drizzle-kit push` applies schema changes directly to the database without generating SQL files. It is a code-first workflow and good for rapid prototyping. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-push.mdx>

## How It Works

1. Read schema files into a JSON snapshot.
2. Introspect current database schema.
3. Generate SQL based on diff.
4. Apply SQL to the database. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-push.mdx>

## Usage

```bash
npx drizzle-kit push
npx drizzle-kit push --dialect=postgresql --schema=./src/schema.ts --url=postgresql://user:password@host:port/dbname
```

## Required Configuration

Requires `dialect`, `schema`, and DB credentials (`url` or `user/password/host/port/db`). Configure in `drizzle.config.ts` or via CLI. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-push.mdx>

## Filters and Drivers

Use `tablesFilter`, `schemaFilter`, and `extensionsFilters` to limit scope. Some driver exceptions (e.g., `pglite`, `d1-http`) require explicit `driver` selection. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-push.mdx>

## Safety Options

- `--verbose`: print SQL before execution
- `--strict`: always ask for approval
- `--force`: auto-accept data-loss statements <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-push.mdx>

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-push.mdx>

## Related

- [[drizzle-orm-migrations]]
