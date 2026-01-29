---
title: New Features in Svelte 5 / SvelteKit 2
type: reference
domain: Development Tools
tags:
  - svelte
  - svelte5
  - sveltekit
  - sveltekit2
  - new-features
  - async-ssr
  - forking
  - streaming
  - form-api
  - context
  - inspect
  - boundary
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# New Features in Svelte 5 / SvelteKit 2

## Overview

Svelte 5 and SvelteKit 2 introduce significant new features that improve developer experience, performance, and enable new patterns. This document covers the major additions announced for Svelte 5.x and SvelteKit 2.x.

**Key New Features:**
- Async SSR with streaming support
- Forking API for speculative data loading
- Stream uploads for better form handling
- Enhanced Form API (remote functions)
- Context API improvements
- `$inspect` for debugging
- `<svelte:boundary>` for error handling
- `hydratable` for SSR performance

## Async SSR with await Expressions

Svelte 5.36+ introduces asynchronous expressions, allowing you to use `await` directly in your components.

### Opt-in Required

This feature is currently experimental and requires opting in:

```javascript
// svelte.config.js
export default {
  compilerOptions: {
    experimental: {
      async: true
    }
  }
};
```

**Note:** The experimental flag will be removed in Svelte 6.

### Where You Can Use await

As of Svelte 5.36, you can use `await` in three new places:

1. **At the top level of your component's `<script>`**
2. **Inside `$derived(...)` declarations**
3. **Inside your markup**

```svelte
<script>
  // Top-level await in script
  const data = await fetchData();

  // Inside $derived
  const doubled = $derived(await fetchDouble(data));
</script>

<!-- Inside markup -->
<h1>{await fetchData()}</h1>
```

### Synchronized Updates

When an `await` expression depends on state, changes to that state won't be reflected until async work completes — preventing inconsistent UI:

```svelte
<script>
  let a = $state(1);
  let b = $state(2);

  async function add(a, b) {
    await new Promise(f => setTimeout(f, 500));
    return a + b;
  }
</script>

<input type="number" bind:value={a}>
<input type="number" bind:value={b}>

<!-- Updates atomically when add() resolves -->
<p>{a} + {b} = {await add(a, b)}</p>
```

If you increment `a`, the text won't show `2 + 2 = 3` then update to `2 + 2 = 4`. Instead, it waits for `add(a, b)` to resolve and shows `2 + 2 = 4` directly.

### Concurrency

Independent `await` expressions run in parallel:

```svelte
<p>{await one()}</p>
<p>{await two()}</p>
```

Both functions run simultaneously, even though they appear visually sequential.

**Inside `$derived`:** Independent derived states update independently after initial creation:

```javascript
// These run sequentially the first time,
// but update independently when dependencies change
let a = $derived(await functionOne());
let b = $derived(await functionTwo());
```

**⚠️ Warning:** Sequential awaits may trigger `await_waterfall` warnings.

### During SSR

When using `await` expressions during SSR:
- The renderer waits for promises to resolve before returning HTML
- Loading states can be shown with `<svelte:boundary>` and `pending` snippets
- In the future, streaming SSR will render content incrementally

### Streaming Support (Future)

> **Note:** Streaming SSR is planned for a future Svelte release. When implemented, it will render HTML in chunks as promises resolve, reducing time-to-first-byte.

Currently, all `await` expressions resolve before `await render(...)` returns.

### SvelteKit Integration

SvelteKit 2 supports async SSR through load functions:

```typescript
// +page.server.js
export async function load({ fetch }) {
  const [posts, users] = await Promise.all([
    fetch('/api/posts').then(r => r.json()),
    fetch('/api/users').then(r => r.json())
  ]);

  return { posts, users };
}
```

**Breaking Change:** In SvelteKit 2, top-level promises are no longer automatically awaited. You must use `Promise.all` or `await` explicitly:

