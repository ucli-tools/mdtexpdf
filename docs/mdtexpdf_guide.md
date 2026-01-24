# mdtexpdf Comprehensive Guide

A complete reference for writing professional books and documents using mdtexpdf.

---

## Overview

mdtexpdf is a command-line tool that converts Markdown files to professional PDF documents using LaTeX. It combines the simplicity of Markdown with the power of LaTeX typesetting.

---

## Document Structure

### File Organization

A typical book project structure:

```
book_name/
├── book_name.md          # Main content file
├── Makefile              # Build automation
├── chapters/             # Optional: separate chapter files
│   ├── chapter_1.md
│   ├── chapter_2.md
│   └── ...
├── literature/           # Source materials
├── rnd/                  # Research and development notes
└── archive/              # Previous versions
```

### Single File vs. Multiple Files

For most books, a single markdown file is recommended. The file should be named after the directory (e.g., `my_book.md` in `my_book/` directory).

---

## YAML Frontmatter (Metadata)

The metadata block appears at the very beginning of the file, enclosed in `---` delimiters.

### Complete Metadata Template

```yaml
---
# =============================================================================
# COMMON METADATA (used by both mdtexpdf and mdaudiobook)
# =============================================================================
title: "Book Title"
subtitle: "Optional Subtitle"
author: "Author Name"
email: "author@example.com"
date: "January 2026"
description: "Brief description of the book"
language: "en"

# =============================================================================
# PDF-SPECIFIC METADATA (mdtexpdf only)
# =============================================================================
# Document structure
format: "book"                       # "article", "book", or "report"
section: "category"                  # Section identifier

# Section numbering
no_numbers: true                     # Disable section numbering (cleaner look)

# Table of contents
toc: true                            # Enable table of contents
toc_depth: 2                         # TOC depth (1-6)

# Headers and footers
header_footer_policy: "all"          # "default", "partial", or "all"
footer: "© 2026 Author Name. All rights reserved."
pageof: true                         # Show "Page X of Y"
date_footer: true                    # Include date in footer

# =============================================================================
# PROFESSIONAL BOOK FEATURES
# =============================================================================
half_title: false                    # Half-title page before full title
copyright_page: true                 # Include copyright page
dedication: "To those who seek truth."
epigraph: "A fitting quote for the book."
epigraph_source: "Author of Quote, Source"
chapters_on_recto: true              # Chapters start on right-hand pages
drop_caps: true                      # Decorative first letters

# Publisher information
publisher: "Publisher Name"
copyright_year: 2026
edition: "First Edition"
edition_date: "January 2026"
printing: "First Printing, January 2026"
publisher_address: "Publisher Address"
publisher_website: "www.publisher.com"

# =============================================================================
# AUDIO-SPECIFIC METADATA (mdaudiobook only - optional)
# =============================================================================
genre: "Non-Fiction"
narrator_voice: "en-us-standard-c"
reading_speed: "medium"
narrator: "AI Narrator"
---
```

### Metadata Field Reference

#### Document Information

| Field | Description | Example |
|-------|-------------|---------|
| `title` | Book title | `"Book Title"` |
| `subtitle` | Subtitle (book format, shown under title) | `"A Study in the Subject"` |
| `author` | Author name | `"Author Name"` |
| `email` | Author email (book format, next to author) | `"author@example.com"` |
| `date` | Publication date | `"January 2026"` |
| `description` | Brief description | `"Exploring data analysis..."` |
| `language` | ISO language code | `"en"` |

#### Document Format

| Field | Options | Description |
|-------|---------|-------------|
| `format` | `"article"`, `"book"`, `"report"` | Document type |
| `no_numbers` | `true`, `false` | Disable section numbering |
| `toc` | `true`, `false` | Enable table of contents |
| `toc_depth` | `1-6` | How deep the TOC goes |

#### Headers and Footers

| Field | Options | Description |
|-------|---------|-------------|
| `header_footer_policy` | `"default"`, `"partial"`, `"all"` | When headers/footers appear |
| `footer` | Any string | Custom footer text |
| `no_footer` | `true`, `false` | Disable footer completely |
| `pageof` | `true`, `false` | Show "Page X of Y" |
| `date_footer` | `true`, `false` | Include date in footer |

