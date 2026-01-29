---
title: Svelte Events API (svelte/events)
type: reference
domain: Development Tools
tags:
  - svelte
  - events
  - event-handlers
  - window
  - document
  - cleanup
  - imperative
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Svelte Events API (svelte/events)

## Overview

The `svelte/events` module provides the `on()` function for attaching event handlers to the window, document, or elements with automatic cleanup. Using `on()` instead of `addEventListener` ensures proper ordering relative to declarative handlers (like `onclick`). <https://svelte.dev/docs/svelte/svelte-events>

## on

Attaches an event handler and returns a cleanup function to remove it.

```typescript
import { on } from 'svelte/events';
```

### Window Events

```typescript
function on<Type extends keyof WindowEventMap>(
  window: Window,
  type: Type,
  handler: (
    this: Window,
    event: WindowEventMap[Type]
  ) => any,
  options?: AddEventListenerOptions
): () => void;
```

**Example:**
```svelte
<script>
  import { on } from 'svelte/events';
  import { onMount } from 'svelte';

  onMount(() => {
    const cleanup = on(window, 'resize', (e) => {
      console.log('Window resized:', e);
    });

    // Return cleanup function
    return cleanup;
  });
</script>
```

### Document Events

```typescript
function on<Type extends keyof DocumentEventMap>(
  document: Document,
  type: Type,
  handler: (
    this: Document,
    event: DocumentEventMap[Type]
  ) => any,
  options?: AddEventListenerOptions
): () => void;
```

**Example:**
```svelte
<script>
  import { on } from 'svelte/events';

  let key = $state('');

  const cleanup = on(document, 'keydown', (e) => {
    key = e.key;
  });
</script>

<p>Last key: {key}</p>
```

### Element Events

```typescript
function on<
  Element extends HTMLElement,
  Type extends keyof HTMLElementEventMap
>(
  element: Element,
  type: Type,
  handler: (
    this: Element,
    event: HTMLElementEventMap[Type]
  ) => any,
  options?: AddEventListenerOptions
): () => void;
```

**Example:**
```svelte
<script>
  import { on } from 'svelte/events';
  import { onMount } from 'svelte';

  let div;

  onMount(() => {
    const cleanup = on(div, 'click', (e) => {
      console.log('Div clicked!', e);
    });

    return cleanup;
  });
</script>

<div bind:this={div}>Click me</div>
```

### MediaQueryList Events

```typescript
function on<
  Element extends MediaQueryList,
  Type extends keyof MediaQueryListEventMap
>(
  element: Element,
  type: Type,
  handler: (
    this: Element,
    event: MediaQueryListEventMap[Type]
  ) => any,
  options?: AddEventListenerOptions
): () => void;
```

**Example:**
```svelte
<script>
  import { on } from 'svelte/events';

  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  let isDark = $state(mediaQuery.matches);

  const cleanup = on(mediaQuery, 'change', (e) => {
    isDark = e.matches;
  });
</script>

<p>Dark mode: {isDark}</p>
```

### Generic EventTarget

```typescript
function on(
  element: EventTarget,
  type: string,
  handler: EventListener,
  options?: AddEventListenerOptions
): () => void;
```

**Example:**
```svelte
<script>
  import { on } from 'svelte/events';

  const customTarget = new EventTarget();

  const cleanup = on(customTarget, 'customevent', (e) => {
    console.log('Custom event:', e.detail);
  });
</script>
```

## Why Use on() Instead of addEventListener?

### 1. Proper Event Ordering

Svelte uses **event delegation** for declarative handlers (like `onclick`). Using `on()` ensures your imperative handlers are called in the correct order relative to declarative ones.

```svelte
<!-- Bad: addEventListener might execute before/after declarative handlers -->
<script>
  let div;

  onMount(() => {
    div.addEventListener('click', handler); // Unpredictable order
  });
</script>

<div bind:this={div} onclick={declarativeHandler}>
  Click me
</div>

<!-- Good: on() respects event delegation order -->
<script>
  let div;

  onMount(() => {
    const cleanup = on(div, 'click', handler); // Correct order
    return cleanup;
  });
</script>

<div bind:this={div} onclick={declarativeHandler}>
  Click me
</div>
```

### 2. Automatic Cleanup

The returned cleanup function makes it easy to remove event handlers:

```svelte
<script>
  import { on } from 'svelte/events';
  import { onMount } from 'svelte';

  onMount(() => {
    const cleanup1 = on(window, 'resize', handleResize);
    const cleanup2 = on(window, 'scroll', handleScroll);

    // Clean up both listeners when component unmounts
    return () => {
      cleanup1();
      cleanup2();
    };
  });
</script>
```

### 3. Type Safety

TypeScript provides full type inference for event types:

```typescript
// TypeScript knows 'e' is a MouseEvent
const cleanup = on(window, 'click', (e) => {
  console.log(e.clientX); // ✅ Type-safe
});

// TypeScript knows 'e' is a KeyboardEvent
const cleanup2 = on(document, 'keydown', (e) => {
  console.log(e.key); // ✅ Type-safe
});
```

