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
docker run --rm -v "$(pwd):/data" logismosis/mdtexpdf convert document.md --read-metadata --epub
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

### TikZ drawings and print layout

EPUB export renders self-contained `tikzpicture` blocks, including those inside
LaTeX `figure` environments, as embedded PNG images at 144 dpi. Document
`header-includes` supply packages, TikZ libraries, and macro definitions. Rendering
uses XeLaTeX with shell escape disabled and Poppler's `pdftoppm`; on Debian/Ubuntu
install `texlive-xetex texlive-latex-extra texlive-pictures poppler-utils`.
A failed drawing render fails the conversion;
the original Markdown is restored.

Artwork is centered, limited to the reading width, and given 36pt of padding above
and below. Existing captions remain visible. Uncaptioned artwork has no added
label or caption and uses empty alternative text for decorative images. Supply a
caption when a diagram conveys information the surrounding prose does not explain.
E-readers may adapt spacing to the screen and reading preferences.

`minipage` and `samepage` wrappers around Markdown prose are removed for EPUB,
including paragraph spacing commands; their contents keep normal Markdown
formatting and reflow naturally. Literal examples in Markdown code blocks remain
code. This support does not convert arbitrary LaTeX documents: custom environments,
external files used by drawings, and document-wide page-layout settings may need
adaptation. Inspect the EPUB in a reader as well as running structural validation.

### Raw LaTeX, numbers and the index

An EPUB writer drops raw LaTeX it does not understand, so mdtexpdf converts what a
book typically writes that way before the writer sees it:

- `table` environments, a `figure` holding a `tabular`, and a `tabular` inside
  `center` become real tables with their captions. Print-only column types
  (`R{3cm}` from a `\newcolumntype`, `>{..}`, `@{..}`), row spacing (`\\[11pt]`,
  `\noalign`, `\arraystretch`) and size commands are set aside first.
- `\begin{center}...\end{center}` text, including a `\parbox` inside it, stays as
  centred text.
- A wide equation fitted for print as `\[\sbox0{$\displaystyle ...$}...\]` becomes
  an ordinary display equation, keeping a `\tag` written after the box.
- Commands that only shape the printed page (`\newpage`, `\nopagebreak`,
  `\enlargethispage`, `\begingroup` penalty groups, vertical spacing) are removed.
- Other raw LaTeX that carries text is read with pandoc's LaTeX reader; anything
  still left out is named in the build output.

Numbers follow the PDF. With `equation_numbers: true`, display equations are
numbered as LaTeX numbers them (by chapter in a book, where every `Chapter N:` or
`Appendix X:` heading restarts the count); `\tag{..}` labels are shown as written,
and `\notag` equations stay unnumbered. Captioned figures and tables are labelled
"Figure 2.1:" and "Table 2.1:" unless `no_figure_numbers: true` removes figure
labels, as it does in the PDF. The number sits beside its equation.

`[index:term]` markers become anchors, and an Index at the end lists every term with
links to where it occurs, named by the chapter or section heading above each
occurrence (`[index:main|sub]` nests; `[index:sort@display]` sorts by its first
part and shows its second).

### What Has Limitations in EPUB

| Feature | EPUB Behavior |
|---------|---------------|
| LaTeX math | MathML (see Math in EPUB) |
| Complex tables | May reflow awkwardly |
| Page breaks | Suggestions only (e-reader decides) |
| Footnotes | Converted to endnotes or pop-ups |
| Page numbers | Not applicable (reflowable) |
| Headers/footers | Not supported |
| Columns | Not supported |

### Math in EPUB

Maths is written as MathML, which current readers display directly or typeset with
MathJax. Every formula is first converted exactly as written. Only a formula pandoc
cannot convert is repaired, one rule at a time (`\mathbbm` as `\mathbb`; a pair of
quotation marks inside maths set as text), and each repair is listed in the build
output. A formula that no rule repairs stops the build and is named, so no formula
is ever shown to a reader as raw TeX.

