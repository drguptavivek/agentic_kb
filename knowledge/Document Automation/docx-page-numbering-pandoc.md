---
tags:
  - pandoc
  - docx
  - word
  - page-numbering
  - ooxml
  - document-automation
created: 2025-12-25
---

# DOCX Page Numbering with Pandoc

## Problem Overview

When generating DOCX files from Markdown using Pandoc, page numbers often don't appear correctly because:

1. **Pandoc only adds footer references to the first section** - Subsequent sections created by section breaks don't inherit footer references automatically
2. **Page numbering doesn't continue properly** without explicit `w:pgNumType` settings in each section
3. **Word defaults to decimal numbering** when sections have footers but no explicit page numbering type

## Key OOXML Concepts

### Section Properties (`w:sectPr`)

Each section in a Word document is defined by a `<w:sectPr>` element that contains:

- **`w:footerReference`** - Links to footer XML files (even/default/first page types)
- **`w:pgNumType`** - Defines page number format and start value
- **`w:type`** - Section break type (nextPage, continuous, etc.)

### Page Number Formats

| Format Value | Example | Usage |
|-------------|---------|-------|
| `lowerRoman` | i, ii, iii | Front matter, prefaces |
| `decimal` | 1, 2, 3 | Main content |
| `upperRoman` | I, II, III | Some front matter styles |

### Footer Reference Types

- **`w:type="first"`** - First page of section
- **`w:type="default"`** - Odd/even pages when odd/even not specified
- **`w:type="even"`** - Even pages

## Solution Architecture

### 1. Markdown Structure

Define section breaks and page numbering in Markdown files using OpenXML blocks:

```markdown
# Cover Page

```{=openxml}
<w:p>
  <w:r><w:br w:type="page"/></w:r>
  <w:pPr>
    <w:sectPr>
      <w:pgNumType w:fmt="lowerRoman" w:start="1"/>
    </w:sectPr>
  </w:pPr>
</w:p>
```

# Next Section - Arabic Numerals Start Here

```{=openxml}
<w:p>
  <w:pPr>
    <w:sectPr>
      <w:pgNumType w:fmt="decimal" w:start="1"/>
    </w:sectPr>
  </w:pPr>
</w:p>
```
```

### 2. Post-Processing Script

Since Pandoc doesn't propagate footer references, a post-processing script is required:

```python
#!/usr/bin/env python3
"""
Post-process DOCX to add footer references and page numbering.
"""

def add_footers_to_all_sections(docx_path: str):
    # Unpack DOCX
    # Process word/document.xml
    # 1. Add footer references to sections that need them
    # 2. Add explicit page numbering types (lowerRoman/decimal)
    # 3. Remove conflicting page numbering from later sections
    # Pack DOCX
```

Key logic:
- **Skip first N sections** for documents where front matter should have no page numbers
- **Add footer references** to sections starting from a specified index
- **Add explicit `w:pgNumType`** to sections that should show page numbers
- **Preserve decimal numbering** after it starts (remove `lowerRoman` from later sections)

### 3. Footer XML Files

Footer files (`footer1.xml`, `footer2.xml`, `footer3.xml`) in `word/` directory contain:

```xml
<w:ftr>
  <w:p>
    <w:r>
      <w:fldSimple w:instr="PAGE">
        <w:r>
          <w:t>- PAGE -</w:t>
        </w:r>
      </w:fldSimple>
    </w:r>
  </w:p>
</w:ftr>
```

**Important**: Use `<w:fldSimple>` or nested `<w:instrText>` with `<w:fldChar>` elements. Avoid SDT (Structured Data Tag) wrappers which can cause issues.

## Common Patterns

### Pattern 1: No Page Numbers for Front Matter

```python
for idx, sectpr in enumerate(sectprs):
    if idx < 2:  # Skip first 2 sections
        continue
    # Add footer references starting from section 3
```

### Pattern 2: Roman Numerals then Arabic Numerals

```python
found_decimal_reset = False
for sectpr in sectprs:
    has_decimal = check_for_decimal(sectpr)
    if has_decimal:
        found_decimal_reset = True

    # Before decimal reset: add lowerRoman if needed
    if not found_decimal_reset and needs_lower_roman(sectpr):
        add_lower_roman(sectpr)

    # After decimal reset: remove lowerRoman to continue decimal
    if found_decimal_reset:
        remove_lower_roman(sectpr)
```

### Pattern 3: TOC with Bookmark Range

```markdown
```{=openxml}
<w:p>
  <w:pPr>
    <w:sectPr>
      <w:type w:val="nextPage"/>
    </w:sectPr>
  </w:pPr>
</w:p>
<w:bookmarkStart w:id="99" w:name="_TocStart"/>
```

Then in TOC:

```markdown
<w:instrText xml:space="preserve"> TOC \\o "1-2" \\l 2 \\h \\z \\u \\b "_TocStart" </w:instrText>
```

The `\b "_TocStart"` switch limits TOC entries to content after that bookmark.

## TOC Field Switches

| Switch | Purpose | Example |
|--------|---------|---------|
| `\o "1-2"` | Outline levels to include | `\o "1-3"` for levels 1-3 |
| `\l 2` | Limit depth to N levels | `\l 2` for 2 levels max |
| `\h` | Hyperlinks | `\h` for clickable links |
| `\z` | Hide page numbers in web view | `\z` |
| `\u` | Use paragraph styles | `\u` |
| `\b "bookmark"` | Start from bookmark | `\b "_TocStart"` |

## Build Process Integration

```python
import subprocess

# Build with pandoc
subprocess.run(["pandoc", "--reference-doc=reference.docx", ...])

# Post-process DOCX
subprocess.run(["python", "c_add_footers.py", "output.docx"])
```

## Troubleshooting

### Issue: Page numbers not appearing

**Cause**: Section has footer references but footers don't contain PAGE field.

**Fix**: Ensure footer XML files have `<w:fldSimple w:instr="PAGE">` or proper field codes.

### Issue: Wrong number format (shows Arabic instead of Roman)

**Cause**: Section has footer references but no explicit `w:pgNumType`. Word defaults to decimal.

**Fix**: Add explicit `<w:pgNumType w:fmt="lowerRoman"/>` to section properties.

### Issue: Numbering restarts unexpectedly

**Cause**: Later section has `w:pgNumType w:fmt="lowerRoman"` after decimal section.

**Fix**: Post-process to remove `lowerRoman` from sections after decimal reset.

### Issue: TOC shows all content including front matter

**Cause**: TOC field doesn't have bookmark range limit.

**Fix**: Add bookmark at start of desired TOC content and use `\b "bookmark"` switch.

## Files Reference

- `reference.docx` - Pandoc template with footer definitions and initial section settings
- `c_add_footers.py` - Post-processing script
- `word/document.xml` - Main document with section properties
- `word/footer1.xml`, `footer2.xml`, `footer3.xml` - Footer content files
- `word/_rels/document.xml.rels` - Relationship file linking footer references to files

## Best Practices

1. **Use explicit page numbering** - Never rely on inheritance when sections have footer references
2. **Post-process is necessary** - Pandoc cannot handle complex page numbering scenarios
3. **Test in Word** - Preview tools may not accurately render page numbering
4. **Bookmark-based TOC** - Use bookmarks to control TOC range, not just levels
5. **Consistent section structure** - Each logical section should have explicit `w:sectPr`

---

## Related

- [[ooxml-manipulation-techniques]]
- [[page-numbering-implementation]]
