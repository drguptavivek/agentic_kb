---
title: Knowledge Base
tags: [index, readme]
---

# agentic_kb

Cross repo knowledge base that may be referenced by multiple repositories as git submodule.

A centralized, flat-structure knowledge base with tag-based organization for cross-project reference.

**Need to add or update knowledge?** See [INSTRUCTIONS.md](INSTRUCTIONS.md)

---

## Knowledge by Domain

### Document Automation

| File | Description | Tags |
|------|-------------|------|
| [knowledge/docx-page-numbering-pandoc.md](knowledge/docx-page-numbering-pandoc.md) | Complete guide to DOCX page numbering with Pandoc - problems, solutions, and best practices | `pandoc`, `docx`, `word`, `page-numbering`, `document-automation` |
| [knowledge/ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) | OOXML structure, Python manipulation, unpacking/packing workflows | `ooxml`, `docx`, `word`, `xml`, `python`, `document-automation` |
| [knowledge/page-numbering-implementation.md](knowledge/page-numbering-implementation.md) | Quick reference for page numbering implementation with code examples | `pandoc`, `docx`, `word`, `page-numbering`, `implementation`, `example`, `document-automation` |

### Development Tools

*Coming soon - Add your knowledge here*

### APIs & Integrations

*Coming soon - Add your knowledge here*

### Security

*Coming soon - Add your knowledge here*

### DevOps & CI/CD

*Coming soon - Add your knowledge here*

---

## Tag Index

| Tag | Domain | Files |
|-----|--------|-------|
| `pandoc` | Document Automation | [docx-page-numbering-pandoc.md](knowledge/docx-page-numbering-pandoc.md), [page-numbering-implementation.md](knowledge/page-numbering-implementation.md) |
| `docx` | Document Automation | [docx-page-numbering-pandoc.md](knowledge/docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) |
| `word` | Document Automation | [docx-page-numbering-pandoc.md](knowledge/docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) |
| `page-numbering` | Document Automation | [docx-page-numbering-pandoc.md](knowledge/docx-page-numbering-pandoc.md), [page-numbering-implementation.md](knowledge/page-numbering-implementation.md) |
| `ooxml` | Document Automation | [ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) |
| `xml` | Document Automation | [ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) |
| `python` | Document Automation | [ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) |
| `document-automation` | Document Automation | [docx-page-numbering-pandoc.md](knowledge/docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](knowledge/ooxml-manipulation-techniques.md) |
| `implementation` | Document Automation | [page-numbering-implementation.md](knowledge/page-numbering-implementation.md) |
| `example` | Document Automation | [page-numbering-implementation.md](knowledge/page-numbering-implementation.md) |

---

## Finding Information

### By Domain

Browse the **Knowledge by Domain** section above for topic-based discovery.

### By Tag

Search for files with a specific tag:

```bash
grep -l "tags:.*your-tag" knowledge/*.md
```

Or search within files:
```bash
grep -r "your-tag" knowledge/ --include="*.md"
```

### By Relationships

Each file has a `related` field in frontmatter. Follow these links to discover related content.

---

## Using This Knowledge Base in Your Project

### Add as Submodule

```bash
git submodule add https://github.com/drguptavivek/agentic_kb.git kb
```

### Update Submodule

```bash
git submodule update --remote kb
```

### Clone with Submodules

```bash
git clone --recursive https://github.com/your-username/project.git
```

### Reference Files

Reference files relative to the submodule path:

```
See: kb/knowledge/docx-page-numbering-pandoc.md for page numbering details
```

---

## Directory Structure

```
kb/
├── README.md           # This file - knowledge index
├── INSTRUCTIONS.md     # How to add/update knowledge
├── LICENSE            # License file
└── knowledge/         # All knowledge files
    ├── topic1.md
    ├── topic2.md
    └── ...
```

---

## File Format

All knowledge files use this frontmatter format:

```yaml
---
title: Document Title
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
related: [file1.md, file2.md]
---

# Your Title Here

Content...
```

---

## License

See [LICENSE](LICENSE) file for details.