## Common Patterns

### Media Query Listener

```svelte
<script>
  import { on } from 'svelte/events';

  const mediaQuery = window.matchMedia('(min-width: 768px)');
  let isDesktop = $state(mediaQuery.matches);

  const cleanup = on(mediaQuery, 'change', (e) => {
    isDesktop = e.matches;
  });
</script>

<p>
  {isDesktop ? 'Desktop' : 'Mobile'} view
</p>
```

### Keyboard Shortcuts

```svelte
<script>
  import { on } from 'svelte/events';

  const cleanup = on(document, 'keydown', (e) => {
    // Ctrl/Cmd + S to save
    if ((e.ctrlKey || e.metaKey) && e.key === 's') {
      e.preventDefault();
      save();
    }

    // Escape to close
    if (e.key === 'Escape') {
      close();
    }
  });
</script>
```

### Window Resize

```svelte
<script>
  import { on } from 'svelte/events';
  import { debounce } from '$lib/utils';

  let width = $state(window.innerWidth);

  const handleResize = debounce(() => {
    width = window.innerWidth;
  }, 100);

  const cleanup = on(window, 'resize', handleResize);
</script>

<p>Window width: {width}px</p>
```

### Online/Offline Detection

```svelte
<script>
  import { on } from 'svelte/events';

  let online = $state(navigator.onLine);

  const cleanup1 = on(window, 'online', () => online = true);
  const cleanup2 = on(window, 'offline', () => online = false);
</script>

<p>
  Status: {online ? '🟢 Online' : '🔴 Offline'}
</p>
```

### Visibility Change

```svelte
<script>
  import { on } from 'svelte/events';

  let visible = $state(!document.hidden);

  const cleanup = on(document, 'visibilitychange', () => {
    visible = !document.hidden;
  });
</script>

<p>
  Page is {visible ? 'visible' : 'hidden'}
</p>
```

### Before Unload (Unsaved Changes)

```svelte
<script>
  import { on } from 'svelte/events';

  let hasUnsavedChanges = $state(false);

  const cleanup = on(window, 'beforeunload', (e) => {
    if (hasUnsavedChanges) {
      e.preventDefault();
      e.returnValue = ''; // Required for Chrome
    }
  });
</script>

<textarea oninput={(e) => hasUnsavedChanges = true}></textarea>
```

## Event Listener Options

Pass options as the fourth parameter:

```svelte
<script>
  import { on } from 'svelte/events';

  // Capture phase
  const cleanup1 = on(div, 'click', handler, { capture: true });

  // Passive listener (better performance for scroll/touch)
  const cleanup2 = on(div, 'touchstart', handler, { passive: true });

  // Once (automatically removes after first invocation)
  const cleanup3 = on(div, 'click', handler, { once: true });

  // Signal-based abort
  const controller = new AbortController();
  const cleanup4 = on(div, 'click', handler, { signal: controller.signal });
</script>
```

## Cleanup with $effect

Use `$effect` for automatic cleanup:

```svelte
<script>
  import { on } from 'svelte/events';
  import { $effect } from 'svelte';

  let target = $state(document.body);

  $effect(() => {
    const cleanup = on(target, 'click', handleClick);
    return cleanup; // Automatically called when target changes
  });
</script>
```

## Cleanup with onMount

```svelte
<script>
  import { on } from 'svelte/events';
  import { onMount } from 'svelte';

  onMount(() => {
    const cleanup = on(window, 'resize', handleResize);
    return cleanup; // Called on unmount
  });
</script>
```

## Cleanup Manually

```svelte
<script>
  import { on } from 'svelte/events';

  let active = $state(true);

  const cleanup = on(window, 'scroll', handleScroll);

  function toggle() {
    if (active) {
      cleanup(); // Remove listener
    } else {
      // Re-add listener (create new cleanup)
      // Note: You'll need to recreate the handler
    }
    active = !active;
  }
</script>

<button onclick={toggle}>
  {active ? 'Disable' : 'Enable'} scroll tracking
</button>
```

## Comparing Event Handling Approaches

| Approach | Type Safety | Cleanup | Order | Use Case |
|----------|-------------|---------|-------|----------|
| `onclick` attribute | ✅ Yes | Automatic | ✅ Delegated | Component interactions |
| `on()` from svelte/events | ✅ Yes | Manual | ✅ Delegated | Global events, imperative |
| `addEventListener()` | ⚠️ Loose | Manual | ❌ Native | Non-Svelte code |

**Use `onclick` for component-level events:**
```svelte
<button onclick={handleClick}>Click me</button>
```

**Use `on()` for global/window events:**
```svelte
<script>
  import { on } from 'svelte/events';
  const cleanup = on(window, 'resize', handleResize);
</script>
```

## References

- <https://svelte.dev/docs/svelte/svelte-events>
- <https://svelte.dev/docs/svelte/lifecycle-hooks>

## Related

- [[svelte-lifecycle-hooks]]
- [[svelte-event-handling]]