A display equation is set in a block of its own that scrolls sideways when it is
wider than the screen, so it never runs into the next page or over the text; it
starts at its left edge rather than losing it. An inline formula long enough to be
wider than a phone screen scrolls sideways the same way, since a formula cannot
wrap.

### Tables on e-readers

Each chapter carries a short reading-layout style (`templates/epub_layout.html`,
included after the book's stylesheets): tables break across pages instead of being
one box that a page cuts off at its foot, and on a narrow screen (below 36em) each
row shows its cells one under another. A book can override these rules with more
specific selectors in its own `--epub-css`.

### Images

```markdown
![Alt text for accessibility](images/diagram.png)
```

**Tips**:
- Use relative paths from the markdown file
- Include alt text for accessibility
- Optimize file sizes for faster loading
- Prefer PNG for diagrams, JPG for photos

### Figure descriptions (alt text)

A screen reader cannot see a drawing. Describe it in an HTML comment right after the
figure, and the EPUB uses the description as the image's alt text:

```markdown
\begin{figure}[H]
\centering
\begin{tikzpicture}
  \draw (0,0) circle (1);
\end{tikzpicture}
\caption{The unit circle.}
\end{figure}

<!-- audio-description
Here in Figure 2.1 we see a circle drawn around the origin, with a dot on its
right-hand edge where $x$ is one and $y$ is zero.
-->
```

The comment shows nowhere: not in the PDF, not in the EPUB's text. It is the same comment
mdaudiobook reads aloud after the caption, so one description serves the listener and the
screen-reader user. It is Markdown: `$x$` becomes the letter x in the alt text. A description
also works after a Markdown image. A figure without one gets its caption as alt text, as
plain text (maths as Unicode, never raw TeX).

### Accessibility metadata

Every EPUB declares its accessibility in the package document (schema.org metadata, as
EPUB Accessibility 1.1 and the e-book stores ask): access modes, whether every image has a
text alternative, MathML, table of contents, headings, hazards. The values are computed
from what the EPUB holds, so they stay true. The summary sentence is generated too; give
your own with `accessibility_summary` in the metadata:

```yaml
accessibility_summary: "Reflowable text; every figure has a text description; mathematics as MathML."
```

---

## Testing Your EPUB

### Validation

Every EPUB build ends with a quick check of what was written against its source:
nothing may leak into the visible text (`[index:` markers, TeX commands, `$...$`,
comment remains, Markdown or pandoc syntax, a formula left as TeX), every image,
link and contents entry must resolve, and everything in the source must be there
(headings, display equations, tables, drawings, equation labels, index entries, and
the text of every block). A build that fails the check says so and exits non-zero.

The full check is `mdtexpdf validate`:

```bash
mdtexpdf validate mybook.epub --pdf mybook.pdf
```

It adds:

- **epubcheck**, the reference validator;
- **calibre**, which must open the book and extract clean text (when installed);
- **numbering against the PDF**: the equation numbers and the figure and table labels
  printed in a PDF of the same source must appear in the EPUB in the same order;
- **layout**: headless Chrome or Chromium lays out every chapter as paginated
  readers do, one screen per page, at phone and tablet size, with native MathML and
  with MathJax (calibre's copy, or the one `MDTEXPDF_MATHJAX` names). A formula,
  image or table that paints over text, runs into the next page or is clipped is
  an error; one that scrolls sideways or is taller than a page is a warning.
  `--shots DIR` saves a screenshot of every page with an error.

The source defaults to the `.md` beside the EPUB (`--source` names another). Exit
status is 0 when everything passed, 1 when something failed, and 2 when a check
could not run (no PDF for a book that numbers its equations, no Chrome, no
epubcheck): that is "not verified", never "passed". `--no-pdf` and `--no-layout`
accept a skipped check explicitly.

Install epubcheck with `sudo apt install epubcheck` or `brew install epubcheck`.

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
docker run --rm -v "$(pwd):/data" logismosis/mdtexpdf convert doc.md --read-metadata --epub
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
