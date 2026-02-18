# Back Matter Order

Standard order for book back matter in mdtexpdf, based on the Chicago Manual of Style and publishing industry conventions.

## mdtexpdf Implementation

The template renders back matter in this order after the main body:

1. **List of Figures** (`lof: true`) - Auto-generated from `\caption{}` in figure environments
2. **List of Tables** (`lot: true`) - Auto-generated from `\caption{}` in table environments
3. **Subject Index** (`index: true`) - Generated from `[index:term]` markers via makeindex
4. **Acknowledgments** (`acknowledgments: "..."`) - Thanks to contributors, supporters, editors
5. **About the Author** (`about-author: "..."`) - Author biography
6. **Back Cover** (if configured) - Back cover image with text overlay

All sections are conditional on their YAML metadata being set. Each appears as a chapter-level entry in the Table of Contents.

## Rationale

Reference material (LoF, LoT, Index) comes before personal sections (Acknowledgments, About the Author). This follows the Chicago Manual of Style principle that navigational aids should precede non-reference content, and that the Index should be the last reference section for practical page-lookup reasons.

## Subject Index Syntax

Mark terms in your Markdown source using inline markers:

```markdown
The [index:monad]monad is the fundamental unit.
[index:Euler's formula]Euler's formula connects five constants.
[index:consciousness|default unconscious]Default unconscious states are common.
```

- `[index:term]` creates an index entry with the current page number
- `[index:term|subterm]` creates a sub-entry under `term`
- Place markers at the first significant discussion per chapter
- The `index_filter.lua` Lua filter converts markers to `\index{term}` commands

## Notes

- All back matter sections are optional and metadata-driven
- Use YAML `|` (literal block) for multi-line acknowledgments and about-author text
- Inside YAML strings passed to the LaTeX template, use `\textit{}` for italics (not Markdown `*...*`)
- Short captions (`\caption[Short]{Long}`) improve LoF/LoT readability for long captions

## References

- The Chicago Manual of Style, 18th Edition
- Industry standard publishing conventions
