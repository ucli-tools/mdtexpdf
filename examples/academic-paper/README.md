# Academic Paper Example

This example demonstrates how to create an academic paper with:

- Title, author, abstract
- Section numbering
- Mathematical equations (inline and display)
- Tables
- Code blocks
- Citations (placeholder format)
- Appendices

## Build

```bash
# PDF
mdtexpdf convert paper.md --read-metadata

# EPUB (for e-readers, tablets, online distribution)
mdtexpdf convert paper.md --read-metadata --epub

# Or with Docker
docker run --rm -v "$(pwd):/data" logismosis/mdtexpdf convert paper.md --read-metadata
docker run --rm -v "$(pwd):/data" logismosis/mdtexpdf convert paper.md --read-metadata --epub
```

## PDF vs EPUB for Academic Papers

| Feature | PDF | EPUB |
|---------|-----|------|
| Math equations | Full LaTeX support | Limited (Unicode fallback) |
| Tables | Fixed layout | Reflowable |
| Print quality | Excellent | N/A |
| Mobile reading | Fixed size | Adapts to screen |
| Accessibility | Limited | Better (reflowable text) |

**Recommendation**: Use PDF for formal submission/printing, EPUB for personal reading or sharing drafts.

## Features Demonstrated

- `format: "article"` - Academic article format
- `toc: true` - Table of contents
- `section_numbers: true` - Numbered sections (1.1, 1.2, etc.)
- `abstract:` - Paper abstract
- `keywords:` - Keyword list
- LaTeX math: `$E=mc^2$` and `$$\int ... $$`
- Tables with proper formatting
- Code syntax highlighting
- Appendices

## Notes

For full citation support with `.bib` files, you would use Pandoc's citeproc:

```bash
pandoc paper.md --citeproc --bibliography=refs.bib -o paper.pdf
```

mdtexpdf can be extended to support this workflow.
