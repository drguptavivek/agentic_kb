# Codex Skill Setup: kb-search

This guide explains how to install and use the `kb-search` Codex skill for searching and managing the agentic_kb knowledge base.

## What is the kb-search Codex Skill?

The `kb-search` Codex skill enables Codex to:
- Search the agentic_kb knowledge base using Typesense (fast) or FAISS (semantic)
- Set up the KB as a submodule (fork or read-only)
- Keep your KB synced with upstream updates
- Follow proper retrieval workflows (search -> read -> cite)
- Document new knowledge back to the KB

## Prerequisites

- **Codex CLI** - OpenAI's CLI tool
- **Git** - For submodule management
- **Python 3.8+** with `uv` - For running search scripts
- **Docker** (optional) - For Typesense server

If you are on Windows PowerShell, use `*.ps1` script variants where available.

## Sandbox/CI Note

If `uv` reports permission errors, set a repo-local cache before running commands:

```bash
export UV_CACHE_DIR="$(pwd)/.uv-cache"
mkdir -p "$UV_CACHE_DIR"
```

```powershell
$env:UV_CACHE_DIR = (Join-Path (Resolve-Path .).Path ".uv-cache")
New-Item -ItemType Directory -Path $env:UV_CACHE_DIR -Force | Out-Null
```

## Installation

### Option A: Install from a direct download

```bash
# Clean up existing
rm -r  ~/.codex/skills/kb-search
rm ~/.codex/skills/kb-search.skill

# Download the packaged skill
wget https://raw.githubusercontent.com/drguptavivek/agentic_kb/main/skills/kb-search.skill   -O ~/.codex/skills/kb-search.skill

# Unpack to folder-based install (some Codex builds prefer this)
mkdir -p ~/.codex/skills/kb-search
unzip -o ~/.codex/skills/kb-search.skill -d ~/.codex/skills/

# Restart Codex to load the skill
```

```powershell
# Clean up existing
Remove-Item "$HOME/.codex/skills/kb-search" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$HOME/.codex/skills/kb-search.skill" -Force -ErrorAction SilentlyContinue

# Download the packaged skill
Invoke-WebRequest "https://raw.githubusercontent.com/drguptavivek/agentic_kb/main/skills/kb-search.skill" `
  -OutFile "$HOME/.codex/skills/kb-search.skill"

# Unpack to folder-based install (some Codex builds prefer this)
Expand-Archive "$HOME/.codex/skills/kb-search.skill" "$HOME/.codex/skills/" -Force
```

### Option B: Install from skill local REPO folder - Helps Keeps skill updated


```bash
# From your workspace directory
git clone https://github.com/drguptavivek/agentic_kb
cd agentic_kb

# Fetch latest
git pull

# Remove older version of skill
rm -r ~/.codex/skills/kb-search
rm    ~/.codex/skills/kb-search.skill

# Copy the folder into Codex skills directory
cp -R skills/kb-search ~/.codex/skills/
unzip -o ~/.codex/skills/kb-search.skill -d ~/.codex/skills/
# Restart Codex to load the skill
```

```powershell
# From your workspace directory
git clone https://github.com/drguptavivek/agentic_kb
cd agentic_kb
git pull

Remove-Item "$HOME/.codex/skills/kb-search" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "skills/kb-search" "$HOME/.codex/skills/" -Recurse -Force
```


## Verify Installation

The skill is installed if you see it listed in Codex's available skills. You can trigger it by asking Codex to:
- "Search the KB for..."
- "Set up the agentic_kb knowledge base"
- "Update the KB to latest"

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

# Update KB (each session, auto-detects KB path)
scripts/update_kb.sh [kb_path]

# Search KB (smart search with fallback, auto-detects KB path)
scripts/smart_search.sh "your query"
scripts/smart_search.sh "pandoc" --filter "domain:Document Automation"
scripts/smart_search.sh "your query" --kb-path path/to/agentic_kb
```

```powershell
# Setup KB (first time)
scripts/setup_kb.ps1 -ReadOnly  # or use -ForkUrl / -Default

# Update KB (each session, auto-detects KB path)
scripts/update_kb.ps1 [-SubmodulePath <kb_path>]

# Search KB (smart search with fallback, auto-detects KB path)
scripts/smart_search.ps1 "your query"
scripts/smart_search.ps1 "pandoc" -Filter "domain:Document Automation"
scripts/smart_search.ps1 "your query" -KbPath path/to/agentic_kb
```

## Typesense Setup (Recommended)

Typesense is strongly recommended for fast searches (10-50ms) and typo-tolerant matching. Set it up once:

```bash
# Start Typesense server
export TYPESENSE_API_KEY=xyz
docker volume create typesense-agentic-kb-data
docker run -d --name typesense -p 8108:8108 \
  -v typesense-agentic-kb-data:/data \
  typesense/typesense:29.0 --data-dir /data \
  --api-key=$TYPESENSE_API_KEY --enable-cors

# Build the index (run from repo root)
uv run --active --with typesense --with tqdm \
  python scripts/index_typesense.py
```

Typesense will now be used automatically. If not running, the skill falls back to FAISS.

## Troubleshooting

### Skill Not Loading

```bash
# Check skill is in correct location
ls -la ~/.codex/skills/kb-search.skill
ls -la ~/.codex/skills/kb-search
```

### Typesense Connection Failed

```bash
# Check if Typesense is running
docker ps | grep typesense

# Start if not running
docker start typesense
```

### FAISS Index Missing

```bash
# Build the index (from repo root)
uv run --active --with faiss-cpu --with numpy \
  --with sentence-transformers --with tqdm \
  python scripts/index_kb.py
```
