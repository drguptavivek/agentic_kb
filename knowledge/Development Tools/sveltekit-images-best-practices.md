---
title: SvelteKit Images Best Practices
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - images
  - performance
  - cdn
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit Images Best Practices

## Goals

Optimize images with modern formats (`avif`, `webp`), responsive sizes, and cache-friendly assets. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/07-images.md>

## Options

- **Vite asset handling**: hashed filenames, inlining below `assetsInlineLimit`, works for CSS `url()`.
- **@sveltejs/enhanced-img**: build-time processing, auto sizes, intrinsic dimensions, format conversion, EXIF stripping.
- **CDN delivery**: dynamic optimization for images not available at build time. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/07-images.md>

## enhanced-img Setup

```bash
npm i -D @sveltejs/enhanced-img
```

```js
// vite.config.js
import { sveltekit } from '@sveltejs/kit/vite';
import { enhancedImages } from '@sveltejs/enhanced-img';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [
    enhancedImages(), // must come before sveltekit()
    sveltekit()
  ]
});
```

## Best Practices

- Use `sizes` for wide images and provide 2x source images for HiDPI.
- Avoid layout shift with explicit dimensions (enhanced-img adds them).
- Prioritize LCP images (`fetchpriority="high"`, avoid `loading="lazy"`).
- Provide good `alt` text.
- Avoid `em`/`rem` in `sizes` if you change default font size. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/07-images.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/07-images.md>

## Related

- [[sveltekit-performance-best-practices]]
