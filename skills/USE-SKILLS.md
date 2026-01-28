# Skill Usage Examples

This document provides practical examples of how to invoke skills in Claude Code and Codex.

## kb-search Skill

The `kb-search` skill helps you search and manage the agentic_kb knowledge base.

### Natural Language Invocations (Claude Code & Codex)

Claude Code and Codex automatically detect when to use the skill based on context:

```
# Search queries
"Search the KB for pandoc workflows"
"Find information about git submodules in the knowledge base"
"Look up how to configure Typesense"
"What does the KB say about document automation?"

# Setup and maintenance
"Set up the agentic_kb knowledge base"
"Update the KB submodule to latest"
"Initialize the KB as a read-only submodule"

# Documentation
"Document this new workflow in the KB"
"Add this solution to the knowledge base"
"Capture this learning for future reference"

# Specific domain queries
"How do I add page numbers in pandoc?"
"What's the git workflow for syncing a fork?"
"Show me the checklist for deploying with Docker"
```

### Direct Skill Invocation (Claude Code)

Use slash commands for explicit skill invocation:

```bash
# Basic search
/kb-search pandoc page numbering

# Domain-specific search
/kb-search search strategies domain:Search

# Type-specific search
/kb-search docker deployment type:checklist

# Status-filtered search
/kb-search git workflows status:approved
```

### Example Search Scenarios

#### 1. Finding How-To Guides

**Natural Language:**
```
"How do I configure Typesense for the KB?"
"Show me how to set up FAISS indexing"
```

**Direct Invocation:**
```bash
/kb-search typesense setup type:howto
/kb-search faiss indexing type:howto
```

**Expected Output:**
- Relevant how-to documents
- Step-by-step instructions
- Configuration examples

#### 2. Domain-Specific Searches

**Natural Language:**
```
"Find all document automation workflows in the KB"
"What does the KB have on search strategies?"
```

**Direct Invocation:**
```bash
/kb-search workflows domain:"Document Automation"
/kb-search strategies domain:Search
```

**Expected Output:**
- Documents filtered by domain
- Related workflows and guides
- Cross-referenced materials

#### 3. Finding Checklists and References

**Natural Language:**
```
"Show me the deployment checklist"
"Find reference material on git commands"
```

**Direct Invocation:**
```bash
/kb-search deployment type:checklist
/kb-search git commands type:reference
```

**Expected Output:**
- Actionable checklists
- Reference tables and quick guides
- Command syntax examples

#### 4. Semantic/Conceptual Queries

**Natural Language:**
```
"Find documents about managing knowledge over time"
"What's in the KB about organizing information?"
```

**Direct Invocation:**
```bash
/kb-search knowledge management semantic:true
/kb-search information architecture semantic:true
```

**Expected Output:**
- Conceptually related documents
- May not contain exact keywords
- Semantically similar content

#### 5. Setup and Maintenance

**Natural Language:**
```
"Set up the KB as a fork of the main repo"
"Update my KB to the latest version"
"Initialize KB in read-only mode"
```

**Direct Invocation:**
```bash
/kb-search --setup fork
/kb-search --update
/kb-search --setup read-only
```

**Expected Actions:**
- Run setup scripts
- Configure submodule
- Update to latest upstream

#### 6. Knowledge Capture

**Natural Language:**
```
"Document this pandoc workflow I just discovered"
"Add this Typesense configuration to the KB"
"Capture this git workaround for future reference"
```

**Direct Invocation:**
```bash
/kb-search --document "pandoc workflow" --content "..."
/kb-search --capture "typesense config" --domain "Search"
```

**Expected Actions:**
- Create new KB entry
- Follow KB conventions
- Add appropriate frontmatter
- Link to related documents

## Example Agent Prompts: Adding New Learning to KB

These are complete, copy-paste ready prompts you can use to document new knowledge.

### Scenario 1: After Solving a Problem

**Prompt Template:**
```
I just discovered a solution for [PROBLEM]. Please document this in the knowledge base:

Topic: [Topic Name]
Domain: [e.g., Document Automation, Search, Development Tools]
Type: [howto, reference, checklist, note]

The solution:
[Describe the problem and solution in detail]

Steps:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Related topics: [topic1, topic2]
```

