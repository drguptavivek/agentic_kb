---
tags:
  - pandoc
  - docx
  - word
  - page-numbering
  - implementation
  - example
created: 2025-12-25
---

# Page Numbering Implementation - Quick Reference

## The Final Solution

### Document Structure

```
Section 1: Cover + Version_Control          [No page numbers - lowerRoman, no footers]
Section 2: Blank_Page + foreword + TOC      [No page numbers - inherited, no footers]
Section 3: Executive_Summary                [Roman: ii - lowerRoman + footers]
Section 4: How_to_Read_This_Policy          [Roman: iii - lowerRoman + footers]
Section 5: Policy_Applicability             [Roman: iv - lowerRoman + footers]
Section 6: Policy_Authority                 [Roman: v - lowerRoman + footers]
Section 7: Relationship_to_Standards        [Roman: vi - lowerRoman + footers]
Section 8: SECTION_1 (starts main content)  [Arabic: 1 - decimal + footers]
Section 9+: All remaining chapters          [Arabic: 2, 3, 4... - decimal + footers]
```

### File Modifications

#### 1. Cover.md

```markdown
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
```

#### 2. Executive_Summary.md

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
```

Note: No `w:pgNumType` here - inherits lowerRoman from Cover. The bookmark is for TOC range limiting.

#### 3. SECTION_1.md

```markdown
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

#### 4. TOC.md

```markdown
<w:instrText xml:space="preserve"> TOC \\o "1-2" \\l 2 \\h \\z \\u \\b "_TocStart" </w:instrText>
```

Switches explained:
- `\o "1-2"` - Include outline levels 1-2
- `\l 2` - Limit to 2 levels deep
- `\h` - Hyperlinks
- `\z` - Hide in web view
- `\u` - Use paragraph styles
- `\b "_TocStart"` - Start from bookmark

### Post-Processing Script: c_add_footers.py

```python
#!/usr/bin/env python3
"""
Adds footer references and page numbering to DOCX sections.

Logic:
- Skip sections 0-1 (no page numbers)
- Sections 2-6: Add footer references + lowerRoman (if not present)
- Section 7+: Add footer references + continue decimal (remove lowerRoman)
"""

def add_footers_to_all_sections(docx_path: str):
    # ... unpack code ...

    count = 0
    found_decimal_reset = False

    for idx, sectpr in enumerate(sectprs):
        # Skip first 2 sections (Cover through TOC)
        if idx < 2:
            continue

        # Check for decimal reset (SECTION_1.md)
        has_decimal = False
        for child in list(sectpr.childNodes):
            if child.nodeType == child.ELEMENT_NODE and child.tagName == 'w:pgNumType':
                if child.getAttribute('w:fmt') == 'decimal':
                    has_decimal = True
                    found_decimal_reset = True

        # Add footer references if missing
        has_footer = any(
            child.nodeType == child.ELEMENT_NODE and
            child.tagName == 'w:footerReference'
            for child in sectpr.childNodes
        )

        if not has_footer:
            # Add footer references
            # ...

        # Handle page numbering
        has_pgnumtype = any(
            child.nodeType == child.ELEMENT_NODE and
            child.tagName == 'w:pgNumType'
            for child in sectpr.childNodes
        )

        if not has_decimal and not has_pgnumtype and not found_decimal_reset:
            # Before decimal reset: add lowerRoman
            editor.append_to(sectpr, '<w:pgNumType w:fmt="lowerRoman"/>')
        elif found_decimal_reset and not has_decimal:
            # After decimal reset: remove any lowerRoman
            for child in list(sectpr.childNodes):
                if child.nodeType == child.ELEMENT_NODE and child.tagName == 'w:pgNumType':
                    if child.getAttribute('w:fmt') == 'lowerRoman':
                        sectpr.removeChild(child)

    # ... save and pack code ...
```

### Key Insights

1. **Pandoc Limitation**: Pandoc only adds footer references to the first section in reference.docx. Post-processing is mandatory.

2. **Explicit Page Numbering**: Sections with footer references MUST have explicit `w:pgNumType` or Word defaults to decimal.

3. **No Footer References = No Visible Page Numbers**: Even if `w:pgNumType` exists, page numbers only appear if section has footer references.

4. **Inheritance Doesn't Work Across Footer Boundaries**: A section with footers doesn't inherit page numbering from previous section without footers.

5. **Decimal Reset is Persistent**: Once a section has `decimal` numbering, subsequent sections continue with decimal unless explicitly overridden.

### Verification Checklist

- [ ] Cover page: No page number visible
- [ ] Foreword/TOC: No page number visible
- [ ] Executive Summary: Shows "ii" in footer
- [ ] How to Read: Shows "iii" in footer
- [ ] Policy Applicability: Shows "iv" in footer
- [ ] Policy Authority: Shows "v" in footer
- [ ] Relationship to Standards: Shows "vi" in footer
- [ ] SECTION_1 (first page): Shows "1" in footer
- [ ] Second page of SECTION_1: Shows "2" in footer
- [ ] TOC: Only shows entries from Executive Summary onwards
- [ ] TOC: Only shows 2 heading levels

### Common Modifications

#### Adding a New Front Matter Section

1. Create new markdown file with section break
2. Rebuild (post-processing will automatically add footer + lowerRoman)
3. Verify Roman numeral sequence continues correctly

#### Changing TOC Depth

Edit TOC.md, modify the `\l` value:
- `\l 1` for 1 level
- `\l 2` for 2 levels
- `\l 3` for 3 levels

#### Starting Arabic Numbers Earlier

Move the decimal reset from SECTION_1.md to an earlier file.

#### Starting Arabic Numbers Later

1. Remove decimal reset from SECTION_1.md
2. Add decimal reset to a later file
3. Update post-processing logic to account for new section count

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| All pages show Arabic numbers | Sections 3-7 missing explicit lowerRoman | Check post-processing added lowerRoman |
| Roman numbers restart after SECTION_1 | Later section has lowerRoman | Post-processing should remove it |
| TOC shows front matter | Missing bookmark or \b switch | Add _TocStart bookmark and \b switch |
| Page numbers don't appear | Section missing footer references | Check post-processing added them |
| Wrong TOC depth | \l value incorrect | Update TOC.md \l value |

### Files Involved

- `Cover.md` - Starts lowerRoman numbering
- `Executive_Summary.md` - Has _TocStart bookmark
- `SECTION_1.md` - Has decimal reset
- `TOC.md` - Has TOC field with bookmark switch
- `c_add_footers.py` - Post-processing script
- `reference.docx` - Template with footer definitions
- `word/document.xml` - Target of post-processing
- `word/footer1-3.xml` - Footer content with PAGE fields

---

## Related

- [[DOCX Page Numbering with Pandoc]]
- [[OOXML Manipulation Techniques]]
