---
tags:
  - instructions
  - maintenance
---

# Knowledge Conventions

Guidance for adding, updating, and maintaining notes under `knowledge/`.

## Repository Layout (Canonical)

```
agentic_kb/
├── knowledge/
├── INSTRUCTIONS.md
├── README.md
├── .obsidian/
└── .git/
```

Rule: agents read only from `knowledge/`, never from `.obsidian/`.

## File Template

```yaml
---
tags:
  - tag1
  - tag2
created: YYYY-MM-DD
---

# Title

## Overview

Brief description of what this knowledge covers.

## Problem/Context

What problem does this solve?

## Solution

Your solution...

## Examples

Code/examples...

## References

External links...

---

## Related

- [[Related Topic 1]]
- [[Related Topic 2]]
```

## Adding New Knowledge

1. Create a markdown file under the correct domain in `knowledge/`.
2. Use the template and add 3-7 focused tags.
3. Add wikilinks in a `Related` section.
4. Update `README.md` to list the new file.

## Naming Conventions

### Files

- Use Title Case: `Git Workflow.md`
- Be descriptive: `DOCX Page Numbering with Pandoc.md`
- Avoid numbers unless part of a series

### Folders

- Use Title Case: `Document Automation`, `DevOps & CI/CD`
- Group by domain, not technology

### Tags

- Lowercase: `#pandoc`, `#docx`
- Hyphenate multi-word: `#page-numbering`

## Folder Structure (Examples)

```
knowledge/
├── Document Automation/
├── Development Tools/
├── APIs & Integrations/
├── Security/
└── DevOps & CI/CD/
```

## Maintenance Guidelines

- Keep links healthy; update wikilinks after renames.
- Prefer Obsidian for renames so links update automatically.
- Be specific and concrete in solutions and examples.
- Keep content concise and actionable.
- Use explicit headings; they are retrieval anchors.
- Prefer procedural steps over long prose.

## KB Hygiene Rules

1. One topic per file.
2. Headings should be explicit and descriptive.
3. Steps/checklists beat prose for procedures.

## Updating and Renaming

### Via Obsidian (Preferred)

Use Obsidian rename to update wikilinks automatically.

### Via Text Editor

```bash
# Find references
rg "Old Name" knowledge/

# Replace links (macOS sed example)
find knowledge/ -type f -exec sed -i '' 's/\[\[Old Name\]\]/[[New Name]]/g' {} +
```

## Removing Content

### Deprecating (Preferred)

```markdown
---
tags:
  - deprecated
---

# Old Topic

**DEPRECATED**: This content is superseded by [[New Topic]].
```

### Deleting

```bash
git rm "knowledge/Domain/Obsolete.md"
git add README.md
git commit -m "Remove: Obsolete note"
git push
```
