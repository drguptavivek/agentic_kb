---
title: Drizzle Kit generate
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

# Drizzle Kit generate

## Overview

`drizzle-kit generate` creates SQL migrations from your Drizzle schema and stores `migration.sql` + `snapshot.json` in a timestamped folder. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-generate.mdx>

## How It Works

1. Reads schema file(s) into a JSON snapshot.
2. Compares against the latest snapshot in previous migration folders.
3. Generates SQL migrations (prompts for renames if needed).
4. Writes `migration.sql` and `snapshot.json` to a new migrations folder. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-generate.mdx>

## Required Configuration

You must provide `dialect` and `schema` via `drizzle.config.ts` or CLI flags. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-generate.mdx>

## Options

- `--name`: custom migration name
- `--custom`: create an empty migration for manual SQL
- `--config`: alternate config file
- `--out`: output folder (default `./drizzle`)
- `--breakpoints`: SQL breakpoints (default `true`) <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-generate.mdx>

## Schema Paths

`schema` accepts a glob to include multiple schema files. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-generate.mdx>

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/drizzle-kit-generate.mdx>

## Related

- [[drizzle-orm-migrations]]
