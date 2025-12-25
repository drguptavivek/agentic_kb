---
title: Better Auth Installation
type: howto
domain: Development Tools
tags:
  - auth
  - better-auth
  - installation
  - env
  - database
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Better Auth Installation

## Install the Package

Install Better Auth in your project. If you have separate client and server packages, install it in both. <https://www.better-auth.com/docs/installation>

## Set Environment Variables

Create a `.env` file at the project root:

- **Secret Key**: at least 32 characters with high entropy. Use `openssl rand -base64 32` to generate one.
- **Base URL**: the base URL of your app (used by the client when pointing at the auth server). <https://www.better-auth.com/docs/installation>

## Create the Auth Instance

Create `auth.ts` in one of these locations (or under `src/`, `app/`, or `server/`):

- project root
- `lib/`
- `utils/`

Export the instance as `auth` or as the default export. <https://www.better-auth.com/docs/installation>

## Configure Database

Better Auth uses a database for user data. Supported options include SQLite, PostgreSQL, MySQL, and supported ORM adapters. Stateless mode is available but most plugins require a database. <https://www.better-auth.com/docs/installation>

## Create Database Tables

Use the Better Auth CLI to manage schema:

- **Generate**: produce an ORM schema or SQL migration file. Use this when you plan to apply migrations yourself.
- **Migrate**: create required tables directly in the database (Kysely adapter only).

If you want to create the schema manually, use the core schema described in the database section of the docs. <https://www.better-auth.com/docs/installation>

## Configure Authentication Methods

Enable the authentication methods you need. Built-in support includes email/password and social sign-on. Additional methods (passkey, username, magic link, etc.) are available via plugins. <https://www.better-auth.com/docs/installation>

## Mount the Handler

Create a catch-all route for `/api/auth/*` (or your configured base path). The handler must run on a server route that receives Request/Response objects. <https://www.better-auth.com/docs/installation>

Cloudflare Workers:
- Enable `nodejs_compat` for AsyncLocalStorage support in `wrangler.toml`.

Express v5:
- Use the named wildcard syntax `/{*any}` instead of `*` for catch-all routes. <https://www.better-auth.com/docs/installation>

## Create Client Instance

Use the client library for your framework (e.g., `better-auth/react`). Create a client and point it at your auth server base URL if it differs from the app origin or path. If you use a custom base path (not `/api/auth`), include the path in the URL. <https://www.better-auth.com/docs/installation>

## References

- <https://www.better-auth.com/docs/installation>
