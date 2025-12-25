---
title: Typesense v30 Deprecation Warnings Fix
type: howto
domain: Search
tags:
  - typesense
  - python
  - deprecation
  - troubleshooting
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Typesense v30 Deprecation Warnings Fix

## Problem

When using Typesense Python client with Typesense server v30+, you may see deprecation warnings:

```
Deprecation warning: AnalyticsRulesV1 is deprecated on v30+. Use client.analytics instead.
Deprecation warning: Overrides is deprecated on v30+. Use client.curation_sets instead.
Deprecation warning: The synonyms API (collections/{collection}/synonyms) is deprecated is removed on v30+. Use synonym sets (synonym_sets) instead.
```

## Root Cause

These warnings are printed by the Typesense Python client library itself when connecting to a v30+ server. The warnings appear even if your code doesn't use these deprecated features.

**Key Points**:
- The warnings come from the client library, not your code
- They're printed directly to stderr (not using Python's warnings module)
- The Python client hasn't been fully updated for v30+ API changes yet
- Your search/index code is already compatible - these are internal client warnings

## Solution

Suppress the warnings by redirecting stderr during client operations.

### Implementation

Add this context manager to your scripts:

```python
import sys
from contextmanager import contextmanager
from io import StringIO

@contextmanager
def suppress_typesense_warnings():
    """Suppress Typesense v30+ deprecation warnings printed to stderr."""
    old_stderr = sys.stderr
    sys.stderr = StringIO()
    try:
        yield
    finally:
        sys.stderr = old_stderr
```

### Usage

Wrap client creation and Typesense operations:

```python
def main():
    args = parse_args()

    with suppress_typesense_warnings():
        client = create_client(args.host, args.port, args.api_key)
        results = search(client, args.collection, args.query)

    print_results(results)
```

## Applied In

This fix has been applied to:
- `scripts/index_typesense.py` (lines 14-22, 218-221)
- `scripts/search_typesense.py` (lines 11-19, 135-144)

## Why Not Use Python's warnings Module?

Python's `warnings.filterwarnings()` doesn't work because:
- Typesense client prints directly to stderr
- It doesn't use Python's warnings system
- The messages are plain print statements, not DeprecationWarning objects

## Alternative: Environment Variable

You can also suppress all stderr output globally:

```bash
# Suppress all stderr (not recommended - hides real errors)
uv run python scripts/search_typesense.py "query" 2>/dev/null

# Better: Use the context manager approach in code
```

## When Will This Be Fixed?

The Typesense Python client library will eventually be updated to use the v30+ API. Once the client is updated:
- Remove the `suppress_typesense_warnings` context manager
- Update the client library: `uv add --upgrade typesense`

Monitor: https://github.com/typesense/typesense-python/releases

## Verification

After applying the fix:

```bash
# Should show NO deprecation warnings (direct repo)
uv run --with typesense python scripts/search_typesense.py "test query"
uv run --with typesense --with tqdm python scripts/index_typesense.py

# Or from parent project (submodule)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "test query"
uv run --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
```

## Related

- [[typesense-integration]] - Typesense setup guide
- [[search-backends]] - Search backend comparison

## Sources

- [Typesense Python Client](https://github.com/typesense/typesense-python)
- [Typesense v30.0 Release Notes](https://typesense.org/docs/30.0/)
