---
tags:
  - instructions
  - agents
---

# Agent Instructions

This is the single source of truth for agent behavior when using this KB.

**For Parent Projects**: If this KB is used as a submodule, the parent project's `CLAUDE.md` should reference these instructions. See [GIT_WORKFLOWS.md](GIT_WORKFLOWS.md#integrating-agent-instructions-into-parent-projects) for integration template.

## Scope and Sources

- Direct repo path: `knowledge/`
- Submodule path: `agentic_kb/knowledge/`
- Ignore `.obsidian/` and `.git/`
- Treat the KB as authoritative

## First-Time Setup

For initial KB setup with a submodule:
- **With your fork**: `scripts/setup_kb.sh --fork-url <YOUR_FORK_URL>`
- **Default KB**: `scripts/setup_kb.sh --default`
- **Read-only**: `scripts/setup_kb.sh --read-only`

For detailed setup options, see `GIT_WORKFLOWS.md`.

## Session Initialization

**CRITICAL**: At the start of each session, agents MUST update the KB to ensure access to the latest knowledge:

```bash
# Auto-detect KB path (works for direct repo or submodule):
scripts/update_kb.sh

# If KB is a submodule and you're in the parent repo:
agentic_kb/scripts/update_kb.sh

# Or manually update submodule:
git submodule update --remote agentic_kb
git add agentic_kb
git commit -m "Update: agentic_kb submodule to latest"
git push

# If KB is a direct clone (not a submodule):
cd agentic_kb && git pull && cd ..
# Or from knowledge/ if KB is the main repo:
git pull
```

This ensures:
- The KB is current with upstream changes
- The parent project tracks the latest KB version
- All agents work with synchronized knowledge

## Required Workflow

1. Search the KB before answering using one of these methods (in order of preference):
   - **Smart search** (tries Typesense → FAISS automatically)
   - **Typesense** for fast full-text search with filters
   - **FAISS** for semantic/conceptual queries
   - **ripgrep** (`rg`) for exact pattern matching
2. Open the most relevant file(s) using the Read tool.
3. Answer using KB content, preferring exact steps or checklists.
4. Cite sources using: `<file path> -> <heading>`.
5. If missing, say: "Not found in KB" and suggest where to add it.

**IMPORTANT**: Never answer from search snippets alone. Always read the full files first. See `knowledge/Search/agent-retrieval-workflow.md` for detailed workflow.

## Smart Search (Recommended)

Use the smart search script that automatically tries Typesense first, then falls back to FAISS (auto-detects KB path):

```bash
# If KB is a submodule:
agentic_kb/scripts/smart_search.sh "your query"
agentic_kb/scripts/smart_search.sh "search" --filter "domain:Search && type:howto"
agentic_kb/scripts/smart_search.sh "git workflow" --min-score 0.8

# If KB is the main repo:
scripts/smart_search.sh "your query"
scripts/smart_search.sh "search" --filter "domain:Search && type:howto"

# If auto-detection fails:
scripts/smart_search.sh "your query" --kb-path path/to/agentic_kb
```

**Performance**: Combines the speed of Typesense (10-50ms) with the semantic understanding of FAISS (100-500ms) as fallback.

## Deterministic Search Pattern (ripgrep)

```bash
# Direct repo
rg "pandoc" knowledge/
rg "page number" knowledge/

# Submodule
rg "pandoc" agentic_kb/knowledge/
rg "page number" agentic_kb/knowledge/
```

## Typesense Full-Text Search (Recommended)

Fast, typo-tolerant search with faceted filtering. **5-10x faster than vector search.**

### Setup (One-Time)

Start Typesense server:

```bash
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data --api-key=$TYPESENSE_API_KEY --enable-cors
```

Build the index (run from parent project root):

```bash
uv run --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
```

### Search

```bash
# Basic search
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering pandoc"

# Filter by domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "domain:Search"

# Filter by type (howto, reference, checklist, policy, note)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page" --filter "type:howto"

# Filter by status (draft, approved, deprecated)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "status:approved"

# Combine filters
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" \
  --filter "domain:Search && type:howto && status:approved"
```

**Quick Reference**: See `agentic_kb/QUICK-TYPESENSE-WORKFLOW.md`

**Performance**: 10-50ms (vs FAISS 100-500ms). Returns full chunk content - often no need to read files!

## FAISS Vector Search (Semantic)

Use for semantic/conceptual queries when Typesense doesn't find relevant results:

1. Build the vector index (run from parent project root):

```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
cd ..
```

2. Query the index (run from parent project root):

```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "your query"
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering in pandoc" --min-score 0.8
cd ..
```

**Quick Reference**: See `agentic_kb/QUICK-FAISS-WORKFLOW.md`

Notes:
- The index is stored under `agentic_kb/.kb_index/`.
- Use `--model` to override the default embedding model.
- Filter by similarity with `--min-score` (default: `0.7`).
- Slower but better for conceptual queries.

## Knowledge Capture

Agents must document new, reusable knowledge learned during tasks. 
If a KB update is needed based on new findings, ask for user confirmation before making edits.
Follow `knowledge/Document Automation/learning-capture-steps.md`.
Follow `KNOWLEDGE_CONVENTIONS.md`.


## Obsidian-Specific Requirements

When generating knowledge notes, include:

- YAML frontmatter with tags and created date
- Explicit headings that match likely queries
- A `Related` section with `[[wikilinks]]`

Follow `KNOWLEDGE_CONVENTIONS.md` for the full Obsidian usage rules.
