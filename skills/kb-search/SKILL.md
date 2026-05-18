---
name: kb-search
description: Token-light router for agentic_kb. Core loop: Search Knowledge when KB help is requested; Capture Reusable Knowledge when work teaches something durable; update stale existing knowledge when evidence shows it is outdated. Use on explicit KB search/use/update/capture/setup requests and when a task produces reusable or corrective knowledge worth proposing for KB_Update.
---

# KB Search

## Core Loop

- Search Knowledge: use KB retrieval when the user asks for KB-backed help.
- Capture Reusable Knowledge: when work reveals repeatable knowledge, propose KB_Update before finishing.
- Update Stale Knowledge: when retrieved KB content is wrong, incomplete, or outdated, propose KB_Update to correct the existing note.
- Keep KB entries short, objective, pointed, and token-efficient.
- This is how the KB and future agents get smarter.

Do not search the KB for ordinary questions. Do not silently edit the KB.

## Load References Only If Needed

- Setup, central repo, sandbox allowlist: `references/setup-reference.md`
- Capture Reusable Knowledge / KB_Update: `references/kb-update.md`
- Command failure, indexing, Typesense/FAISS issues: `references/troubleshooting.md`
- Windows/PowerShell: `references/windows-powershell.md`
- Missing `rg`: `references/rg-installation.md`
- Domains: `references/kb-domains.md`
- Filter/search examples: `references/search-patterns.md`

## Path Order

Use first existing path:

1. `$AGENTIC_KB_PATH`
2. `agentic_kb/`
3. `~/.agentic_kb/`
4. current repo root with `knowledge/`

## Search

Prefer smart search:

```bash
agentic_kb/scripts/smart_search.sh "query"
~/.agentic_kb/scripts/smart_search.sh "query"
scripts/smart_search.sh "query"
```

Exact fallback:

```bash
rg "query" agentic_kb/knowledge/
rg "query" ~/.agentic_kb/knowledge/
rg "query" knowledge/
```

## Update

Ask first: `Do you want me to update the KB from git for this session?`

```bash
agentic_kb/scripts/update_kb.sh
~/.agentic_kb/scripts/update_kb.sh
scripts/update_kb.sh
```

## Answer Rules

1. Search.
2. Read full relevant file(s); never answer from snippets alone.
3. Cite as `<file path> -> <heading>`.
4. If absent, say `Not found in KB` and suggest where to add it.

## KB_Update

If work reveals reusable knowledge, propose KB_Update before finishing. Do not silently edit. After user confirms: search for duplicates, add/update the best note, follow `KNOWLEDGE_CONVENTIONS.md`, and cite the changed KB file. Load `references/kb-update.md` for details.
