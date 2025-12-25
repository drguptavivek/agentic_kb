---
title: Typesense Integration for KB Search
type: howto
domain: Document Automation
tags:
  - typesense
  - search
  - full-text
  - indexing
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Typesense Integration for KB Search

This guide shows how to integrate Typesense for typo-tolerant, full-text search in your knowledge base. Typesense complements the existing FAISS vector search by providing keyword-based search with fuzzy matching.

## Prerequisites

Install and run Typesense server using Docker Compose (recommended):

Create `docker-compose.yml`:

```yaml
services:
  typesense:
    image: typesense/typesense:29.0
    restart: on-failure
    ports:
      - "8108:8108"
    volumes:
      - typesense-agentic-kb-data:/data
    command: '--data-dir /data --api-key=xyz --enable-cors'

volumes:
  typesense-agentic-kb-data:
```

Start the server:

```bash
docker-compose up -d
```

Alternatively, use Docker directly with a named volume:

```bash
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d \
  --name typesense \
  -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 \
  --data-dir /data \
  --api-key=$TYPESENSE_API_KEY \
  --enable-cors
```

## Configuration

Set environment variables (optional):

```bash
export TYPESENSE_HOST=localhost
export TYPESENSE_PORT=8108
export TYPESENSE_API_KEY=xyz
```

If not set, the scripts use the defaults above.

## Indexing the KB

Build the Typesense index (no dependency installation required):

```bash
# Direct repo usage
uv run --with typesense --with tqdm python scripts/index_typesense.py

# Submodule usage (run from parent project root)
uv run --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
```

### Index Options

```bash
# Custom host/port (direct repo)
uv run --with typesense --with tqdm python scripts/index_typesense.py --host localhost --port 8108

# Custom API key (submodule)
uv run --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py --api-key your-secret-key

# Custom collection name
uv run --with typesense --with tqdm python scripts/index_typesense.py --collection my_kb

# Custom batch size for large KBs
uv run --with typesense --with tqdm python scripts/index_typesense.py --batch-size 200
```

## Searching

Search the indexed KB:

```bash
# Direct repo usage
uv run --with typesense python scripts/search_typesense.py "your query"

# Submodule usage (run from parent project root)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "your query"
```

### Search Examples

```bash
# Basic search (submodule)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering pandoc"

# Limit results
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering pandoc" --k 10

# Filter by tags
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" --filter "tags:=[pandoc, docx]"

# Search specific fields
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" --query-by "heading,path"

# Custom collection (direct repo)
uv run --with typesense python scripts/search_typesense.py "query" --collection my_kb
```

## How It Works

### Indexing Process

1. **File Processing**: Scans `knowledge/` directory for `.md` files
2. **Frontmatter Extraction**: Parses YAML frontmatter for tags and metadata
3. **Chunking**: Splits documents by headings (same as FAISS approach)
4. **Schema Creation**: Creates Typesense collection with fields:
   - `path`: File path (faceted)
   - `heading`: Section heading
   - `text`: Chunk content
   - `tags`: Array of tags from frontmatter (faceted)
   - `created`: Creation date from frontmatter
5. **Batch Import**: Imports chunks in configurable batches

### Search Features

- **Typo Tolerance**: Handles misspellings automatically
- **Faceted Search**: Filter by tags, paths
- **Field Weighting**: Search specific fields
- **Relevance Ranking**: Text match scoring

## Schema Design

The Typesense collection uses this schema:

```json
{
  "name": "kb_chunks",
  "fields": [
    {"name": "path", "type": "string", "facet": true},
    {"name": "heading", "type": "string", "facet": false},
    {"name": "text", "type": "string", "facet": false},
    {"name": "tags", "type": "string[]", "facet": true, "optional": true},
    {"name": "created", "type": "string", "facet": false, "optional": true}
  ]
}
```

## Comparison with FAISS

See [[search-backends]] for a detailed comparison of Typesense vs FAISS vs hybrid approaches.

## Troubleshooting

### Connection Refused

If you get connection errors:

```bash
# Check if Typesense is running
docker ps | grep typesense

# Check logs
docker logs <container-id>

# Restart if needed
docker restart <container-id>
```

### Index Not Found

Rebuild the index:

```bash
# Direct repo
uv run --with typesense --with tqdm python scripts/index_typesense.py

# Submodule
uv run --with typesense --with tqdm python agentic_kb/scripts/index_typesense.py
```

### No Results

1. Check collection name matches between index and search
2. Verify documents were indexed: check Typesense admin UI at `http://localhost:8108`
3. Try broader queries or adjust filters

## Production Deployment

For production use, create `docker-compose.yml` with secure settings:

```yaml
services:
  typesense:
    image: typesense/typesense:29.0
    restart: unless-stopped
    ports:
      - "8108:8108"
    volumes:
      - typesense-agentic-kb-data:/data
    environment:
      - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
    command: '--data-dir /data --api-key=${TYPESENSE_API_KEY} --enable-cors'

volumes:
  typesense-agentic-kb-data:
    driver: local
```

Create `.env` file (add to `.gitignore`):

```bash
TYPESENSE_API_KEY=$(openssl rand -hex 32)
```

Deploy:

```bash
docker-compose up -d
```

### Production Checklist

- [ ] Use strong API key (not `xyz`)
- [ ] Store API key in `.env` file (add to `.gitignore`)
- [ ] Use HTTPS with SSL certificates for external access
- [ ] Configure volume backups: `docker run --rm -v typesense-agentic-kb-data:/data -v $(pwd):/backup alpine tar czf /backup/typesense-backup.tar.gz /data`
- [ ] Set `restart: unless-stopped` for automatic recovery
- [ ] Monitor container health: `docker ps` and `docker logs typesense`
- [ ] Consider Typesense Cloud for managed hosting

## Related

- [[search-backends]] - Comparison of search backends
- [[typesense-v30-deprecation-warnings]] - Fix for v30+ deprecation warnings
- [[typesense-yaml-frontmatter-parsing]] - Fix for YAML frontmatter parsing
- [[learning-capture-steps]] - Knowledge capture workflow
