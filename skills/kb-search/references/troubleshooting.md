# KB Troubleshooting Reference

Use this file only when normal `SKILL.md` commands fail.

## Typesense Server Not Running

```bash
curl http://localhost:8108/health
docker ps | grep typesense
docker logs typesense --tail 50
docker start typesense
```

If missing:

```bash
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data \
  --api-key=$TYPESENSE_API_KEY --enable-cors
```

## Rebuild Typesense Index

```bash
uv run --active --with typesense --with tqdm python scripts/index_typesense.py
uv run --active --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
uv run --active --with typesense --with tqdm python ~/.agentic_kb/scripts/index_typesense.py
```

`index_typesense.py` auto-detects KB root and does not accept `--kb-root`.

## UV Sandbox Errors

Use KB-local generated state:

```bash
export UV_CACHE_DIR="$(pwd)/.uv-cache"
export UV_PROJECT_ENVIRONMENT="$(pwd)/.venv"
mkdir -p "$UV_CACHE_DIR"
mkdir -p "$UV_PROJECT_ENVIRONMENT"
```

For central mode:

```bash
export UV_CACHE_DIR="$HOME/.agentic_kb/.uv-cache"
export UV_PROJECT_ENVIRONMENT="$HOME/.agentic_kb/.venv"
mkdir -p "$UV_CACHE_DIR"
mkdir -p "$UV_PROJECT_ENVIRONMENT"
```

If sandbox still blocks access, request scoped write permission for only:

```text
~/.agentic_kb/.uv-cache/
~/.agentic_kb/.venv/
~/.agentic_kb/.kb_index/
```

If the agent cannot receive that permission, set `AGENTIC_KB_UV_CACHE_DIR` and `AGENTIC_KB_UV_ENV` to writable temp paths. This avoids repeated downloads less reliably than the central prewarmed env.

## Prewarm Central Python Env

Run once during setup:

```bash
~/.agentic_kb/scripts/setup_kb.sh --central
```

Or repair manually:

```bash
export UV_CACHE_DIR="$HOME/.agentic_kb/.uv-cache"
uv venv "$HOME/.agentic_kb/.venv"
uv pip install --python "$HOME/.agentic_kb/.venv/bin/python" \
  typesense tqdm faiss-cpu numpy sentence-transformers
```

## FAISS Index Missing

```bash
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
```

For central mode:

```bash
cd ~/.agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
```

## No Results

1. Remove restrictive filters.
2. Try exact `rg` search.
3. Try FAISS for conceptual wording.
4. If still missing, answer `Not found in KB` and suggest where to add it.

## ripgrep Missing

If `rg` is not found, read `rg-installation.md`.
