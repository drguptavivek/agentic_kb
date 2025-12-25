---
title: Agent Retrieval Workflow with Search Backends
type: howto
domain: Search
tags:
  - agents
  - workflow
  - retrieval
  - search
  - rag
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Agent Retrieval Workflow with Search Backends

## Overview

When agents need to answer questions using the KB, they should follow a structured retrieval workflow. Search results are **pointers to knowledge**, not the knowledge itself.

## The Workflow

### 1. Search for Relevant Documents

Use the appropriate search backend:

```bash
# Typesense (fast, keyword-based) - submodule usage
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering pandoc" --k 3

# FAISS (semantic, concept-based) - submodule usage
cd agentic_kb
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "page numbering pandoc" --k 3
cd ..

# ripgrep (exact patterns)
rg "page.*number" agentic_kb/knowledge/
```

**Important**: Typesense returns the **full chunk text** (not snippets!), while FAISS and ripgrep only return file paths.

**Chunk Example**:
```python
{
  'path': 'knowledge/Document Automation/docx-page-numbering-pandoc.md',
  'heading': 'Problem Overview',
  'text': '## Problem Overview\n\nWhen generating DOCX...',  # FULL chunk (hundreds of chars)
  'tags': ['pandoc', 'docx', 'word'],
  'score': 578730123365187706
}
```

### 2. Decision: Use Chunks or Read Full Files?

**Typesense Optimization**: Since Typesense returns full chunks, you can often answer directly without reading files!

#### Use Chunks Directly (Fast Path ⚡)

When the top result chunks contain complete answers:

```python
results = typesense_search("page numbering problem", k=3)

# Each result has FULL chunk text
answer_text = results[0]['document']['text']  # Complete section!

# Answer immediately from chunks
synthesize_answer(answer_text, user_question)
```

**Best for**:
- Focused questions answered in 1-2 sections
- Quick facts or specific procedures
- When top 3 chunks cover the topic

#### Read Full Files (Complete Context)

When you need broader context:

```python
results = typesense_search("page numbering", k=3)

# Get file paths
file_paths = [r['document']['path'] for r in results]

# Read complete files
full_content = [read_file(p) for p in file_paths[:2]]

# Answer with full context
synthesize_answer(full_content, user_question)
```

**Best for**:
- Complex questions spanning multiple sections
- Need to understand relationships between concepts
- Code examples that might be in different sections
- Want to see the full document structure

### 3. Synthesize Answer

Whether using chunks or full files:

```python
# Agent workflow (conceptual)
search_results = typesense_search("page numbering pandoc", k=3)

for result in search_results:
    file_path = result['path']
    heading = result['heading']

    # Read the full file
    content = read_file(file_path)

    # Now you have the full context
```

### 4. Synthesize Answer

Use the retrieved content to answer the user's question:

1. **Cite sources**: Reference file paths and headings
2. **Extract relevant steps**: Pull out procedures, code, or explanations
3. **Combine knowledge**: Merge info from multiple files if needed
4. **Provide context**: Explain why this solution works

## Example: Agent Workflow

**User asks**: "How do I add page numbers to DOCX with Pandoc?"

### Step 1: Search
```bash
# Submodule usage
uv run --with typesense python agentic_kb/scripts/search_typesense.py "page numbering pandoc" --k 3
```

**Results**:
- `knowledge/Document Automation/docx-page-numbering-pandoc.md`
- `knowledge/Document Automation/page-numbering-implementation.md`

### Step 2: Read Files

```python
# Read both files
file1 = read("knowledge/Document Automation/docx-page-numbering-pandoc.md")
file2 = read("knowledge/Document Automation/page-numbering-implementation.md")
```

### Step 3: Answer with Citations

> Based on the KB, here's how to add page numbers to DOCX with Pandoc:
>
> **Source**: `knowledge/Document Automation/docx-page-numbering-pandoc.md -> Problem Overview`
>
> 1. Create a reference DOCX with footer containing page number field
> 2. Use `pandoc --reference-doc=reference.docx input.md -o output.docx`
> 3. Post-process with Python to add footer references to all sections
>
> **Source**: `knowledge/Document Automation/page-numbering-implementation.md -> Code Example`
>
> ```python
> # Post-processing script
> subprocess.run(["python", "c_add_footers.py", "output.docx"])
> ```
>
> The key insight is that Pandoc only adds footers to the first section, so post-processing is required.

## Search-Then-Read Pattern

**CRITICAL**: Never answer based solely on search result snippets.

### ❌ Wrong Approach

```python
# BAD: Answer from snippet only
results = search("page numbering")
snippet = results[0]['text'][:200]  # First 200 chars
answer = f"According to the KB: {snippet}..."
```

**Problems**:
- Incomplete context
- Missing steps
- No code examples
- Can't verify accuracy

### ✓ Correct Approach

```python
# GOOD: Search, then read full files
results = search("page numbering")
file_paths = [r['path'] for r in results[:3]]

full_content = []
for path in file_paths:
    content = read_file(path)
    full_content.append(content)

# Now synthesize answer from complete information
answer = synthesize_answer(full_content, user_question)
```