```typescript
// ❌ SvelteKit 1 - automatically awaited
export async function load({ fetch }) {
  const a = fetch(url1).then(r => r.json());
  const b = fetch(url2).then(r => r.json());
  return { a, b };
}

// ✅ SvelteKit 2 - explicit awaiting
export async function load({ fetch }) {
  const [a, b] = await Promise.all([
    fetch(url1).then(r => r.json()),
    fetch(url2).then(r => r.json())
  ]);
  return { a, b };
}
```

### Loading States with <svelte:boundary>

Use `<svelte:boundary>` with `pending` snippet for initial loading UI:

```svelte
<script>
  async function delayed(message) {
    await new Promise(f => setTimeout(f, 1000));
    return message;
  }
</script>

<svelte:boundary>
  <p>{await delayed('hello!')}</p>

  {#snippet pending()}
    <p>loading...</p>
  {/snippet}
</svelte:boundary>
```

**Important:** The `pending` snippet only shows on first creation. For subsequent async updates, use `$effect.pending()`:

```svelte
<script>
  import { $effect } from 'svelte';

  let validating = $state(false);

  $effect(() => {
    if (someCondition) {
      validating = true;
      // async work...
    }
  });
</script>

{#if validating}
  <p>Validating...</p>
{/if}
```

### Using settled()

The `settled()` function returns a promise that resolves when all current async work completes:

```svelte
<script>
  import { tick, settled } from 'svelte';

  async function handleClick() {
    let updating = true;

    // Ensure the UI reflects the change before async work
    await tick();

    // Do async state changes
    let color = 'octarine';
    let answer = 42;

    // Wait for all async work and DOM updates to complete
    await settled();

    // All updates affected by `color` and `answer` have now been applied
    updating = false;
  }
</script>
```

### Error Handling

Errors in `await` expressions bubble to the nearest error boundary (`<svelte:boundary>` with `failed` snippet).

### Forking

The `fork()` API (added in Svelte 5.42) enables speculative data loading — running `await` expressions that you expect to happen in the near future.

### Purpose

Forking is primarily intended for frameworks like SvelteKit to implement preloading when users signal intent to navigate (e.g., hover on a link).

### Basic Usage

```svelte
<script>
  import { fork } from 'svelte';
  import Menu from './Menu.svelte';

  let open = $state(false);
  let pending = null;

  function preload() {
    pending ??= fork(() => {
      open = true;
    });
  }

  function discard() {
    pending?.discard();
    pending = null;
  }
</script>

<button
  onfocusin={preload}
  onfocusout={discard}
  onpointerenter={preload}
  onpointerleave={discard}
  onclick={() => {
    pending?.commit();
    pending = null;
    open = true;
  }}
>
  open menu
</button>

{#if open}
  <!-- any async work inside this component will start
       as soon as the fork is created -->
  <Menu onclose={() => open = false} />
{/if}
```

### Fork API

```typescript
interface Fork {
  // Commit the fork - apply the state changes
  commit(): void;

  // Discard the fork - cancel pending work
  discard(): void;
}

function fork<T>(fn: () => T): Fork;
```

### Usage Pattern

1. **Create fork:** When user signals intent (hover, focus)
2. **Commit fork:** When user actually triggers action (click)
3. **Discard fork:** When user cancels intent (mouseleave)

### Use Cases

- **Navigation preloading:** Start loading page data on hover
- **Menu preloading:** Fetch menu items before menu opens
- **Modal preloading:** Load modal content before opening
- **Tab preloading:** Load tab content on hover

### SvelteKit Integration

SvelteKit can use forking for link prefetching:

```typescript
// Example future pattern
import { fork } from 'svelte';

function prefetchRoute(url: string) {
  const forked = fork(async () => {
    // Preload the route
    await loadRouteData(url);
  });

  // Store fork for later commit or discard
  return forked;
}
```

## Stream Uploads

SvelteKit 2.49.0 introduces streaming file uploads in `form` remote functions, allowing form data to be accessed before large files finish uploading.

### Basic Streaming Pattern

