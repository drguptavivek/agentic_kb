---
tags:
  - index
  - readme
---

# agentic_kb

Cross repo knowledge base that may be referenced by multiple repositories as git submodule.

**Obsidian-enabled knowledge base** with folder organization, wikilinks, and graph view.

**Offline Vector Search** enabled

**Need to add or update knowledge?** See [INSTRUCTIONS.md](INSTRUCTIONS.md)

**Integrate instructions for your AGENT** See [AGENTS.md](AGENTS.md)

---


## Using This Knowledge Base in Your Projects

Best practice: use this repo as a git submodule.

### Add as Submodule

```bash
git submodule add https://github.com/drguptavivek/agentic_kb.git agentic_kb
git submodule update --init --recursive
```

### Search with ripgrep

```bash
# Tag search
rg "#pandoc" agentic_kb/knowledge/
rg "#docx" agentic_kb/knowledge/
rg "#ooxml" agentic_kb/knowledge/
# Phrase Search
rg "page numbering" agentic_kb/knowledge/
rg "ISO 27001" agentic_kb/knowledge/
```

### Offline Vector Search (Optional)

```bash
uv init
uv run python agentic_kb/scripts/recommend_setup.py
uv add faiss-cpu numpy sentence-transformers tqdm
uv run python agentic_kb/scripts/index_kb.py
uv run python agentic_kb/scripts/search.py "page numbering in pandoc" --min-score 0.8
```



## Finding Information

### By Domain

Browse the **Knowledge by Domain** section above or navigate folders in `knowledge/`.

### By Tags

All files use `#tag` format in content. Search by tag:

```bash
# Search in Obsidian: Click on any #tag
# Or use rg:
rg "#pandoc" knowledge/
```

### By Graph View

Open in [Obsidian](https://obsidian.md) and use the **Graph View** to visualize connections between knowledge files. Files are linked via wikilinks `[[filename]]`.

### By Relationships

Each file has a **Related** section at the end with wikilinks to connected topics.

---


## Offline Vector Search

Use the local, offline search tool when it helps retrieval:

1. Add the dependencies to the parent project's environment (run in the parent repo):

```bash
uv add faiss-cpu numpy sentence-transformers tqdm
```

2. Build the vector index (run from `agentic_kb/`):

```bash
uv run python scripts/index_kb.py
```

3. Query the index (run from `agentic_kb/`):

```bash
uv run python scripts/search.py "your query"
uv run python scripts/search.py "page numbering in pandoc"
uv run python scripts/search.py "page numbering in pandoc" --min-score 0.8

```

Notes:
- The index is stored under `.kb_index/`.
- The default model can be overridden with `--model /path/to/local/model`.
- Filter by similarity with `--min-score` (default: `0.7`).
- This tool must run fully offline; do not call external APIs.
- Ensure `.kb_index/` is listed in `.gitignore`.

### Setup Recommendations (Optional)

Generate OS- and hardware-specific setup suggestions (no installs performed):

```bash
uv run python scripts/recommend_setup.py
```


## Browse Knowledge by Domain

### Document Automation

| File | Description | Tags |
|------|-------------|------|
| [[docx-page-numbering-pandoc]] | Complete guide to DOCX page numbering with Pandoc - problems, solutions, and best practices | `#pandoc`, `#docx`, `#word`, `#page-numbering` |
| [[ooxml-manipulation-techniques]] | OOXML structure, Python manipulation, unpacking/packing workflows | `#ooxml`, `#docx`, `#word`, `#xml`, `#python` |
| [[page-numbering-implementation]] | Quick reference for page numbering implementation with code examples | `#pandoc`, `#docx`, `#word`, `#page-numbering`, `#implementation` |
| [[agent-memory-practices]] | How agents capture reusable knowledge during tasks | `#agents`, `#knowledge-base`, `#documentation`, `#workflow` |
| [[obsidian-documentation]] | Documentation structure and retrieval-friendly note patterns | `#obsidian`, `#documentation`, `#knowledge-base`, `#workflow` |
| [[learning-capture-steps]] | Step-by-step process for documenting new learnings | `#knowledge-base`, `#documentation`, `#workflow`, `#agents` |

### Development Tools

*Coming soon - Add your knowledge here*

### APIs & Integrations

*Coming soon - Add your knowledge here*

### Security

| File | Description | Tags |
|------|-------------|------|
| [[iso-27001-compliance-checklist]] | Complete ISO/IEC 27001:2022 compliance checklist with 93 controls across 14 domains | `#iso27001`, `#security`, `#compliance`, `#audit`, `#isms` |

### DevOps & CI/CD

*Coming soon - Add your knowledge here*

---

## Directory Structure

```
agentic_kb/
├── README.md           # This file - knowledge index
├── INSTRUCTIONS.md     # How to add/update knowledge
├── AGENTS.md           # Agent instructions (direct and submodule paths)
├── CLAUDE.md           # Symlink to AGENTS.md for Claude Code integration
├── KNOWLEDGE_CONVENTIONS.md  # Knowledge organization and maintenance rules
├── GIT_WORKFLOWS.md    # Git and submodule workflows
├── LICENSE            # License file
├── pyproject.toml     # Python project configuration
├── .obsidian/         # Obsidian configuration (graph view, settings)
├── scripts/           # Vector search and setup utilities
└── knowledge/         # All knowledge files organized by domain
```

---


## Conventions

See [KNOWLEDGE_CONVENTIONS.md](KNOWLEDGE_CONVENTIONS.md) for file format,
linking rules, and how to add or update knowledge.

---

## License

See [LICENSE](LICENSE) file for details.
