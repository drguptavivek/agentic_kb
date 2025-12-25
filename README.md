---
tags:
  - index
  - readme
---

# agentic_kb

Cross repo knowledge base that may be referenced by multiple repositories as git submodule.

**Obsidian-enabled knowledge base** with folder organization, wikilinks, and graph view.

**Need to add or update knowledge?** See [INSTRUCTIONS.md](INSTRUCTIONS.md)

---

## Knowledge by Domain

### Document Automation

| File | Description | Tags |
|------|-------------|------|
| [[DOCX Page Numbering with Pandoc]] | Complete guide to DOCX page numbering with Pandoc - problems, solutions, and best practices | `#pandoc`, `#docx`, `#word`, `#page-numbering` |
| [[OOXML Manipulation Techniques]] | OOXML structure, Python manipulation, unpacking/packing workflows | `#ooxml`, `#docx`, `#word`, `#xml`, `#python` |
| [[Page Numbering Implementation]] | Quick reference for page numbering implementation with code examples | `#pandoc`, `#docx`, `#word`, `#page-numbering`, `#implementation` |

### Development Tools

*Coming soon - Add your knowledge here*

### APIs & Integrations

*Coming soon - Add your knowledge here*

### Security

| File | Description | Tags |
|------|-------------|------|
| [[ISO 27001 Compliance Checklist]] | Complete ISO/IEC 27001:2022 compliance checklist with 93 controls across 14 domains | `#iso27001`, `#security`, `#compliance`, `#audit`, `#isms` |

### DevOps & CI/CD

*Coming soon - Add your knowledge here*

---

## Directory Structure

```
kb/
├── README.md           # This file - knowledge index
├── INSTRUCTIONS.md     # How to add/update knowledge
├── LICENSE            # License file
├── .obsidian/         # Obsidian configuration (graph view, settings)
└── knowledge/         # All knowledge files organized by domain
    ├── Document Automation/
    │   ├── DOCX Page Numbering with Pandoc.md
    │   ├── OOXML Manipulation Techniques.md
    │   └── Page Numbering Implementation.md
    ├── Development Tools/
    ├── APIs & Integrations/
    ├── Security/
    └── DevOps & CI/CD/
```

---

## Finding Information

### By Domain

Browse the **Knowledge by Domain** section above or navigate folders in `knowledge/`.

### By Tags

All files use `#tag` format in content. Search by tag:

```bash
# Search in Obsidian: Click on any #tag
# Or use grep:
grep -r "#pandoc" knowledge/
```

### By Graph View

Open in [Obsidian](https://obsidian.md) and use the **Graph View** to visualize connections between knowledge files. Files are linked via wikilinks `[[filename]]`.

### By Relationships

Each file has a **Related** section at the end with wikilinks to connected topics.

---

## Using This Knowledge Base

### In Obsidian (Recommended)

1. Clone or download this repository
2. Open the folder in Obsidian
3. Use Graph View to explore connections
4. Click wikilinks `[[filename]]` to navigate between topics
5. Use `#tags` to discover related content

### As Git Submodule

```bash
# Add to your project
git submodule add https://github.com/drguptavivek/agentic_kb.git kb

# Update to latest
git submodule update --remote kb
```

### As Markdown Files

All files are standard markdown with YAML frontmatter. Read with any markdown viewer.

---

## File Format

### Obsidian Frontmatter

```yaml
---
tags:
  - tag1
  - tag2
  - tag3
created: YYYY-MM-DD
---

# Title

Content...

## Related

- [[Other File]]
- [[Another File]]
```

### Wikilinks

Use `[[filename]]` to link to other knowledge files:

```markdown
See [[OOXML Manipulation Techniques]] for XML details.
```

### Tags

Use `#tag` anywhere in content:

```markdown
This covers #pandoc and #docx file manipulation.
```

---

## Obsidian Features Enabled

- **Folder Structure**: Knowledge organized by domain in `knowledge/`
- **Wikilinks**: Files linked with `[[filename]]` syntax
- **Tags**: YAML `tags:` field plus inline `#tag` support
- **Graph View**: Visualize connections via `.obsidian/graph.json`
- **Live Preview**: Real-time markdown rendering
- **Backlinks**: See which files link to current file

---

## Adding New Knowledge

1. Create file in appropriate domain folder
2. Use Obsidian frontmatter format
3. Link to related files with `[[wikilinks]]`
4. Add relevant `tags:`

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for complete guide.

---

## License

See [LICENSE](LICENSE) file for details.
