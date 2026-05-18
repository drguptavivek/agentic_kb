# Capture Reusable Knowledge / KB_Update Reference

Use this when the current task produces reusable knowledge, shows existing KB content is stale, or the user asks to add/update KB content.

The operating loop is:

1. Search Knowledge.
2. Do the work.
3. Capture Reusable Knowledge or update stale knowledge.

That is how the KB becomes more complete and future agents become smarter.

## When to Propose KB_Update

Propose a KB update when you learn:

- a repeatable debugging workflow
- a setup or sandbox fix
- a repo-specific command sequence
- a service bring-up or verification checklist
- an error cause and durable fix
- a project convention that future agents should reuse
- existing KB content is wrong, incomplete, stale, or contradicted by current verified evidence

Do not propose KB_Update for one-off facts, temporary states, or secrets.

## Workflow

1. Say what reusable knowledge should be captured and why.
2. Ask for confirmation before editing.
3. Search the KB for duplicates:

```bash
agentic_kb/scripts/smart_search.sh "topic"
~/.agentic_kb/scripts/smart_search.sh "topic"
rg "exact phrase" agentic_kb/knowledge/ ~/.agentic_kb/knowledge/ knowledge/
```

4. If a note exists, update it narrowly. Prefer correcting the existing note over creating a duplicate.
5. If missing, create a note in the best domain folder under the active KB `knowledge/` path, usually `~/.agentic_kb/knowledge/` in central mode.
6. Follow `KNOWLEDGE_CONVENTIONS.md`.
7. Rebuild/search indexes only if the user needs immediate indexed retrieval.
8. Final response should cite changed KB file(s).

## Writing Standard

- Keep notes short, objective, pointed, and token-efficient.
- Prefer commands, exact symptoms, durable causes, and verification steps.
- Remove narrative, praise, speculation, and duplicate background.
- Update stale lines in place when possible.
- Do not create broad essays when a checklist or focused how-to is enough.

## Note Skeleton

```markdown
---
title: Short Retrieval-Friendly Title
type: howto
domain: Search
tags:
  - agents
  - workflow
status: approved
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Short Retrieval-Friendly Title

## Problem / Context

## Reusable Procedure

## Verification

## Related

- [[related-note]]
```

## Automation Helper

```bash
uv run --active python skills/kb-search/scripts/capture_note.py \
  --title "Title" \
  --domain "Search" \
  --type howto \
  --status draft \
  --tags "agents,workflow"
```