**Header/Footer Policy:**

- `"default"`: No headers/footers on title, part, or chapter pages
- `"partial"`: Headers/footers on part and chapter pages, but NOT on title page
- `"all"`: Headers/footers on ALL pages including title, part, and chapter pages

#### Professional Book Features

| Field | Description |
|-------|-------------|
| `half_title` | Half-title page before full title |
| `copyright_page` | Include copyright page |
| `dedication` | Dedication text |
| `epigraph` | Opening quote for the book |
| `epigraph_source` | Attribution for the epigraph |
| `chapters_on_recto` | Chapters start on right-hand (odd) pages |
| `drop_caps` | Decorative large first letters |
| `publisher` | Publisher name |
| `copyright_year` | Copyright year |
| `edition` | Edition name |
| `edition_date` | Edition date |
| `printing` | Printing information |
| `publisher_address` | Publisher address |
| `publisher_website` | Publisher website |

---

## Content Formatting

### Headings Structure

```markdown
# Part 1: Part Title

## Chapter 1: Chapter Title

### Section Heading

#### Subsection Heading
```

**Rules:**

- Use `#` for Parts
- Use `##` for Chapters
- Use `###` and below for sections within chapters
- Do NOT add subtitles, epigraphs, or italic text directly under part or chapter headings
- Leave a blank line after every heading before content begins

### Paragraphs

- Leave an empty line between paragraphs
- Leave an empty line between a paragraph and a bullet list
- Leave an empty line between a heading and the first line of content

**Correct:**

```markdown
## Chapter 1: Introduction

This is the first paragraph of the chapter.

This is the second paragraph, separated by a blank line.
```

**Incorrect:**

```markdown
## Chapter 1: Introduction
This is the first paragraph with no blank line after heading.
This is another paragraph with no separation.
```

### Bullet Lists

Use `-` for bullet points, not `*`.

**Correct format with proper spacing:**

```markdown
The following points are important:

- First point

- Second point

- Third point

The list is now complete.
```

**Note:** Each list item should have a blank line before and after it for proper rendering.

### Numbered Lists

```markdown
The steps are as follows:

1.  First step

2.  Second step

3.  Third step

Continue with the explanation.
```

**Note:** Use two spaces after the number and period for proper alignment.

### Emphasis

```markdown
This is **bold text** for emphasis.

This is *italic text* for titles or foreign words.

This is `inline code` for technical terms.
```

### Block Quotes

```markdown
> This is a block quote. It can span multiple lines and is useful
> for quoting sources or highlighting important passages.
```

### Horizontal Rules

Do NOT use `---` or `***` to separate sections. These are reserved for metadata delimiters. Instead, use blank lines and headings for section separation.

### Special Characters

Do NOT use the em dash symbol `—` as a comma. Instead, use proper comma syntax.

**Incorrect:**

```markdown
The candidates—now colleagues—listened carefully.
```

**Correct:**

```markdown
The candidates, now colleagues, listened carefully.
```

---

## Mathematics (LaTeX)

### Inline Math

Use single dollar signs for inline mathematics:

```markdown
The equation $E = mc^2$ shows the relationship between energy and mass.

The variable $x$ represents the unknown value.
```

### Display Math (Block Equations)

Use double dollar signs with blank lines before and after:

```markdown
The quadratic formula is:

$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

This gives us the roots of any quadratic equation.
```

### Important Rules for Math

1. All **block-level math** (display equations) must be enclosed in `$$ ... $$`
2. All **inline math** must be enclosed in single `$...$`
3. Do NOT place raw LaTeX outside of `$` or `$$` delimiters
4. Leave a blank line before and after display equations
5. Use proper LaTeX syntax for all mathematical symbols

### Common Math Examples

**Fractions:**

```markdown
$$\frac{a}{b}$$
```

**Subscripts and Superscripts:**

```markdown
$x^2$ for squared, $x_i$ for subscript
```

**Greek Letters:**

```markdown
$\alpha$, $\beta$, $\gamma$, $\delta$, $\omega$, $\pi$
```

**Integrals:**

```markdown
$$\int_{a}^{b} f(x) \, dx$$
```