```typescript
// src/routes/upload/data.remote.ts
import { form } from '$app/server';

export const uploadFile = form(async (data: {
  file: File;
  description: string;
}) => {
  // File data is already streamed in
  const file = data.file;

  // Process file
  const buffer = await file.arrayBuffer();
  // ... upload to storage, etc.

  return { success: true };
});
```

### Accessing Form Data During Upload

```typescript
export const uploadWithMetadata = form(async (data) => {
  // Access other form fields while file streams
  const { title, category, file } = data;

  // File is already uploaded by the time this runs
  console.log(`Uploading ${title} to ${category}`);

  // Process the file
  const url = await uploadToStorage(file);

  return { url };
});
```

### Large File Support

```typescript
export const uploadLargeFile = form(async (data: {
  video: File;
}) => {
  // File streams efficiently even for very large files
  const video = data.video;

  // Check file size
  if (video.size > 500 * 1024 * 1024) { // 500MB
    throw new Error('File too large');
  }

  // Process in chunks if needed
  const stream = video.stream();
  // ... process stream

  return { success: true };
});
```

### Enhanced FormData Handling

SvelteKit 2 provides better support for streaming `FormData`:

```typescript
// +page.server.js
export const actions = {
  async upload({ request }) {
    const formData = await request.formData();
    const file = formData.get('file');

    // Stream file upload
    const stream = file.stream();
    // Process stream...
  }
};
```

### Form API with Remote Functions

The new `form` remote function provides type-safe form handling:

```typescript
// src/routes/blog/data.remote.ts
import { form } from '$app/server';

export const createPost = form(async (data: { title: string; content: string }) => {
  const post = await db.posts.create({
    title: data.title,
    content: data.content
  });

  return post;
});
```

```svelte
<!-- +page.svelte -->
<script>
  import { createPost } from './data.remote';
</script>

<form {...createPost}>
  <input name="title" type="text" />
  <textarea name="content"></textarea>
  <button>Publish!</button>
</form>
```

## Enhanced Form API

### Remote Functions

Remote functions (query, command, form) provide type-safe client-server communication:

```typescript
// query - for fetching data
export const getUser = query(async ({ id }: { id: string }) => {
  return await db.users.findById(id);
});

// command - for mutations
export const updateUser = command(async ({ id, name }: { id: string; name: string }) => {
  return await db.users.update(id, { name });
});

// form - for form submissions
export const contactForm = form(async (data: ContactFormData) => {
  await sendEmail(data);
  return { success: true };
});
```

### Form Validation

```typescript
import { form } from '$app/server';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  message: z.string().min(10)
});

export const contactForm = form(schema, async (data) => {
  // data is fully typed
  await sendEmail(data);
});
```

### Snapshots

SvelteKit 2 includes snapshots for preserving form state during navigation:

```typescript
import { snapshot } from '$app/state';

// Form state is automatically preserved
const formData = $state({
  name: '',
  email: ''
});

// Navigate without losing form data
function navigateAway() {
  snapshot.set(formData); // Save state
  goto('/other-page');
}

// Restore state when returning
if (snapshot.get()) {
  Object.assign(formData, snapshot.get());
}
```

## Context API Improvements

Svelte 5 provides an improved context API with better TypeScript support.

### Basic Usage

```svelte
<script>
  import { setContext } from 'svelte';

  let counter = $state({
    count: 0
  });

  setContext('counter', counter);
</script>

<button onclick={() => counter.count += 1}>
  increment
</button>

<Child />
```

```svelte
<!-- Child.svelte -->
<script>
  import { getContext } from 'svelte';

  const counter = getContext('counter');
</script>

<p>Count: {counter.count}</p>
```

### New Context Functions

- `setContext(key, value)` - Set context value
- `getContext(key)` - Get context value
- `hasContext(key)` - Check if context exists
- `getAllContexts()` - Get all context values

### Type-Safe Context

