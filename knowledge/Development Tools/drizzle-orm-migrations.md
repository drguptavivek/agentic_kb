---
title: Drizzle ORM Migrations Fundamentals
type: reference
domain: Development Tools
tags:
  - drizzle
  - orm
  - migrations
  - database
  - schema
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Drizzle ORM Migrations Fundamentals

## Overview

Drizzle supports both **database-first** (DB schema is source of truth) and **codebase-first** (TypeScript schema is source of truth) migration workflows. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>

## drizzle-kit Commands

- `drizzle-kit pull`: pull database schema into TypeScript (database-first)
- `drizzle-kit push`: apply schema changes directly to DB (codebase-first, no SQL files)
- `drizzle-kit generate`: generate SQL migration files (codebase-first)
- `drizzle-kit migrate`: apply generated SQL migrations <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>

## Migration Options

1. **Database-first**: manage schema externally, use `drizzle-kit pull` to sync TS schema.
2. **Codebase-first, push**: use `drizzle-kit push` to apply schema directly.
3. **Codebase-first, SQL**: use `drizzle-kit generate` + `drizzle-kit migrate` to create/apply SQL files. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>

## Additional Migration Flows

4. **Runtime migrations**: generate SQL with `drizzle-kit generate` and apply during app runtime via the Drizzle migrator (common for monoliths and serverless deploys). <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>
5. **External tools**: generate SQL with `drizzle-kit generate` and apply manually or with tools like Bytebase/Liquibase/Atlas. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>
6. **Export-only**: use `drizzle-kit export` to print SQL for use with Atlas or other tooling. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>

## Sequencing and Review (Doc-backed)

Drizzle’s generate flows read previous migration folders, compute diffs, and persist `snapshot.json` and `migration.sql` for each new migration. The migrate flow reads migration files, checks migration history, and applies unapplied migrations. This implies a strict file-sequencing model based on the migrations folder contents and database history. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>

## Local Policy (Team)

- Never manually create migration files; always generate via `drizzle-kit generate`.
- Always review generated `migration.sql` before applying.

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/migrations.mdx>

## Related

- [[svelte-cli-addon-drizzle]]
