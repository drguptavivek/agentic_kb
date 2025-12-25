# KB Search Patterns and Examples

This document provides common search patterns and examples for effectively querying the knowledge base.

## Table of Contents

- [Basic Search Patterns](#basic-search-patterns)
- [Faceted Search with Filters](#faceted-search-with-filters)
- [Advanced Filter Combinations](#advanced-filter-combinations)
- [When to Use Each Search Method](#when-to-use-each-search-method)
- [Common Search Scenarios](#common-search-scenarios)

## Basic Search Patterns

### Typesense (Recommended First Choice)

Fast full-text search with typo tolerance. Returns full chunk content.

```bash
# Basic query
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering"

# Multi-word phrase
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc template workflow"

# Technical terms
uv run --with typesense python agentic_kb/scripts/search_typesense.py "FAISS vector search"
```

### FAISS Vector Search

Semantic search using embeddings. Better for conceptual queries.

```bash
# From parent project root
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "how to handle authentication"
cd ..

# With similarity threshold
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "document processing workflows" --min-score 0.8
cd ..
```

### ripgrep (rg) for Exact Matches

Use for finding exact strings or patterns.

```bash
# In direct repo
rg "pandoc" knowledge/

# In submodule
rg "page number" agentic_kb/knowledge/

# Case-insensitive
rg -i "authentication" agentic_kb/knowledge/

# Show context lines
rg -C 3 "FAISS" agentic_kb/knowledge/
```

## Faceted Search with Filters

### Filter by Domain

```bash
# Document Automation domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" \
  --filter "domain:Document Automation"

# Search domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "retrieval" \
  --filter "domain:Search"

# Security domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "auth" \
  --filter "domain:Security"
```

### Filter by Type

```bash
# Find how-to guides
uv run --with typesense python agentic_kb/scripts/search_typesense.py "workflow" \
  --filter "type:howto"

# Find reference docs
uv run --with typesense python agentic_kb/scripts/search_typesense.py "API" \
  --filter "type:reference"

# Find checklists
uv run --with typesense python agentic_kb/scripts/search_typesense.py "deployment" \
  --filter "type:checklist"

# Find policies
uv run --with typesense python agentic_kb/scripts/search_typesense.py "security" \
  --filter "type:policy"
```

### Filter by Status

```bash
# Approved content only
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" \
  --filter "status:approved"

# Draft content
uv run --with typesense python agentic_kb/scripts/search_typesense.py "template" \
  --filter "status:draft"

# Exclude deprecated
uv run --with typesense python agentic_kb/scripts/search_typesense.py "workflow" \
  --filter "status:!=deprecated"
```

### Filter by Tags

```bash
# Single tag
uv run --with typesense python agentic_kb/scripts/search_typesense.py "guide" \
  --filter "tags:pandoc"

# Multiple tags (match any)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "automation" \
  --filter "tags:[pandoc,latex]"
```

## Advanced Filter Combinations

Combine multiple filters using `&&` (AND) or `||` (OR).

### AND Combinations

```bash
# Approved how-to guides in Document Automation
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" \
  --filter "domain:Document Automation && type:howto && status:approved"

# Search domain reference docs
uv run --with typesense python agentic_kb/scripts/search_typesense.py "FAISS" \
  --filter "domain:Search && type:reference"

# Approved security policies
uv run --with typesense python agentic_kb/scripts/search_typesense.py "authentication" \
  --filter "domain:Security && type:policy && status:approved"
```

### OR Combinations

```bash
# Either how-to or checklist
uv run --with typesense python agentic_kb/scripts/search_typesense.py "deployment" \
  --filter "type:howto || type:checklist"

# Multiple domains
uv run --with typesense python agentic_kb/scripts/search_typesense.py "API" \
  --filter "domain:Search || domain:Security"
```

### Complex Combinations

```bash
# Approved (how-to OR reference) in Document Automation
uv run --with typesense python agentic_kb/scripts/search_typesense.py "template" \
  --filter "domain:Document Automation && (type:howto || type:reference) && status:approved"
```

## When to Use Each Search Method

### Use Typesense When:

- Looking for specific terms or keywords
- Need fast results (10-50ms)
- Want to filter by metadata (domain, type, status, tags)
- The query matches document terminology
- Want full chunk content without reading files

**Examples:**
- "Find pandoc page numbering examples"
- "Show me approved workflows for document automation"
- "What security policies exist?"

### Use FAISS When:

- Searching for concepts rather than exact terms
- Typesense returns no/poor results
- Query is phrased naturally or conversationally
- Looking for semantically similar content

**Examples:**
- "How do I authenticate users securely?"
- "Best practices for document generation"
- "Conceptual overview of search systems"

### Use ripgrep When:

- Need exact string matching
- Looking for code snippets or specific syntax
- Want to see immediate file context
- Searching for patterns or regex

**Examples:**
- Find exact function name or variable
- Locate specific configuration values
- Search for file paths or URLs

## Common Search Scenarios

### Scenario 1: Learning a New Topic

```bash
# Step 1: Broad Typesense search with domain filter
uv run --with typesense python agentic_kb/scripts/search_typesense.py "document automation" \
  --filter "domain:Document Automation && status:approved"

# Step 2: Refine to how-to guides
uv run --with typesense python agentic_kb/scripts/search_typesense.py "document automation" \
  --filter "domain:Document Automation && type:howto && status:approved"

# Step 3: Read the returned files for full context
```

### Scenario 2: Solving a Specific Problem

```bash
# Step 1: Try Typesense with specific keywords
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc page numbers"

# Step 2: If no results, try FAISS with natural query
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "how to add page numbers in pandoc"
cd ..

# Step 3: Use rg to find exact references in promising files
rg "page.*number" agentic_kb/knowledge/Document\ Automation/
```

### Scenario 3: Finding Policies or Standards

```bash
# Search for approved policies
uv run --with typesense python agentic_kb/scripts/search_typesense.py "security" \
  --filter "type:policy && status:approved"

# Search for checklists
uv run --with typesense python agentic_kb/scripts/search_typesense.py "deployment" \
  --filter "type:checklist && status:approved"
```

### Scenario 4: Exploring a Domain

```bash
# Get overview of all approved content in domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "*" \
  --filter "domain:Security && status:approved"

# Find all how-to guides in domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "*" \
  --filter "domain:Document Automation && type:howto"
```

## Performance Comparison

| Method | Speed | Best For | Returns |
|--------|-------|----------|---------|
| Typesense | 10-50ms | Exact terms, keywords | Full chunk content |
| FAISS | 100-500ms | Concepts, semantic search | File paths + scores |
| ripgrep | <10ms | Exact strings, patterns | Matching lines |

## Tips for Effective Searching

1. **Start with Typesense** - Fastest and often sufficient
2. **Use filters liberally** - Narrow results by domain, type, status
3. **Fall back to FAISS** - If Typesense finds nothing relevant
4. **Always read full files** - Don't rely on search snippets alone
5. **Cite sources properly** - Use format: `<file path> -> <heading>`
6. **Check file status** - Prefer `approved` over `draft` content
