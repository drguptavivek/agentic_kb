---
tags:
  - instructions
  - maintenance
status: approved
created: 2025-01-01
updated: 2025-01-01
---

# Knowledge Conventions (Authoritative)

This document defines the **mandatory conventions** for creating, updating, and maintaining knowledge notes under the `knowledge/` directory.

These rules apply to **all human contributors and all AI/agent-based workflows**.

---

## Repository Layout (Canonical)

```

agentic_kb/
├── AGENTS.md
├── GIT_WORKFLOWS.md
├── INSTRUCTIONS.md
├── knowledge
│   ├── <Domain 1>
│   │     ├── article-1.md
│   │     └── article-2.md
│   ├── <Domain 2>
│   └── <Domain 3>
├── KNOWLEDGE_CONVENTIONS.md
├── LICENSE
└── README.md

```

**Rule:**  
Agents and tools MUST read knowledge **only** from `knowledge/`.  
The `.obsidian/` directory is editor configuration and MUST be ignored.

---

## File Placement Rules

1. All knowledge files MUST live under:
```

knowledge/<Domain>/

```

2. Files MUST NOT be placed at the repository root.

Examples:
```

knowledge/Document Automation/docx-page-numbering-pandoc.md
knowledge/Security/iso-27001-compliance-checklist.md

````

---

## File Naming Conventions (Authoritative)

1. Filenames MUST use **kebab-case**
2. Filenames MUST be:
   - lowercase
   - descriptive
   - stable
   - free of spaces
3. Filenames MUST NOT contain version numbers

Examples:
✔ `docx-page-numbering-pandoc.md`  
✔ `git-workflow.md`  
✖ `docx-page-numbering.md`  
✖ `policy-v1.md`

Versioning belongs in **frontmatter** and via git commits, not filenames.

---

## Required YAML Frontmatter (Mandatory)

Every Markdown file MUST begin with YAML frontmatter as the **first content** in the file.
Example:

```yaml
---
title: Page numbering in Pandoc DOCX
type: howto | reference | checklist | policy | note
domain: Document Automation | Security | Compliance | DevOps
tags:
  - pandoc
  - docx
  - page-numbering
status: draft | approved | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
````

Rules:

* No blank lines before `---`
* Dates MUST be ISO-8601
* `title`, `type`, and `domain` are mandatory
* `status: approved` may be used **only** for finalized content

---

## Heading Structure (Critical)

1. Each file MUST contain **exactly one H1 (`#`)**
2. The H1 MUST match the `title` field in frontmatter exactly
3. Heading levels MUST be hierarchical (`##`, `###` only; never skip levels)

Example:

```md
# Page numbering in Pandoc DOCX

## Problem / Context

## Recommended Approach

### Steps

### Common Pitfalls
```

Headings act as **retrieval anchors** for both humans and agents.

---

## Obsidian Linking Rules

### Internal Links

Use **Obsidian wikilinks only**:
Example

```md
See [[docx-page-numbering-pandoc]] for details.
```

Rules:

* Do NOT include `.md`
* Use exact filename (without extension)
* Prefer links over repeating content

### Section Links

Example

```md
[[docx-page-numbering-pandoc#Steps]]
```

---

## Content Structure (Strongly Preferred)

### Procedural Steps

```md
### Steps
1. Create a reference DOCX
2. Define header and footer styles
3. Pass `--reference-doc` to Pandoc
```

### Checklists

```md
### Checklist
- [ ] Section breaks inserted
- [ ] Header/footer verified
- [ ] TOC tested
```

Avoid long narrative prose unless strictly necessary.

---

## Code Blocks (Strict Rules)

1. Use fenced code blocks only
2. Always specify a language

````md
```bash
pandoc input.md -o output.docx
```
````

3. Commands MUST be copy-pasteable
4. Do NOT embed screenshots or terminal images

---

## Tables (Preferred for Comparison)

Use Markdown tables instead of prose when comparing options:

```md
| Option  | Pros           | Cons            |
|--------|----------------|-----------------|
| Pandoc | Reproducible   | Requires setup  |
```

---

## Normative vs Informative Content

Explicitly label authoritative guidance:

```md
## Normative Guidance
The following steps MUST be followed.

## Informative Notes
Background and contextual information.
```

This distinction is mandatory for policy and compliance notes.

---

## Authority & Status Markers

Use blockquotes to indicate institutional authority:

```md
> **Authority**
> This guidance reflects current institutional practice.
```

Only content marked `status: approved` is considered authoritative.

---

## Obsidian Compatibility Rules

The following are **NOT allowed** unless explicitly approved:

* Raw HTML blocks
* Embedded iframes
* Theme-dependent callouts
* Mermaid diagrams
* Footnotes (unless required)

Markdown must remain **portable, readable, and tool-agnostic**.

---

## Index / Map of Content (Recommended)

For any folder containing more than **5 notes**, create an index file:

```
knowledge/<Domain>/_index.md
```

Example:

```md
# Document Automation — Index

- [[docx-page-numbering-pandoc]]
- [[pandoc-toc-docx]]
```

---

## Adding New Knowledge

1. Create a Markdown file under the correct `knowledge/<Domain>/`
2. Apply the required YAML frontmatter
3. Use 3–7 focused tags
4. Add a `Related` section with wikilinks
5. Update `_index.md` (or README.md if introducing a new domain)

---

## Updating and Renaming Files

Prefer renaming within Obsidian so links update automatically.

CLI verification example:

```bash
rg "Old Name" knowledge/
```

Bulk link replacement (macOS example):

```bash
find knowledge/ -type f -exec sed -i '' 's/\[\[Old Name\]\]/[[New Name]]/g' {} +
```

---

## Deprecation and Removal

### Deprecation (Preferred)

```md
---
status: deprecated
tags:
  - deprecated
---

# Old Topic

**DEPRECATED**: Superseded by [[New Topic]].
```

### Deletion

```bash
git rm "knowledge/Domain/obsolete-topic.md"
git add README.md
git commit -m "Remove deprecated knowledge note"
git push
```

---

## Agent Safety Rules (Mandatory)

When an agent edits or creates files, it MUST:

1. Preserve YAML frontmatter
2. Not rename files unless explicitly instructed
3. Not reflow or reorder headings
4. Not remove existing wikilinks
5. Output the **entire file**, not a diff

---

## Validation Checklist (Before Commit)

* [ ] Valid YAML frontmatter present
* [ ] Exactly one H1
* [ ] Filename follows kebab-case rules
* [ ] Wikilinks resolve
* [ ] Content is scoped, procedural, and concrete
* [ ] Status field is correct

---

## Enforcement

This document is **authoritative**.
Non-compliant files MUST be corrected before merge.

```
