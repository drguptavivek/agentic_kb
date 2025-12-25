---
tags:
  - instructions
  - maintenance
---

# Knowledge Base Instructions

Guide for adding, updating, and maintaining the Obsidian-enabled knowledge base.

---

## Adding New Knowledge

### Step 1: Create the File

Create a new markdown file in the appropriate domain folder under `knowledge/`:

```bash
# Example: Adding a Git workflow guide
cat > "knowledge/Development Tools/Git Workflow.md" << 'EOF'
---
tags:
  - git
  - version-control
  - workflow
created: 2025-12-25
---

# Git Workflow Guide

## Overview

Brief description of what this knowledge covers.

## Problem/Context

What problem does this solve? What context is needed?

## Solution

Your solution content here...

## Examples

Code examples, commands, or usage patterns...

## References

Links to external documentation, related files, etc.

---

## Related

- [[Other Related Topic]]
EOF
```

### Step 2: Use Wikilinks

Link to related knowledge files using Obsidian's `[[wikilink]]` syntax:

```markdown
## Related

- [[DOCX Page Numbering with Pandoc]]
- [[OOXML Manipulation Techniques]]
```

**Note**: Use the exact filename (without folder path) for wikilinks.

### Step 3: Update README.md

Add your file to the appropriate domain section in README.md:

```markdown
### Development Tools

| File | Description | Tags |
|------|-------------|------|
| [[Git Workflow]] | Git branching and commit workflows | `#git`, `#version-control` |
```

### Step 4: Commit and Push

```bash
# From the kb directory
git add "knowledge/Development Tools/Git Workflow.md" README.md
git commit -m "Add: Git Workflow guide"
git push
```

### Step 5: Update Dependent Projects

```bash
# In projects using this submodule
git submodule update --remote kb
```

---

## Obsidian Workflow

### Opening in Obsidian

1. Download [Obsidian](https://obsidian.md)
2. Open the `kb/` folder as a vault
3. Use **Graph View** to see connections between files
4. Click any `[[wikilink]]` to navigate

### Using Graph View

- **Nodes** = knowledge files
- **Edges** = wikilinks between files
- **Click node** to open the file
- **Zoom/Pan** to explore the knowledge graph

### Backlinks Panel

In Obsidian, open any file to see:
- **Backlinks**: Which files link to this file
- **Outlinks**: Which files this file links to

### Creating Links

**While typing**: Type `[[` and Obsidian will suggest files to link to.

**To existing file**: `[[Filename]]`

**To new file**: `[[New Filename]]` → Obsidian creates it on click

**With alias**: `[[Filename|Display Text]]`

**With heading**: `[[Filename#Heading]]`

---

## File Template

```yaml
---
tags:
  - tag1
  - tag2
  - tag3
created: YYYY-MM-DD
---

# Title

## Overview

Brief description of what this knowledge covers.

## Problem/Context

What problem does this solve?

## Solution

Your solution...

## Examples

Code/examples...

## References

External links...

---

## Related

- [[Related Topic 1]]
- [[Related Topic 2]]
```

---

## Folder Structure

```
knowledge/
├── Document Automation/
│   └── (DOCX/OOXML/Pandoc related content)
├── Development Tools/
│   └── (Git, IDEs, CLI tools)
├── APIs & Integrations/
│   └── (REST, GraphQL, webhooks)
├── Security/
│   └── (Auth, encryption, compliance)
└── DevOps & CI/CD/
    └── (Docker, CI/CD, deployment)
```

**Creating new folders**: Add a new domain folder when a distinct topic area emerges.

---

## Naming Conventions

### Files

- Use **Title Case** for filenames: `Git Workflow.md`
- Be **descriptive**: `DOCX Page Numbering with Pandoc.md` (not `docx.md`)
- Avoid numbers unless part of a series: `Docker Part 1.md`

### Folders

- Use **Title Case** for folder names: `Document Automation`, `DevOps & CI/CD`
- Group by **domain** not technology

### Tags

- Use **lowercase**: `#pandoc`, `#docx`
- Use **hyphens** for multi-word: `#page-numbering`, `#document-automation`
- Be **specific**: `#ooxml` + `#xml` (not just one)

---

## Maintenance Guidelines

### Link Hygiene

- **Check for broken links**: Use Obsidian's broken link warning
- **Update related sections**: When moving/renaming files
- **Use consistent titles**: File title should match wikilink text

### Tag Management

- **Keep tags focused**: 3-7 tags per file
- **Use existing tags** when possible
- **Remove unused tags** periodically

### Content Quality

- **Be specific**: Include concrete examples and commands
- **Be concise**: Get to the point
- **Link externally**: Reference official docs
- **Link internally**: Use wikilinks to connect topics

---

## Updating Existing Files

### In Obsidian (Recommended)

1. Open file in Obsidian
2. Edit with live preview
3. See backlinks update in real-time
4. Graph view shows new connections

### Via Text Editor

```bash
# Edit file
vim "knowledge/Document Automation/Topic.md"

# Stage and commit
git add "knowledge/Document Automation/Topic.md"
git commit -m "Update: Improved explanation of X"
git push
```

### When Moving/Renaming Files

**In Obsidian**: Use file rename (obsidian updates wikilinks automatically)

**Via git**: Manually update all `[[Old Name]]` references to `[[New Name]]`

```bash
# Find files linking to old name
grep -r "Old Name" knowledge/

# Replace in all files
find knowledge/ -type f -exec sed -i '' 's/\[\[Old Name\]\]/[[New Name]]/g' {} +
```

---

## Removing Content

### Deprecating (Preferred)

Add deprecation notice at top:

```markdown
---
tags:
  - deprecated
  - old-topic
---

# Old Topic

**DEPRECATED**: This content has been superseded by [[New Topic]].
```

### Deleting

```bash
# Remove file
git rm "knowledge/Document Automation/Obsolete.md"

# Update README.md (remove from domain section)
vim README.md

# Commit
git add README.md
git commit -m "Remove: Obsolete.md - superseded by New.md"
git push
```

---

## Troubleshooting

### Graph View Shows No Connections

**Cause**: No wikilinks between files.

**Fix**: Add `[[Related File]]` sections to connect topics.

### Broken Wikilinks

**Cause**: File renamed but links not updated.

**Fix**:
```bash
# Find broken links
grep -r "\[\[Missing File\]\]" knowledge/

# Or use Obsidian's broken link report
```

### Submodule Not Updating

```bash
# In parent project
git submodule sync
git submodule update --init --recursive
git submodule update --remote kb
```

### Merge Conflicts

```bash
git fetch origin
git checkout main
git merge origin/main
# Resolve conflicts
git add resolved-files
git commit
git push
```

---

## Git Workflow

### Typical Workflow

```bash
# 1. Pull latest
git pull origin main

# 2. Open in Obsidian
# Edit files, add wikilinks, etc.

# 3. Stage changes
git add knowledge/

# 4. Update README if new files added
git add README.md

# 5. Commit
git commit -m "Add: New topic on XYZ"

# 6. Push
git push origin main
```

### Commit Message Style

Use prefixes:
- `Add:` - New knowledge files
- `Update:` - Improvements to existing files
- `Fix:` - Corrections
- `Remove:` - Deleting/deprecating content
- `Restructure:` - Moving files, reorganizing

---

## Best Practices

1. **Use Obsidian** for editing (wikilink suggestions, graph view)
2. **Link generously** - More connections = better graph
3. **Write for future you** - Be detailed and specific
4. **Review periodically** - Update outdated content
5. **Keep flat** - Avoid deep nesting in folders
6. **Test links** - Click wikilinks after editing

---

## Using in Projects (Submodule Workflow)

When this knowledge base is used as a git submodule in projects, follow this workflow:

### Updating Knowledge from Personal Vault

If you edit `~/kb` (your personal Obsidian vault), push changes first:

```bash
# In ~/kb (personal vault)
cd ~/kb
git add .
git commit -m "Update: Your changes"
git push
```

Then update in project:
```bash
# In project directory (e.g., SecPolicy)
cd /path/to/project
git submodule update --remote kb
git add kb
git commit -m "Update kb submodule: Your changes summary"
git push
```

### Updating Knowledge Directly in Project

If you edit files in the project's `kb/` folder:

```bash
# In project directory
cd kb
git add .
git commit -m "Update: Your changes"
git push

# Go back to project root
cd ..
git add kb
git commit -m "Update kb submodule: Your changes summary"
git push
```

### Syncing Across Multiple Projects

If you use this knowledge base in multiple projects, update all projects after changes:

```bash
# In each project directory
cd /path/to/project1
git submodule update --remote kb
git add kb
git commit -m "Sync kb submodule"
git push

# Repeat for project2, project3, etc.
```

### Ensuring Consistency Across Projects

To ensure all projects using this submodule stay synchronized:

1. **Always pull before editing**:
   ```bash
   cd ~/kb  # or project/kb
   git pull origin main
   ```

2. **Push to central source first** - Always push to `https://github.com/drguptavivek/agentic_kb.git` before updating projects

3. **Update all projects** after changes:
   ```bash
   # Update all projects using this submodule
   for project in ~/project1 ~/project2 ~/project3; do
     cd "$project"
     git submodule update --remote kb
     git add kb
     git commit -m "Sync kb submodule"
     git push
   done
   ```

4. **Check submodule status**:
   ```bash
   # In any project using kb
   git submodule status
   # Should show: 8844785... kb (8844785) [or latest commit]
   ```

### Workflow Diagram

```
┌─────────────┐
│  ~/kb       │  Edit in Obsidian (personal vault)
│  (Personal) │
└──────┬──────┘
       │ git push
       ↓
┌─────────────────────┐
│  agentic_kb         │  Central source of truth
│  (GitHub repo)      │  https://github.com/drguptavivek/agentic_kb
└──────┬──────────────┘
       │ git submodule update --remote kb
       ↓
┌─────────────────────────────────────┐
│  Project1/kb  Project2/kb  Project3/kb  │  Projects using submodule
└─────────────────────────────────────┘
```

### Troubleshooting Submodule Issues

#### Submodule shows detached HEAD
```bash
cd kb
git checkout main
cd ..
git add kb
git commit -m "Fix: Reattach kb submodule to main branch"
```

#### Submodule not updating
```bash
# Force refresh
git submodule deinit -f kb
rm -rf .git/modules/kb
git submodule update --init kb
```

#### Different commits in different projects
```bash
# All projects should show same commit hash
git submodule status

# If different, update to latest
git submodule update --remote kb
```

---

## Resources

- [Obsidian Documentation](https://help.obsidian.md/)
- [Obsidian Graph View](https://help.obsidian.md/Graph+view)
- [Obsidian Wikilinks](https://help.obsidian.md/Linking+notes+and+files)
- [Obsidian Tags](https://help.obsidian.md/Tags)

---

**Need help?** See [README.md](README.md) for knowledge base overview.
