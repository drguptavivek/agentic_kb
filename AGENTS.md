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

## Initial Setup

**CRITICAL**: At the start of each session, agents MUST update the KB submodule to ensure access to the latest knowledge:

```bash
# Update submodule to latest from remote
git submodule update --remote agentic_kb

# Stage and commit the pointer update in parent project
git add agentic_kb
git commit -m "Update: agentic_kb submodule to latest"
git push
```

This ensures:
- The KB is current with upstream changes
- The parent project tracks the latest KB version
- All agents work with synchronized knowledge

## Required Workflow

1. Search the KB before answering (use `rg` under the correct KB path).
2. Open the most relevant file(s) using the Read tool.
3. Answer using KB content, preferring exact steps or checklists.
4. Cite sources using: `<file path> -> <heading>`.
5. If missing, say: "Not found in KB" and suggest where to add it.

**IMPORTANT**: Never answer from search snippets alone. Always read the full files first. See `knowledge/Search/agent-retrieval-workflow.md` for detailed workflow.

## Deterministic Search Pattern

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

1. Install dependency and start Typesense server:

```bash
uv add typesense
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data --api-key=$TYPESENSE_API_KEY --enable-cors
```

2. Build the index (run from parent project root):

```bash
uv run python agentic_kb/scripts/index_typesense.py
```

### Search

```bash
# Basic search
uv run python agentic_kb/scripts/search_typesense.py "page numbering pandoc"

# Filter by domain
uv run python agentic_kb/scripts/search_typesense.py "search" --filter "domain:Search"

# Filter by type (howto, reference, checklist, policy, note)
uv run python agentic_kb/scripts/search_typesense.py "page" --filter "type:howto"

# Filter by status (draft, approved, deprecated)
uv run python agentic_kb/scripts/search_typesense.py "search" --filter "status:approved"

# Combine filters
uv run python agentic_kb/scripts/search_typesense.py "search" \
  --filter "domain:Search && type:howto && status:approved"
```

**Quick Reference**: See `agentic_kb/QUICK-TYPESENSE-WORKFLOW.md`

**Performance**: 10-50ms (vs FAISS 100-500ms). Returns full chunk content - often no need to read files!

## FAISS Vector Search (Semantic)

Use for semantic/conceptual queries when Typesense doesn't find relevant results:

1. Add the dependencies to the parent project's environment:

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
uv run python scripts/search.py "page numbering in pandoc" --min-score 0.8
```

Notes:
- The index is stored under `.kb_index/`.
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
