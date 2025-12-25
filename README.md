---
tags:
  - index
  - readme
---

# agentic_kb

Cross repo knowledge base that may be referenced by multiple repositories as git submodule.

**Obsidian-enabled knowledge base** with folder organization, wikilinks, and graph view.

**Search Options**:
- **Typesense** (recommended): Fast full-text search with faceted filtering → [QUICK-TYPESENSE-WORKFLOW.md](QUICK-TYPESENSE-WORKFLOW.md)
- **FAISS**: Semantic vector search for conceptual queries → [QUICK-FAISS-WORKFLOW.md](QUICK-FAISS-WORKFLOW.md)

**Need to add or update knowledge?** See [INSTRUCTIONS.md](INSTRUCTIONS.md)

**Integrate instructions for your AGENT** See [AGENTS.md](AGENTS.md)

## 🤖 Claude Code Skill

**Automate KB setup, search, and updates with the `kb-search` Claude skill!**

The `kb-search.skill` enables Claude Code to automatically:
- Set up the KB as a submodule (fork or read-only)
- Search using Typesense → FAISS smart fallback
- Keep KB synced with upstream updates
- Document new knowledge with proper formatting

**Quick Start**:
```bash
# 1. Install the skill
cp kb-search.skill ~/.claude/skills/

# 2. Ask Claude to set it up
"Set up the agentic_kb knowledge base"

# 3. Start searching
"Search the KB for page numbering in Pandoc"
```

**📖 Full Guide**: [CLAUDE-SKILL-SETUP.md](CLAUDE-SKILL-SETUP.md)

---


## Using This Knowledge Base in Your Projects

Best practice: use this repo as a git submodule.

### Add as Submodule

```bash
git submodule add https://github.com/drguptavivek/agentic_kb.git agentic_kb
git submodule update --init --recursive
```

**For Coding Agents**: After adding as a submodule, integrate the KB's agent instructions into your parent project's `CLAUDE.md` file.
- Quick start: Copy template from [PARENT_PROJECT_TEMPLATE.md](PARENT_PROJECT_TEMPLATE.md)
- Full guide: [GIT_WORKFLOWS.md](GIT_WORKFLOWS.md#integrating-agent-instructions-into-parent-projects)

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
# Setup and index (one-time, 5-10 minutes)
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
cd ..

# Search
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering in pandoc" --min-score 0.8
cd ..
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


## FAISS Vector Search (Optional - Semantic)

For semantic/conceptual queries when keyword search isn't sufficient.

**Quick Reference**: See [QUICK-FAISS-WORKFLOW.md](QUICK-FAISS-WORKFLOW.md) for command cheat sheet.

**Setup**:

1. Build the vector index (one-time, 5-10 minutes):

```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
cd ..
```

2. Query the index:

```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering in pandoc" --min-score 0.8
cd ..
```

**Performance**: 100-500ms (slower than Typesense, but finds semantically similar content)

Notes:
- The index is stored under `.kb_index/`.
- Use `--model` to override the default embedding model.
- Filter by similarity with `--min-score` (default: `0.7`).
- Fully offline; no external APIs.

### Setup Recommendations (Optional)

Generate OS- and hardware-specific setup suggestions (no installs performed):

```bash
uv run python scripts/recommend_setup.py
```

## Typesense Full-Text Search (Optional)

For typo-tolerant, keyword-based search with faceting and filtering.

**Quick Reference**: See [QUICK-TYPESENSE-WORKFLOW.md](QUICK-TYPESENSE-WORKFLOW.md) for command cheat sheet.

**Setup**: See [[typesense-integration]] for complete setup guide.

**Quick Start**:

1. Start Typesense server (Docker with named volume):

```bash
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data --api-key=$TYPESENSE_API_KEY --enable-cors
```

2. Build the index:

```bash
# Direct repo usage
uv run --with typesense --with tqdm python scripts/index_typesense.py

# Submodule usage
uv run --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
```

3. Search:

```bash
# Direct repo usage
uv run --with typesense python scripts/search_typesense.py "page numbering pandoc"

# Submodule usage
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" --filter "tags:=[pandoc, docx]"
```

**When to Use**:
- Fast keyword searches with typo tolerance
- Filtering by tags or file paths
- Interactive search UIs

**Comparison**: See [[search-backends]] for detailed comparison of ripgrep vs FAISS vs Typesense.


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
| [[typesense-integration]] | Typesense integration for typo-tolerant full-text search | `#typesense`, `#search`, `#full-text`, `#indexing` |

### Search

| File | Description | Tags |
|------|-------------|------|
| [[search-backends]] | Comparison of FAISS, Typesense, and ripgrep search backends | `#search`, `#faiss`, `#typesense`, `#vector-search`, `#full-text` |
| [[agent-retrieval-workflow]] | How agents should use search results (search → read → answer pattern) | `#agents`, `#workflow`, `#retrieval`, `#search`, `#rag` |
| [[typesense-v30-deprecation-warnings]] | Fix for Typesense v30+ deprecation warnings | `#typesense`, `#python`, `#deprecation`, `#troubleshooting` |
| [[typesense-yaml-frontmatter-parsing]] | Fix for YAML frontmatter tag parsing in Typesense indexing | `#typesense`, `#yaml`, `#frontmatter`, `#parsing`, `#python` |

### Android Development

| File | Description | Tags |
|------|-------------|------|
| [[android-common-pitfalls]] | Common pitfalls including threading, lifecycle, and build issues in Android | `#android`, `#threading`, `#performance` |
| [[odk-collect-core]] | Core architecture of ODK Collect (MVVM, JavaRosa, Repo Pattern) | `#odk`, `#architecture`, `#android` |
| [[aiims-odk-collect-customizations]] | AIIMS-specific fork details: Auth, PIN Security, Data Isolation | `#aiims`, `#auth`, `#customization` |

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
├── PARENT_PROJECT_TEMPLATE.md  # Template for integrating KB into parent projects
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