**Summations:**

```markdown
$$\sum_{i=1}^{n} x_i$$
```

**Square Roots:**

```markdown
$$\sqrt{x^2 + y^2}$$
```

**Matrices:**

```markdown
$$\begin{pmatrix} a & b \\ c & d \end{pmatrix}$$
```

**Aligned Equations:**

```markdown
$$\begin{align}
a &= b + c \\
d &= e + f
\end{align}$$
```

### Chemistry

mdtexpdf supports chemical formulas using the mhchem package with the `\ce{}` command.

#### Inline Chemical Formulas

For chemical formulas within text, use `$\ce{...}$`:

```markdown
Water ($\ce{H2O}$) is essential for life.

Acetic acid ($\ce{CH3COOH}$) is the active component of vinegar.

The hydroxide ion ($\ce{OH-}$) is a common base.
```

#### Chemical Equations (Block)

For standalone chemical equations, use `$$\ce{...}$$`:

```markdown
The combustion of methane:

$$\ce{CH4 + 2O2 -> CO2 + 2H2O}$$

Acid-base neutralization:

$$\ce{HCl + NaOH -> NaCl + H2O}$$
```

#### Chemical Reaction Arrows

| Arrow | Syntax | Meaning |
|-------|--------|---------|
| `->` | `\ce{A -> B}` | Forward reaction |
| `<-` | `\ce{A <- B}` | Reverse reaction |
| `<->` | `\ce{A <-> B}` | Resonance |
| `<=>` | `\ce{A <=> B}` | Equilibrium |
| `<=>>` | `\ce{A <=>> B}` | Equilibrium (forward favored) |
| `<<=>` | `\ce{A <<=> B}` | Equilibrium (reverse favored) |

**Equilibrium example:**

```markdown
$$\ce{CH3COOH <=> CH3COO- + H+}$$
```

#### Common Chemical Formulas

```markdown
# Simple molecules
$\ce{H2O}$, $\ce{CO2}$, $\ce{O2}$, $\ce{N2}$, $\ce{H2}$

# Acids
$\ce{HCl}$, $\ce{H2SO4}$, $\ce{HNO3}$, $\ce{CH3COOH}$

# Bases
$\ce{NaOH}$, $\ce{KOH}$, $\ce{Ca(OH)2}$, $\ce{NH3}$

# Salts
$\ce{NaCl}$, $\ce{CaCO3}$, $\ce{Na2SO4}$

# Ions
$\ce{H+}$, $\ce{OH-}$, $\ce{Na+}$, $\ce{Cl-}$, $\ce{SO4^2-}$, $\ce{CO3^2-}$

# Complex formulas
$\ce{Ca(CH3COO)2}$, $\ce{Al2O3}$, $\ce{Fe2O3}$, $\ce{Fe3O4}$
```

#### Charges and Oxidation States

```markdown
# Ionic charges
$\ce{Fe^2+}$, $\ce{Fe^3+}$, $\ce{O^2-}$

# Oxidation states
$\ce{Fe^{II}}$, $\ce{Fe^{III}}$

# Radical dot
$\ce{Cl.}$
```

#### Stoichiometry

```markdown
$$\ce{2H2 + O2 -> 2H2O}$$

$$\ce{6CO2 + 6H2O -> C6H12O6 + 6O2}$$
```

#### State Symbols

```markdown
$\ce{H2O (l)}$    # liquid
$\ce{NaCl (s)}$   # solid
$\ce{CO2 (g)}$    # gas
$\ce{NaCl (aq)}$  # aqueous
```

#### Important: Avoid Unicode Subscripts/Superscripts

**Do NOT use Unicode subscript/superscript characters** in chemical formulas. While mdtexpdf can render them, the `\ce{}` command produces better typography.

| Incorrect (Unicode) | Correct (mhchem) |
|---------------------|------------------|
| `H₂O` | `$\ce{H2O}$` |
| `CO₂` | `$\ce{CO2}$` |
| `CH₃COOH` | `$\ce{CH3COOH}$` |
| `H⁺` | `$\ce{H+}$` |
| `OH⁻` | `$\ce{OH-}$` |
| `Fe²⁺` | `$\ce{Fe^2+}$` |

