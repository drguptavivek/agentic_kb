---
title: SvelteKit Adapter Node
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - adapter-node
  - deploy
  - node
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Node

## Overview

`adapter-node` builds a standalone Node server. Install `@sveltejs/adapter-node` and set it in `svelte.config.js`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/40-adapter-node.md>

## Deploying

Run `npm run build`, then start with `node build`. Copy `package.json` and production `node_modules` (e.g., `npm ci --omit dev`). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/40-adapter-node.md>

## Environment Variables

`.env` files are not loaded in production. Use `node -r dotenv/config build` or `node --env-file=.env build` (Node 20.6+). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/40-adapter-node.md>

## Networking

Defaults: `HOST=0.0.0.0`, `PORT=3000`. Use `SOCKET_PATH` for unix sockets. Use `ORIGIN` or proxy headers (`PROTOCOL_HEADER`, `HOST_HEADER`, `PORT_HEADER`) behind reverse proxies. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/40-adapter-node.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/40-adapter-node.md>

## Related

- [[sveltekit-adapters]]
