---
title: KB Search Backends Comparison
type: reference
domain: Search
tags:
  - search
  - faiss
  - typesense
  - vector-search
  - full-text
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# KB Search Backends Comparison

This knowledge base supports multiple search backends, each optimized for different use cases. This document compares the available options and provides guidance on when to use each.

## Quick Decision Guide

**Need speed?** → Use **Typesense** (5-10x faster than FAISS)

**Need semantic understanding?** → Use **FAISS** (finds conceptually similar content)

**Need exact patterns/regex?** → Use **ripgrep** (no indexing required)

**Building a search UI?** → Use **Typesense** (fast, typo-tolerant, faceted)

**Agent retrieval?** → Use **FAISS** first, **ripgrep** for verification

## Available Backends

### FAISS (Vector Search)

**Location**: `scripts/search.py`, `scripts/index_kb.py`

**Type**: Semantic vector search using sentence embeddings

**Strengths**:
- Finds semantically similar content even with different wording
- Excellent for conceptual queries
- Works well with synonyms and paraphrases
- Fully offline, no external services required

**Limitations**:
- Slower indexing (requires computing embeddings)
- Higher memory usage
- Less effective for exact keyword matching
- Typos reduce accuracy

**Best For**:
- Conceptual questions ("how to format documents")
- Finding related content across different topics
- Queries where exact wording may vary

### Typesense (Full-Text Search)

**Location**: `scripts/search_typesense.py`, `scripts/index_typesense.py`

**Type**: Typo-tolerant full-text search with filtering

**Strengths**:
- Fast indexing and search
- Built-in typo tolerance
- Faceted search (filter by tags, paths)
- Field-specific searching
- Lower resource usage

**Limitations**:
- Requires running Typesense server
- Less effective for conceptual/semantic queries
- Exact keyword matching focus

**Best For**:
- Keyword-based searches ("pandoc", "page numbering")
- Filtering by tags or paths
- Queries with known terminology
- Fast, responsive search interfaces

### ripgrep (Text Search)

**Location**: Command-line `rg`

**Type**: Pattern-based text search with regex

**Strengths**:
- Extremely fast
- No indexing required
- Regex support
- Zero dependencies
- Works on any text corpus

**Limitations**:
- No ranking/relevance scoring
- No typo tolerance
- Requires exact pattern matching
- No semantic understanding

**Best For**:
- Finding specific code snippets or commands
- Regex-based pattern matching
- Quick ad-hoc searches during development
- Searching for exact strings

## Comparison Table

| Feature | FAISS | Typesense | ripgrep |
|---------|-------|-----------|---------|
| **Search Type** | Semantic | Full-text | Pattern |
| **Typo Tolerance** | None | Yes | None |
| **Semantic Understanding** | Yes | No | No |
| **Indexing Speed** | Slow | Fast | N/A |
| **Search Speed** | Medium | Fast | Very Fast |
| **Memory Usage** | High | Medium | Low |
| **Dependencies** | Python libs | Docker/Server | None |
| **Offline** | Yes | Yes (self-hosted) | Yes |
| **Faceting** | No | Yes | No |
| **Ranking** | Similarity score | Relevance score | None |
| **Regex Support** | No | Limited | Full |

## Use Case Decision Matrix

### When to Use FAISS

- "How do I add page numbers to documents?"
- "Find information about authentication workflows"
- "What's related to data privacy compliance?"
- Agent-driven semantic retrieval

### When to Use Typesense

- "pandoc docx page numbering"
- "git workflows" (with typos like "git workflws")
- Filter by tags: `tags:=[security, compliance]`
- Building search UIs for end users

### When to Use ripgrep

- Find all files mentioning "ISO 27001"
- Search for specific commands: `pandoc --reference-doc`
- Pattern matching: `rg "page \d+" knowledge/`
- Quick verification during development

## Hybrid Approach

For comprehensive search, combine multiple backends:

