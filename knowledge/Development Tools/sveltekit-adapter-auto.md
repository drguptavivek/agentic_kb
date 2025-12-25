---
title: SvelteKit Adapter Auto
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - adapter-auto
  - deploy
  - zero-config
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Adapter Auto

## Overview

`adapter-auto` detects supported platforms at deploy time and installs the correct adapter. It is the default when creating a project with `npx sv create`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/30-adapter-auto.md>

## Supported Targets

Cloudflare Pages, Netlify, Vercel, Azure Static Web Apps, AWS via SST, and Google Cloud Run (Node). <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/30-adapter-auto.md>

## When to Switch

Install the platform-specific adapter to set options (e.g., `edge: true`) or to improve CI install times. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/30-adapter-auto.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/25-build-and-deploy/30-adapter-auto.md>

## Related

- [[sveltekit-adapters]]
