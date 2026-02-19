---
title: Typesense YAML Frontmatter Parsing Fix
type: howto
domain: Search
tags:
  - typesense
  - yaml
  - frontmatter
  - parsing
  - python
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Typesense YAML Frontmatter Parsing Fix

## Problem

When indexing documents into Typesense, tags from YAML frontmatter weren't being extracted, causing tag-based filtering to fail.

### Symptoms

```bash
# Search returns results but tags are empty
uv run --active python scripts/search_typesense.py "pandoc"
# Output shows: Tags: (empty)

# Filter by tags returns no results
uv run --active python scripts/search_typesense.py "pandoc" --filter "tags:pandoc"
# Output: No results found.
```

## Root Cause

The `strip_frontmatter()` function in `scripts/index_typesense.py` only handled two tag formats:

1. **JSON-style array**: `tags: [pandoc, docx]`
2. **Comma-separated**: `tags: pandoc, docx`

But **did not handle** the standard YAML list format used in this KB:

```yaml
---
tags:
  - pandoc
  - docx
  - word
created: 2025-12-25
---
```

## Solution

Updated the `strip_frontmatter()` function to parse multi-line YAML lists properly.

### Implementation

```python
def strip_frontmatter(text: str) -> tuple[str, dict]:
    """Strip YAML frontmatter and return content + metadata."""
    if not text.startswith("---"):
        return text, {}

    parts = text.split("---", 2)
    if len(parts) < 3:
        return text, {}

    frontmatter_raw = parts[1].strip()
    content = parts[2].lstrip("\n")

    # Parse YAML frontmatter
    metadata = {}
    lines = frontmatter_raw.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("tags:"):
            tags_part = line.replace("tags:", "").strip()
            if tags_part.startswith("[") and tags_part.endswith("]"):
                # JSON-style array: tags: [pandoc, docx]
                metadata["tags"] = json.loads(tags_part)
                i += 1
            elif tags_part:
                # Inline comma-separated: tags: pandoc, docx
                metadata["tags"] = [t.strip() for t in tags_part.split(",")]
                i += 1
            else:
                # YAML list format with hyphens on next lines
                tags = []
                i += 1
                while i < len(lines) and lines[i].strip().startswith("-"):
                    tag = lines[i].strip()[1:].strip()  # Remove hyphen
                    if tag:
                        tags.append(tag)
                    i += 1
                metadata["tags"] = tags
        elif line.startswith("created:"):
            metadata["created"] = line.replace("created:", "").strip()
            i += 1
        else:
            i += 1

    return content, metadata
```

### Key Changes

The fix adds support for multi-line YAML lists by:

1. Detecting when `tags:` line has no inline value
2. Reading subsequent lines starting with `-`
3. Stripping the hyphen and whitespace from each tag
4. Building the tags array progressively

## Applied In

This fix was applied to:
- `scripts/index_typesense.py` (lines 14-59)

## Verification

After applying the fix, rebuild the index:

```bash
# Rebuild index (direct repo)
uv run --active --with typesense --with tqdm python scripts/index_typesense.py

# Or from parent project (submodule)
uv run --active --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py

# Verify tags are extracted
uv run --active --with typesense python scripts/search_typesense.py "pandoc" --k 3
# Should show: Tags: pandoc, docx, word, page-numbering, ...

# Test tag filtering
uv run --active --with typesense python scripts/search_typesense.py "pandoc" --filter "tags:pandoc"
# Should return filtered results
```

## Supported Tag Formats

After the fix, all three formats work:

```yaml
# Format 1: JSON array (inline)
tags: [pandoc, docx, word]

# Format 2: Comma-separated (inline)
tags: pandoc, docx, word

# Format 3: YAML list (multi-line) - STANDARD IN THIS KB
tags:
  - pandoc
  - docx
  - word
```

## Why Not Use a YAML Parser?

A full YAML parser (like `pyyaml`) would be more robust, but adds a dependency. The current solution:
- Has zero dependencies beyond `typesense`
- Handles the specific frontmatter format used in this KB
- Is fast and lightweight

If you need more complex YAML parsing in the future, consider:

```bash
uv add pyyaml
```

```python
import yaml

def strip_frontmatter(text: str) -> tuple[str, dict]:
    if not text.startswith("---"):
        return text, {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return text, {}

    frontmatter = yaml.safe_load(parts[1])
    content = parts[2].lstrip("\n")

    return content, {
        "tags": frontmatter.get("tags", []),
        "created": frontmatter.get("created", "")
    }
```

## Related

- [[typesense-integration]] - Typesense setup guide
- [[typesense-v30-deprecation-warnings]] - Fix for deprecation warnings
- [[search-backends]] - Search backend comparison

## References

- [YAML Specification](https://yaml.org/spec/1.2.2/)
- [Knowledge Conventions](../../KNOWLEDGE_CONVENTIONS.md) - KB frontmatter format
