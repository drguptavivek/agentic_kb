---
title: Knowledge Base
tags: [index, readme]
---

# agentic_kb

Cross repo knowledge base that may be referenced by multiple repositories as git submodule.

A centralized, flat-structure knowledge base with tag-based organization for cross-project reference.

## Knowledge by Domain

### Document Automation

| File | Description | Tags |
|------|-------------|------|
| [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md) | Complete guide to DOCX page numbering with Pandoc - problems, solutions, and best practices | `pandoc`, `docx`, `word`, `page-numbering`, `document-automation` |
| [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) | OOXML structure, Python manipulation, unpacking/packing workflows | `ooxml`, `docx`, `word`, `xml`, `python`, `document-automation` |
| [page-numbering-implementation.md](page-numbering-implementation.md) | Quick reference for page numbering implementation with code examples | `pandoc`, `docx`, `word`, `page-numbering`, `implementation`, `example`, `document-automation` |

### Development Tools

*Coming soon - Add your knowledge here*

### APIs & Integrations

*Coming soon - Add your knowledge here*

### Security

*Coming soon - Add your knowledge here*

### DevOps & CI/CD

*Coming soon - Add your knowledge here*

---

## How This Knowledge Base is Organized

1. **Flat file structure** - All `.md` files in root directory for easy access
2. **Tag-based discovery** - YAML frontmatter tags enable cross-cutting organization
3. **Domain categories** - Files grouped by domain above for topical browsing
4. **Related content links** - Each file's `related` field links to related documents

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

## Adding New Knowledge

### 1. Create the File

Create a new markdown file with proper frontmatter:

```bash
# Example: Adding a Git workflow guide
cat > git-workflow.md << 'EOF'
---
title: Git Workflow Guide
tags: [git, version-control, workflow]
created: 2025-12-25
related: []
---

# Git Workflow Guide

Content goes here...
EOF
```

### 2. Update This README

**IMPORTANT**: When adding new files, update both sections below:

#### A. Add to Domain Section (above)

Add your file to the appropriate domain category. If a new domain is needed, create a new section header.

```markdown
### Your New Domain Name

| File | Description | Tags |
|------|-------------|------|
| [your-file.md](your-file.md) | Brief description | `tag1`, `tag2`, `tag3` |
```

#### B. Update Tag Index (below)

Add new tags to the tag index. Tags should be **lowercase** and use **hyphens** for multi-word tags.

```markdown
| `your-new-tag` | [file1.md](file1.md), [file2.md](file2.md) |
```

### 3. Commit and Push

```bash
cd kb
git add your-file.md README.md
git commit -m "Add: Your new knowledge file"
git push
```

### 4. Update Dependent Projects

Projects using this submodule should update:

```bash
# In projects using this submodule
git submodule update --remote kb
```

---

## Tag Index

| Tag | Domain | Files |
|-----|--------|-------|
| `pandoc` | Document Automation | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [page-numbering-implementation.md](page-numbering-implementation.md) |
| `docx` | Document Automation | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `word` | Document Automation | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `page-numbering` | Document Automation | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [page-numbering-implementation.md](page-numbering-implementation.md) |
| `ooxml` | Document Automation | [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `xml` | Document Automation | [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `python` | Document Automation | [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `document-automation` | Document Automation | [docx-page-numbering-pandoc.md](docx-page-numbering-pandoc.md), [ooxml-manipulation-techniques.md](ooxml-manipulation-techniques.md) |
| `implementation` | Document Automation | [page-numbering-implementation.md](page-numbering-implementation.md) |
| `example` | Document Automation | [page-numbering-implementation.md](page-numbering-implementation.md) |

---

## Finding Information

### By Domain

Browse the **Knowledge by Domain** section above for topic-based discovery.

### By Tag

Search for files with a specific tag:

```bash
grep -l "tags:.*your-tag" *.md
```

Or search within files:
```bash
grep -r "your-tag" . --include="*.md"
```

### By Relationships

Each file has a `related` field in frontmatter. Follow these links to discover related content.

---

## Git Submodule Usage

### Add to Your Project

```bash
# Add as submodule to your project
git submodule add https://github.com/drguptavivek/agentic_kb.git kb

# Or specify a custom path
git submodule add https://github.com/drguptavivek/agentic_kb.git path/to/kb
```

### Update Submodule

```bash
# Update to latest version
git submodule update --remote kb

# Update all submodules
git submodule update --remote
```

### Clone with Submodules

```bash
# Clone repository and its submodules
git clone --recursive https://github.com/your-username/project.git

# Or initialize submodules after cloning
git submodule init
git submodule update
```

### Referencing from Other Projects

Reference files relative to the submodule path:

```
See: kb/docx-page-numbering-pandoc.md for page numbering details
```

---

## File Template

Copy this template for new knowledge files:

```yaml
---
title: Your Knowledge Title
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
related: [related-file1.md, related-file2.md]
---

# Your Knowledge Title

## Overview

Brief description of what this knowledge covers.

## Problem/Context

What problem does this solve? What context is needed?

## Solution

Your solution content here...

## Examples

Code examples, commands, or usage patterns...

## References

Links to external documentation, related files, etc.
```

---

## Maintenance Guidelines

### Tag Conventions

- Use **lowercase** tags
- Use **hyphens** for multi-word tags: `document-automation`, `page-numbering`
- Use **descriptive tags** that will be useful for searching
- Include both **specific** and **general** tags: e.g., `ooxml` + `xml` + `document-automation`

### Domain Organization

- Add new domain sections when a distinct topic area emerges
- Keep domain descriptions concise (one line per file)
- Update the Tag Index when adding new tags

### File Naming

- Use **kebab-case**: `git-workflow.md`, `api-integration.md`
- Be **descriptive**: `docx-page-numbering-pandoc.md` (not `docx.md`)
- Avoid numbers unless part of a series: `docker-part-1.md`

---

## License

See [LICENSE](LICENSE) file for details.
