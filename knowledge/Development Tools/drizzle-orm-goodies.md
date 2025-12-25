---
title: Drizzle ORM Goodies
type: reference
domain: Development Tools
tags:
  - drizzle
  - orm
  - types
  - logging
  - utilities
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Drizzle ORM Goodies

## Type Helpers

Use `$inferSelect`, `$inferInsert`, or `InferSelectModel` / `InferInsertModel` to derive types from table schemas. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## Logging

Enable query logging with `{ logger: true }` or provide custom `DefaultLogger`/`Logger` implementations. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## Multi-Project Schema

Use `*TableCreator` to add prefixes (e.g., `project1_`) and filter tables via `tablesFilter`. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## SQL Output and Raw Queries

- Use `toSQL()` to print SQL and params from query builders.
- Use `db.execute` for parameterized raw SQL. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## Standalone Query Builder

`QueryBuilder` can generate SQL without a DB instance. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## Schema Utilities

- `getTableColumns` for selecting subsets of columns.
- `getTableConfig` for introspecting table metadata. <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## Type Checks and Mocking

- Use `is()` for Drizzle type checks instead of `instanceof`.
- Use `drizzle.mock()` for test DB instances (optionally with schema). <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## References

- <https://raw.githubusercontent.com/drizzle-team/drizzle-orm-docs/main/src/content/docs/goodies.mdx>

## Related

- [[drizzle-orm-migrations]]