**Example:**
```
I just discovered a solution for adding custom headers to all pages in pandoc.
Please document this in the knowledge base:

Topic: Adding Custom Headers in Pandoc
Domain: Document Automation
Type: howto

The solution:
Pandoc supports custom headers via the --include-in-header flag and custom LaTeX.

Steps:
1. Create a header.tex file with your LaTeX header content
2. Add --include-in-header=header.tex to your pandoc command
3. For HTML output, use --include-in-header with HTML/CSS content
4. Test with: pandoc input.md -o output.pdf --include-in-header=header.tex

Related topics: pandoc, pdf-generation, latex
```

### Scenario 2: After Learning a New Workflow

**Prompt Template:**
```
I learned a new workflow for [TASK]. Please create a checklist in the KB:

Workflow: [Workflow Name]
Domain: [Domain]
Use case: [When to use this workflow]

Checklist:
- [ ] [Step 1]
- [ ] [Step 2]
- [ ] [Step 3]

Prerequisites: [What you need before starting]
Related workflows: [Link to similar processes]
```

**Example:**
```
I learned a new workflow for setting up Typesense with Docker for production.
Please create a checklist in the KB:

Workflow: Typesense Production Setup
Domain: Search
Use case: Setting up Typesense search backend in production with persistence

Checklist:
- [ ] Create Docker volume for data persistence
- [ ] Generate secure API key (min 32 characters)
- [ ] Start Typesense container with volume mount
- [ ] Configure firewall rules (port 8108)
- [ ] Test connection with health endpoint
- [ ] Build search index
- [ ] Set up automated backups of Docker volume
- [ ] Configure monitoring and alerts

Prerequisites: Docker installed, API key generated
Related workflows: FAISS setup, search backend comparison
```

### Scenario 3: Documenting a Configuration

**Prompt Template:**
```
I found the correct configuration for [TOOL/SERVICE]. Document this as a reference:

Tool/Service: [Name]
Domain: [Domain]
Purpose: [What this configuration achieves]

Configuration:
[Paste configuration code/commands]

Notes:
- [Important note 1]
- [Important note 2]

Gotchas:
- [Common mistake 1]
- [Common mistake 2]
```

**Example:**
```
I found the correct configuration for Typesense with faceted filtering.
Document this as a reference:

Tool/Service: Typesense Schema Configuration
Domain: Search
Purpose: Enable faceted filtering by domain, type, status, and tags

Configuration:
```python
schema = {
    'name': 'kb_chunks',
    'fields': [
        {'name': 'chunk_id', 'type': 'string'},
        {'name': 'content', 'type': 'string'},
        {'name': 'file_path', 'type': 'string', 'facet': True},
        {'name': 'heading', 'type': 'string'},
        {'name': 'tags', 'type': 'string[]', 'facet': True},
        {'name': 'domain', 'type': 'string', 'facet': True},
        {'name': 'type', 'type': 'string', 'facet': True},
        {'name': 'status', 'type': 'string', 'facet': True}
    ]
}
```

Notes:
- facet: True enables filtering on that field
- string[] allows multiple tags per document
- All 5 fields (path, tags, domain, type, status) support filtering

Gotchas:
- Must drop and recreate collection if schema changes
- Facet fields add to index size but enable fast filtering
- Use facet: True only on fields you'll filter by
```

### Scenario 4: After Debugging an Error

**Prompt Template:**
```
I debugged an error with [TOOL/SYSTEM]. Add this troubleshooting guide:

Error: [Error message or symptom]
Domain: [Domain]
Context: [When this error occurs]

Cause:
[What causes this error]

Solution:
[How to fix it]

Prevention:
[How to avoid this in the future]

Related errors: [Similar issues]
```

**Example:**
```
I debugged an error with Typesense connection failures. Add this troubleshooting guide:

Error: "Connection refused" or "ECONNREFUSED localhost:8108"
Domain: Search
Context: When trying to search KB with Typesense

Cause:
Typesense Docker container is not running or not exposed on correct port

Solution:
1. Check if container is running: `docker ps | grep typesense`
2. If not running, start it: `docker start typesense`
3. If doesn't exist, recreate with proper port mapping:
   ```bash
   docker run -d --name typesense -p 8108:8108 \
     -v typesense-data:/data \
     typesense/typesense:29.0 \
     --data-dir /data --api-key=$TYPESENSE_API_KEY
   ```
4. Test connection: `curl http://localhost:8108/health`