## Multi-Backend Strategy

For comprehensive retrieval, use multiple backends:

```python
def retrieve_knowledge(query):
    # 1. Fast keyword search
    typesense_results = typesense_search(query, k=5)

    # 2. Semantic search for related concepts
    faiss_results = faiss_search(query, k=5)

    # 3. Exact pattern matching for verification
    ripgrep_results = ripgrep_search(query)

    # 4. Deduplicate and merge
    all_paths = deduplicate([
        *[r['path'] for r in typesense_results],
        *[r['path'] for r in faiss_results],
        *ripgrep_results
    ])

    # 5. Read top N files
    return [read_file(p) for p in all_paths[:5]]
```

## Citation Format

Always cite sources using this format:

```
<file_path> -> <heading>
```

**Examples**:
- `knowledge/Document Automation/docx-page-numbering-pandoc.md -> Problem Overview`
- `knowledge/Security/iso-27001-compliance-checklist.md -> Access Control`

This allows users to:
- Verify information
- Read full context
- Navigate to source
- Understand KB structure

## Performance Optimization

### Typesense Fast Path (No File Reads!)

**Fastest possible workflow** using Typesense chunks:

```python
# 1. Search (10-50ms)
results = typesense_search("page numbering pandoc", k=3)

# 2. Extract chunks (already complete!)
chunks = [r['document']['text'] for r in results]

# 3. Answer (immediate)
answer = synthesize_from_chunks(chunks, user_question)
```

**Total time**: **10-50ms** (just the search!)

Compare to traditional workflow:
- Search: 10-50ms
- Read 3 files: 300-600ms
- **Total**: 310-650ms

**Savings**: **6-13x faster** by skipping file reads!

### Use Typesense for Initial Retrieval

When file reads are needed:

1. **First pass**: Typesense (10-50ms) → Get file paths
2. **Read files**: Read tool (100-200ms each)
3. **Verification** (optional): ripgrep for exact patterns

### Only Use FAISS When Needed

Reserve FAISS for:
- Conceptual queries where keywords fail
- Finding related topics across different terminology
- Exploratory research

## Agent Instruction Template

Here's the pattern agents should follow:

```markdown
## Required Workflow

1. Search the KB before answering (use `rg` or search scripts).
2. Open the most relevant file(s) using Read tool.
3. Answer using KB content, preferring exact steps or checklists.
4. Cite sources using: `<file path> -> <heading>`.
5. If missing, say: "Not found in KB" and suggest where to add it.
```

This is already documented in `CLAUDE.md` for this KB.

## Common Mistakes

### 1. Not Reading Files

```python
# ❌ Wrong
results = search("authentication")
print(f"Found {len(results)} results about authentication")
```

```python
# ✓ Correct
results = search("authentication")
content = read_file(results[0]['path'])
answer_question_using(content)
```

### 2. Reading Too Many Files

```python
# ❌ Wasteful
results = search("pandoc", k=20)
for r in results:
    read_file(r['path'])  # Reading 20 files!
```

```python
# ✓ Efficient
results = search("pandoc", k=3)
for r in results[:3]:  # Only top 3
    read_file(r['path'])
```

### 3. No Source Citations

```python
# ❌ No provenance
print("Use pandoc --reference-doc to add page numbers")
```

```python
# ✓ With citation
print("""
Use pandoc --reference-doc to add page numbers.

Source: knowledge/Document Automation/docx-page-numbering-pandoc.md -> Steps
""")
```

## Fallback Strategy

When search returns no results:

1. **Try different keywords**: "authentication" → "auth", "login"
2. **Use semantic search**: Switch to FAISS
3. **Broaden query**: "page numbering pandoc" → "page numbering"
4. **Manual exploration**: `ls knowledge/` to browse domains
5. **Admit gap**: "Not found in KB. Should this be added?"

## Integration with CLAUDE.md

This workflow is already specified in the KB's agent instructions:

From `CLAUDE.md`:
```markdown
## Required Workflow

1. Search the KB before answering (use `rg` under the correct KB path).
2. Open the most relevant file(s).
3. Answer using KB content, preferring exact steps or checklists.
4. Cite sources using: `<file path> -> <heading>`.
```

## Related

- [[search-backends]] - Which search backend to use
- [[typesense-integration]] - Typesense setup
- [[learning-capture-steps]] - Adding knowledge to KB

## Summary

**Two Retrieval Patterns**:

### Fast Path (Typesense Chunks) ⚡
1. **Search** → Get full chunks (10-50ms)
2. **Answer** → Synthesize from chunks immediately
3. **Total**: 10-50ms

**Use when**: Focused questions, top chunks contain complete answer

### Complete Path (Full Files) 📖
1. **Search** → Get file paths (10-50ms)
2. **Read** → Get full files (100-200ms each)
3. **Answer** → Synthesize with full context
4. **Total**: 310-650ms

**Use when**: Complex questions, need broader context

**Key Insight**: Typesense returns **full chunk content**, not snippets. For many queries, you can answer directly without reading files!
