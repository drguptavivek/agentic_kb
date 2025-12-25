---
title: Creating a SvelteKit Project
type: howto
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - project-setup
  - cli
  - getting-started
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Creating a SvelteKit Project

## Quick Start

```bash
npx sv create my-app
cd my-app
npm run dev
```

This scaffolds a new project in `my-app` and can prompt for tooling (e.g., TypeScript). Install dependencies if you did not during creation. The dev server runs at `http://localhost:5173`. <https://github.com/sveltejs/kit/blob/main/documentation/docs/10-getting-started/20-creating-a-project.md>

## Core Concepts

- Each page is a Svelte component.
- Routes are created by adding files under `src/routes`. These are server-rendered on first load, then the client app takes over. <https://github.com/sveltejs/kit/blob/main/documentation/docs/10-getting-started/20-creating-a-project.md>

## Editor Setup

Recommended: VS Code + Svelte extension. Other editor options are available. <https://github.com/sveltejs/kit/blob/main/documentation/docs/10-getting-started/20-creating-a-project.md>

## References

- <https://github.com/sveltejs/kit/blob/main/documentation/docs/10-getting-started/20-creating-a-project.md>
- <https://svelte.dev/docs/cli/overview>

## Related

- [[sveltekit-remote-functions]]
