---
name: kb-search
description: Search and retrieve knowledge from agentic_kb knowledge base. Use when the user requests to search the KB, asks "How do I..." questions that should consult the KB, wants to document new knowledge, or at session start to update the KB submodule. Supports Typesense (fast full-text search), FAISS (semantic vector search), and ripgrep (exact pattern matching).
---

# KB Search

## Overview

This skill enables searching and retrieving knowledge from the agentic_kb knowledge base, a structured repository of domain-specific knowledge organized into domains (Document Automation, Search, Security, Android, ODK Central).

The skill supports three search methods, in this order:
1. **Typesense** - Fast full-text search with typo tolerance (10-50ms, default when available)
2. **FAISS** - Semantic vector search for conceptual queries (100-500ms, fallback if Typesense is not running)
3. **ripgrep** - Exact pattern matching for strings and code (< 10ms, fallback for simple exact queries)

## First-Time Setup

If the user doesn't have agentic_kb set up yet, guide them through the initial setup:

### Option 1: Fork and Use Your Own KB (Recommended)

For users who want to customize and extend the KB with their own knowledge:

```bash
# Run the setup script
scripts/setup_kb.sh
```

The script will:
1. Check if KB already exists
2. Prompt user to fork the repository on GitHub
3. Add it as a submodule pointing to their fork
4. Set up the original repository as an upstream remote
5. Guide user through initial configuration

**Manual setup alternative:**

```bash
# 1. User forks https://github.com/drguptavivek/agentic_kb on GitHub to their account

# 2. Add the fork as a submodule to their project
git submodule add https://github.com/USERNAME/agentic_kb.git agentic_kb

# 3. Add upstream remote to pull updates from original
cd agentic_kb
git remote add upstream https://github.com/drguptavivek/agentic_kb.git
cd ..

# 4. Commit the submodule addition
git add .gitmodules agentic_kb
git commit -m "Add: agentic_kb submodule (personal fork)"
git push
```

**Syncing with upstream updates:**

```bash
cd agentic_kb
git fetch upstream
git merge upstream/main
git push origin main
cd ..
git add agentic_kb
git commit -m "Update: agentic_kb synced with upstream"
git push
```

### Option 2: Read-Only Access

For users who only want to search/read the KB without contributing:

```bash
# Add as submodule (read-only, will fail on push)
git submodule add https://github.com/drguptavivek/agentic_kb.git agentic_kb
git add .gitmodules agentic_kb
git commit -m "Add: agentic_kb submodule (read-only)"
```

**Note:** This won't allow pushing updates. If user wants to add knowledge later, they'll need to fork (Option 1).

### Option 3: Clone from Source, Then Fork Later

Use this when the user wants to get started quickly without forking yet, and migrate later.

```bash
# Clone directly from upstream
git clone https://github.com/drguptavivek/agentic_kb.git
```

Later, the user can fork on GitHub and repoint the remote:

```bash
# Inside the cloned repo
git remote set-url origin https://github.com/USERNAME/agentic_kb.git
git push -u origin main
```

## Search Preference (Ask First)

Before running searches, ask the user which search backend they prefer:
1. **Typesense (Docker)** - Fastest, typo-tolerant
2. **FAISS** - Semantic search, slower but good for conceptual queries
3. **File search only (ripgrep)** - Exact matches, no index required

If they choose Typesense, offer to set it up and index the KB. If they choose FAISS, offer to build the index. If they choose file search, use `rg` only.

### Option 3: Direct Repository Clone

For using KB as a standalone repository (not as submodule):

```bash
git clone https://github.com/drguptavivek/agentic_kb.git
cd agentic_kb
# Use search commands directly in this directory
```

## Quick Start

### Session Initialization

**CRITICAL**: At the start of each session, update the KB submodule to ensure access to latest knowledge:

```bash
scripts/update_kb.sh [submodule_path]
```

The script will:
- Update submodule to latest from remote
- Stage and commit the pointer update
- Report if KB is already up to date

### Basic Search Workflow

1. **Search first** - Use Typesense for fast results
2. **Read full files** - Always read complete files, never rely on snippets alone
3. **Cite sources** - Use format: `<file path> -> <heading>`
4. **If not found** - Say "Not found in KB" and suggest where to add it

### Smart Search (Recommended)

Use the smart search script that tries Typesense first, falls back to FAISS:

```bash
scripts/smart_search.sh "your query" [--filter "filter_expr"] [--min-score 0.8]
```

Examples:
```bash
# Basic search
scripts/smart_search.sh "page numbering pandoc"

# With domain filter
scripts/smart_search.sh "search" --filter "domain:Search && type:howto"

# Higher similarity threshold for FAISS fallback
scripts/smart_search.sh "git workflow" --min-score 0.8
```

## Search Methods

### Method 1: Typesense (Fast Full-Text Search)

**When to use:**
- First choice for most queries
- Looking for specific terms or keywords
- Need fast results with faceted filtering
- Want full chunk content without reading files

**Basic search:**
```bash
uv run --with typesense python agentic_kb/scripts/search_typesense.py "query"
```

**With filters:**
```bash
# Filter by domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" \
  --filter "domain:Document Automation"

# Filter by type (howto, reference, checklist, policy, note)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "workflow" \
  --filter "type:howto"

# Filter by status (approved, draft, deprecated)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "guide" \
  --filter "status:approved"

# Combine filters
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" \
  --filter "domain:Search && type:howto && status:approved"
```

