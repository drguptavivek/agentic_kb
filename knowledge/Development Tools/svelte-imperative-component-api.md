---
title: Svelte Imperative Component API
type: reference
domain: Development Tools
tags:
  - svelte
  - svelte5
  - imperative
  - mount
  - render
  - hydrate
  - ssr
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Svelte Imperative Component API

## Overview

The imperative component API provides functions to programmatically create, mount, render, and hydrate Svelte components. This is the foundational API for starting Svelte applications on the client and server. <https://svelte.dev/docs/svelte/imperative-component-api>

**Key Functions:**
- `mount()` - Client-side component mounting
- `unmount()` - Component cleanup with transitions
- `render()` - Server-side rendering
- `hydrate()` - Client-side hydration of SSR content

## mount

Instantiates and mounts a component to a target DOM element.

```typescript
import { mount } from 'svelte';
import App from './App.svelte';

const app = mount(App, {
  target: document.querySelector('#app'),
  props: {
    some: 'property'
  }
});
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `target` | `Element \| Document \| ShadowRoot` | Required. Target element where component will be mounted |
| `props` | `Record<string, any>` | Optional. Component properties |
| `intro` | `boolean` | Optional. Play transitions during initial render (default: `true`) |

### Return Value

Returns the component's exports (and props if compiled with `accessors: true`):

```typescript
interface ComponentExports {
  $on?(type: string, callback: (e: any) => void): () => void;
  $set?(props: Partial<Record<string, any>>): void;
  // ... custom exports
}
```

### Multiple Components

You can mount multiple components per page, even from within your application:

```svelte
<script>
  import { mount } from 'svelte';
  import Tooltip from './Tooltip.svelte';
  import { onDestroy } from 'svelte';

  let tooltip;
  let element;

  function showTooltip() {
    tooltip = mount(Tooltip, {
      target: element,
      props: { text: 'Hello!' }
    });
  }

  function hideTooltip() {
    if (tooltip) {
      unmount(tooltip);
      tooltip = null;
    }
  }

  onDestroy(hideTooltip);
</script>

<div bind:this={element} onmouseenter={showTooltip} onmouseleave={hideTooltip}>
  Hover me
</div>
```

### Important Notes

**Effects don't run during `mount`**: Unlike calling `new App(...)` in Svelte 4, things like effects (including `onMount` callbacks and action functions) will not run during `mount`. If you need to force pending effects to run (e.g., in tests), use `flushSync()`:

```typescript
import { mount, flushSync } from 'svelte';

const app = mount(App, { target: document.body });
flushSync(); // Forces all pending effects to run
```

## unmount

Unmounts a component that was previously created with `mount` or `hydrate`.

```typescript
import { mount, unmount } from 'svelte';
import App from './App.svelte';

const app = mount(App, { target: document.body });

// later...
unmount(app, { outro: true });
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `outro` | `boolean` | Play transitions before removing component (default: `false`) |

### Return Value

Returns a `Promise` that resolves after transitions complete if `outro` is `true`, or immediately otherwise.

**Version Note:** Since Svelte 5.13.0, `unmount` returns a `Promise`. Prior versions returned `void`.

### Usage Pattern

```svelte
<script>
  import { mount, unmount } from 'svelte';
  import Modal from './Modal.svelte';

  let modal = null;
  let open = $state(false);

  function openModal() {
    open = true;
    modal = mount(Modal, {
      target: document.body,
      props: { onClose: closeModal }
    });
  }

  async function closeModal() {
    if (modal) {
      await unmount(modal, { outro: true });
      modal = null;
      open = false;
    }
  }
</script>

<button onclick={openModal}>Open Modal</button>
```

## render

Only available on the server when compiling with the `server` option. Returns HTML for SSR.

```typescript
import { render } from 'svelte/server';
import App from './App.svelte';

const result = render(App, {
  props: {
    some: 'property'
  }
});

result.html; // '<html>...</html>'
result.head; // '<head>...</head>'
result.body; // '<body>...</body>'
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `props` | `Record<string, any>` | Optional. Component properties (excluding `$$slots` and `$$events`) |
| `context` | `Map<any, any>` | Optional. Context map for the component |
| `idPrefix` | `string` | Optional. Prefix for auto-generated IDs |
| `csp` | `CspNonce \| CspHashes \| Csp` | Optional. Content Security Policy configuration |

### CSP Configuration

**Using Nonce:**

```typescript
import { render } from 'svelte/server';
import { crypto } from 'node:crypto';

const nonce = crypto.randomUUID();

const { head, body } = render(App, {
  csp: {
    nonce,
  },
});

// Add nonce to CSP header
const cspHeader = `script-src 'nonce-${nonce}'`;
```

**Using Hashes (Static HTML):**

```typescript
const { head, body, hashes } = render(App, {
  csp: {
    hash: true,
  },
});

