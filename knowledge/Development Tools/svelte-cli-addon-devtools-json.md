---
title: Svelte CLI Add-on devtools-json
type: reference
domain: Development Tools
tags:
  - svelte
  - cli
  - add-ons
  - devtools
  - vite
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Svelte CLI Add-on devtools-json

## Overview

Installs `vite-plugin-devtools-json` to serve `/.well-known/appspecific/com.chrome.devtools.json` for Chromium DevTools workspaces. Enables read/write access to project files for Chromium users. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/30-add-ons/03-devtools-json.md>

## Usage

```bash
npx sv add devtools-json
```

## Alternatives

Disable the DevTools Project Settings flag in Chrome or respond to the request manually in `handle` to avoid warnings without the plugin. <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/30-add-ons/03-devtools-json.md>

## References

- <https://raw.githubusercontent.com/sveltejs/cli/main/documentation/docs/30-add-ons/03-devtools-json.md>

## Related

- [[svelte-cli-sv-add]]