**Available facets:**
- `domain`: Document Automation, Search, Security, Android, ODK Central
- `type`: howto, reference, checklist, policy, note
- `status`: approved, draft, deprecated
- `tags`: Various topic tags

**Performance:** 10-50ms, returns full chunk content

For complete filter examples and patterns, see [references/search-patterns.md](references/search-patterns.md).

### Method 2: FAISS (Semantic Vector Search)

**When to use:**
- Typesense returns no/poor results
- Searching for concepts rather than exact terms
- Query is phrased naturally or conversationally
- Looking for semantically similar content

**Search from parent project root:**
```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "your query"
cd ..
```

**With similarity threshold:**
```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "page numbering in pandoc" --min-score 0.8
cd ..
```

**Performance:** 100-500ms, better for conceptual queries

### Method 3: ripgrep (Exact Pattern Matching)

**When to use:**
- Need exact string matching
- Looking for code snippets or specific syntax
- Want to see immediate file context
- Searching for patterns or regex

**Basic usage:**
```bash
# Direct repo
rg "pattern" knowledge/

# Submodule
rg "pattern" agentic_kb/knowledge/

# Case-insensitive
rg -i "authentication" agentic_kb/knowledge/

# With context lines
rg -C 3 "FAISS" agentic_kb/knowledge/
```

## Required Retrieval Workflow

Follow this workflow strictly for every KB query:

1. **Search the KB** using appropriate method (prefer Typesense → FAISS fallback)
2. **Read full files** - Use Read tool on the most relevant file(s)
3. **Answer using KB content** - Prefer exact steps or checklists from the KB
4. **Cite sources** - Format: `<file path> -> <heading>`
5. **If not found** - State "Not found in KB" and suggest where to add it

**CRITICAL:** Never answer from search snippets alone. Always read the complete files.

For detailed workflow, see `agentic_kb/knowledge/Search/agent-retrieval-workflow.md`.

## Knowledge Domains

The KB is organized into these domains:

- **Android** - Mobile development and Android-specific knowledge
- **Document Automation** - Pandoc, PDF, LaTeX, document processing workflows
- **ODK Central** - ODK Central server admin and data collection
- **Search** - Information retrieval, search systems, agent workflows
- **Security** - Security practices, authentication, secure coding

For detailed domain descriptions, see [references/kb-domains.md](references/kb-domains.md).

## Knowledge Capture

When you learn new, reusable knowledge during tasks:

1. Ask user for confirmation before making KB edits
2. Follow the learning capture workflow in `knowledge/Document Automation/learning-capture-steps.md`
3. Follow conventions in `KNOWLEDGE_CONVENTIONS.md`

**Requirements for new notes:**
- YAML frontmatter with tags and created date
- Explicit headings matching likely queries
- A `Related` section with `[[wikilinks]]`

## Common Search Scenarios

### Learning a New Topic

```bash
# Step 1: Broad search with domain filter
uv run --with typesense python agentic_kb/scripts/search_typesense.py "document automation" \
  --filter "domain:Document Automation && status:approved"

# Step 2: Refine to how-to guides
uv run --with typesense python agentic_kb/scripts/search_typesense.py "document automation" \
  --filter "domain:Document Automation && type:howto && status:approved"

# Step 3: Read the returned files
```

### Solving a Specific Problem

```bash
# Step 1: Try Typesense
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc page numbers"

# Step 2: If no results, try FAISS
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "how to add page numbers in pandoc"
cd ..

# Step 3: Use rg for exact references
rg "page.*number" agentic_kb/knowledge/Document\ Automation/
```

### Finding Policies or Standards

```bash
# Approved policies
uv run --with typesense python agentic_kb/scripts/search_typesense.py "security" \
  --filter "type:policy && status:approved"

# Checklists
uv run --with typesense python agentic_kb/scripts/search_typesense.py "deployment" \
  --filter "type:checklist && status:approved"
```

## Path Detection

The skill automatically detects whether the KB is:
- A direct repository (path: `knowledge/`)
- A submodule (path: `agentic_kb/knowledge/`)

Adjust search commands accordingly.

## Troubleshooting

### Typesense Server Not Running

If Typesense search fails with connection error:

```bash
# Check if server is running
docker ps | grep typesense

# Start server if needed
export TYPESENSE_API_KEY=xyz
docker run -d --name typesense -p 8108:8108 -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data --api-key=$TYPESENSE_API_KEY --enable-cors
```

### FAISS Index Missing

If FAISS search fails with index error:

```bash
# Build the index (run from parent project root)
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers --with tqdm \
  python scripts/index_kb.py
cd ..
```

### No Search Results

1. Try different search terms
2. Use FAISS for semantic/conceptual queries
3. Check if content exists with `rg`
4. Verify filters aren't too restrictive
5. Try removing status/type filters

## Resources

### scripts/

- `update_kb.sh` - Update KB submodule to latest version
- `smart_search.sh` - Intelligent search with Typesense → FAISS fallback

### references/

- `kb-domains.md` - Detailed domain descriptions and structure
- `search-patterns.md` - Comprehensive search examples and patterns

Both references provide additional context when needed. Load them into context when:
- User asks about available domains or KB structure → read `kb-domains.md`
- User needs search examples or filter syntax → read `search-patterns.md`
