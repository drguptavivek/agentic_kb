# Claude Skill Setup: kb-search

This guide explains how to install and use the `kb-search` Claude skill for searching and managing the agentic_kb knowledge base.

## What is the kb-search Skill?

The `kb-search` skill enables Claude Code to:
- Search the agentic_kb knowledge base using Typesense (fast) or FAISS (semantic)
- Set up the KB as a submodule (fork or read-only)
- Keep your KB synced with upstream updates
- Follow proper retrieval workflows (search → read → cite)
- Document new knowledge back to the KB

## Prerequisites

- **Claude Code** - Anthropic's CLI tool
- **Git** - For submodule management
- **Python 3.8+** with `uv` - For running search scripts
- **Docker** (optional) - For Typesense server

## Installation

### Step 1: Download the Skill

Download `kb-search.skill` from this repository:

```bash
# If you have access to this repo
curl -O https://raw.githubusercontent.com/drguptavivek/agentic_kb/main/kb-search.skill

# Or clone and copy
git clone https://github.com/drguptavivek/agentic_kb.git
cp agentic_kb/kb-search.skill ~/Downloads/
```

### Step 2: Install in Claude Code

```bash
# Copy to Claude skills directory
cp kb-search.skill ~/.claude/skills/

# Restart Claude Code to load the skill
# The skill will automatically activate when needed
```

### Step 3: Verify Installation

The skill is installed if you see it listed in Claude Code's available skills. You can trigger it by asking Claude to:
- "Search the KB for..."
- "Set up the agentic_kb knowledge base"
- "Update the KB to latest"

## Setting Up agentic_kb

Once the skill is installed, Claude can help you set up the KB. There are three options:

### Option 1: Fork & Customize (Recommended for Contributors)

**Best for**: Users who want to add their own knowledge while staying synced with upstream.

1. **Fork the repository** on GitHub:
   - Go to https://github.com/drguptavivek/agentic_kb
   - Click "Fork" (top-right)
   - Create fork in your account

2. **Let Claude set it up**:
   ```
   User: "Set up the agentic_kb knowledge base using my fork"
   ```

   Claude will:
   - Prompt for your GitHub username
   - Add your fork as a submodule
   - Configure upstream remote for syncing
   - Guide you through the commit process

3. **Sync with upstream updates**:
   ```
   User: "Update the KB to latest"
   ```

   Claude will:
   - Fetch from upstream
   - Merge updates
   - Push to your fork
   - Update parent project

### Option 2: Read-Only Access (Recommended for Readers)

**Best for**: Users who only want to search/read the KB.

```
User: "Set up the agentic_kb in read-only mode"
```

Claude will:
- Add KB as a submodule directly from upstream
- Configure for pull-only access
- Warn that you can't push changes

**Note**: You can later convert to fork mode if needed.

### Option 3: Standalone Clone

**Best for**: Using KB as a standalone repository (not in a project).

```bash
git clone https://github.com/drguptavivek/agentic_kb.git
cd agentic_kb
# Use search commands directly
```

## Using the Skill

### Automatic Activation

The skill automatically activates when you:
- Ask "How do I..." questions that should consult the KB
- Request to search the KB explicitly
- Want to update the KB submodule
- Need to document new knowledge

### Manual Commands

If you want to use the scripts directly:

```bash
# Setup KB (first time)
scripts/setup_kb.sh --read-only  # or without flag for fork mode

# Update KB (each session)
scripts/update_kb.sh

# Search KB (smart search with fallback)
scripts/smart_search.sh "your query"
scripts/smart_search.sh "pandoc" --filter "domain:Document Automation"

# Direct Typesense search
uv run --with typesense python agentic_kb/scripts/search_typesense.py "query"

# Direct FAISS search
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "query"
cd ..
```

### Example Interactions

**Search for information:**
```
User: Search the KB for page numbering in Pandoc
Claude: [Uses Typesense search, reads files, provides answer with citations]
```

**Update at session start:**
```
User: Update the KB to latest
Claude: [Runs update_kb.sh, syncs with upstream if fork, commits pointer]
```

**Document new knowledge:**
```
User: I just learned how to optimize FAISS searches. Document this in the KB.
Claude: [Asks for confirmation, creates properly formatted note, commits to KB]
```

## Search Methods

The skill supports three search methods with automatic fallback:

### 1. Typesense (Primary - Fast Full-Text)
- **Speed**: 10-50ms
- **Best for**: Keyword searches, specific terms
- **Features**: Typo tolerance, faceted filtering, returns full content
- **Requires**: Docker + Typesense server running

### 2. FAISS (Fallback - Semantic Search)
- **Speed**: 100-500ms
- **Best for**: Conceptual queries, natural language
- **Features**: Embedding-based similarity, semantic understanding
- **Requires**: Python packages (auto-installed by uv)

### 3. ripgrep (Exact Pattern Matching)
- **Speed**: <10ms
- **Best for**: Exact string/code searches, regex patterns
- **Features**: Fast grep with color output
- **Requires**: rg command (usually pre-installed)

## Search Filters

Typesense supports faceted filtering:

```bash
# Filter by domain
--filter "domain:Document Automation"
--filter "domain:Search"

# Filter by type
--filter "type:howto"          # How-to guides
--filter "type:reference"      # Reference docs
--filter "type:checklist"      # Checklists
--filter "type:policy"         # Policies

# Filter by status
--filter "status:approved"     # Reviewed content
--filter "status:draft"        # Work in progress

# Combine filters
--filter "domain:Search && type:howto && status:approved"
```

