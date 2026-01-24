<h1> Markdown to PDF with LaTeX (mdtexpdf) </h1>

<h2> Table of Contents</h2>

- [Introduction](#introduction)
- [Repository Structure](#repository-structure)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Converting Markdown to PDF](#converting-markdown-to-pdf)
  - [Command-Line Options](#command-line-options)
  - [Header/Footer Policy](#headerfooter-policy)
  - [Metadata Reference](#metadata-reference)
- [Professional Book Features](#professional-book-features)
  - [Front Matter Pages](#front-matter-pages)
  - [Cover System](#cover-system)
  - [Authorship & Support](#authorship--support)
  - [Drop Caps](#drop-caps)
- [LaTeX Math & Chemistry](#latex-math--chemistry)
- [Documentation](#documentation)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Introduction

mdtexpdf is a command-line tool designed to simplify the process of creating professional PDF documents from Markdown files using LaTeX. It combines the simplicity of Markdown with the power of LaTeX, allowing you to include complex mathematical equations, custom formatting, and professional typesetting in your documents.

## Repository Structure

```
mdtexpdf/
├── mdtexpdf.sh              # Main conversion script
├── Makefile                 # Build, test, and Docker automation
├── Dockerfile               # Docker image definition
├── CHANGELOG.md             # Version history
├── metadata_template.yaml   # Metadata template for new documents
├── templates/
│   └── Makefile.book        # Makefile template for book projects
├── lib/                     # Modular components
│   ├── core.sh              # Common utilities and logging
│   └── check.sh             # Prerequisites verification
├── tests/
│   └── run_tests.sh         # Automated test suite
├── docs/
│   ├── mdtexpdf_guide.md    # Comprehensive user guide
│   ├── METADATA.md          # Complete metadata field reference
│   ├── AUTHORSHIP.md        # Authorship verification guide
│   ├── ROADMAP.md           # Planned features and improvements
│   └── syntax.md            # Math and chemistry syntax reference
├── filters/
│   ├── book_structure.lua       # Part/chapter/special page handling
│   ├── drop_caps_filter.lua     # Decorative first letters
│   └── long_equation_filter.lua # Equation line-breaking
├── examples/                # Example documents with PDFs
└── .github/workflows/       # CI/CD automation
```

## Features

### Core Features
- **Markdown to PDF Conversion**: Convert Markdown files to professionally formatted PDFs
- **Markdown to EPUB Conversion**: Generate EPUB3 ebooks with cover, front matter, and TOC
- **LaTeX Math Support**: Inline (`$...$`) and display (`$$...$$`) equations
- **Chemical Equations**: Full mhchem support (`\ce{H2O}`, `\ce{CH3COOH <=> CH3COO- + H+}`)
- **Code Highlighting**: Syntax highlighting for code blocks
- **Tables and Figures**: Full support for Markdown tables and images
- **YAML Frontmatter**: Comprehensive metadata configuration

### Professional Book Features
- **Front Matter Pages**: Half-title, copyright page, dedication, and epigraph
- **Cover System**: Front and back cover images with text overlay
- **Authorship & Support**: Embedded PGP key verification and donation wallet addresses
- **Drop Caps**: Decorative first letters for chapter openings
- **Chapter Formatting**: Chapters on recto pages, part pages, special sections

### Typography & Formatting
- **Header/Footer Policy**: Three-tier system (default, partial, all) for page headers/footers
- **Unicode Support**: Subscripts (₀₁₂₃), superscripts (⁰¹²³⁺⁻), chemistry arrows (⇌)
- **CJK Support**: Chinese, Japanese, and Korean characters
- **Automatic Line Breaking**: Long equations wrap to fit page width
- **Section Numbering Control**: Enable or disable numbered sections

### Usability
- **Automatic Prerequisites Check**: Verifies required software and packages
- **Multiple PDF Engines**: pdfLaTeX, XeLaTeX, LuaLaTeX with auto-detection
- **Easy Installation**: Simple Makefile-based install

## Prerequisites

- [Pandoc](https://pandoc.org/installing.html) - Markdown to LaTeX conversion
- LaTeX distribution:
  - Linux: TexLive (`texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-science`)
  - macOS: MacTeX or BasicTeX
  - Windows: MiKTeX
- For CJK support: Noto Sans CJK fonts (`fonts-noto-cjk` on Debian/Ubuntu)

## Installation

### Option 1: Docker (Recommended - No Dependencies)

The easiest way to use mdtexpdf is via Docker, which includes all dependencies:

```bash
# Run directly with Docker
docker run --rm -v $(pwd):/work uclitools/mdtexpdf convert book.md --read-metadata

# Or create an alias for convenience
alias mdtexpdf='docker run --rm -v $(pwd):/work uclitools/mdtexpdf'
mdtexpdf convert book.md --read-metadata
mdtexpdf convert book.md --read-metadata --epub
```

### Option 2: Native Installation

Requires Pandoc and LaTeX to be installed first (see Prerequisites).

```bash
git clone https://github.com/ucli-tools/mdtexpdf.git
cd mdtexpdf
make
```

This installs `mdtexpdf` to `/usr/local/bin/` for system-wide access.

## Usage

### Converting Markdown to PDF

```bash
mdtexpdf convert document.md                    # Basic conversion
mdtexpdf convert document.md output.pdf         # Specify output filename
mdtexpdf convert -t "Title" -a "Author" doc.md  # With metadata
```

### Command-Line Options

**Global Options:**

| Option | Description |
|--------|-------------|
| `--version`, `-V` | Show version number |
| `--verbose`, `-v` | Enable verbose output |
| `--debug` | Enable debug output (includes verbose) |
| `--help`, `-h` | Show help information |

**Convert Options:**

| Option | Description |
|--------|-------------|
| `-t, --title` | Document title |
| `-a, --author` | Author name |
| `-d, --date` | Document date |
| `-f, --footer` | Custom footer text |
| `--no-footer` | Disable footer |
| `--no-numbers` | Disable section numbering |
| `--header-footer-policy` | `default`, `partial`, or `all` |
| `--epub` | Output EPUB format instead of PDF |

### Header/Footer Policy

- **`default`**: No headers/footers on title, part, or chapter pages
- **`partial`**: Headers/footers on part/chapter pages, not title page
- **`all`**: Headers/footers on all pages

### Metadata Reference

Configure documents using YAML frontmatter:

```yaml
---
title: "Document Title"
author: "Author Name"
subtitle: "Optional subtitle"           # Book format only
date: "January 2026"
format: "book"                          # "article" or "book"
toc: true
header_footer_policy: "all"
footer: "© 2026 Author. All rights reserved."
pageof: true                            # Page X of Y
---
```

For complete metadata reference, see [docs/METADATA.md](docs/METADATA.md).

## Professional Book Features

mdtexpdf supports professional book publishing with front matter, covers, and authorship verification.

### Front Matter Pages

Create professional front matter with these metadata fields:

```yaml
---
format: "book"
half_title: true                        # Title-only page before main title
copyright_page: true                    # Copyright and publishing info
dedication: "To those who inspire."     # Dedication page
epigraph: "A meaningful quote..."       # Opening quote
epigraph_source: "Author Name"          # Quote attribution

# Copyright page details
publisher: "Publisher Name"
copyright_year: 2026
edition: "First Edition"
printing: "First Printing, January 2026"
---
```

### Cover System

Add front and back cover images with text overlay:

```yaml
---
# Front cover (première de couverture)
cover_image: "img/cover.jpg"            # Background image
cover_title_color: "white"              # Title text color
cover_subtitle_show: true               # Show subtitle on cover
cover_author_position: "bottom"         # Author position: top, center, bottom
cover_overlay_opacity: 0.3              # Dark overlay for readability (0-1)

# Back cover (quatrième de couverture)
back_cover_image: "img/back.jpg"
back_cover_content: "quote"             # quote, summary, or custom
back_cover_quote: "A compelling excerpt from the book..."
back_cover_quote_source: "From Chapter 1"
back_cover_author_bio: true
back_cover_author_bio_text: "Author bio text here."
---
```

Cover images are auto-detected in `img/`, `images/`, or project root if not specified.

### Authorship & Support

Embed cryptographic authorship verification and donation addresses for an "open source book" that can prove authorship without relying on external services:

```yaml
---
# Authorship verification (PGP/GPG key fingerprint)
author_pubkey: "4A2B 8C3D E9F1 7A6B 2C4D 9E8F 1A3B 5C7D 8E9F 0A1B"
author_pubkey_type: "PGP"

# Support the author (multiple wallets)
donation_wallets:
  - type: "Bitcoin"
    address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
  - type: "Ethereum"
    address: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F"
  - type: "Monero"
    address: "48daf1rG3hE1Txap..."
---
```

This creates an "Authorship & Support" page after the copyright page. See [docs/AUTHORSHIP.md](docs/AUTHORSHIP.md) for the complete guide on setting up PGP keys.

### Drop Caps

Enable decorative first letters for chapter openings:

```yaml
---
drop_caps: true
---
```

The first letter of each chapter becomes a large decorative capital.

## EPUB Generation

mdtexpdf can generate EPUB3 ebooks alongside PDFs using the same source file.

### Basic EPUB Conversion

```bash
mdtexpdf convert document.md --epub              # Generate EPUB
mdtexpdf convert document.md --read-metadata --epub  # With YAML metadata
```

### EPUB Features

- **Automatic Cover Generation**: If ImageMagick is installed, generates cover with title/subtitle/author overlay
- **Front Matter**: Title page, copyright, dedication, and epigraph as separate pages
- **Table of Contents**: Automatic TOC generation with customizable depth
- **Same Metadata**: Uses the same YAML frontmatter as PDF output

### Cover Generation

EPUB covers are automatically generated from your cover image with text overlay:

```yaml
---
cover_image: "img/cover.jpg"          # Background image
cover_title_color: "white"            # Title text color
cover_subtitle_show: true             # Include subtitle
cover_overlay_opacity: 0.3            # Dark overlay for readability
---
```

Requires ImageMagick (`convert` command). Install with:
```bash
sudo apt install imagemagick    # Debian/Ubuntu
brew install imagemagick        # macOS
```

### Project Makefile

For book projects, use a Makefile to build both formats:

```makefile
.PHONY: all build build-epub clean

MDTEXPDF := mdtexpdf

# Default: build PDF and EPUB
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

This assumes your markdown file matches the directory name (e.g., `my_book/my_book.md`).

A ready-to-use Makefile template is available at `templates/Makefile.book`.

## LaTeX Math & Chemistry

### Math Equations

```markdown
Inline: $E = mc^2$
Display: $$\int_{a}^{b} f(x) \, dx$$
```

### Chemical Formulas

Using mhchem package:
```markdown
Water: $\ce{H2O}$
Reaction: $$\ce{2H2 + O2 -> 2H2O}$$
Equilibrium: $$\ce{CH3COOH <=> CH3COO- + H+}$$
```

Unicode is also supported: H₂O, CO₂, Fe²⁺, ⇌

For complete syntax reference, see [docs/syntax.md](docs/syntax.md).

## Documentation

| Document | Description |
|----------|-------------|
| [docs/mdtexpdf_guide.md](docs/mdtexpdf_guide.md) | Comprehensive user guide |
| [docs/METADATA.md](docs/METADATA.md) | Complete metadata field reference |
| [docs/AUTHORSHIP.md](docs/AUTHORSHIP.md) | Authorship verification guide |
| [docs/syntax.md](docs/syntax.md) | Math and chemistry syntax reference |

## Examples

The `examples/` directory contains sample documents demonstrating various features:

- Basic Markdown with math equations
- Code highlighting and tables
- Chemical formulas

## Troubleshooting

```bash
mdtexpdf check    # Verify prerequisites
```

Common issues:
1. **Missing Pandoc**: Ensure Pandoc is installed and in PATH
2. **LaTeX errors**: Verify LaTeX distribution is complete
3. **Long equations**: Use `\\` for manual breaks or `\begin{multline*}...\end{multline*}`
4. **CJK characters**: Install `fonts-noto-cjk` package

## License

Apache 2.0 License - see [LICENSE](LICENSE) for details.

Free to use, modify, and distribute for any purpose.

