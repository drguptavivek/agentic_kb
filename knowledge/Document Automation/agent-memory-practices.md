---
tags:
  - agents
  - knowledge-base
  - documentation
  - workflow
created: 2025-03-12
---

# Agent Memory Practices

## Overview

How agents should capture new, reusable knowledge learned during tasks so it becomes
durable, searchable memory in this KB.

## Problem/Context

Agents often discover working patterns, pitfalls, library behaviors, and architecture
decisions while solving tasks. If this knowledge is not documented, it is lost and
cannot be reused across future work.

## Solution

### When to Document

Document new knowledge when it is:

1. Reusable across future tasks or projects
2. Specific and actionable (steps, constraints, pitfalls)
3. Not already captured in the KB
4. A hard-won lesson (errors, edge cases, incompatibilities)

### What to Capture

- Working patterns and best practices
- Things to avoid and why
- Library or tool behavior, including versions
- Architecture or design decisions and their rationale
- Stable commands, templates, or snippets

### How to Write It

1. Use explicit headings that match likely search queries.
2. Prefer steps, checklists, and concrete examples over prose.
3. Include constraints and "do not" guidance if relevant.
4. Add related wikilinks to connect context.

### Confirmation Rule

If the KB needs updating based on new findings, ask for user confirmation before
making KB edits.

## Examples

### Example Headings

- `## Retry strategy for API rate limits`
- `## Common pitfalls with library X`
- `## Recommended folder structure for service Y`

### Example Checklist

1. Identify the new knowledge and confirm it is not already in the KB.
2. Ask the user to confirm adding or updating a KB note.
3. Add a focused note under the correct domain with YAML frontmatter.
4. Link related topics using `[[wikilinks]]`.

## References

- [[Knowledge Conventions]]

---

## Related

- [[DOCX Page Numbering with Pandoc]]
- [[OOXML Manipulation Techniques]]