## Optional: Typesense Setup

For fast searches, set up Typesense (one-time):

```bash
# Start Typesense server
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data \
  --api-key=$TYPESENSE_API_KEY --enable-cors

# Build the index (run from parent project root)
uv run --with typesense --with tqdm \
  python agentic_kb/scripts/index_typesense.py
```

Typesense will now be used automatically. If not running, skill falls back to FAISS.

## Project Integration

### Adding to CLAUDE.md

If using the KB in a parent project, reference these instructions in your `CLAUDE.md`:

```markdown
## Knowledge Base

This project uses agentic_kb as a submodule for domain knowledge.

**Setup**: See `agentic_kb/CLAUDE-SKILL-SETUP.md` for installation
**Usage**: Claude automatically searches KB when using kb-search skill
**Update**: At session start, Claude updates KB to latest via `scripts/update_kb.sh`
```

### Submodule Workflow

For developers using the KB in their projects:

```bash
# Clone project with submodules
git clone --recurse-submodules https://github.com/YOUR_USERNAME/your-project.git

# Or if already cloned
git submodule update --init --recursive

# Update KB in existing project
scripts/update_kb.sh

# Parent project tracks specific KB commit
git add agentic_kb
git commit -m "Update: KB to latest"
git push
```

## Troubleshooting

### Skill Not Loading

**Issue**: Claude doesn't recognize kb-search skill

**Solution**:
```bash
# Check skill is in correct location
ls -la ~/.claude/skills/kb-search.skill

# Restart Claude Code
# The skill should appear in available skills list
```

### Typesense Connection Failed

**Issue**: Search falls back to FAISS immediately

**Solution**:
```bash
# Check if Typesense is running
docker ps | grep typesense

# Start if not running
docker start typesense

# Or start fresh
docker run -d --name typesense -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data \
  --api-key=xyz --enable-cors
```

### FAISS Index Missing

**Issue**: FAISS search fails with "index not found"

**Solution**:
```bash
# Build the index (from parent project root)
cd agentic_kb
uv run --with faiss-cpu --with numpy \
  --with sentence-transformers --with tqdm \
  python scripts/index_kb.py
cd ..
```

### Submodule Not Found

**Issue**: `scripts/update_kb.sh` reports "Submodule not found"

**Solution**:
```bash
# Run initial setup
scripts/setup_kb.sh --read-only  # or fork mode

# Or verify submodule exists
git submodule status
ls -la agentic_kb
```

### Push Permission Denied (Read-Only)

**Issue**: Can't push changes to KB

**Solution**:
This is expected for read-only mode. To contribute:
1. Fork the repository on GitHub
2. Remove read-only submodule: `git rm agentic_kb`
3. Re-run setup: `scripts/setup_kb.sh` (without --read-only)
4. Enter your GitHub username when prompted

### Merge Conflicts on Update

**Issue**: Upstream sync fails due to conflicts

**Solution**:
```bash
cd agentic_kb
git status  # Check conflicting files
# Resolve conflicts manually
git add .
git commit -m "Resolve merge conflicts"
git push origin main
cd ..
git add agentic_kb
git commit -m "Update: KB with conflict resolution"
```

## Advanced Usage

### Custom Search Strategies

The skill uses smart search by default (Typesense → FAISS fallback). For specific needs:

```bash
# Force FAISS for semantic search
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "your conceptual query"
cd ..

# Use ripgrep for exact patterns
rg "exact pattern" agentic_kb/knowledge/

# Typesense with specific filters
uv run --with typesense python agentic_kb/scripts/search_typesense.py \
  "query" --filter "domain:Security && status:approved"
```

### Knowledge Capture Workflow

When Claude learns something new during a task:

1. Claude identifies reusable knowledge
2. Asks for your confirmation to document
3. Creates properly formatted note with:
   - YAML frontmatter (tags, created date)
   - Explicit headings matching queries
   - Related section with wikilinks
4. Commits to appropriate domain
5. Pushes to your fork (if applicable)

### Syncing Fork with Upstream

For fork users, Claude handles this automatically via `update_kb.sh`. Manual approach:

```bash
cd agentic_kb
git fetch upstream
git merge upstream/main
git push origin main
cd ..
git add agentic_kb
git commit -m "Update: KB synced with upstream"
git push
```

## Support

- **Issues**: https://github.com/drguptavivek/agentic_kb/issues
- **Documentation**: See `QUICK-TYPESENSE-WORKFLOW.md` and `QUICK-FAISS-WORKFLOW.md`
- **Skill Source**: `kb-search.skill` in this repository

## Skill Development

The skill includes:

- **SKILL.md** - Main skill instructions with workflows
- **scripts/setup_kb.sh** - Interactive setup for fork/read-only/direct modes
- **scripts/update_kb.sh** - Update KB with fork/upstream sync support
- **scripts/smart_search.sh** - Intelligent search with automatic fallback
- **references/kb-domains.md** - KB structure and domain descriptions
- **references/search-patterns.md** - Search examples and filter patterns

To modify or extend the skill, see the skill-creator documentation in Claude Code.

---

**Quick Start Checklist**:
- [ ] Download `kb-search.skill`
- [ ] Copy to `~/.claude/skills/`
- [ ] Restart Claude Code
- [ ] Ask Claude to "Set up agentic_kb"
- [ ] Choose fork or read-only mode
- [ ] Start searching: "Search KB for..."

Happy searching! 🚀
