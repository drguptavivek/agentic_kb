---
name: kb-search
description: Search and retrieve knowledge from agentic_kb knowledge base. Use when the user requests to search the KB, asks "How do I..." questions that should consult the KB, wants to document new knowledge, or at session start to update the KB submodule. Also use when User wants to udpate the knowledge base with new knowledge. Knowledge Capture when you learn new, reusable knowledge during tasks. Supports Typesense (fast full-text search), FAISS (semantic vector search), and ripgrep (exact pattern matching). All KB is Obsidian formatted and can be browsed easily and visually with network maps in Obsidian.
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

### Option 1: Your Personal Fork of Source KB Repo (recommended)

Ask the user:
- Do you already have a knowledge-base repo fork you want to use?
- If not, guide them to create a fork, then ask for the fork URL.
  - Web: Go to https://github.com/drguptavivek/agentic_kb and Click FORK button
  - CLI: `gh auth login && gh repo fork drguptavivek/agentic_kb --clone=false`
- If they have a fork, ask for the repo URL (you can infer a likely GitHub username from the project’s `origin` remote, but confirm with the user).

If they have a fork, add it as a submodule using the setup script:

```bash
agentic_kb/scripts/setup_kb.sh --fork-url <USER_KB_REPO_URL>
git add .gitmodules agentic_kb
git commit -m "Add: agentic_kb submodule (existing fork)"
git push
```

If they want the default KB, add the upstream as the submodule:

```bash
agentic_kb/scripts/setup_kb.sh --default
git add .gitmodules agentic_kb
git commit -m "Add: agentic_kb submodule (default KB)"
git push
```

**Agent tip: infer GitHub username from origin (confirm with user):**

```bash
# HTTPS origin
git remote get-url origin | sed -n 's#https://github.com/\\([^/]*\\)/.*#\\1#p'

# SSH origin
git remote get-url origin | sed -n 's#git@github.com:\\([^/]*\\)/.*#\\1#p'
```

### Option 2: Add source KB as Submodule. Add knowldge locally. Keeps KB and Project code separate.

For users who only want to search/read the KB but do not have a fork yet:
- In Main Project Repo - `git commit` works (it just records the submodule pointer).
- In agentic_kb submodule - `git commit` works locally, but `git push` will fail because you don’t have permission to push to the upstream repo.
But you can subsequenly create a fork and change the submoduel remote URL to you own fork.
This way later on you can persist knowledge in personal git project effectively upgrading to option 1
```bash
# Add as submodule (read-only, will fail on push)
agentic_kb/scripts/setup_kb.sh --read-only
git add .gitmodules agentic_kb
git commit -m "Add: agentic_kb submodule (read-only)"
```

**Upgrade path (switch submodule to fork):**

```bash
# From parent repo
cd agentic_kb
git remote set-url origin https://github.com/USERNAME/agentic_kb.git
git remote add upstream https://github.com/drguptavivek/agentic_kb.git
cd ..
git add agentic_kb
git commit -m "Update: agentic_kb to fork remote"
git push
```

### Option 3: Clone from Source (not as git submodule). Integrate with main project.
This does not add a sub-module; it brings the source KB into the main repo.
The KB becomes part of the main repo only (no cross-project KB).
All knowledge becomes local to current project. Add and udpate knowldge in current project.
Commit knowledge as part of main project (not as submodule).

```bash
# Clone directly from upstream
git clone https://github.com/drguptavivek/agentic_kb.git
```


## Search Preference (Ask First)

Before running searches, ask the user which search backend they prefer:
1. **Typesense (Docker)** - Fastest, typo-tolerant
2. **FAISS** - Semantic search, slower but good for conceptual queries
3. **File search only (ripgrep)** - Exact matches, no index required

If they choose Typesense, offer to set it up and index the KB. If they choose FAISS, offer to build the index. If they choose file search, use `rg` only.


## Quick Start

### Session Initialization

**CRITICAL**: At the start of each session, update the KB to ensure access to latest knowledge.

If the parent repo includes the submodule, run the update script (auto-detects KB path):

```bash
agentic_kb/scripts/update_kb.sh [submodule_path]
```

If you're in the KB repo directly, use:

```bash
scripts/update_kb.sh [kb_path]
```

If the update script is missing, pull updates directly:

```bash
git -C agentic_kb pull
```

### Basic Search Workflow

1. **Search first** - Use Typesense for fast results
2. **Read full files** - Always read complete files, never rely on snippets alone
3. **Cite sources** - Use format: `<file path> -> <heading>`
4. **If not found** - Say "Not found in KB" and suggest where to add it

### Smart Search (Recommended)

Use the smart search script that tries Typesense first, falls back to FAISS (auto-detects KB path):

```bash
agentic_kb/scripts/smart_search.sh "your query" [--filter "filter_expr"] [--min-score 0.8] [--kb-path PATH]
```

Examples:
```bash
# Basic search
agentic_kb/scripts/smart_search.sh "page numbering pandoc"

# With domain filter
agentic_kb/scripts/smart_search.sh "search" --filter "domain:Search && type:howto"

# Higher similarity threshold for FAISS fallback
agentic_kb/scripts/smart_search.sh "git workflow" --min-score 0.8

# If auto-detection fails
agentic_kb/scripts/smart_search.sh "your query" --kb-path agentic_kb
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
  python agentic_kb/scripts/search.py "your query"
cd ..
```

**With similarity threshold:**
```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python agentic_kb/scripts/search.py "page numbering in pandoc" --min-score 0.8
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

1. Search to confirm the knowledge is not already in the KB.
2. Ask user for confirmation before making KB edits.
3. Follow the learning capture workflow in `knowledge/Document Automation/learning-capture-steps.md`.
4. Follow conventions in `KNOWLEDGE_CONVENTIONS.md`.

### Create a New Note Skeleton (Automated)

After the user confirms, generate a correctly formatted note skeleton (frontmatter + headings) with:

```bash
uv run python skills/kb-search/scripts/capture_note.py \
  --title "Your Title" \
  --domain "Search" \
  --type note \
  --status draft \
  --tags "agents,workflow,retrieval"
```

The script auto-detects whether the KB lives in `knowledge/` or `agentic_kb/knowledge/`, creates the domain folder if missing, and prints the created path.

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
  python agentic_kb/scripts/search.py "how to add page numbers in pandoc"
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
  python agentic_kb/scripts/index_kb.py
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

- `agentic_kb/scripts/update_kb.sh` - Update KB (submodule usage)
- `scripts/update_kb.sh` - Update KB (direct repo usage; auto-detects path)
- `agentic_kb/scripts/smart_search.sh` - Smart search (submodule usage)
- `scripts/smart_search.sh` - Smart search (direct repo usage; auto-detects path)

### references/

- `kb-domains.md` - Detailed domain descriptions and structure
- `search-patterns.md` - Comprehensive search examples and patterns

Both references provide additional context when needed. Load them into context when:
- User asks about available domains or KB structure → read `kb-domains.md`
- User needs search examples or filter syntax → read `search-patterns.md`
