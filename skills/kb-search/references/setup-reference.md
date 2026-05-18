# KB Setup Reference

Use this file only for first-time setup, central repo mode, sandbox allowlists, or installation questions. Normal KB search should use only `SKILL.md`.

## Choosing a Mode

- Centralized repo mode: one shared machine-local KB at `~/.agentic_kb`; best when many projects use the same current KB.
- Submodule mode: project-pinned KB revision at `agentic_kb/`; best when reproducibility and PR review matter.
- Direct repo mode: working inside the KB itself.

## Centralized Repo Mode

```bash
scripts/setup_kb.sh --central
scripts/setup_kb.sh --central --fork-url <USER_KB_REPO_URL>
AGENTIC_KB_PATH=/path/to/agentic_kb scripts/setup_kb.sh --central
```

Use from any project:

```bash
~/.agentic_kb/scripts/update_kb.sh
~/.agentic_kb/scripts/smart_search.sh "query"
```

Central setup also prepares generated Python state once:

```bash
~/.agentic_kb/.uv-cache/
~/.agentic_kb/.venv/
```

Sandboxed agents should reuse those paths instead of creating per-project dependency caches. Normal `smart_search.sh` uses `~/.agentic_kb/.venv/bin/python` directly when it exists, avoiding repeated `uv run` dependency syncs.

## File Placement Contract

Use this layout for central mode:

```text
~/.agentic_kb/                  # central KB repo, source of truth
  knowledge/                    # reusable knowledge notes
  scripts/                      # canonical KB scripts
  .uv-cache/                    # generated dependency cache
  .venv/                        # prewarmed Python env
  .kb_index/                    # generated FAISS index

~/.agents/skills/kb-search/      # installed agent skill
  SKILL.md                      # token-light router
  references/                   # lazy-loaded instructions
  scripts/                      # packaged helper copies
```

Runtime preference:

1. Execute canonical scripts from `~/.agentic_kb/scripts/`.
2. Write KB content only under `~/.agentic_kb/knowledge/`.
3. Use `~/.agents/skills/kb-search/` only as the installed skill interface.
4. Treat skill-packaged scripts as fallback helpers, not the source of truth.

## Submodule Mode

Personal fork:

```bash
scripts/setup_kb.sh --fork-url <USER_KB_REPO_URL>
git add .gitmodules agentic_kb
git commit -m "Add: agentic_kb submodule"
```

Default/read-only:

```bash
scripts/setup_kb.sh --default
scripts/setup_kb.sh --read-only
```

For Windows/PowerShell setup commands, load `windows-powershell.md`.

## Central KB Sandbox Access

Parent project instructions should include this when using central mode:

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

## Typesense Service

```bash
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data \
  --api-key=$TYPESENSE_API_KEY --enable-cors
```

Index:

```bash
uv run --active --with typesense --with tqdm python scripts/index_typesense.py
uv run --active --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
uv run --active --with typesense --with tqdm python ~/.agentic_kb/scripts/index_typesense.py
```
