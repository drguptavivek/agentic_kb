---
title: KB Search Trigger Policy and Sandbox-safe UV Commands
type: howto
domain: Search
tags:
  - agents
  - search
  - workflow
  - uv
  - sandbox
status: approved
created: 2026-02-19
updated: 2026-02-19
---

# KB Search Trigger Policy and Sandbox-safe UV Commands

## Problem / Context

Two recurring issues were identified during agent sessions:

1. Unrequested KB searches can interrupt normal Q&A flow and feel noisy.
2. `uv run` can fail in restricted environments due to cache/interpreter access patterns.

## Recommended Policy: Search KB Only on Explicit Request

Use KB search only when the user explicitly asks to search or use the KB.

### Rules

1. Do not auto-search KB for every question.
2. If user did not ask for KB search, answer normally.
3. If user asks for KB search, follow retrieval workflow:
   1. Search
   2. Read full file(s)
   3. Answer with citations

## Session Start Policy: Confirm KB Git Update First

Before any KB update command, ask:

`Do you want me to update the KB from git for this session?`

If user says yes, run update workflow.  
If user says no, continue with local KB content.

## Sandbox-safe UV Execution Pattern

In restricted environments, set a repo-local cache and use active environment execution.

### PowerShell

```powershell
$env:UV_CACHE_DIR = (Join-Path (Resolve-Path .).Path ".uv-cache")
New-Item -ItemType Directory -Path $env:UV_CACHE_DIR -Force | Out-Null
uv run --active --with typesense python scripts/search_typesense.py "query"
```

If `uv` still fails due to access under `~/.cache/uv`, rerun with elevated permissions.  
If `uv` fails with PyPI DNS/connectivity errors, dependency resolution is blocked by network limits.

## Command Differences That Matter

1. `update_kb.sh` is a wrapper and may report success after fallback behavior.
2. `git -C agentic_kb pull --ff-only` is the direct verification/update command.
3. `index_typesense.py` auto-detects KB root and does not accept `--kb-root`.
4. `index_typesense.py` needs `tqdm`; include `--with tqdm`.
5. `search_typesense.py` needs `typesense`; include `--with typesense`.

Examples:

```bash
# Direct KB update
git -C agentic_kb pull --ff-only

# Typesense index
uv run --active --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py

# Typesense search
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "query"
```

### Bash

```bash
export UV_CACHE_DIR="$(pwd)/.uv-cache"
mkdir -p "$UV_CACHE_DIR"
uv run --active --with typesense python scripts/search_typesense.py "query"
```

## Checklist

- [ ] Ask before KB git update at session start
- [ ] Search KB only on explicit user request
- [ ] Read full files before answering from KB
- [ ] Use `UV_CACHE_DIR` + `uv run --active` in restricted environments
- [ ] Prefer direct `git -C agentic_kb pull --ff-only` when update script shows permission errors
- [ ] Use correct Typesense index command (no `--kb-root`, include `--with tqdm`)
- [ ] Propose KB capture when a new reusable problem-solving technique is learned

## References

- [[agent-retrieval-workflow]]
- [[learning-capture-steps]]
- [[search-backends]]

## Related

- [[typesense-integration]]
- [[typesense-v30-deprecation-warnings]]