```typescript
// context.ts
import { setContext, getContext } from 'svelte';
import type { Writable } from 'svelte/store';

interface UserContext {
  user: User;
  logout: () => void;
}

const USER_KEY = Symbol('user');

export function setUserContext(userContext: UserContext) {
  setContext(USER_KEY, userContext);
}

export function getUserContext(): UserContext {
  return getContext(USER_KEY);
}
```

### Context with Reactive State

You can store reactive state in context, and all consumers will react to changes:

```svelte
<!-- Parent.svelte -->
<script>
  import { setContext } from 'svelte';
  import Child from './Child.svelte';

  let theme = $state('dark');

  setContext('theme', {
    get value() { return theme; },
    set value(v) { theme = v; }
  });
</script>

<Child />
<Child />
<Child />
```

All child components will re-render when `theme` changes.

## print (AST to Source Code)

The `print` function (added in Svelte 5.45.0) converts a Svelte AST node back into Svelte source code. It's primarily intended for tools that parse and transform components using the compiler's modern AST representation.

```typescript
import { print } from 'svelte/compiler';
import { parse } from 'svelte/compiler';

// Parse a component
const ast = parse(`<div>Hello world</div>`);

// Convert AST back to source
const code = print(ast.instance);
console.log(code); // "<div>Hello world</div>"
```

### Use Cases

- **Code transformers** - Modify components and output valid Svelte code
- **Code generators** - Programmatically create components
- **AST tools** - Build linters, formatters, codemods
- **Debugging** - Inspect compiled component structure

### Example: Simple Transformer

```typescript
import { parse, print } from 'svelte/compiler';

function addTestId(component) {
  const ast = parse(component);

  // Transform AST...
  // Add testid attributes to elements

  return print(ast);
}
```

### Module vs Instance

```typescript
const ast = parse(component);

// Print module script (<script context="module">)
const moduleCode = print(ast.module);

// Print instance script (<script>)
const instanceCode = print(ast.instance);

// Print template
const templateCode = print(ast.html);
```

## $inspect for Debugging

The `$inspect` rune provides powerful debugging capabilities for tracking state changes.

### Basic Usage

```svelte
<script>
  let count = $state(0);

  $inspect(count);
</script>

<button onclick={() => count++}>
  Increment
</button>
```

On every update of `count`, the value will be logged to the console with a stack trace.

### Custom Inspection

Use `.with()` to customize inspection behavior:

```svelte
<script>
  let count = $state(0);

  $inspect(count).with((type, value) => {
    if (type === 'update') {
      debugger; // or console.trace, or whatever you want
    }
  });
</script>
```

### Trace Mode

`$inspect.trace()` provides detailed stack traces:

```svelte
<script>
  let data = $state({ items: [] });

  $inspect.trace(data);
</script>
```

### Inspector Generator

For components that use generators, use `inspect` with `.trace()`:

```svelte
<script>
  $inspect.trace().with((type) => {
    console.log('State changed:', type);
  });
</script>
```

## <svelte:boundary> for Error Handling

The `<svelte:boundary>` element (added in Svelte 5.3) provides error boundaries and async loading states.

### Pending Snippet

Show loading state while await expressions resolve:

```svelte
<svelte:boundary>
  <p>{await delayed('hello!')}</p>

  {#snippet pending()}
    <p>loading...</p>
  {/snippet}
</svelte:boundary>
```

### Error Handling

Catch and handle rendering errors:

```svelte
<svelte:boundary>
  <FlakyComponent />

  {#snippet failed(error, reset)}
    <button onclick={reset}>oops! try again</button>
  {/snippet}
</svelte:boundary>
```

### Error Reporting

```svelte
<script>
  function onerror(e, reset) {
    reportToSentry(e);
  }
</script>

<svelte:boundary onerror={onerror}>
  <FlakyComponent />
</svelte:boundary>
```

### External Error Display

