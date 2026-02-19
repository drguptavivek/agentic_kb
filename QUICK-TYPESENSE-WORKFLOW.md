# Quick Typesense Workflow

**For submodule usage** (most common). Run from parent project root where `agentic_kb/` is the submodule directory.

## Setup (One-Time)

```bash
# Create Docker volume
docker volume create typesense-agentic-kb-data

# Start Typesense server
export TYPESENSE_API_KEY=xyz
docker run -d --name typesense -p 8108:8108 -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data --api-key=$TYPESENSE_API_KEY --enable-cors
```

`uv run --active --with ...` installs dependencies on demand. In offline/DNS-restricted environments, this can fail.

**Sandbox/CI note**: If `uv` hits permission errors, use a local cache path:

```bash
export UV_CACHE_DIR="$(pwd)/.uv-cache"
mkdir -p "$UV_CACHE_DIR"
```

```powershell
$env:UV_CACHE_DIR = (Join-Path (Resolve-Path .).Path ".uv-cache")
New-Item -ItemType Directory -Path $env:UV_CACHE_DIR -Force | Out-Null
```

If sandbox still blocks `~/.cache/uv`, rerun with elevated permissions.

## Index KB

```bash
# Build search index (run after adding/updating knowledge files)
uv run --active --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
```

Note: `index_typesense.py` does not support `--kb-root`; it auto-detects KB root from script location.

## Search

```bash
# Basic search
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "your query"

# Limit results
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "page numbering" --k 10

# Filter by tag
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" --filter "tags:pandoc"

# Filter by multiple tags (OR)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "page" --filter "tags:=[pandoc,docx]"

# Filter by domain
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "domain:Search"

# Filter by type (howto, reference, checklist, policy, note)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "page" --filter "type:howto"

# Filter by status (draft, approved, deprecated)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "status:approved"

# Combine filters (AND)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "domain:Search && type:howto"

# Search specific fields
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" --query-by "heading,path"
```


## Troubleshooting

```bash
# Rebuild index if search returns no results
uv run --active --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py

# Check Typesense server status
curl http://localhost:8108/health

# View Docker logs for errors
docker logs typesense --tail 50
```

Common failures:

- `Search error: [Errno 61] Connection refused`: Typesense container is not running.
- `ModuleNotFoundError: No module named 'tqdm'`: add `--with tqdm` to index command.
- `ModuleNotFoundError: No module named 'typesense'`: add `--with typesense` to search command.
- `Failed to fetch https://pypi.org/simple/...`: network/DNS unavailable for dependency download.

## Standalone Usage (If Not Using as Submodule)

If running directly in the KB repo (not as submodule), omit the `agentic_kb/` prefix:

```bash
# Index
uv run --active --with typesense --with tqdm python scripts/index_typesense.py

# Search
uv run --active --with typesense python scripts/search_typesense.py "your query"
```

## Performance

- **Search speed**: 10-50ms (5-10x faster than FAISS)
- **Index time**: 1-2 minutes for ~500 chunks
- **Returns**: Full chunk content (no need to read files for simple queries!)


## Manage Docker

```bash
# Check if Typesense is running
docker ps | grep typesense

# View logs
docker logs typesense

# Stop server
docker stop typesense

# Start server (after stop)
docker start typesense

# Restart server
docker restart typesense

# Remove container (keeps data in volume)
docker rm typesense

# Remove volume (deletes all indexed data!)
docker volume rm typesense-agentic-kb-data
```
