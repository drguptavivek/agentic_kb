---
title: Using uv in Sandboxed Environments
type: howto
domain: Development Tools
tags:
  - uv
  - python
  - sandbox
  - ci
  - troubleshooting
status: approved
created: 2026-02-19
updated: 2026-02-19
---

# Using uv in Sandboxed Environments

## Problem / Context

In restricted environments, `uv` may fail with access-denied errors when it tries to use default user-level cache or interpreter paths.

## Recommended Approach

1. Use a repo-local UV cache.
2. Run commands with `--active` so `uv` uses the active environment path.

## PowerShell Pattern

```powershell
$env:UV_CACHE_DIR = (Join-Path (Resolve-Path .).Path ".uv-cache")
New-Item -ItemType Directory -Path $env:UV_CACHE_DIR -Force | Out-Null
uv run --active --with typesense python scripts/search_typesense.py "query"
```

## Bash Pattern

```bash
export UV_CACHE_DIR="$(pwd)/.uv-cache"
mkdir -p "$UV_CACHE_DIR"
uv run --active --with typesense python scripts/search_typesense.py "query"
```

## Common Command Templates

```bash
# Typesense indexing
uv run --active --with typesense --with tqdm python scripts/index_typesense.py

# Typesense search
uv run --active --with typesense python scripts/search_typesense.py "query"

# FAISS search
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "query"
```

## Troubleshooting Checklist

- [ ] `UV_CACHE_DIR` points to a writable repo-local path (for example, `.uv-cache`)
- [ ] Cache directory exists
- [ ] Command uses `uv run --active`
- [ ] Active environment/interpreter is available

## References

- [[search-backends]]
- [[typesense-integration]]

## Related

- [[kb-search-trigger-policy-and-sandbox-safe-uv]]
- [[typesense-v30-deprecation-warnings]]