The mhchem package automatically handles subscripts for numbers and superscripts for charges, producing professional chemical typesetting.

---

### Unicode Support and Special Symbols

mdtexpdf supports various Unicode characters, but for best results, use LaTeX commands when available.

#### Supported Unicode Symbols (pdfLaTeX)

**Greek Letters** - Use directly or via LaTeX:

```markdown
α, β, γ, δ, ε, ζ, η, θ, ι, κ, λ, μ, ν, ξ, π, ρ, σ, τ, υ, φ, χ, ψ, ω
Γ, Δ, Θ, Λ, Ξ, Π, Σ, Υ, Φ, Ψ, Ω

Or in math mode: $\alpha$, $\beta$, $\gamma$, etc.
```

**Mathematical Symbols** - Supported in text and math:

```markdown
∞ (infinity), ∫ (integral), ∑ (sum), ∏ (product), √ (sqrt)
∂ (partial), ∇ (nabla), ∈ (in), ∉ (not in), ⊂ (subset)
≠ (not equal), ≤ (leq), ≥ (geq), ≈ (approx), ≡ (equiv)
```

**Arrows** - Supported directly:

```markdown
→ (right arrow), ← (left arrow), ↔ (left-right arrow)
⇒ (implies), ⇐ (implied by), ⇔ (iff)
⇌ (equilibrium/reversible reaction)
```

**Subscripts and Superscripts** - Supported but LaTeX preferred:

```markdown
# These work but are not recommended:
₀₁₂₃₄₅₆₇₈₉ (subscript digits)
⁰¹²³⁴⁵⁶⁷⁸⁹ (superscript digits)
⁺⁻ (superscript plus/minus)
₊₋ (subscript plus/minus)

# Preferred approach in math mode:
$x_0$, $x_1$, $x^2$, $x^{-1}$
```

#### Best Practices for Special Content

| Content Type | Recommended Approach |
|--------------|---------------------|
| Chemical formulas | `$\ce{H2O}$` (mhchem) |
| Math expressions | `$x^2 + y^2$` (LaTeX math) |
| Greek in text | Direct Unicode: α, β, γ |
| Greek in math | `$\alpha$`, `$\beta$` |
| Arrows in text | Direct Unicode: → |
| Arrows in math | `$\rightarrow$` |
| Subscript numbers | `$x_1$` not `x₁` |
| Superscript numbers | `$x^2$` not `x²` |

#### CJK (Chinese, Japanese, Korean) Support

For documents containing CJK characters, mdtexpdf automatically switches to XeLaTeX with xeCJK support. No special configuration needed.

```markdown
中文文本 (Chinese)
日本語テキスト (Japanese)
한국어 텍스트 (Korean)
```

---

## Code Blocks

### Inline Code

```markdown
Use the `print()` function to display output.
```

### Code Blocks with Syntax Highlighting

````markdown
```python
def hello_world():
    print("Hello, World!")
```
````

Supported languages include: python, javascript, bash, c, cpp, java, rust, go, and many more.

---

## Tables

```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

For alignment:

```markdown
| Left | Center | Right |
|:-----|:------:|------:|
| L    |   C    |     R |
```

---

## Images

```markdown
![Alt text](path/to/image.png)
```

For images with captions:

```markdown
![This is the caption](path/to/image.png)
```

---

## Book Structure Example

### Complete Book Template

```markdown
---
title: "Book Title"
subtitle: "Subtitle Here"
author: "Author Name"
date: "January 2026"
description: "Book description"

format: "book"
no_numbers: true
toc: true
header_footer_policy: "all"
footer: "© 2026 Author Name. All rights reserved."
pageof: true
date_footer: true

copyright_page: true
dedication: "To the seekers of truth."
epigraph: "A fitting quote."
epigraph_source: "Quote Author, Source"
drop_caps: true
publisher: "Publisher Name"
copyright_year: 2026
---

# Preface

Opening remarks about the book. Why it was written, who it is for, and how to read it.



# Part 1: First Major Section


## Chapter 1: Opening Chapter

Introduction to the topic. Set the stage for what follows.

### First Section

Content of the first section.

