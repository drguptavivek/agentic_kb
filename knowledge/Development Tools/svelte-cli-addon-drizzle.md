---
title: Svelte CLI Add-on drizzle
type: reference
domain: Development Tools
tags:
  - svelte
  - cli
  - add-ons
  - drizzle
  - database
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Svelte CLI Add-on drizzle

## Overview

Adds Drizzle ORM setup with server-only DB access, `.env` for credentials, Lucia compatibility, and optional Docker config. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/30-add-ons/05-drizzle.md>

## Usage

```bash
npx sv add drizzle
```

## Options

- `database`: `postgresql`, `mysql`, or `sqlite`
- `client`: varies by database (e.g., `postgres.js`, `neon`, `mysql2`, `planetscale`, `better-sqlite3`, `libsql`, `turso`)
- `docker`: `yes` for Postgres/MySQL docker-compose <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/30-add-ons/05-drizzle.md>

## References

- <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/30-add-ons/05-drizzle.md>

## Related

- [[svelte-cli-addon-lucia]]
