# Technical Documentation Example

This example demonstrates how to create API reference documentation with:

- Code blocks with syntax highlighting
- HTTP request/response examples
- Tables for parameters and error codes
- Multi-language SDK examples
- Appendices

## Build

```bash
# PDF (best for printing and fixed layouts)
mdtexpdf convert api-reference.md --read-metadata

# EPUB (best for reading on tablets/e-readers)
mdtexpdf convert api-reference.md --read-metadata --epub

# Or with Docker
docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert api-reference.md --read-metadata
docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert api-reference.md --read-metadata --epub
```

## PDF vs EPUB for Technical Documentation

| Feature | PDF | EPUB |
|---------|-----|------|
| Code blocks | Fixed-width, exact layout | Reflowable, may wrap |
| Tables | Fixed columns | May require scrolling |
| Searchability | Good | Excellent |
| Offline reading | Yes | Yes |
| Mobile-friendly | Requires zoom | Native reflow |

**Tip**: Generate both formats. PDF for reference/printing, EPUB for mobile reading.

## Features Demonstrated

- `format: "article"` - Document format
- `toc: true` - Table of contents
- `toc_depth: 3` - Deep navigation
- `section_numbers: true` - Numbered sections
- Fenced code blocks with language identifiers
- Tables for structured data
- Blockquotes for warnings/notes
- Horizontal rules for section separation

## Code Block Languages

Syntax highlighting is supported for:

- `python`, `javascript`, `go`, `java`, `rust`
- `bash`, `shell`
- `json`, `yaml`, `xml`
- `http` for HTTP requests
- `sql`, `graphql`
- And many more

## Tips for Technical Docs

1. **Use tables** for parameter lists and comparisons
2. **Include examples** for every endpoint/function
3. **Show error cases** not just happy paths
4. **Version your docs** with date and version number
5. **Add a changelog** to track API changes