// hashes.script will be like ["sha256-abcd1234..."]
const cspHeader = `script-src ${hashes.script.map(h => `'${h}'`).join(' ')}`;
```

**Note:** Nonce is preferred over hash for dynamic SSR. Hashes are only for static builds.

### Return Value

```typescript
interface RenderOutput {
  head: string; // HTML that goes into the <head>
  body: string; // HTML that goes into the <body>
}
```

### SSR Pattern

```typescript
// src/server.ts
import { render } from 'svelte/server';
import App from './App.svelte';
import { buildHTML } from './html';

export async function ssr() {
  const { head, body } = render(App, {
    props: {
      url: new URL(request.url)
    }
  });

  return buildHTML(head, body);
}
```

## hydrate

Like `mount`, but reuses existing HTML from SSR output and makes it interactive.

```typescript
import { hydrate } from 'svelte';
import App from './App.svelte';

const app = hydrate(App, {
  target: document.querySelector('#app'),
  props: {
    some: 'property'
  }
});
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `target` | `Element \| Document \| ShadowRoot` | Required. Target element containing SSR HTML |
| `props` | `Record<string, any>` | Optional. Component properties |
| `events` | `Record<string, (e: any) => any>` | Optional. Event handlers |
| `context` | `Map<any, any>` | Optional. Context map for the component |
| `intro` | `boolean` | Optional. Play transitions during hydration (default: `true`) |
| `recover` | `boolean` | Optional. Attempt to recover from hydration mismatches |

### Effects and Hydration

As with `mount`, effects will not run during `hydrate`. Use `flushSync()` immediately afterwards if needed:

```typescript
import { hydrate, flushSync } from 'svelte';

const app = hydrate(App, { target: document.body });
flushSync(); // Forces all pending effects to run
```

### Hydration Pattern

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import { hydrate } from 'svelte';
  import { browser } from '$app/environment';

  let mounted = false;

  if (browser) {
    // Hydrate the app
    mounted = true;
  }
</script>

{#if mounted}
  <slot />
{/if}
```

## Comparison: mount vs hydrate

| Feature | mount | hydrate |
|---------|-------|---------|
| **Use case** | Client-side only app | SSR app with hydration |
| **Initial HTML** | Creates from scratch | Reuses existing SSR HTML |
| **Performance** | Slower initial render | Faster (HTML already exists) |
| **SEO** | Poor (content not in HTML) | Excellent (content in HTML) |
| **Effects** | Don't run during mount | Don't run during hydrate |

## Common Patterns

### Entry Point (Browser)

```typescript
// src/main.ts
import { mount } from 'svelte';
import App from './App.svelte';

const app = mount(App, {
  target: document.body,
  props: {
    // Initial app data
  }
});

export default app;
```

### Entry Point (SSR)

```typescript
// src/entry-server.ts
import { render } from 'svelte/server';
import App from './App.svelte';

export async function handleRequest(request: Request) {
  const { head, body } = render(App, {
    props: {
      url: new URL(request.url)
    }
  });

  return new Response(
    `<!DOCTYPE html>
    <html>
      <head>${head}</head>
      <body>${body}</body>
    </html>`,
    {
      headers: { 'content-type': 'text/html' }
    }
  );
}
```

### Testing Pattern

```typescript
import { mount, flushSync } from 'svelte';
import { describe, it, expect } from 'vitest';
import Counter from './Counter.svelte';

describe('Counter', () => {
  it('increments when clicked', () => {
    const container = document.createElement('div');
    const counter = mount(Counter, { target: container });

    flushSync(); // Ensure effects run

    const button = container.querySelector('button');
    button.click();
    flushSync(); // Ensure reactivity processes

    expect(container.textContent).toContain('1');

    // Cleanup
    counter.$on = undefined;
    counter.$set = undefined;
  });
});
```

### Dynamic Component Loading

```typescript
import { mount, unmount } from 'svelte';

async function loadComponent(name: string) {
  const Component = await import(`./${name}.svelte`);
  return mount(Component.default, { target: document.body });
}

async function switchComponent(from: any, to: string) {
  if (from) {
    await unmount(from, { outro: true });
  }
  return loadComponent(to);
}
```

## Migration from Svelte 4

### Old Way (Svelte 4)

```typescript
// Svelte 4
import App from './App.svelte';

const app = new App({
  target: document.body,
  props: { some: 'property' }
});
```

### New Way (Svelte 5)

```typescript
// Svelte 5
import { mount } from 'svelte';
import App from './App.svelte';

const app = mount(App, {
  target: document.body,
  props: { some: 'property' }
});
```

**Key Changes:**
- Use `mount()` instead of `new Component()`
- Components are no longer classes
- Effects don't run automatically during mount/hydrate

## References

- <https://svelte.dev/docs/svelte/imperative-component-api>
- <https://svelte.dev/docs/svelte/server>
- <https://svelte.dev/docs/svelte/hydratable>

## Related

- [[svelte-hydratable]]
- [[sveltekit-fullstack-features]]
- [[sveltekit-server-side-rendering]]
