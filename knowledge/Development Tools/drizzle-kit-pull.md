---
title: Drizzle Kit pull
type: reference
domain: Development Tools
tags:
  - drizzle
  - drizzle-kit
  - migrations
  - cli
  - introspection
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Drizzle Kit pull

## Overview

`drizzle-kit pull` introspects an existing database schema and generates `schema.ts`. It supports database-first workflows. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-pull.mdx>

## How It Works

1. Pull database schema (DDL).
2. Generate `schema.ts` in the output folder. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-pull.mdx>

## Usage

```bash
npx drizzle-kit pull
npx drizzle-kit pull --dialect=postgresql --url=postgresql://user:password@host:port/dbname
```

## Required Configuration

Requires `dialect` and DB credentials (`url` or `user/password/host/port/db`). Configure in `drizzle.config.ts` or via CLI. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-pull.mdx>

## Options

- `driver`: exceptions (e.g., `aws-data-api`, `pglite`, `d1-http`)
- `out`: output folder (default `./drizzle`)
- `introspect-casing`: `preserve` or `camel`
- `tablesFilter`, `schemaFilter`, `extensionsFilters` <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-pull.mdx>

## Notes

On-device DBs (Expo SQLite, OP SQLite) cannot be pulled; use embedded migrations instead. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-pull.mdx>

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-pull.mdx>

## Related

- [[drizzle-orm-migrations]]
