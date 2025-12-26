# Claude Code Skill Setup: kb-search

This guide explains how to install and use the `kb-search` skill with Claude Code for searching and managing the agentic_kb knowledge base.

## What is the kb-search Skill?

The `kb-search` skill enables Claude Code to:
- Search the agentic_kb knowledge base using Typesense (fast) or FAISS (semantic)
- Set up the KB as a submodule (fork or read-only)
- Keep your KB synced with upstream updates
- Follow proper retrieval workflows (search -> read -> cite)
- Document new knowledge back to the KB

## Prerequisites

- **Claude Code CLI** - Anthropic's official CLI tool
- **Git** - For submodule management
- **Python 3.8+** with `uv` - For running search scripts
- **Docker** (optional) - For Typesense server

## Installation
## Installation

### Option A: Install from a direct download

```bash
# Clean up existing
rm -r  ~/.claude-code/skills/kb-search
rm ~/.claude-code/skills/kb-search.skill

# Download the packaged skill
wget https://raw.githubusercontent.com/drguptavivek/agentic_kb/main/skills/kb-search.skill   -O ~/.claude-code/skills/kb-search.skill

# Unpack to folder-based install (some Claude Code builds prefer this)
mkdir -p ~/.claude-code/skills/kb-search
unzip -o ~/.claude-code/skills/kb-search.skill -d ~/.claude-code/skills/

# Restart Claude Code to load the skill
```

### Option B: Install from skill local REPO folder - Helps Keeps skill updated


```bash
# From your workspace directory
git clone https://github.com/drguptavivek/agentic_kb
cd agentic_kb

# Fetch latest
git pull

# Remove older version of skill
rm -r ~/.claude-code/skills/kb-search
rm    ~/.claude-code/skills/kb-search.skill

# Copy the folder into Claude Code skills directory
cp -R skills/kb-search ~/.claude-code/skills/
unzip -o ~/.claude-code/skills/kb-search.skill -d ~/.claude-code/skills/
# Restart Claude Code to load the skill
```


## Verify Installation

Check if the skill is loaded:

```bash
# List installed skills
ls -la ~/.claude-code/skills/

# You should see kb-search directory
```

In Claude Code, the skill will be available when you ask questions like:
- "Search the KB for..."
- "Set up the agentic_kb knowledge base"
- "Update the KB to latest"

## Using the Skill

### Automatic Activation

The skill automatically activates when you:
- Ask "How do I..." questions that should consult the KB
- Request to search the KB explicitly
- Want to update the KB submodule at session start
- Need to document new knowledge

### Manual Invocation

You can invoke the skill directly using:

```
/kb-search <query>
```

Or ask Claude Code to use the skill in natural language:
- "Use kb-search to find information about pandoc"
- "Search the knowledge base for git workflows"

## Typesense Setup (Recommended)

Typesense provides fast searches (10-50ms) with typo-tolerance. Set it up once:

```bash
# Start Typesense server
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data \
  --api-key=$TYPESENSE_API_KEY --enable-cors

# Build the index (run from KB repo root)
cd /Users/vivekgupta/kb
uv run --with typesense --with tqdm \
  python scripts/index_typesense.py
```

The skill will automatically use Typesense if available, falling back to FAISS otherwise.

## FAISS Setup (Semantic Search)

For semantic/conceptual searches:

```bash
# Build FAISS index (from KB repo root)
cd /Users/vivekgupta/kb
uv run --with faiss-cpu --with numpy \
  --with sentence-transformers --with tqdm \
  python scripts/index_kb.py
```

## Using Search Scripts Directly

The skill uses these scripts under the hood, but you can also run them manually:

```bash
# Smart search (Typesense -> FAISS fallback)
./scripts/smart_search.sh "your query"
./scripts/smart_search.sh "pandoc" --filter "domain:Document Automation"

# Typesense search
uv run --with typesense python scripts/search_typesense.py "query" --filter "domain:Search"

# FAISS search
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "query" --min-score 0.8

# Exact pattern matching
rg "pattern" knowledge/
```

## Session Workflow

At the start of each Claude Code session:

1. **Update KB submodule** (if using as submodule):
   ```bash
   ./scripts/update_kb.sh
   ```

2. **Search before answering**:
   - Claude Code will use kb-search skill automatically
   - Or manually invoke: `/kb-search <query>`

3. **Read full files**:
   - Never answer from search snippets alone
   - Always read the complete files returned by search

4. **Cite sources**:
   - Format: `<file path> -> <heading>`

## Troubleshooting

### Skill Not Loading

```bash
# Check skill location
ls -la ~/.claude-code/skills/kb-search

# Check skill descriptor
cat ~/.claude-code/skills/kb-search/SKILL.md

# Verify directory structure
tree ~/.claude-code/skills/kb-search
```

### Typesense Connection Failed

```bash
# Check if Typesense is running
docker ps | grep typesense

# Check logs
docker logs typesense

# Restart if needed
docker restart typesense

# Test connection
curl http://localhost:8108/health
```

### FAISS Index Missing

```bash
# Check if index exists
ls -la .kb_index/

# Rebuild index
uv run --with faiss-cpu --with numpy \
  --with sentence-transformers --with tqdm \
  python scripts/index_kb.py

# Verify index files
ls -la .kb_index/
```

### Search Scripts Not Working

```bash
# Check uv is installed
uv --version

# Check Python dependencies
uv run --with typesense python -c "import typesense; print(typesense.__version__)"
uv run --with faiss-cpu python -c "import faiss; print(faiss.__version__)"

# Make scripts executable
chmod +x scripts/*.sh

# Check script paths
which smart_search.sh
```

## Skill Configuration

The skill can be configured through environment variables or config files. Check `skills/kb-search/SKILL.md` for available options.

## References

- See `CLAUDE.md` for agent instructions when using this KB
- See `QUICK-TYPESENSE-WORKFLOW.md` for Typesense quick reference
- See `QUICK-FAISS-WORKFLOW.md` for FAISS quick reference
- See `knowledge/Search/agent-retrieval-workflow.md` for detailed workflow
