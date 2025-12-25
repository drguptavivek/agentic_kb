# Quick Typesense Workflow

**For submodule usage** (most common). Run from parent project root where `agentic_kb/` is the submodule directory.

## Setup (One-Time)

```bash
# Install dependency in parent project
uv add typesense

# Create Docker volume
docker volume create typesense-agentic-kb-data

# Start Typesense server
export TYPESENSE_API_KEY=xyz
docker run -d --name typesense -p 8108:8108 -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data --api-key=$TYPESENSE_API_KEY --enable-cors
```

## Index KB

```bash
# Build search index (run after adding/updating knowledge files)
uv run python agentic_kb/scripts/index_typesense.py
```

## Search

```bash
# Basic search
uv run python agentic_kb/scripts/search_typesense.py "your query"

# Limit results
uv run python agentic_kb/scripts/search_typesense.py "page numbering" --k 10

# Filter by single tag
uv run python agentic_kb/scripts/search_typesense.py "pandoc" --filter "tags:pandoc"

# Filter by multiple tags (OR condition)
uv run python agentic_kb/scripts/search_typesense.py "page" --filter "tags:=[pandoc,docx]"

# Search specific fields only
uv run python agentic_kb/scripts/search_typesense.py "pandoc" --query-by "heading,path"

# Combine filters
uv run python agentic_kb/scripts/search_typesense.py "page" --filter "tags:pandoc && path:*Document*"
```

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

## Troubleshooting

```bash
# Rebuild index if search returns no results
uv run python agentic_kb/scripts/index_typesense.py

# Check Typesense server status
curl http://localhost:8108/health

# View Docker logs for errors
docker logs typesense --tail 50
```

## Standalone Usage (If Not Using as Submodule)

If running directly in the KB repo (not as submodule), omit the `agentic_kb/` prefix:

```bash
# Index
uv run python scripts/index_typesense.py

# Search
uv run python scripts/search_typesense.py "your query"
```

## Performance

- **Search speed**: 10-50ms (5-10x faster than FAISS)
- **Index time**: 1-2 minutes for ~500 chunks
- **Returns**: Full chunk content (no need to read files for simple queries!)
