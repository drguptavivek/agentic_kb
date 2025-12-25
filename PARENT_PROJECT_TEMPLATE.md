# Parent Project CLAUDE.md Template

Copy this template to your parent project's root as `CLAUDE.md` to enable agents to use the agentic_kb submodule.

---

```markdown
# Agent Instructions for [Your Project Name]

## Knowledge Base Integration

This project uses `agentic_kb` as a git submodule for reusable knowledge.

**IMPORTANT**: Before answering questions, agents MUST:

1. Check if the question relates to documented knowledge
2. Search the KB using the patterns below
3. Cite sources from KB when using its content

### KB Search Patterns

```bash
# Tag search
rg "#pandoc" agentic_kb/knowledge/
rg "#docx" agentic_kb/knowledge/
rg "#ooxml" agentic_kb/knowledge/

# Phrase search
rg "page numbering" agentic_kb/knowledge/
rg "ISO 27001" agentic_kb/knowledge/
```

### KB Typesense Search (Recommended - Fast!)

If Typesense is set up (5-10x faster than vector search):

```bash
# Basic search
uv run python agentic_kb/scripts/search_typesense.py "page numbering pandoc"

# Filter by domain/type/status
uv run python agentic_kb/scripts/search_typesense.py "search" --filter "domain:Search"
uv run python agentic_kb/scripts/search_typesense.py "page" --filter "type:howto"
uv run python agentic_kb/scripts/search_typesense.py "search" --filter "status:approved"

# See agentic_kb/QUICK-TYPESENSE-WORKFLOW.md for setup and examples
```

### KB Vector Search (Semantic - Slower)

If vector search is set up (use for conceptual queries):

```bash
uv run python agentic_kb/scripts/search.py "your query"
uv run python agentic_kb/scripts/search.py "page numbering in pandoc" --min-score 0.8
```

### KB Scope and Rules

- Submodule path: `agentic_kb/knowledge/`
- Ignore `agentic_kb/.obsidian/` and `agentic_kb/.git/`
- Treat KB content as authoritative
- Cite sources using format: `<file path> -> <heading>`
- If knowledge is missing, say: "Not found in KB" and suggest where to add it

### Full KB Instructions

For complete KB agent instructions, see: [agentic_kb/AGENTS.md](agentic_kb/AGENTS.md)

For KB conventions and knowledge capture: [agentic_kb/KNOWLEDGE_CONVENTIONS.md](agentic_kb/KNOWLEDGE_CONVENTIONS.md)

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
   git submodule update --remote agentic_kb
   git add agentic_kb && git commit -m "Update: agentic_kb to latest" && git push
   ```

**During work**:
2. **Check KB first**: Search `agentic_kb/knowledge/` for relevant documentation
3. **Follow project conventions**: Apply project-specific rules from sections above
4. **Document learnings**: Capture reusable knowledge in the KB (see agentic_kb/KNOWLEDGE_CONVENTIONS.md)
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
