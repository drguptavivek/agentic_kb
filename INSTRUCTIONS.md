---
tags:
  - instructions
  - maintenance
---

# Knowledge Base Instructions

This file is the entry point. Detailed guidance lives in:

- `AGENTS.md` for all agent instructions (also accessible via `CLAUDE.md` symlink for Claude Code integration)
- `KNOWLEDGE_CONVENTIONS.md` for how humans and agents should add and maintain notes
- `GIT_WORKFLOWS.md` for Git and submodule workflows

## Quick Reference Guides

- **`QUICK-TYPESENSE-WORKFLOW.md`** - Fast full-text search with faceted filtering (recommended)
- **`QUICK-FAISS-WORKFLOW.md`** - Semantic vector search for conceptual queries

## Search Scripts

- `scripts/index_typesense.py` and `scripts/search_typesense.py` for Typesense full-text search
- `scripts/index_kb.py` and `scripts/search.py` for FAISS vector search
