# KB Search Patterns and Examples

This document provides common search patterns and examples for effectively querying the knowledge base.

## Table of Contents

- [Smart Search (Recommended)](#smart-search-recommended)
- [Basic Search Patterns](#basic-search-patterns)
- [Faceted Search with Filters](#faceted-search-with-filters)
- [Advanced Filter Combinations](#advanced-filter-combinations)
- [When to Use Each Search Method](#when-to-use-each-search-method)
- [Common Search Scenarios](#common-search-scenarios)
- [Performance Comparison](#performance-comparison)
- [Tips for Effective Searching](#tips-for-effective-searching)

## Smart Search (Recommended)

The smart search script automatically tries Typesense first, then falls back to FAISS if Typesense is unavailable or returns poor results.

```bash
# Basic search
agentic_kb/scripts/smart_search.sh "your query"

# With domain filter
agentic_kb/scripts/smart_search.sh "pandoc" --filter "domain:Document Automation"

# With type filter
agentic_kb/scripts/smart_search.sh "workflow" --filter "type:howto"

# Combined filters
agentic_kb/scripts/smart_search.sh "search" --filter "domain:Search && type:howto"

# Higher similarity threshold for FAISS fallback
agentic_kb/scripts/smart_search.sh "git workflow" --min-score 0.8

# If auto-detection fails, pass the KB path explicitly
agentic_kb/scripts/smart_search.sh "your query" --kb-path agentic_kb

# Direct repo usage
scripts/smart_search.sh "your query"
```

**Benefits:**
- Automatic fallback (Typesense → FAISS)
- Single command for both methods
- Consistent interface
- Best performance when Typesense is available

## Basic Search Patterns

### Typesense (Recommended First Choice)

Fast full-text search with typo tolerance. Returns full chunk content.

```bash
# Basic query
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "page numbering"

# Multi-word phrase
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "pandoc template workflow"

# Technical terms
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "FAISS vector search"
```

### FAISS Vector Search

Semantic search using embeddings. Better for conceptual queries.

```bash
# From parent project root
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "how to handle authentication"
cd ..

# With similarity threshold
cd agentic_kb
uv run --active --with faiss-cpu --with numpy --with sentence-transformers \
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
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" \
  --filter "domain:Document Automation"

# Search domain
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "retrieval" \
  --filter "domain:Search"

# Security domain
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "auth" \
  --filter "domain:Security"
```

### Filter by Type

```bash
# Find how-to guides
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "workflow" \
  --filter "type:howto"

# Find reference docs
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "API" \
  --filter "type:reference"

# Find checklists
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "deployment" \
  --filter "type:checklist"

# Find policies
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "security" \
  --filter "type:policy"
```

### Filter by Status

```bash
# Approved content only
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "search" \
  --filter "status:approved"

# Draft content
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "template" \
  --filter "status:draft"

# Exclude deprecated
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "workflow" \
  --filter "status:!=deprecated"
```

### Filter by Tags

```bash
# Single tag
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "guide" \
  --filter "tags:pandoc"

# Multiple tags (match any)
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "automation" \
  --filter "tags:[pandoc,latex]"
```

## Advanced Filter Combinations

Combine multiple filters using `&&` (AND) or `||` (OR).

### AND Combinations

```bash
# Approved how-to guides in Document Automation
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" \
  --filter "domain:Document Automation && type:howto && status:approved"

# Search domain reference docs
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "FAISS" \
  --filter "domain:Search && type:reference"

# Approved security policies
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "authentication" \
  --filter "domain:Security && type:policy && status:approved"
```

### OR Combinations

```bash
# Either how-to or checklist
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "deployment" \
  --filter "type:howto || type:checklist"

# Multiple domains
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "API" \
  --filter "domain:Search || domain:Security"
```

### Complex Combinations

```bash
# Approved (how-to OR reference) in Document Automation
uv run --active --with typesense python agentic_kb/scripts/search_typesense.py "template" \
  --filter "domain:Document Automation && (type:howto || type:reference) && status:approved"
```

## When to Use Each Search Method

### Use Smart Search When:

- **Starting any search task** - It automatically chooses the best method
- **Unsure which method to use** - Combines Typesense speed with FAISS semantic fallback
- **Want consistent behavior** - Single interface for both search backends

**Examples:**
- "Find anything about pandoc workflows"
- "Search for deployment guides"
- "Look up authentication patterns"

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
# Step 1: Broad smart search
agentic_kb/scripts/smart_search.sh "document automation"

# Step 2: Filter by domain and status
agentic_kb/scripts/smart_search.sh "document automation" \
  --filter "domain:Document Automation && status:approved"

# Step 3: Refine to how-to guides
agentic_kb/scripts/smart_search.sh "document automation" \
  --filter "domain:Document Automation && type:howto && status:approved"

# Step 4: Read the returned files for full context
```

### Scenario 2: Solving a Specific Problem

```bash
# Step 1: Try smart search with specific keywords
agentic_kb/scripts/smart_search.sh "pandoc page numbers"

# Step 2: If results aren't specific enough, add filters
agentic_kb/scripts/smart_search.sh "page numbers" \
  --filter "domain:Document Automation && type:howto"

# Step 3: Use rg to find exact references in promising files
rg "page.*number" agentic_kb/knowledge/Document\ Automation/

# Step 4: Read full files for complete context
```

### Scenario 3: Finding Policies or Standards

```bash
# Search for approved policies
agentic_kb/scripts/smart_search.sh "security" \
  --filter "type:policy && status:approved"

# Search for checklists
agentic_kb/scripts/smart_search.sh "deployment" \
  --filter "type:checklist && status:approved"

# Find all reference documentation
agentic_kb/scripts/smart_search.sh "*" \
  --filter "type:reference && status:approved"
```

### Scenario 4: Exploring a Domain

```bash
# Get overview of all approved content in domain
agentic_kb/scripts/smart_search.sh "*" \
  --filter "domain:Security && status:approved"

# Find all how-to guides in domain
agentic_kb/scripts/smart_search.sh "*" \
  --filter "domain:Document Automation && type:howto"

# Find all checklists across all domains
agentic_kb/scripts/smart_search.sh "*" \
  --filter "type:checklist && status:approved"
```

## Performance Comparison

| Method | Speed | Best For | Returns | Fallback |
|--------|-------|----------|---------|----------|
| Smart Search | 10-50ms* | All queries | Full chunks or file paths | Auto (Typesense→FAISS) |
| Typesense | 10-50ms | Exact terms, keywords | Full chunk content | None |
| FAISS | 100-500ms | Concepts, semantic | File paths + scores | None |
| ripgrep | <10ms | Exact strings, patterns | Matching lines | None |

*Smart search speed depends on which backend it uses

## Tips for Effective Searching

1. **Start with Smart Search** - Handles fallback automatically, best overall choice
2. **Use filters liberally** - Narrow results by domain, type, status
3. **Fall back to FAISS** - If Typesense finds nothing relevant
4. **Always read full files** - Don't rely on search snippets alone
5. **Cite sources properly** - Use format: `<file path> -> <heading>`
6. **Check file status** - Prefer `approved` over `draft` content
