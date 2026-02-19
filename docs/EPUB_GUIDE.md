# EPUB Generation Guide

Complete guide to creating EPUB e-books with mdtexpdf.

## Table of Contents

- [Quick Start](#quick-start)
- [EPUB vs PDF: When to Use Which](#epub-vs-pdf-when-to-use-which)
- [EPUB Metadata](#epub-metadata)
- [Cover Images](#cover-images)
- [Table of Contents](#table-of-contents)
- [Front Matter](#front-matter)
- [Content Considerations](#content-considerations)
- [Testing Your EPUB](#testing-your-epub)
- [Distribution](#distribution)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

Convert any Markdown file to EPUB:

```bash
# Basic conversion
mdtexpdf convert document.md --epub

# With metadata from YAML frontmatter
mdtexpdf convert document.md --read-metadata --epub

# With Docker
docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert document.md --read-metadata --epub
```

Output: `document.epub`

---

## EPUB vs PDF: When to Use Which

| Use Case | Recommended Format |
|----------|-------------------|
| Print publication | PDF |
| E-reader devices (Kindle, Kobo) | EPUB |
| Mobile phone reading | EPUB |
| Tablet reading | Either |
| Academic submission | PDF |
| Online distribution | EPUB |
| Fixed layout (diagrams, tables) | PDF |
| Accessibility needs | EPUB |
| Quick file sharing | EPUB (smaller) |

### EPUB Advantages

- **Reflowable text**: Adapts to any screen size
- **Smaller file size**: No embedded fonts required
- **Better accessibility**: Screen readers work well
- **Native e-reader support**: Works on Kindle, Kobo, Apple Books
- **Easier multilingual**: Unicode works without extra setup

### PDF Advantages

- **Exact layout control**: WYSIWYG
- **Full LaTeX math**: Complex equations render perfectly
- **Print-ready**: Suitable for professional printing
- **Universal viewing**: Works everywhere without conversion

---

## EPUB Metadata

### Essential Metadata

```yaml
---
title: "My E-Book"
author: "Author Name"
date: "2026"
lang: "en"                    # Language code (important for e-readers)
---
```

### Complete Metadata

```yaml
---
# Basic info
title: "The Complete Guide"
subtitle: "Everything You Need to Know"
author: "Jane Smith"
date: "2026-01-24"
lang: "en"

# Publisher info
publisher: "Independent Press"
rights: "© 2026 Jane Smith. All rights reserved."

# Identifiers
identifier:
  - scheme: ISBN
    text: "978-0-000000-00-0"
  - scheme: UUID
    text: "urn:uuid:12345678-1234-1234-1234-123456789abc"

# Subject/category
subject: "Technology"
description: "A comprehensive guide to the subject."

# Cover
cover_image: "img/cover.jpg"
---
```

### Language Codes

Use proper ISO 639-1 codes for better e-reader compatibility:

| Language | Code |
|----------|------|
| English | `en` |
| Spanish | `es` |
| French | `fr` |
| German | `de` |
| Chinese (Simplified) | `zh-CN` |
| Chinese (Traditional) | `zh-TW` |
| Japanese | `ja` |
| Korean | `ko` |

---

## Cover Images

### Adding a Cover

```yaml
---
title: "My Book"
cover_image: "img/cover.jpg"
---
```

### Cover Image Guidelines

| Specification | Recommendation |
|--------------|----------------|
| Format | JPG or PNG |
| Minimum size | 625 x 1000 pixels |
| Recommended size | 1600 x 2400 pixels |
| Aspect ratio | 1:1.6 (close to 2:3) |
| File size | Under 2MB |
| Color space | RGB |

### Platform-Specific Requirements

- **Amazon Kindle**: 1600 x 2560 pixels ideal, JPG format
- **Apple Books**: 1400 x 1873 pixels minimum
- **Kobo**: 1072 x 1448 pixels minimum
- **Google Play**: 1280 x 1920 pixels recommended

**Tip**: Create at 1600 x 2400 and it will work everywhere.

---

## Table of Contents

### Enabling TOC

```yaml
---
title: "My Book"
toc: true
toc_depth: 2    # How many heading levels to include
---
```

### TOC Depth Levels

- `toc_depth: 1` - Only `# Heading 1`
- `toc_depth: 2` - `# Heading 1` and `## Heading 2`
- `toc_depth: 3` - Down to `### Heading 3`

### EPUB Navigation

EPUB generates two types of navigation:

1. **NCX TOC**: Traditional navigation (EPUB 2 compatibility)
2. **Nav document**: HTML5 navigation (EPUB 3)

mdtexpdf generates both for maximum compatibility.

---

## Front Matter

### Book-Style Front Matter

```yaml
---
title: "My Novel"
format: "book"

# Front matter options
half_title: true              # Half-title page
copyright_page: true          # Copyright page
copyright_year: 2026
copyright_holder: "Author Name"
publisher: "Publisher Name"
isbn: "978-0-000000-00-0"

dedication: "To my readers"
epigraph: "The beginning is the most important part."
epigraph_source: "Plato"
---
```

### How Front Matter Appears in EPUB

1. **Cover**: Full-screen cover image
2. **Half-title**: Just the title, centered
3. **Title page**: Title, subtitle, author
4. **Copyright**: Publisher info, ISBN, rights
5. **Dedication**: Centered, italicized
6. **Epigraph**: Quote with attribution
7. **Table of Contents**: Linked navigation
8. **Content**: Your chapters

---

## Content Considerations

### What Works Well in EPUB

- **Markdown formatting**: Bold, italic, links
- **Headings**: Proper hierarchy (`#`, `##`, `###`)
- **Lists**: Ordered and unordered
- **Block quotes**: For emphasis or citations
- **Code blocks**: With syntax highlighting
- **Simple tables**: Single-row headers
- **Images**: JPG, PNG, GIF

### What Has Limitations in EPUB

| Feature | EPUB Behavior |
|---------|---------------|
| LaTeX math | Converted to Unicode where possible |
| Complex tables | May reflow awkwardly |
| Page breaks | Suggestions only (e-reader decides) |
| Footnotes | Converted to endnotes or pop-ups |
| Page numbers | Not applicable (reflowable) |
| Headers/footers | Not supported |
| Columns | Not supported |

### Math in EPUB

Simple math works:
```markdown
$E = mc^2$  →  E = mc²
$x^2$       →  x²
$H_2O$      →  H₂O
```

Complex math may need alternatives:
```markdown
<!-- Instead of complex LaTeX, use Unicode or images -->
∫₀^∞ e^(-x²) dx = √π/2
```

### Images

```markdown
![Alt text for accessibility](images/diagram.png)
```

**Tips**:
- Use relative paths from the markdown file
- Include alt text for accessibility
- Optimize file sizes for faster loading
- Prefer PNG for diagrams, JPG for photos

---

## Testing Your EPUB

### Validation

Use epubcheck to validate your EPUB:

```bash
# Install epubcheck
# macOS
brew install epubcheck

# Then validate
epubcheck mybook.epub
```

### E-Reader Testing

Test on multiple platforms:

1. **Calibre**: Free, shows how most e-readers render
   ```bash
   # Install Calibre
   sudo apt-get install calibre
   
   # Open EPUB
   ebook-viewer mybook.epub
   ```

2. **Kindle Previewer**: Free from Amazon, shows Kindle rendering

3. **Apple Books**: On macOS/iOS

4. **Google Play Books**: Upload to test

### Common Issues to Check

- [ ] Cover displays correctly
- [ ] TOC navigation works
- [ ] Images appear and scale properly
- [ ] Links work (internal and external)
- [ ] Text is readable at different sizes
- [ ] Chapter breaks are correct
- [ ] Metadata appears in e-reader library

---

## Distribution

### Amazon Kindle (KDP)

Amazon accepts EPUB but converts to their format:

1. Upload EPUB to Kindle Direct Publishing
2. KDP converts to AZW3/KF8
3. Preview before publishing
4. Some formatting may change in conversion

### Apple Books

1. Use Apple Books Author or iTunes Producer
2. EPUB uploads directly
3. Good support for EPUB 3 features

### Kobo, Google Play, etc.

Most platforms accept standard EPUB files directly.

### DRM-Free Distribution

For direct sales (Gumroad, your website, etc.):
- EPUB files work as-is
- Consider offering both EPUB and PDF
- No DRM means easier customer experience

---

## Troubleshooting

### EPUB file won't open

1. Validate with epubcheck
2. Check for special characters in filename
3. Ensure .epub extension is correct

### Cover not showing

1. Check image path is correct
2. Verify image format (JPG/PNG)
3. Ensure image is under 5MB

### TOC missing or incorrect

1. Add `toc: true` to metadata
2. Check heading hierarchy (don't skip levels)
3. Ensure headings use `#` syntax

### Images missing

1. Use relative paths from markdown file
2. Check file permissions
3. Verify supported format (JPG, PNG, GIF)

### Math not rendering

Math has limited support in EPUB. Options:
1. Use Unicode symbols: `²`, `³`, `π`, `∞`
2. Convert complex equations to images
3. Accept that EPUB is for simpler content

### Characters displaying incorrectly

1. Save markdown as UTF-8
2. Add `lang:` to metadata
3. Test in Calibre viewer

---

## Quick Reference

### EPUB Build Commands

```bash
# Basic
mdtexpdf convert doc.md --epub

# With metadata
mdtexpdf convert doc.md --read-metadata --epub

# With TOC
mdtexpdf convert doc.md --read-metadata --epub --toc

# Docker
docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert doc.md --read-metadata --epub
```

### Minimal EPUB Metadata

```yaml
---
title: "Document Title"
author: "Author Name"
lang: "en"
cover_image: "cover.jpg"
toc: true
---
```

### Build Both Formats

Create a Makefile:

```makefile
BOOK = mybook

all: pdf epub

pdf:
	mdtexpdf convert $(BOOK).md --read-metadata

epub:
	mdtexpdf convert $(BOOK).md --read-metadata --epub

clean:
	rm -f $(BOOK).pdf $(BOOK).epub
```

---

## See Also

- [mdtexpdf_guide.md](mdtexpdf_guide.md) - Comprehensive guide
- [METADATA.md](METADATA.md) - All metadata options
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
