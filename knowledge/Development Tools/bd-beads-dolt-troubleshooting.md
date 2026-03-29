---
title: bd (Beads) Dolt troubleshooting guide
type: howto
domain: Development Tools
tags:
  - beads
  - bd
  - dolt
  - issue-tracker
  - troubleshooting
status: approved
created: 2026-03-29
updated: 2026-03-29
---

# bd (Beads) Dolt troubleshooting guide

## Problem / Context

`bd` (beads v0.62.0) uses Dolt as its only supported storage backend. Two classes
of failure appear often:

1. **Wrong server targeted** — bd connects to the wrong Dolt instance (shared vs
   per-project) and reports `database "central" not found`.
2. **JSONL type mismatches** — `bd import` fails with Go unmarshal errors when
   the JSONL was produced by an older bd version or a Python export script.

---

## Issue 1 — Wrong Dolt server (shared vs per-project conflict)

### Symptoms

```
Error: failed to open database: database "central" not found on Dolt server at 127.0.0.1:3308
```

`bd dolt show` reports port 3308 (shared server), but `dolt-server.pid` and
`dolt-server.port` in `.beads/` point to a different port (e.g. 61195).

### Root cause

`dolt.shared-server: true` in `.beads/config.yaml` overrides the per-project
Dolt server. bd looks for the database on the shared server at `~/.beads/shared-server/`
instead of the local `.beads/dolt/` server.

This setting is written by `bd init --shared-server`. If you later want the
per-project server (the default), you must remove or comment it out.

### Diagnosis

```bash
bd dolt show           # shows which host:port bd is targeting
cat .beads/dolt-server.port   # shows what port the local server is actually on
ps aux | grep dolt            # confirm which servers are running
```

### Fix

1. Comment out `dolt.shared-server: true` in `.beads/config.yaml`:

   ```yaml
   # dolt.shared-server: true
   ```

2. Ensure `metadata.json` has `"database": "dolt"` (not `"jsonl"`):

   ```json
   {
     "database": "dolt",
     "backend": "dolt",
     "dolt_mode": "server",
     "dolt_database": "central",
     "project_id": "<uuid>"
   }
   ```

3. Stop any stray shared-server process (`kill <pid>`).

4. Verify:

   ```bash
   bd dolt show     # should show per-project port and "✓ Server connection OK"
   bd stats         # should return counts
   ```

### Important

Do NOT manually create Dolt databases or edit Dolt's data dir — let `bd init`
and `bd dolt start` manage the database lifecycle. Direct Dolt manipulation
will diverge from bd's metadata.

---

## Issue 2 — JSONL type mismatches on `bd import`

### Symptoms

```
Error: import failed: failed to parse issue from JSONL:
  json: cannot unmarshal number into Go struct field Comment.comments.id of type string
```

Or variants:

```
json: cannot unmarshal number into Go struct field Issue.ephemeral of type bool
json: cannot unmarshal string into Go struct field Issue.waiters of type []string
```

### Root cause

The JSONL was exported or hand-edited with incorrect types:

| Field | bd expects | Common bad value |
|---|---|---|
| `comments[].id` | `string` | `123` (number) |
| `ephemeral` | `bool` | `0` / `1` (int) |
| `pinned` | `bool` | `0` / `1` (int) |
| `is_template` | `bool` | `0` / `1` (int) |
| `waiters` | `[]string` | `""` (bare string) |

### Fix

Run this Python snippet against the JSONL file before importing:

```python
import json

with open('.beads/issues.jsonl') as f:
    lines = [l.strip() for l in f if l.strip()]

cleaned = []
for line in lines:
    obj = json.loads(line)
    # comment IDs: number → string
    for c in obj.get('comments') or []:
        if isinstance(c.get('id'), (int, float)):
            c['id'] = str(int(c['id']))
    # bool fields: int → bool
    for field in ('ephemeral', 'pinned', 'is_template'):
        if field in obj and isinstance(obj[field], int):
            obj[field] = bool(obj[field])
    # waiters: string → list
    if isinstance(obj.get('waiters'), str):
        obj['waiters'] = [obj['waiters']] if obj['waiters'] else []
    cleaned.append(json.dumps(obj))

with open('.beads/issues.jsonl', 'w') as f:
    f.write('\n'.join(cleaned) + '\n')
```

Then:

```bash
bd import              # import from .beads/issues.jsonl
bd stats               # verify counts
```

---

## Restoring from a backup JSONL

When `bd import` fails and the backup also needs cleaning:

```bash
# 1. Fix types in backup file → /tmp/issues_fixed.jsonl  (use script above)
# 2. Import
bd import /tmp/issues_fixed.jsonl

# 3. Verify
bd stats
bd list --status=open
```

Prefer `backup/issues.from-db.full.jsonl` over `backup/issues.jsonl` — the
former is the most complete export (direct DB dump), while the latter may have
been zeroed by a failed restore.

---

## Common `bd dolt` diagnostic commands

```bash
bd dolt show          # config + connection test
bd dolt status        # server PID, port, data dir
bd dolt start         # start per-project server
bd dolt stop          # stop per-project server
bd doctor             # full health check (57+ checks)
bd doctor --fix --yes # attempt automatic repairs
```

---

## Related

- [[bd-beads-workflow]] (if exists)