### Second Section

Content of the second section.


## Chapter 2: Building on the Foundation

Continue developing the ideas.



# Part 2: Second Major Section


## Chapter 3: New Territory

Explore new concepts.


## Chapter 4: Going Deeper

More detailed examination.



# Part 3: Practical Applications


## Chapter 5: Putting It into Practice

How to apply the concepts.


## Chapter 6: Conclusion

Final thoughts and summary.



# Appendix A: Additional Resources

Supplementary material.


# Glossary

**Term One**: Definition of the first term goes here.

**Term Two**: Definition of the second term with more detail.

**Term Three**: Another definition explaining this concept.


# Acknowledgments

Recognition of contributors and sources.


# About the Author

Author biography and background.
```

### Back Matter Formatting

The back matter sections (Glossary, Acknowledgments, About the Author) use simple markdown patterns that render well:

**Glossary entries** use bold terms followed by definitions:
```markdown
**Acetic acid**: The active component of vinegar. Chemical formula CH3COOH.

**Data analysis**: The practice of dispersing substances into clouds to modify precipitation.
```

**Acknowledgments** and **About the Author** are regular prose sections that appear after the glossary.

---

## Build Commands

### Using Makefile

Most book projects include a Makefile with these targets:

```bash
make build           # Convert markdown to PDF
make build-audiobook # Convert to audiobook (.m4b)
make build-all       # Build both formats
make publish         # Publish to library
make upload          # Build and publish
make clean           # Remove generated files
```

### Direct Command

```bash
mdtexpdf convert book_name.md
```

With options:

```bash
mdtexpdf convert book_name.md -t "Title" -a "Author" --no-numbers
```

---

## Best Practices

### Writing Style

1. **Blank lines matter** - Always leave blank lines between paragraphs, before/after lists, and after headings
2. **Use proper list formatting** - Blank lines between list items
3. **No raw LaTeX** - Keep all math within `$` or `$$` delimiters
4. **Consistent heading levels** - Parts (`#`), Chapters (`##`), Sections (`###`)

### Metadata

1. Always include: `title`, `author`, `date`, `description`
2. Use `format: "book"` for books, `format: "article"` for papers
3. Set `no_numbers: true` for cleaner chapter headings
4. Use `header_footer_policy: "all"` for consistent professional appearance

### Organization

1. Use the standard directory structure
2. Keep research notes in `rnd/`
3. Store source materials in `literature/`
4. Archive old versions in `archive/`

### Common Mistakes to Avoid

1. Missing blank lines after headings
2. Using `*` instead of `-` for bullets
3. Using `—` (em dash) instead of `, ` (comma)
4. Placing raw LaTeX outside math delimiters
5. Using `---` or `***` for section breaks
6. Adding subtitles or epigraphs directly under part/chapter headings
7. Forgetting blank lines around display equations

---

## Troubleshooting

### Prerequisites Check

```bash
mdtexpdf check
```

### Common Issues

1. **YAML parsing errors**: Check indentation and quote usage
2. **Missing metadata**: Ensure required fields are present
3. **LaTeX errors**: Check math syntax within `$` delimiters
4. **Long equations overflow**: Use `\\` for line breaks or `\begin{multline*}` environment

### Required Software

- Pandoc
- LaTeX distribution (TexLive, MacTeX, or MiKTeX)
- For CJK support: Noto Sans CJK fonts

---

## EPUB Generation

mdtexpdf can generate EPUB3 ebooks using the same markdown source as PDF output.

### Basic Usage

```bash
# Generate EPUB
mdtexpdf convert document.md --epub

# With metadata from YAML frontmatter
mdtexpdf convert document.md --read-metadata --epub
```

### EPUB Features

The EPUB output includes:

- **Cover with Text Overlay**: Automatically generated from your cover image with title, subtitle, and author
- **Title Page**: Custom title page (no publisher info)
- **Copyright Page**: Full copyright information
- **Dedication**: Separate page for dedication
- **Epigraph**: Separate page for opening quote
- **Table of Contents**: Automatic TOC named "Contents"
- **Chapter Structure**: Each chapter as a separate section

### Cover Generation