Prevention:
- Add Docker container to system startup
- Use Docker restart policy: `--restart unless-stopped`
- Create health check script in cron

Related errors: FAISS index not found, search timeout errors
```

### Scenario 5: Documenting Best Practices

**Prompt Template:**
```
I discovered best practices for [ACTIVITY]. Create a policy/guideline document:

Topic: [Topic Name]
Domain: [Domain]
Applies to: [When/where these practices apply]

Best Practices:
1. [Practice 1] - [Why it matters]
2. [Practice 2] - [Why it matters]
3. [Practice 3] - [Why it matters]

Anti-patterns (avoid these):
- [Anti-pattern 1] - [Why it's bad]
- [Anti-pattern 2] - [Why it's bad]

Examples:
- Good: [Example]
- Bad: [Example]
```

**Example:**
```
I discovered best practices for agent KB retrieval. Create a policy document:

Topic: Agent Retrieval Workflow Best Practices
Domain: Search
Applies to: All agents using the knowledge base

Best Practices:
1. Always search before answering - Ensures accurate, documented solutions
2. Read full files, not just snippets - Context prevents misinterpretation
3. Cite sources with format `file -> heading` - Enables verification
4. Use smart search for auto-fallback - Combines speed + semantic understanding
5. Filter by domain/type when possible - Reduces noise, increases relevance

Anti-patterns (avoid these):
- Answering from memory instead of KB - KB is source of truth
- Relying on search snippets alone - Missing context leads to errors
- Not citing sources - User can't verify or learn more
- Using only one search method - May miss relevant documents
- Creating new docs without searching first - Leads to duplication

Examples:
- Good: Search -> Read full file -> Answer with citation
- Bad: Remember something -> Answer without checking KB
```

### Scenario 6: Quick Note/Observation

**Prompt Template:**
```
Quick note for the KB:

[Short description of what you learned]

Domain: [Domain]
Tags: [tag1, tag2, tag3]
```

**Example:**
```
Quick note for the KB:

Typesense v30 will deprecate the old REST API format for filtering.
Need to update from filter_by="domain:=Search" to filter_by="domain:Search"
(remove the := operator). This affects all our search scripts.

Domain: Search
Tags: typesense, deprecation, migration, breaking-change
```

## Format Guidelines for KB Contributions

When the agent creates KB documents, it should follow these conventions:

### Required YAML Frontmatter
```yaml
---
tags:
  - topic1
  - topic2
  - topic3
created: YYYY-MM-DD
domain: "Domain Name"
type: howto|reference|checklist|policy|note
status: draft|approved|deprecated
---
```

### Document Structure
1. **Title** (# heading matching filename)
2. **Overview** (what this document covers)
3. **Main content** (steps, configuration, explanation)
4. **Related** section with [[wikilinks]]

### Example Complete KB Entry
```markdown
---
tags:
  - typesense
  - search
  - docker
  - production
created: 2025-12-26
domain: "Search"
type: howto
status: approved
---

# Typesense Production Setup

This guide covers setting up Typesense search backend in production with Docker and data persistence.

## Prerequisites

- Docker installed and running
- Secure API key (32+ characters)
- Firewall configured for port 8108

## Setup Steps

### 1. Create Docker Volume
```bash
docker volume create typesense-data
```

### 2. Start Typesense Container
```bash
export TYPESENSE_API_KEY=your-secure-key
docker run -d --name typesense \
  --restart unless-stopped \
  -p 8108:8108 \
  -v typesense-data:/data \
  typesense/typesense:29.0 \
  --data-dir /data \
  --api-key=$TYPESENSE_API_KEY \
  --enable-cors
```

### 3. Verify Installation
```bash
curl http://localhost:8108/health
# Should return: {"ok":true}
```

### 4. Build Index
```bash
uv run --with typesense --with tqdm \
  python scripts/index_typesense.py
```

## Production Checklist

- [ ] Docker volume created for persistence
- [ ] Secure API key set (not "xyz")
- [ ] Container has restart policy
- [ ] Port 8108 accessible (but firewalled externally)
- [ ] Health check returns OK
- [ ] Index built successfully
- [ ] Backup strategy for Docker volume
- [ ] Monitoring configured

## Troubleshooting

**Connection Refused**: Container not running
```bash
docker start typesense
```

**Lost Data**: Volume not mounted correctly
```bash
docker inspect typesense | grep Mounts -A 10
```

## Related

- [[search-backends]] - Comparison of search options
- [[typesense-schema-config]] - Schema configuration details
- [[faiss-setup]] - Alternative semantic search backend
```

### Advanced Usage Examples

#### Combining Filters

**Natural Language:**
```
"Find approved how-to guides for search in the KB"
"Show me draft documents about document automation"
```

**Direct Invocation:**
```bash
/kb-search type:howto domain:Search status:approved
/kb-search domain:"Document Automation" status:draft
```

#### Threshold-Based Searches

**Natural Language:**
```
"Find highly relevant documents about git workflows, minimum 80% match"
```

**Direct Invocation:**
```bash
/kb-search git workflows --min-score 0.8
```

#### Multi-Tag Searches

**Natural Language:**
```
"Find documents tagged with both 'automation' and 'pandoc'"
```

**Direct Invocation:**
```bash
/kb-search tags:automation,pandoc
```

### Script-Level Usage

If you prefer using the scripts directly:

```bash
# Smart search (auto-fallback)
./scripts/smart_search.sh "pandoc page numbers"
./scripts/smart_search.sh "git workflows" --filter "domain:Git"
./scripts/smart_search.sh "your query" --kb-path path/to/agentic_kb

# Typesense search
uv run --with typesense python scripts/search_typesense.py \
  "search strategies" --filter "domain:Search && type:howto"

# FAISS semantic search
uv run --with faiss-cpu --with numpy --with sentence-transformers \
  python scripts/search.py "knowledge management" --min-score 0.75

# Exact pattern matching
rg "page-number" knowledge/
rg "git submodule" knowledge/ -A 5 -B 2
```

### Common Workflows

#### Daily Session Start

```
# Update KB first
"Update the KB submodule to latest"

# Then search as needed
"Search the KB for today's task: docker deployment"
```

#### Research Workflow

```
1. "Search the KB for information about X"
2. [Review search results]
3. "Read the full file at knowledge/path/to/file.md"
4. [Work with the information]
5. "Document this new finding about X in the KB"
```

#### Troubleshooting Workflow

```
1. "Find error handling strategies in the KB"
2. [Review checklist or guide]
3. "Show me related documents about debugging"
4. [Apply solution]
5. "Add this troubleshooting step to the relevant KB document"
```

## Tips for Effective Skill Usage

### 1. Be Specific with Queries
- ❌ "search docs"
- ✅ "search the KB for pandoc page numbering workflows"

### 2. Use Domain Filters
- ❌ "find automation stuff"
- ✅ "find automation workflows domain:Document Automation"

### 3. Specify Document Type
- ❌ "find git info"
- ✅ "find git workflows type:checklist"

### 4. Always Read Full Files
- ❌ Answer from search snippets
- ✅ "Read the full file at knowledge/path/to/result.md" then answer

### 5. Cite Your Sources
- ❌ "The KB says to do X"
- ✅ "According to `knowledge/Git/workflows.md -> Syncing Forks`, you should..."

## Troubleshooting Skill Invocation

### Skill Not Triggering

**Problem:** Skill doesn't activate automatically

**Solution:**
```
# Be explicit
"Use the kb-search skill to find..."
/kb-search <query>

# Check skill is loaded
"List available skills"
```

### Empty Results

**Problem:** Search returns no results

**Solution:**
```
# Try different search methods
1. Typesense (keyword-based)
2. FAISS (semantic)
3. ripgrep (exact pattern)

# Broaden your query
❌ "find exact phrase 'page number configuration'"
✅ "find page numbering OR pagination"

# Check indices are built
"Verify Typesense and FAISS indices exist"
```

### Wrong Results

**Problem:** Results not relevant

**Solution:**
```
# Increase score threshold
/kb-search <query> --min-score 0.8

# Add filters
/kb-search <query> domain:X type:Y status:Z

# Use semantic search for concepts
/kb-search <concept> semantic:true
```

## References

- See `CLAUDE-SKILL-SETUP.md` for Claude Code installation
- See `CODEX-SKILL-SETUP.md` for Codex installation
- See `kb-search/SKILL.md` for skill descriptor
- See `CLAUDE.md` for agent instructions
