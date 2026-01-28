# Parent Project CLAUDE.md Template

Copy this template to your parent project's root as `CLAUDE.md` to enable agents to use the agentic_kb submodule.

---

```markdown
# Agent Instructions for [Your Project Name]

## Knowledge Base Integration

This project uses `agentic_kb` as a git submodule for reusable knowledge.

**Direct KB Usage** (no skill required): These instructions show how to use the KB directly via scripts and tools. Agents work with the KB using standard bash commands and Python scripts.

**IMPORTANT**: Before answering questions, agents MUST:

1. Check if the question relates to documented knowledge
2. Search the KB using one of the methods below (prefer smart search)
3. Read the full files (never rely on snippets alone)
4. Cite sources from KB when using its content

### KB Smart Search (Recommended - Best Performance)

Use the smart search script that automatically tries Typesense first, then falls back to FAISS:

```bash
# Basic search (auto-fallback from Typesense to FAISS)
agentic_kb/scripts/smart_search.sh "your query"

# With domain filter
agentic_kb/scripts/smart_search.sh "search" --filter "domain:Search && type:howto"

# Higher similarity threshold for FAISS fallback
agentic_kb/scripts/smart_search.sh "git workflow" --min-score 0.8

# If auto-detection fails, pass the KB path explicitly
agentic_kb/scripts/smart_search.sh "your query" --kb-path agentic_kb
```

**Performance**: Combines Typesense speed (10-50ms) with FAISS semantic understanding (100-500ms fallback).

### KB Typesense Search (Fast Full-Text)

If Typesense is set up (5-10x faster than vector search):

```bash
# Basic search
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering pandoc"

# Filter by domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "domain:Search"

# Filter by type (howto, reference, checklist, policy, note)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page" --filter "type:howto"

# Filter by status (draft, approved, deprecated)
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" --filter "status:approved"

# Combine filters
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" \
  --filter "domain:Search && type:howto && status:approved"

# See agentic_kb/QUICK-TYPESENSE-WORKFLOW.md for setup and examples
```

**Performance**: 10-50ms. Returns full chunk content - often no need to read files!

### KB FAISS Search (Semantic - Slower)

Use for semantic/conceptual queries when Typesense doesn't find relevant results:

```bash
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "your query"
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering in pandoc" --min-score 0.8
cd ..

# See agentic_kb/QUICK-FAISS-WORKFLOW.md for setup
```

**Performance**: 100-500ms. Better for conceptual queries.

### KB Pattern Search (Exact Matching)

Use ripgrep for exact string/code searches:

```bash
# Tag search
rg "#pandoc" agentic_kb/knowledge/
rg "#docx" agentic_kb/knowledge/

# Phrase search
rg "page numbering" agentic_kb/knowledge/
rg "ISO 27001" agentic_kb/knowledge/

# Case-insensitive
rg -i "authentication" agentic_kb/knowledge/
```

### KB Scope and Rules

- Submodule path: `agentic_kb/knowledge/`
- Ignore `agentic_kb/.obsidian/` and `agentic_kb/.git/`
- Treat KB content as authoritative
- Cite sources using format: `<file path> -> <heading>`
- If knowledge is missing, say: "Not found in KB" and suggest where to add it

### Full KB Instructions

For complete KB agent instructions, see: [agentic_kb/CLAUDE.md](agentic_kb/CLAUDE.md)

For KB conventions and knowledge capture: [agentic_kb/KNOWLEDGE_CONVENTIONS.md](agentic_kb/KNOWLEDGE_CONVENTIONS.md)

For search setup and examples:
- Smart search workflow: [agentic_kb/QUICK-TYPESENSE-WORKFLOW.md](agentic_kb/QUICK-TYPESENSE-WORKFLOW.md)
- FAISS setup: [agentic_kb/QUICK-FAISS-WORKFLOW.md](agentic_kb/QUICK-FAISS-WORKFLOW.md)
- Git workflows: [agentic_kb/GIT_WORKFLOWS.md](agentic_kb/GIT_WORKFLOWS.md)

**Optional**: For Claude/Codex skill integration, see [agentic_kb/skills/USE-SKILLS.md](agentic_kb/skills/USE-SKILLS.md)

---

## Project-Specific Instructions

[Add your project-specific agent instructions here...]

### Project Context

- **Language/Framework**: [e.g., Python, TypeScript, React]
- **Architecture**: [e.g., microservices, monolith]
- **Key Conventions**: [e.g., coding style, testing approach]

### Project Workflows

[Document your project-specific workflows here...]

### Testing Requirements

[Specify testing requirements here...]

---

## Agent Workflow

**At session start**:
1. **Update KB submodule**: Pull latest knowledge and update pointer in parent project:
   ```bash
   # Recommended: Use the update script (auto-detects KB path)
   agentic_kb/scripts/update_kb.sh [submodule_path]

   # Or manually:
   git submodule update --remote agentic_kb
   git add agentic_kb
   git commit -m "Update: agentic_kb submodule to latest"
   git push
   ```

**During work**:
2. **Search KB first**: Use smart search (Typesense → FAISS fallback) for best results
3. **Read full files**: Never rely on search snippets alone - always read complete files
4. **Follow project conventions**: Apply project-specific rules from sections above
5. **Document learnings**: Capture reusable knowledge in the KB (see agentic_kb/KNOWLEDGE_CONVENTIONS.md)
```

---

## Usage

1. Copy the content between the triple backticks above
2. Save as `CLAUDE.md` in your parent project's root
3. Replace `[Your Project Name]` with your actual project name
4. Fill in the project-specific sections
5. Commit: `git add CLAUDE.md && git commit -m "Add: Agent instructions with KB integration"`

## Updating

When the KB's `AGENTS.md` is updated:

```bash
# Update submodule
git submodule update --remote agentic_kb

# Review changes
git diff agentic_kb

# Sync your CLAUDE.md if needed
# Commit changes
git add CLAUDE.md agentic_kb
git commit -m "Update: Sync KB agent instructions"
git push
```
