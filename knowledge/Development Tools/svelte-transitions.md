---
title: Svelte Transitions (svelte/transition)
type: reference
domain: Development Tools
tags:
  - svelte
  - transitions
  - animations
  - blur
  - fade
  - fly
  - slide
  - scale
  - draw
  - crossfade
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Svelte Transitions (svelte/transition)

## Overview

The `svelte/transition` module provides built-in transition functions for animating elements in and out of the DOM. These transitions work with Svelte's `transition:`, `in:`, and `out:` directives. <https://svelte.dev/docs/svelte/svelte-transition>

## Available Transitions

```typescript
import {
  blur,
  crossfade,
  draw,
  fade,
  fly,
  scale,
  slide
} from 'svelte/transition';
```

## blur

Animates a `blur` filter alongside an element's opacity.

```typescript
function blur(
  node: Element,
  {
    delay,
    duration,
    easing,
    amount,
    opacity
  }?: BlurParams
): TransitionConfig;
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `duration` (ms, default: 400) - Length of animation
- `easing` (function, default: `cubicInOut`) - Easing function
- `amount` (px or string, default: 5) - Blur amount
- `opacity` (number, default: 0) - Target opacity

**Example:**
```svelte
<script>
  import { blur } from 'svelte/transition';
  import { quintOut } from 'svelte/easing';

  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>
  Toggle
</button>

