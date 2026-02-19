---
tags:
  - instructions
  - git
  - workflows
---

# Git Workflows

This file covers Git-specific workflows for the KB. It is separate from how
knowledge is organized.

## Workflow: Edit KB Directly (Primary Repo)

Use this when you are editing the KB in its own repo.

Before running update commands in an agent session, ask:
- `Do you want me to update the KB from git for this session?`

If user says yes, run:

```bash
git pull origin main
git add knowledge/ README.md
git commit -m "Update: KB changes"
git push
```

If user says no, skip git update and continue with local KB content.

## Workflow: KB as Submodule in Projects

Use this when `agentic_kb` is mounted as a submodule inside another project.

### Update Project to Latest KB

Before running update commands in an agent session, ask:
- `Do you want me to update the KB from git for this session?`

If user says yes, run:

```bash
# In the project repo
git submodule update --remote agentic_kb
git add agentic_kb
git commit -m "Update kb submodule"
git push
```

If user says no, skip git update and continue with local KB content.

### Make KB Changes From Inside Project

```bash
# In the project repo
cd agentic_kb
git checkout main
git pull origin main
git add knowledge/ README.md
git commit -m "Update: KB changes"
git push

cd ..
git add agentic_kb
git commit -m "Update kb submodule"
git push
```

## Mounting Patterns (Reference)

```bash
# Clone into a workspace
git clone https://github.com/you/agentic_kb.git agentic_kb

# Or add as submodule (recommended for projects)
git submodule add https://github.com/you/agentic_kb.git agentic_kb
git submodule update --init --recursive
```

## Integrating Agent Instructions into Parent Projects

When using this KB as a submodule, parent projects should reference the KB's agent instructions in their own `CLAUDE.md` or `AGENTS.md` file.

### Setup: Parent Project Agent Instructions

Create or update `CLAUDE.md` in your parent project's root:

```markdown
# Agent Instructions for [Your Project Name]

## Knowledge Base Integration

This project uses `agentic_kb` as a git submodule for reusable knowledge.

**IMPORTANT**: Before answering questions, agents MUST:

1. Check if the question relates to documented knowledge
2. Search the KB using the patterns below
3. Cite sources from KB when using its content

### KB Search Patterns

<!-- Source: agentic_kb/AGENTS.md -->
```bash
# Search in submodule
rg "your query" agentic_kb/knowledge/
rg "#tag" agentic_kb/knowledge/

# Typesense search (recommended - fast)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "your query"

# Vector search (if enabled - semantic)
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "your query" --min-score 0.8
cd ..
```

### KB Scope
- Direct repo path: `knowledge/`
- Submodule path: `agentic_kb/knowledge/`
- Ignore `.obsidian/` and `.git/`
- Treat KB content as authoritative

For full KB agent instructions, see: [agentic_kb/AGENTS.md](agentic_kb/AGENTS.md)

## Project-Specific Instructions

[Add your project-specific agent instructions here...]
```

### Automatic Detection Pattern

To help agents automatically detect and use the KB, ensure:

1. **File exists**: `agentic_kb/AGENTS.md` or `agentic_kb/CLAUDE.md`
2. **Parent references it**: Your `CLAUDE.md` includes the patterns above
3. **Submodule is initialized**: Run `git submodule update --init --recursive`

### Update Parent Instructions When KB Changes

```bash
# Update submodule to latest
git submodule update --remote agentic_kb

# Review if AGENTS.md has new patterns
cat agentic_kb/AGENTS.md

# Update your CLAUDE.md if needed
# Then commit
git add CLAUDE.md agentic_kb
git commit -m "Update: Sync KB agent instructions"
git push
```

---

## RAG Guidance (Optional)

Add embeddings only if the KB grows beyond ~5-10k notes or you need semantic recall
across distant topics. For now, deterministic search is preferred.
