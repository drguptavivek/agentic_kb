---
title: SvelteKit SEO Best Practices
type: reference
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - seo
  - ssr
  - sitemaps
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# SvelteKit SEO Best Practices

## SSR by Default

SSR improves crawlability and should remain enabled unless there is a strong reason to disable it. SvelteKit supports dynamic rendering but it is not generally recommended. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## Performance Signals

Core Web Vitals influence ranking. Use SvelteKit’s hybrid rendering and optimize images; measure with PageSpeed or Lighthouse. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## Normalized URLs

Trailing slash behavior is normalized based on `trailingSlash` configuration to avoid duplicate URLs. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## Titles and Meta

Every page should have a unique `<title>` and `<meta name="description">` inside `<svelte:head>`. A common pattern is to return SEO data from `load` and read it from `page.data` in layouts. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## Sitemaps

Generate a sitemap in a `+server.js` endpoint (e.g., `sitemap.xml`) with `Content-Type: application/xml`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## AMP (Optional)

SvelteKit can render AMP by inlining CSS (`inlineStyleThreshold: Infinity`), disabling `csr`, adding `amp` to `app.html`, and transforming output with `@sveltejs/amp`. <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## References

- <https://raw.githubusercontent.com/sveltejs/kit/main/documentation/docs/40-best-practices/20-seo.md>

## Related

- [[sveltekit-accessibility-best-practices]]