```svelte
<script>
  let error = $state(null);
  let reset = $state(() => {});

  function onerror(e, r) {
    error = e;
    reset = r;
  }
</script>

<svelte:boundary {onerror}>
  <FlakyComponent />
</svelte:boundary>

{#if error}
  <button onclick={() => { error = null; reset(); }}>
    oops! try again
  </button>
{/if}
```

## hydratable with CSP Support

The `hydratable` API (see [[svelte-hydratable]]) now supports Content Security Policies through the `csp` option in `render()` (Svelte 5.46.0):

```typescript
import { render } from 'svelte/server';

const nonce = crypto.randomUUID();

const { head, body } = render(App, {
  props: { /* ... */ },
  csp: {
    nonce, // or hash: true
  },
});
```

This prevents double data fetching during hydration while maintaining CSP compliance:

```svelte
<script>
  import { hydratable } from 'svelte';

  // Fetches on server, serializes result, includes in response
  // Client deserializes directly - no refetch
  const user = await hydratable('user', () => getUser());
</script>
```

## Migration Considerations

### SvelteKit 1 → 2 Breaking Changes

1. **Top-level promises no longer awaited**
2. **`$app/stores` deprecated** - Use `$app/state` and runes
3. **`resolvePath` removed**
4. **Form actions simplified**

### SvelteKit 2.48.8 Breaking Changes

1. **`invalid` must be imported from `@sveltejs/kit`**:
   ```typescript
   // Before (worked indirectly)
   import { invalid } from '$app/server';

   // After (correct import)
   import { invalid } from '@sveltejs/kit';
   ```

2. **`submitter` option removed from experimental form `validate()`**:
   ```typescript
   // Before (with submitter option)
   form.validate(data, { submitter: customSubmitter })

   // After (always uses default submitter)
   form.validate(data)
   ```

## CLI Updates

### Svelte CLI (sv)

The Svelte CLI has received significant updates:

**Cloudflare Support (sv@0.11.0):**

```bash
# Create a new SvelteKit project with Cloudflare adapter
npx sv create my-app --template cloudflare

# Or add Cloudflare to existing project
npx sv add cloudflare
```

**Add-ons in Create Command (sv@0.10.0):**

```bash
# Create project and add add-ons in one command
npx sv create my-app --add tailwind eslint prettier
```

**Skip Directory Checks (sv@0.9.15):**

```bash
# Create in non-empty directory without prompts
npx sv create my-app --no-dir-check
```

**Wrapped Links (sv@0.9.14):**

CLI now wraps links with `resolve()` to follow best practices.

### MCP Tools (mcp@0.1.16)

The Svelte MCP (Model Context Protocol) now exposes tools as both a JS API and CLI for better AI/LLM integration.

## Adapter Updates

### Vercel Adapter (adapter-vercel@6.2.0)

Now supports Node.js 24 for improved performance and security.

```bash
npm update @sveltejs/adapter-vercel
```

### Auto Adapter (adapter-auto@7.0.0)

Updated alongside Vercel adapter with Node 24 support.

## Performance Improvements

January 2026 brought significant performance improvements to the Svelte language-tools (VS Code extension, language server). Make sure your extensions are up to date for:
- Faster IntelliSense
- Improved type checking
- Better error reporting
- Enhanced completion suggestions

### Svelte 4 → 5 Breaking Changes

1. **Components no longer classes** - Use `mount()` instead of `new Component()`
2. **Runes required for reactivity**
3. **`export let` → `$props`**
4. **`<slot>` → `{@render}`**

## References

- <https://svelte.dev/docs/svelte/await-expressions>
- <https://svelte.dev/docs/svelte/$inspect>
- <https://svelte.dev/docs/svelte/svelte-boundary>
- <https://svelte.dev/docs/svelte/hydratable>
- <https://kit.svelte.dev/docs/migrating-to-sveltekit-2>

## Related

- [[sveltekit-remote-functions]]
- [[svelte-hydratable]]
- [[svelte-imperative-component-api]]
- [[sveltekit-security-advisories-2025]]
