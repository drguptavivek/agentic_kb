# Quick FAISS Vector Search Workflow

**For submodule usage** (most common). Run from parent project root where `agentic_kb/` is the submodule directory.

**Note**: FAISS is slower (100-500ms) but better for semantic/conceptual queries. For fast keyword search, use Typesense instead.

## Setup (One-Time)

```bash
# Build vector index (takes 5-10 minutes for ~500 chunks)
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
cd ..
```

**No dependency installation required!** The `uv run --active --with` flags automatically fetch dependencies.

**Sandbox/CI note**: If `uv` hits permission errors, use a local cache path:

```bash
export UV_CACHE_DIR="$(pwd)/.uv-cache"
mkdir -p "$UV_CACHE_DIR"
```

```powershell
$env:UV_CACHE_DIR = (Join-Path (Resolve-Path .).Path ".uv-cache")
New-Item -ItemType Directory -Path $env:UV_CACHE_DIR -Force | Out-Null
```

## Index KB

```bash
# Rebuild index after adding/updating knowledge files
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
cd ..

# Use custom embedding model (optional)
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py --model sentence-transformers/all-mpnet-base-v2
cd ..
```

## Search

```bash
# Basic search
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "your query"
cd ..

# Limit results
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering concepts" --k 10
cd ..

# Filter by similarity score
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering pandoc" --min-score 0.8
cd ..

# Rebuild index and search in one go
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/search.py "authentication patterns" --rebuild
cd ..
```

## When to Use FAISS

Use FAISS for:
- **Conceptual queries**: "How do authentication workflows work?"
- **Paraphrased questions**: Finding content even with different wording
- **Related concepts**: "What's related to data privacy compliance?"
- **Semantic similarity**: When exact keywords aren't known

**Don't use for**:
- Keyword searches (use Typesense - 5-10x faster)
- Exact pattern matching (use ripgrep)
- Filtering by metadata (use Typesense faceted search)

## Performance

- **Index time**: 5-10 minutes for ~500 chunks (vs Typesense 1-2 min)
- **Search time**: 100-500ms (vs Typesense 10-50ms)
- **Memory**: High (embeddings in memory)
- **Offline**: Yes (no external APIs)

## Index Location

- Stored in: `agentic_kb/.kb_index/`
- Automatically ignored by git
- Can be deleted and rebuilt anytime

## Troubleshooting

```bash
# Check if index exists
ls agentic_kb/.kb_index/

# Rebuild if corrupted
cd agentic_kb
rm -rf .kb_index
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py
cd ..

# Test with simple query
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "test" --k 1
cd ..
```

## Comparison with Typesense

| Feature | FAISS | Typesense |
|---------|-------|-----------|
| Speed | 100-500ms | 10-50ms (10x faster) |
| Index time | 5-10 min | 1-2 min (5x faster) |
| Semantic search | ✅ Yes | ❌ No |
| Typo tolerance | ❌ No | ✅ Yes |
| Faceted filtering | ❌ No | ✅ Yes (domain, type, status, tags) |
| Returns full chunks | ❌ No (just paths) | ✅ Yes |
| Best for | Conceptual queries | Keyword searches |

## Recommended Workflow

1. **Start with Typesense** (faster):
   ```bash
   uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "page numbering"
   ```

2. **Use FAISS if needed** (semantic):
   ```bash
   cd agentic_kb
   uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "document formatting concepts" --min-score 0.8
   cd ..
   ```

3. **Verify with ripgrep** (exact):
   ```bash
   rg "page.*number" agentic_kb/knowledge/
   ```

## Standalone Usage (If Not Using as Submodule)

If running directly in the KB repo (not as submodule), omit directory changes:

```bash
# Index
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py

# Search
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "your query"
```
