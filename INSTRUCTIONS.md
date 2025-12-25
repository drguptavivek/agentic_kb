---
title: Knowledge Base Instructions
tags: [instructions, maintenance]
---

# Knowledge Base Instructions

Guide for adding, updating, and maintaining the knowledge base.

---

## Adding New Knowledge

### Step 1: Create the File

Create a new markdown file in the `knowledge/` directory with proper frontmatter:

```bash
# Example: Adding a Git workflow guide
cat > knowledge/git-workflow.md << 'EOF'
---
title: Git Workflow Guide
tags: [git, version-control, workflow]
created: 2025-12-25
related: []
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
EOF
```

### Step 2: Update README.md

**IMPORTANT**: When adding new files, you must update both sections in README.md:

#### A. Add to Domain Section

Add your file to the appropriate domain category. If a new domain is needed, create a new section header.

```markdown
### Your New Domain Name

| File | Description | Tags |
|------|-------------|------|
| [knowledge/your-file.md](knowledge/your-file.md) | Brief description | `tag1`, `tag2`, `tag3` |
```

#### B. Update Tag Index

Add new tags to the Tag Index. Tags should be **lowercase** and use **hyphens** for multi-word tags.

```markdown
| `your-new-tag` | Domain | [file1.md](knowledge/file1.md), [file2.md](knowledge/file2.md) |
```

### Step 3: Commit and Push

```bash
# From the kb directory
git add knowledge/your-file.md README.md
git commit -m "Add: Your new knowledge file"
git push
```

### Step 4: Update Dependent Projects

Projects using this submodule should update:

```bash
# In projects using this submodule
git submodule update --remote kb
```

---

## File Template

Copy this template for new knowledge files:

```yaml
---
title: Your Knowledge Title
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
related: [related-file1.md, related-file2.md]
---

# Your Knowledge Title

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
```

---

## Maintenance Guidelines

### Tag Conventions

- Use **lowercase** tags
- Use **hyphens** for multi-word tags: `document-automation`, `page-numbering`
- Use **descriptive tags** that will be useful for searching
- Include both **specific** and **general** tags: e.g., `ooxml` + `xml` + `document-automation`

### Domain Organization

- Add new domain sections when a distinct topic area emerges
- Keep domain descriptions concise (one line per file)
- Update the Tag Index when adding new tags

### File Naming

- Use **kebab-case**: `git-workflow.md`, `api-integration.md`
- Be **descriptive**: `docx-page-numbering-pandoc.md` (not `docx.md`)
- Avoid numbers unless part of a series: `docker-part-1.md`
- **Always save in `knowledge/` directory**

### Content Quality

- **Be specific**: Include concrete examples, commands, and code
- **Be concise**: Get to the point, avoid fluff
- **Be accurate**: Test code examples before committing
- **Link related content**: Use the `related` field to connect related topics

---

## Updating Existing Files

### Minor Updates

For small corrections or clarifications:

```bash
# Edit the file
vim knowledge/existing-file.md

# Commit with descriptive message
git add knowledge/existing-file.md
git commit -m "Fix: Correct command example in existing-file"
git push
```

### Major Updates

For significant changes that affect structure or organization:

1. Update the knowledge file
2. Update README.md if tags or descriptions changed
3. Update related files if content moved between files
4. Commit with detailed message describing changes

```bash
git add knowledge/affected-file.md README.md
git commit -m "Update: Restructure affected-file for clarity

- Added new section on X
- Updated code examples
- Changed tags to reflect new content"
git push
```

---

## Removing Content

### Removing a File

```bash
# Remove the file
git rm knowledge/obsolete-file.md

# Update README.md (remove from Domain section and Tag Index)
vim README.md

# Commit
git add README.md
git commit -m "Remove: obsolete-file.md - content superseded by new-file.md"
git push
```

### Deprecating Content

Instead of removing, consider deprecating with a notice:

```markdown
---
title: Old Topic
tags: [deprecated, old-topic]
created: 2020-01-01
related: [new-topic.md]
---

# Old Topic

**DEPRECATED**: This content has been superseded by [new-topic.md](new-topic.md).

...
```

---

## Review Process

### Before Committing

- [ ] File saved in `knowledge/` directory
- [ ] Frontmatter complete (title, tags, created, related)
- [ ] README.md updated (Domain section + Tag Index)
- [ ] Links tested (both internal and external)
- [ ] Code examples tested
- [ ] Spelling and grammar checked

### After Major Changes

1. **Test submodule updates** in a dependent project
2. **Verify links** still work
3. **Check for broken references** in `related` fields

---

## Troubleshooting

### Submodule Not Updating in Parent Project

```bash
# In parent project
git submodule sync
git submodule update --init --recursive
git submodule update --remote kb
```

### Broken Links After Moving Files

When moving or renaming files, search for references:

```bash
# Find files linking to old-name.md
grep -r "old-name.md" knowledge/
```

Update all `related` fields and markdown links found.

### Merge Conflicts

When pulling updates with conflicts:

```bash
git fetch origin
git checkout main
git merge origin/main
# Resolve conflicts in affected files
git add resolved-files
git commit
git push
```

---

## Git Workflow

### Typical Workflow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create/edit knowledge files
vim knowledge/new-topic.md

# 3. Update README.md
vim README.md

# 4. Commit changes
git add knowledge/new-topic.md README.md
git commit -m "Add: new-topic on XYZ"

# 5. Push to remote
git push origin main
```

### Best Practices

- **Pull before pushing** to avoid merge conflicts
- **Write descriptive commit messages** with "Add:", "Fix:", "Update:", "Remove:" prefixes
- **Update README.md** in the same commit as content changes
- **Test locally** before pushing (e.g., markdown linting, link checking)

---

## Directory Structure

```
kb/
├── README.md           # Knowledge index (domains, tags, finding info)
├── INSTRUCTIONS.md     # This file - how to add/update knowledge
├── LICENSE            # License file
└── knowledge/         # All knowledge files go here
    ├── docx-page-numbering-pandoc.md
    ├── ooxml-manipulation-techniques.md
    ├── page-numbering-implementation.md
    └── ...
```

---

## Resources

### Markdown Reference

- [GitHub Flavored Markdown](https://github.github.com/gfm/)
- [YAML Frontmatter](https://jekyllrb.com/docs/front-matter/)

### Git Submodule Reference

- [Git Submodule Documentation](https://git-scm.com/docs/git-submodule)
- [Working with Submodules](https://github.blog/2016-02-01-working-with-submodules/)

---

**Need help?** Refer to [README.md](README.md) for knowledge base structure and content.
