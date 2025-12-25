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

```bash
git pull origin main
git add knowledge/ README.md
git commit -m "Update: KB changes"
git push
```

## Workflow: KB as Submodule in Projects

Use this when `agentic_kb` is mounted as a submodule inside another project.

### Update Project to Latest KB

```bash
# In the project repo
git submodule update --remote agentic_kb
git add agentic_kb
git commit -m "Update kb submodule"
git push
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

# Or add as submodule (recommended for projects)
git submodule add https://github.com/you/agentic_kb.git agentic_kb
git submodule update --init --recursive
```

## RAG Guidance (Optional)

Add embeddings only if the KB grows beyond ~5-10k notes or you need semantic recall
across distant topics. For now, deterministic search is preferred.