{#if visible}
  <p transition:blur={{ amount: 10, opacity: 0.5 }}>
    Fades with a blur effect
  </p>
{/if}
```

## crossfade

Creates a pair of transitions (`send` and `receive`) for animating elements between different positions in the DOM.

```typescript
function crossfade({
  fallback,
  ...defaults
}: CrossfadeParams & {
  fallback?: (
    node: Element,
    params: CrossfadeParams,
    intro: boolean
  ) => TransitionConfig;
}): [
  (node: any, params: CrossfadeParams & { key: any }) => () => TransitionConfig,
  (node: any, params: CrossfadeParams & { key: any }) => () => TransitionConfig
];
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `duration` (ms or function, default: 800) - Length of animation
- `easing` (function, default: `cubicInOut`) - Easing function

**Example - List Reordering:**
```svelte
<script>
  import { crossfade } from 'svelte/transition';
  import { quintOut } from 'svelte/easing';

  const [send, receive] = crossfade({
    duration: 1500,
    easing: quintOut
  });

  let items = $state([
    { id: 1, text: 'Item 1' },
    { id: 2, text: 'Item 2' },
    { id: 3, text: 'Item 3' }
  ]);

  function reorder() {
    items = items.reverse();
  }
</script>

<button onclick={reorder}>Reorder</button>

{#each items as item (item.id)}
  <div
    in:receive={{ key: item.id }}
    out:send={{ key: item.id }}
  >
    {item.text}
  </div>
{/each}
```

**Example - Custom Fallback:**
```svelte
<script>
  import { crossfade, scale } from 'svelte/transition';

  const [send, receive] = crossfade({
    fallback: (node, params, intro) => {
      return scale(node, params, intro);
    }
  });
</script>
```

## draw

Animates the stroke of an SVG element, like a snake in a tube. Only works with elements that have a `getTotalLength()` method (like `<path>` and `<polyline>`).

```typescript
function draw(
  node: SVGElement & { getTotalLength(): number },
  {
    delay,
    speed,
    duration,
    easing
  }?: DrawParams
): TransitionConfig;
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `speed` (px/second, default: undefined) - Animation speed (alternative to duration)
- `duration` (ms or function, default: 800) - Length of animation
- `easing` (function, default: `cubicInOut`) - Easing function

**Example:**
```svelte
<script>
  import { draw } from 'svelte/transition';
  import { cubicOut } from 'svelte/easing';

  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>
  Toggle
</button>

<svg viewBox="0 0 100 100">
  {#if visible}
    <path
      in:draw={{ duration: 1000, easing: cubicOut }}
      out:draw
      d="M10,10 L90,90 M90,10 L10,90"
      stroke="currentColor"
      stroke-width="5"
      fill="none"
    />
  {/if}
</svg>
```

## fade

Animates the opacity of an element from 0 to the current opacity (in) and from current opacity to 0 (out).

```typescript
function fade(
  node: Element,
  { delay, duration, easing }?: FadeParams
): TransitionConfig;
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `duration` (ms, default: 400) - Length of animation
- `easing` (function, default: `cubicInOut`) - Easing function

**Example:**
```svelte
<script>
  import { fade } from 'svelte/transition';

  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>
  Toggle
</button>

{#if visible}
  <div transition:fade>
    Fades in and out
  </div>
{/if}
```

## fly

Animates the x and y positions and opacity of an element.

```typescript
function fly(
  node: Element,
  {
    delay,
    duration,
    easing,
    x,
    y,
    opacity
  }?: FlyParams
): TransitionConfig;
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `duration` (ms, default: 400) - Length of animation
- `easing` (function, default: `cubicOut`) - Easing function
- `x` (number, default: 0) - Target x offset
- `y` (number, default: 0) - Target y offset
- `opacity` (number, default: 0) - Target opacity

**Example:**
```svelte
<script>
  import { fly } from 'svelte/transition';

  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>
  Toggle
</button>

{#if visible}
  <div transition:fly={{ x: 100, y: 100, duration: 500 }}>
    Flies in from top-left
  </div>
{/if}
```

## scale

Animates the opacity and scale of an element.

```typescript
function scale(
  node: Element,
  {
    delay,
    duration,
    easing,
    start,
    opacity
  }?: ScaleParams
): TransitionConfig;
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `duration` (ms, default: 400) - Length of animation
- `easing` (function, default: `cubicOut`) - Easing function
- `start` (number, default: 0) - Starting scale
- `opacity` (number, default: 0) - Target opacity

**Example:**
```svelte
<script>
  import { scale } from 'svelte/transition';

  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>
  Toggle
</button>

{#if visible}
  <div transition:scale={{ start: 0.5, duration: 300 }}>
    Scales in from half-size
  </div>
{/if}
```

## slide

Slides an element in and out.

```typescript
function slide(
  node: Element,
  {
    delay,
    duration,
    easing,
    axis
  }?: SlideParams
): TransitionConfig;
```

**Parameters:**
- `delay` (ms, default: 0) - Start after this many milliseconds
- `duration` (ms, default: 400) - Length of animation
- `easing` (function, default: `cubicOut`) - Easing function
- `axis` ('x' | 'y', default: 'y') - Axis to slide along

**Example:**
```svelte
<script>
  import { slide } from 'svelte/transition';

  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>
  Toggle
</button>

{#if visible}
  <div transition:slide={{ axis: 'x' }}>
    Slides in from the left
  </div>
{/if}
```

## Transition Parameters Interface

### Common Parameters

All transitions share these common parameters:

```typescript
interface TransitionParams {
  delay?: number;        // milliseconds before starting
  duration?: number;     // length of animation in milliseconds
  easing?: (t: number) => number; // easing function
}
```

### TransitionConfig

```typescript
interface TransitionConfig {
  delay?: number;
  duration?: number;
  easing?: (t: number) => number;
  css?: (t: number, u: number) => string;
  tick?: (t: number, u: number) => void;
}
```

- `css` - Custom CSS function for the transition
- `tick` - Custom JavaScript function called on each animation frame

## Using with transition:, in:, and out:

### transition: (Bidirectional)

Applies to both entering and leaving the DOM:

```svelte
<script>
  import { fade } from 'svelte/transition';
  let visible = $state(true);
</script>

<button onclick={() => visible = !visible}>Toggle</button>

{#if visible}
  <div transition:fade={{ duration: 300 }}>
    Same transition in and out
  </div>
{/if}
```

### in: and out: (Directional)

Different transitions for entering and leaving:

```svelte
<script>
  import { fly, scale } from 'svelte/transition';
  let visible = $state(false);
</script>

<button onclick={() => visible = !visible}>Toggle</button>

{#if visible}
  <div
    in:fly={{ x: 100, duration: 300 }}
    out:scale={{ duration: 200 }}
  >
    Different transitions
  </div>
{/if}
```

## Easing Functions

Import easing functions from `svelte/easing`:

```typescript
import {
  backIn,
  backOut,
  backInOut,
  bounceIn,
  bounceOut,
  bounceInOut,
  circIn,
  circOut,
  circInOut,
  cubicIn,
  cubicOut,
  cubicInOut,
  elasticIn,
  elasticOut,
  elasticInOut,
  expoIn,
  expoOut,
  expoInOut,
  quadIn,
  quadOut,
  quadInOut,
  quartIn,
  quartOut,
  quartInOut,
  quintIn,
  quintOut,
  quintInOut,
  sineIn,
  sineOut,
  sineInOut,
  linear
} from 'svelte/easing';
```

**Example:**
```svelte
<script>
  import { fade } from 'svelte/transition';
  import { quintOut } from 'svelte/easing';
</script>

<div transition:fade={{ easing: quintOut, duration: 500 }}>
  Fades with quintic easing
</div>
```

## Deferred Transitions

Transitions on multiple elements can be deferred (staggered) using the `|deferred` modifier:

```svelte
<script>
  import { blur } from 'svelte/transition';

  let items = $state([1, 2, 3, 4, 5]);
</script>

{#each items as item (item)}
  <div transition:blur|deferred>
    {item}
  </div>
{/each}
```

## Local vs Global Transitions

### Local Transitions (default)

```svelte
{#each items as item (item.id)}
  <!-- Only animates when item.id changes, not when order changes -->
  <div transition:fade>{item.name}</div>
{/each}
```

### Global Transitions

```svelte
{#each items as item (item.id)}
  <!-- Animates whenever items array changes -->
  <div transition:fade|global>{item.name}</div>
{/each}
```

## Custom Transitions

Create your own transition by returning a `TransitionConfig` object:

```typescript
// myTransition.js
import { cubicOut } from 'svelte/easing';

export function myTransition(
  node,
  { delay = 0, duration = 400, easing = cubicOut } = {}
) {
  const o = +getComputedStyle(node).opacity;

  return {
    delay,
    duration,
    easing,
    css: (t, u) => `opacity: ${t * o}; transform: scale(${t});`
  };
}
```

**Usage:**
```svelte
<script>
  import { myTransition } from './myTransition.js';
</script>

<div transition:myTransition={{ duration: 500 }}>
  Custom transition
</div>
```

## Transition Events

Listen to transition events with `@transitionstart` and `@transitionend`:

```svelte
<script>
  import { fade } from 'svelte/transition';

  function onStart(e) {
    console.log('Transition started', e.detail);
  }

  function onEnd(e) {
    console.log('Transition ended', e.detail);
  }
</script>

<div
  transition:fade
  on:introstart={onStart}
  on:introend={onEnd}
  on:outrostart={onStart}
  on:outroend={onEnd}
>
  Content
</div>
```

## Combining Transitions

You can combine multiple transitions using the plus modifier:

```svelte
<script>
  import { fade, fly } from 'svelte/transition';
</script>

<!-- Note: This doesn't work as expected - use one transition or custom -->
<div transition:fade+fly>
  This won't combine them properly
</div>
```

Instead, create a custom transition that combines effects:

```javascript
export function fadeAndFly(node, params) {
  const base = fade(node, params);
  const flyEffect = fly(node, params);

  return {
    ...base,
    css: (t, u) => {
      return `${base.css(t, u)}; ${flyEffect.css(t, u)}`;
    }
  };
}
```

## Accessibility

Respect user's `prefers-reduced-motion` setting:

```svelte
<script>
  import { fade } from 'svelte/transition';

  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  const duration = prefersReducedMotion ? 0 : 400;
</script>

<div transition:fade={{ duration }}>
  Respects motion preferences
</div>
```

## References

- <https://svelte.dev/docs/svelte/svelte-transition>
- <https://svelte.dev/docs/svelte/svelte-easing>
- <https://svelte.dev/docs/svelte/transition>
- <https://svelte.dev/docs/svelte/in-and-out>

## Related

- [[svelte-animations]]
- [[svelte-motion]]
