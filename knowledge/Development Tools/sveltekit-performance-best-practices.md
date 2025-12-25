---
title: SvelteKit Performance Best Practices
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - performance
  - optimization
  - hosting
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Performance Best Practices

## Built-In Optimizations

SvelteKit includes code-splitting, asset preloading, request coalescing, parallel `load`, data inlining, conservative invalidation, prerendering, and link preloading by default. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## Diagnosing Issues

Use PageSpeed Insights, WebPageTest, and browser devtools. Measure in preview mode after `build` since `dev` behaves differently. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## Asset Optimization

- Images: use `@sveltejs/enhanced-img` or a CDN.
- Videos: compress, lazy-load below the fold, strip audio when not needed.
- Fonts: consider preloading via `handle` hook and subset fonts. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## Reduce Code Size

Prefer latest Svelte, analyze bundles with `rollup-plugin-visualizer`, minimize third-party scripts, and use dynamic `import()` for conditional code. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## Navigation and Waterfalls

Use link preloading and streaming promises for non-critical data. Avoid sequential backend requests; prefer server `load` to reduce client waterfalls. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## Hosting

Deploy frontend close to backend (or at the edge), use HTTP/2+, and consider CDN images. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/05-performance.md>

## Related

- [[sveltekit-images-best-practices]]