If ImageMagick is installed, mdtexpdf generates an EPUB cover with text overlay:

```yaml
---
cover_image: "img/cover.jpg"          # Background image
cover_title_color: "white"            # Title text color (default: white)
cover_subtitle_show: true             # Include subtitle on cover
cover_overlay_opacity: 0.3            # Dark overlay for readability (0-1)
---
```

The cover generator:
- Adds a semi-transparent overlay for text readability
- Centers title and subtitle with automatic text wrapping
- Places author name at the bottom
- Uses DejaVu Serif fonts (Bold for title, Italic for subtitle)

**Install ImageMagick:**

```bash
# Debian/Ubuntu
sudo apt install imagemagick

# macOS
brew install imagemagick
```

If ImageMagick is not available, the original cover image is used without text overlay.

### Front Matter Order

EPUB front matter appears in this order (matching PDF):

1. Cover (generated or original image)
2. Title Page
3. Copyright Page
4. Authorship & Support (if `author_pubkey` is set)
5. Dedication (if set)
6. Epigraph (if set)
7. Table of Contents
8. Book content

### Metadata for EPUB

All standard metadata fields work for EPUB:

```yaml
---
title: "Book Title"
subtitle: "Subtitle"
author: "Author Name"
date: "January 2026"
description: "Book description"       # Used as EPUB description
language: "en"                        # EPUB language code

# Front matter
copyright_page: true
dedication: "To the readers."
epigraph: "A meaningful quote."
epigraph_source: "Quote Author"

# Copyright details
publisher: "Publisher Name"
copyright_year: 2026
edition: "First Edition"

# Cover
cover_image: "img/cover.jpg"
cover_title_color: "white"
cover_overlay_opacity: 0.3

# TOC
toc: true
toc_depth: 2
---
```

### Building Both Formats

Use a Makefile to build PDF and EPUB together:

```makefile
.PHONY: all build build-epub clean

MDTEXPDF := mdtexpdf

# Default: build both formats
all: clean build build-epub
	@echo "Built PDF and EPUB"

# Build PDF
build:
	@dir_name=$$(basename $$(pwd)); \
	$(MDTEXPDF) convert "$$dir_name.md" --read-metadata

# Build EPUB  
build-epub:
	@dir_name=$$(basename $$(pwd)); \
	$(MDTEXPDF) convert "$$dir_name.md" --read-metadata --epub

# Clean generated files
clean:
	@dir_name=$$(basename $$(pwd)); \
	rm -f "$$dir_name.pdf" "$$dir_name.epub"
```

Run with:

```bash
make          # Builds both PDF and EPUB
make build    # PDF only
make build-epub  # EPUB only
make clean    # Remove generated files
```

### Differences from PDF

| Feature | PDF | EPUB |
|---------|-----|------|
| LaTeX math | Full support | Basic (converted to images or MathML) |
| Chemical formulas | Full mhchem | Limited |
| Drop caps | Supported | Not supported |
| Headers/footers | Supported | Not applicable |
| Page numbers | Supported | E-reader dependent |
| Cover | First page of document | Separate cover image |

For best results, keep complex LaTeX to a minimum in documents intended for EPUB.

---

## Quick Reference Card

### Headings

```
# Part Title
## Chapter Title
### Section
#### Subsection
```

### Text Formatting

```
**bold**
*italic*
`code`
```

### Math

```
Inline: $x^2$
Display: $$\frac{a}{b}$$
```

### Chemistry

```
Inline: $\ce{H2O}$, $\ce{CO2}$, $\ce{CH3COOH}$
Ions: $\ce{H+}$, $\ce{OH-}$, $\ce{Fe^2+}$
Reaction: $$\ce{2H2 + O2 -> 2H2O}$$
Equilibrium: $$\ce{A <=> B}$$
```

### Lists

```
- Bullet item (with blank lines around)

1.  Numbered item (with blank lines around)
```

### Metadata Essentials

```yaml
---
title: "Title"
author: "Author"
format: "book"
no_numbers: true
toc: true
header_footer_policy: "all"
---
```

---

*This guide is a comprehensive reference for writing books with mdtexpdf. For the latest features and updates, consult the mdtexpdf README and METADATA documentation.*