```bash
# 1. Semantic search for concepts (direct repo)
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "document formatting" --min-score 0.7
cd ..

# 2. Keyword search for specifics (submodule)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "pandoc docx"

# 3. Exact pattern matching
rg "pandoc.*--reference-doc" agentic_kb/knowledge/
```

### Building a Hybrid Search Tool

Create `scripts/hybrid_search.py` to combine results:

```python
def hybrid_search(query: str):
    faiss_results = faiss_search(query, k=5)      # Semantic
    ts_results = typesense_search(query, k=5)     # Keywords
    return merge_and_rank(faiss_results, ts_results)
```

**Ranking Strategy**:
1. Deduplicate by path + heading
2. Boost documents found by both backends
3. Sort by combined score
4. Return top N unique results

## Performance Characteristics

> **Performance Note**
> Typesense is **5-10x faster** than FAISS for search queries. For interactive/real-time search, prefer Typesense. For semantic/conceptual queries, the extra latency of FAISS may be worth the improved relevance.

### Indexing Time (1000 documents)

| Backend | Initial Index | Incremental Update |
|---------|---------------|-------------------|
| FAISS | 5-10 minutes | 30-60 seconds |
| Typesense | 1-2 minutes | 5-10 seconds |
| ripgrep | N/A | N/A |

**Winner**: Typesense (5x faster indexing)

### Search Time (typical query)

| Backend | Latency | User Experience |
|---------|---------|-----------------|
| FAISS | 100-500ms | Noticeable delay |
| Typesense | 10-50ms | Near-instant |
| ripgrep | 50-200ms | Fast |

**Winner**: Typesense (5-10x faster search)

## Configuration Examples

### FAISS Configuration

```bash
# High quality embeddings (slower) - direct repo
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py --model sentence-transformers/all-mpnet-base-v2
cd ..

# Fast embeddings (faster) - direct repo
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers --with tqdm python scripts/index_kb.py --model sentence-transformers/all-MiniLM-L6-v2
cd ..
```

### Typesense Configuration

```bash
# Development
docker run -p 8108:8108 typesense/typesense:latest --api-key=xyz

# Production with persistence
docker run -p 8108:8108 -v $(pwd)/data:/data typesense/typesense:latest \
  --data-dir /data --api-key=$(cat .typesense-key)
```

### ripgrep Configuration

```bash
# Search only markdown files
rg "query" knowledge/ --type md

# Case-insensitive
rg -i "query" knowledge/

# Show context
rg "query" knowledge/ -A 3 -B 3
```

## Recommendations

### For Agent Workflows

Use Typesense as primary (faster), FAISS for semantic queries, ripgrep for verification:

```bash
# Agent search pattern (submodule)
# 1. Try Typesense first (10-50ms)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "page numbering" --k 5

# 2. Use FAISS for conceptual queries (100-500ms)
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering" --min-score 0.8
cd ..

# 3. Verify with ripgrep
rg "page.*number" agentic_kb/knowledge/
```

### For User-Facing Search

Use Typesense for interactive search:
- Fast response times
- Typo tolerance improves UX
- Faceted filtering for refinement

### For Development

Use ripgrep during active development:
- No index building needed
- Instant results
- Regex power for edge cases

## Future Enhancements

Potential improvements to consider:

1. **Hybrid Search Script**: Unified interface combining all backends
2. **Web UI**: Browser-based search using Typesense API
3. **Search Analytics**: Track common queries, improve indexing
4. **Query Expansion**: Automatic synonym expansion
5. **Result Caching**: Cache frequent queries
6. **Multilingual Support**: Add language-specific models

## Related

- [[typesense-integration]] - Typesense setup guide
- [[learning-capture-steps]] - Knowledge capture workflow

## References

- [FAISS Documentation](https://github.com/facebookresearch/faiss)
- [Typesense Documentation](https://typesense.org/docs/)
- [ripgrep User Guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
