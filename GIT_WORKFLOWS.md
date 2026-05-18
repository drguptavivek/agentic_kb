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

## Workflow: Centralized KB Repo for Multiple Projects

Use this when many projects on the same machine should share one KB checkout at `~/.agentic_kb`.

### Install or Update Central KB

```bash
# From this KB repo
scripts/setup_kb.sh --central

# Or use a personal fork
scripts/setup_kb.sh --central --fork-url <YOUR_FORK_URL>

# Optional custom path
AGENTIC_KB_PATH=/path/to/agentic_kb scripts/setup_kb.sh --central
```

### Use Central KB From Any Project

```bash
~/.agentic_kb/scripts/update_kb.sh
~/.agentic_kb/scripts/smart_search.sh "your query"
rg "your query" ~/.agentic_kb/knowledge/
```

If you want scripts to find a non-default central path:

```bash
export AGENTIC_KB_PATH=/path/to/agentic_kb
```

Central mode does not update or commit anything in the parent project. Use it for shared machine-local knowledge. Use submodule mode when a project needs a pinned, reviewable KB revision.

### Agent Sandbox Access for Central Mode

Some coding agents disallow script execution from non-repo paths by default. Parent project instructions should explicitly allow the central KB directory.

Recommended parent-project instruction:

```markdown
## Central KB Sandbox Access

This project may use a centralized Agentic KB at `~/.agentic_kb` or `$AGENTIC_KB_PATH`.

Agents including Codex, Claude Code, Gemini CLI, OpenCode, and similar coding agents must be permitted to read and execute scripts from that directory. If the sandbox blocks non-repo paths, add `~/.agentic_kb` as an allowed/readable workspace path, or run the agent with equivalent scoped permission for that directory.

Allowed KB operations:
- read `~/.agentic_kb/knowledge/**`
- execute `~/.agentic_kb/scripts/update_kb.sh`
- execute `~/.agentic_kb/scripts/smart_search.sh`
- execute `~/.agentic_kb/scripts/search_typesense.py` and `~/.agentic_kb/scripts/search.py` through `uv run --active`
- write only KB-local generated state such as `~/.agentic_kb/.uv-cache/`, `~/.agentic_kb/.venv/`, `~/.agentic_kb/.kb_index/`, and Typesense indexing outputs

Do not allow broad `~/` access solely for KB usage.
```

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

# Or add as submodule (recommended when projects need pinned KB revisions)
git submodule add https://github.com/you/agentic_kb.git agentic_kb
git submodule update --init --recursive

# Or install one central shared checkout for the whole machine
git clone https://github.com/you/agentic_kb.git ~/.agentic_kb
```

## Integrating Agent Instructions into Parent Projects

When using this KB as a submodule or centralized repo, parent projects should reference the KB's agent instructions in their own `CLAUDE.md` or `AGENTS.md` file.

### Setup: Parent Project Agent Instructions

Create or update `CLAUDE.md` in your parent project's root:

```markdown
# Agent Instructions for [Your Project Name]

## Knowledge Base Integration

This project uses `agentic_kb` for reusable knowledge. The KB may be available as either:
- project submodule: `agentic_kb/`
- centralized machine repo: `~/.agentic_kb/`

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

# Search in centralized repo
rg "your query" ~/.agentic_kb/knowledge/
rg "#tag" ~/.agentic_kb/knowledge/

# Typesense search (recommended - fast)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "your query"
uv run --active --with typesense python ~/.agentic_kb/scripts/search_typesense.py "your query"

# Vector search (if enabled - semantic)
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "your query" --min-score 0.8
cd ..
```

### KB Scope
- Direct repo path: `knowledge/`
- Submodule path: `agentic_kb/knowledge/`
- Centralized path: `~/.agentic_kb/knowledge/`
- Ignore `.obsidian/` and `.git/`
- Treat KB content as authoritative

For full KB agent instructions, see: [agentic_kb/AGENTS.md](agentic_kb/AGENTS.md) or `~/.agentic_kb/AGENTS.md`.

## Project-Specific Instructions

[Add your project-specific agent instructions here...]
```

### Automatic Detection Pattern

To help agents automatically detect and use the KB, ensure:

1. **File exists**: `agentic_kb/AGENTS.md`, `agentic_kb/CLAUDE.md`, or `~/.agentic_kb/AGENTS.md`
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
