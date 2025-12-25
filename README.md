---
title: Knowledge Base
tags: [index, readme]
---

# Knowledge Base

A centralized, flat-structure knowledge base with tag-based organization for cross-project reference.

## Structure

All knowledge files are markdown with YAML frontmatter containing metadata:

```yaml
---
title: Document Title
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
related: [file1.md, file2.md]
---
```

## Tag Index

### By Tag

| Tag | Files |
|-----|-------|
| `pandoc` | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [page-numbering-implementation.md](page-numbering-implementation.md) |
| `docx` | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `word` | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `page-numbering` | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [page-numbering-implementation.md](page-numbering-implementation.md) |
| `ooxml` | [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `xml` | [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `python` | [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `document-automation` | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `implementation` | [page-numbering-implementation.md](page-numbering-implementation.md) |
| `example` | [page-numbering-implementation.md](page-numbering-implementation.md) |

## All Files

1. [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md) - Complete guide to DOCX page numbering with Pandoc
2. [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) - OOXML structure and Python manipulation
3. [page-numbering-implementation.md](page-numbering-implementation.md) - Quick reference for page numbering implementation

## Usage

### Finding Information by Tag

Search for files with a specific tag:
```bash
grep -l "tags:.*your-tag" *.md
```

### Finding Related Content

Each file has a `related` field in frontmatter linking to related documents.

### Adding New Knowledge

Create a new markdown file with frontmatter:

```yaml
---
title: Your Title Here
tags: [relevant, tags, here]
created: YYYY-MM-DD
related: [related-file1.md]
---

# Your Title Here

Content goes here...
```

## Git Submodule Usage

This knowledge base can be used as a git submodule in any project:

```bash
# Add as submodule to your project
git submodule add https://github.com/your-username/kb.git path/to/kb

# Update submodule to latest
git submodule update --remote

# Clone repository with submodules
git clone --recursive https://github.com/your-username/project.git
```

## Cross-Project References

When referencing this knowledge base from other projects:

1. Add as git submodule
2. Reference files relative to submodule path: `kb/docx-page-numbering-pandoc.md`
3. Use tags to discover related content
