---
tags:
  - obsidian
  - documentation
  - knowledge-base
  - workflow
created: 2025-03-12
---

# Obsidian Documentation Practices

## Overview

How to document knowledge effectively in an Obsidian-style repo so it is retrievable,
actionable, and reusable by agents and humans.

## Problem/Context

Notes that are unstructured or overly prose-heavy are hard to search and reuse.
Consistent structure, headings, and links improve retrieval and maintenance.

## Solution

### Structure

1. Use one topic per file.
2. Start with a clear title that matches the filename.
3. Add `Overview`, `Problem/Context`, `Solution`, and `Examples` sections.
4. Keep a `Related` section with wikilinks.

### Headings as Retrieval Anchors

Use explicit headings that match likely queries:

- `## Page numbering in DOCX output`
- `## Common Pandoc pitfalls`
- `## Retry strategy for API rate limits`

### Prefer Procedures Over Prose

Use steps and checklists for operational knowledge:

```md
### Steps
1. Insert a section break
2. Use reference-doc.docx
3. Define header/footer styles
```

### Link Hygiene

- Use `[[wikilinks]]` for related notes.
- Ensure the file title matches the wikilink text.
- Update links after renames (prefer Obsidian rename).

## Examples

### Example Note Skeleton

```md
---
tags:
  - tag1
  - tag2
created: YYYY-MM-DD
---

# Title

## Overview

## Problem/Context

## Solution

## Examples

## References

---

## Related

- [[Related Topic 1]]
```

## References

- [[KNOWLEDGE_CONVENTIONS]]

---

## Related

- [[agent-memory-practices]]
