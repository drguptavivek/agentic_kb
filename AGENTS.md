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
2. Open the most relevant file(s).
3. Answer using KB content, preferring exact steps or checklists.
4. Cite sources using: `<file path> -> <heading>`.
5. If missing, say: "Not found in KB" and suggest where to add it.

## Deterministic Search Pattern

```bash
# Direct repo
rg "pandoc" knowledge/
rg "page number" knowledge/

# Submodule
rg "pandoc" agentic_kb/knowledge/
rg "page number" agentic_kb/knowledge/
```

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
