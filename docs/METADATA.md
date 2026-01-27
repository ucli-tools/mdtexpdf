# YAML Frontmatter Metadata Guide

## Overview

mdtexpdf uses YAML frontmatter for document metadata. This standardized format is shared with mdaudiobook for unified metadata handling across both tools.

## Output Formats

mdtexpdf can generate two output formats from the same source:

| Format | Command | Notes |
|--------|---------|-------|
| PDF | `mdtexpdf convert doc.md --read-metadata` | Full LaTeX support |
| EPUB | `mdtexpdf convert doc.md --read-metadata --epub` | EPUB3 ebook |

Most metadata fields apply to both formats. See the field reference tables for format-specific notes.

## Template Structure

The metadata is organized into four distinct sections:

1. **Common Metadata** - Used by both mdtexpdf and mdaudiobook (PDF and EPUB)
2. **PDF-Specific Metadata** - Used only by mdtexpdf PDF output
3. **Professional Book Features** - Book format front/back matter (PDF and EPUB)
4. **Audio-Specific Metadata** - Used only by mdaudiobook (ignored by mdtexpdf)

## Complete Template

```yaml
---
# =============================================================================
# COMMON METADATA (used by both mdtexpdf and mdaudiobook)
# =============================================================================
title: "Document Title"
author: "Author Name"
subtitle: "Optional subtitle shown under the title (book format front page)"
email: "author@example.com"
date: "2025-01-01"
description: "Brief description of the document content"
language: "en"

# =============================================================================
# PDF-SPECIFIC METADATA (mdtexpdf only)
# =============================================================================
# Document structure
format: "article"                    # article, book, report
section: "chapter_name"              # Section identifier
slug: "document-slug"                # URL-friendly identifier

# Table of contents
toc: true                           # Enable table of contents
toc_depth: 2                        # TOC depth (1-6)

# Section numbering
no_numbers: false                   # Disable section numbering (or use section_numbers: true)

# Headers and footers
header_footer_policy: "default"     # default, partial, all
footer: "© 2025 Author Name"        # Custom footer text
no_footer: false                    # Disable footer completely
pageof: true                        # Show "Page X of Y"
date_footer: "DD/MM/YY"            # Date format in footer
no_date: false                      # Disable date in footer

# Bibliography and citations
bibliography: "references.bib"      # Path to BibTeX file (or .md for simple format)
csl: "chicago-author-date.csl"      # Citation style (CSL file path)

# =============================================================================
# PROFESSIONAL BOOK FEATURES (mdtexpdf only - book format)
# =============================================================================
# Front matter pages (appear in this order)
half_title: true                    # Half-title page (title only, no author)
# [Title Page appears automatically]
copyright_page: true                # Copyright/colophon page
dedication: "To my family"          # Dedication page text
epigraph: "Quote text here"         # Epigraph page quote
epigraph_source: "Author Name"      # Attribution for epigraph

# Chapter formatting
chapters_on_recto: true             # Start chapters on odd (right) pages
drop_caps: true                     # Decorative first letter of chapters

# Copyright page information
publisher: "Publisher Name"         # Publisher name
isbn: "978-0-000-00000-0"          # ISBN number
edition: "First Edition"            # Edition text
edition_date: "January 2025"        # Edition date
printing: "First Printing, Jan 2025" # Printing information
copyright_year: 2025                # Copyright year
copyright_holder: "Author Name"     # Copyright holder (defaults to author)
publisher_address: |                # Publisher address (use | for multi-line)
  Publisher Name
  123 Publishing Lane
  City, State 12345
publisher_website: "https://publisher.com"  # Publisher website URL

# =============================================================================
# COVER SYSTEM (Première et Quatrième de Couverture)
# =============================================================================
# Front cover (première de couverture)
cover_image: "img/cover.jpg"        # Background image path (jpg, png, pdf)
cover_title_color: "white"          # Title text color (name or hex)
cover_subtitle_show: true           # Show subtitle on cover
cover_author_position: "bottom"     # Author position: top, center, bottom, none
cover_overlay_opacity: 0.4          # Dark overlay for readability (0-1)
cover_fit: "contain"                # Image fit: "contain" (keep ratio, may have bars) or "cover" (fill page, crop overflow)

# Back cover (quatrième de couverture)
back_cover_image: "img/back.jpg"    # Background image (can reuse front)
back_cover_content: "quote"         # Content type: quote, summary, custom
back_cover_quote: "Quote text..."   # Quote text (when content: quote)
back_cover_quote_source: "Ch. 5"    # Quote attribution
back_cover_summary: "Summary..."    # Summary text (when content: summary)
back_cover_text: "Custom text..."   # Custom text (when content: custom)
back_cover_author_bio: true         # Include author bio section
back_cover_author_bio_text: "Bio"   # Author biography text
back_cover_isbn_barcode: true       # Reserve space for ISBN barcode
back_cover_text_background: true    # Show subtle frosted rectangles behind text (default: true)
back_cover_text_background_opacity: 0.18  # Opacity of frosted rectangles (0.0-1.0, default: 0.18)
back_cover_text_color: "white"      # Text color on back cover (default: inherits cover_title_color)

# =============================================================================
# AUTHORSHIP & SUPPORT SYSTEM
# =============================================================================
# Author verification (PGP/GPG key for cryptographic authorship proof)
author_pubkey: "4A2B 8C3D E9F1..."  # Author's public key fingerprint
author_pubkey_type: "PGP"           # Key type: PGP, GPG, SSH

# Donation/support wallets (list of cryptocurrency addresses)
donation_wallets:
  - type: "Bitcoin"
    address: "bc1qxy2kgdygjrs..."
  - type: "Ethereum"
    address: "0x71C7656EC7ab88..."
  - type: "Monero"
    address: "48daf1rG3hE1Txap..."

# =============================================================================
# AUDIO-SPECIFIC METADATA (mdaudiobook only)
# =============================================================================
genre: "Educational"                # Audiobook genre
narrator_voice: "en-us-standard-c"  # TTS voice identifier
reading_speed: "medium"             # slow, medium, fast
narrator: "AI Narrator"             # Narrator name for metadata
---
```

## Field Reference

### Common Metadata

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `title` | string | Document title | "Bell's Theorem Analysis" |
| `author` | string | Author name | "Jane Smith" |
| `subtitle` | string | Optional subtitle shown under the title (book format front page) | "A Journey into Mathematical Psychology" |
| `email` | string | Optional author email shown next to author on book front page only | "author@example.com" |
| `date` | string | Publication date | "2025-01-01" |
| `description` | string | Brief description | "Mathematical exploration of Bell's theorem" |
| `language` | string | ISO language code | "en" |

### PDF-Specific Metadata

| Field | Type | Description | Options |
|-------|------|-------------|---------|
| `format` | string | Document format | "article", "book", "report" |
| `section` | string | Section identifier | Any string |
| `slug` | string | URL-friendly identifier | "bells-theorem" |
| `toc` | boolean | Enable table of contents | true, false |
| `toc_depth` | integer | TOC depth | 1-6 |
| `no_numbers` | boolean | Disable section numbering | true, false |
| `header_footer_policy` | string | Header/footer policy | "default", "partial", "all" |
| `footer` | string | Custom footer text | Any string |
| `no_footer` | boolean | Disable footer | true, false |
| `pageof` | boolean | Show "Page X of Y" | true, false |
| `date_footer` | string | Date format in footer | "DD/MM/YY", "MM/DD/YYYY" |
| `no_date` | boolean | Disable date in footer | true, false |

#### Bibliography & Citations

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `bibliography` | string | Path to bibliography file | "refs.bib", "refs.md" |
| `csl` | string | Citation style file (CSL) | "chicago-author-date.csl" |

See [SIMPLE_BIBLIOGRAPHY.md](SIMPLE_BIBLIOGRAPHY.md) for detailed bibliography documentation, including the human-readable Markdown bibliography format.

### Professional Book Features (book format only)

#### Front Matter Pages

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `half_title` | boolean | Half-title page (title only) | true, false |
| `copyright_page` | boolean | Copyright/colophon page | true, false |
| `dedication` | string | Dedication page text | "To my family" |
| `epigraph` | string | Epigraph quote text | "The unexamined life..." |
| `epigraph_source` | string | Epigraph attribution | "Socrates" |

#### Chapter Formatting

| Field | Type | Description | Options |
|-------|------|-------------|---------|
| `chapters_on_recto` | boolean | Start chapters on odd pages | true, false |
| `drop_caps` | boolean | Decorative first letter | true, false |

#### Copyright Page Information

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `publisher` | string | Publisher name | "Example Press" |
| `isbn` | string | ISBN number | "978-0-000-00000-0" |
| `edition` | string | Edition text | "First Edition" |
| `edition_date` | string | Edition date | "January 2025" |
| `printing` | string | Printing information | "First Printing, Jan 2025" |
| `copyright_year` | integer | Copyright year | 2025 |
| `copyright_holder` | string | Copyright holder | "Author Name" |
| `publisher_address` | string | Publisher address (use YAML \| for multi-line) | See template |
| `publisher_website` | string | Publisher website URL | "https://example.com" |

### Cover System (Première et Quatrième de Couverture)

#### Front Cover

| Field | Type | Description | Options/Example |
|-------|------|-------------|-----------------|
| `cover_image` | string | Background image path | "img/cover.jpg", "img/cover.pdf" |
| `cover_title_color` | string | Title text color | "white", "black", "#FFFFFF" |
| `cover_subtitle_show` | boolean | Show subtitle on cover | true, false |
| `cover_author_position` | string | Author name position | "top", "center", "bottom", "none" |
| `cover_overlay_opacity` | float | Dark overlay opacity (0-1) | 0.0 to 1.0 |
| `cover_fit` | string | Image scaling mode | "contain" (default), "cover" |

**Cover Fit Modes**:
- `contain` (default): Maintains aspect ratio. Image fits within page bounds; may show black bars on sides or top/bottom if aspect ratios differ.
- `cover`: Scales image to fill page completely (like CSS `background-size: cover`). Maintains aspect ratio but crops overflow. No black bars, but edges may be cropped.

**Auto-detection**: If `cover_image` is not specified, mdtexpdf searches for:
- `img/cover.{jpg,jpeg,png,pdf}`
- `images/cover.{jpg,jpeg,png,pdf}`
- `cover.{jpg,jpeg,png,pdf}`

**EPUB Cover Generation**: When generating EPUB with `--epub`, if ImageMagick is installed, mdtexpdf creates a cover image with text overlay (title, subtitle, author) using the cover settings above. The generated cover uses:
- Semi-transparent dark overlay for text readability
- Centered title with automatic text wrapping
- Subtitle at 60% width for two-line display
- Author name at bottom
- DejaVu Serif fonts (Bold for title, Italic for subtitle)

#### Back Cover

| Field | Type | Description | Options/Example |
|-------|------|-------------|-----------------|
| `back_cover_image` | string | Background image path | "img/back.jpg" |
| `back_cover_content` | string | Content type | "quote", "summary", "custom" |
| `back_cover_quote` | string | Quote text (when content: quote) | "This book changed..." |
| `back_cover_quote_source` | string | Quote attribution | "Chapter 5", "The Author" |
| `back_cover_summary` | string | Summary text (when content: summary) | "A comprehensive guide..." |
| `back_cover_text` | string | Custom text (when content: custom) | Any text |
| `back_cover_author_bio` | boolean | Include author bio section | true, false |
| `back_cover_author_bio_text` | string | Author biography text | "John is a researcher..." |
| `back_cover_isbn_barcode` | boolean | Reserve space for ISBN barcode | true, false |
| `back_cover_text_background` | boolean | Show frosted rectangles behind back cover text | true (default), false |
| `back_cover_text_background_opacity` | number | Opacity of frosted rectangles (0.0-1.0) | 0.18 (default) |
| `back_cover_text_color` | string | Text color on back cover (rectangle fill auto-inverts) | Inherits `cover_title_color`, default "white" |

**LaTeX and Math in Back Cover Text**: You can include inline LaTeX math in `back_cover_quote`, `back_cover_summary`, or `back_cover_text` using escaped backslashes:
```yaml
back_cover_text: "Euler's identity $e^{i\\pi} + 1 = 0$ reveals deep mathematical beauty."
```
Use `\\textit{}` for italics and other LaTeX commands. Note: backslashes must be doubled (`\\`) in YAML strings.

### Authorship & Support System

This system creates a dedicated "Authorship & Support" page after the copyright page, providing:
- Cryptographic authorship verification via PGP/GPG public key
- Multiple donation wallet addresses for reader support

This follows an "open source book" philosophy where the book is self-contained and can prove authorship without relying on external websites.

#### Author Verification

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `author_pubkey` | string | Author's PGP/GPG key fingerprint | "4A2B 8C3D E9F1 7A6B..." |
| `author_pubkey_type` | string | Key type | "PGP", "GPG", "SSH" |

#### Donation Wallets

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `donation_wallets` | list | List of wallet objects | See below |
| `donation_wallets[].type` | string | Cryptocurrency name | "Bitcoin", "Ethereum", "Monero" |
| `donation_wallets[].address` | string | Wallet address | "bc1qxy2kgdygjrs..." |

**Example:**
```yaml
donation_wallets:
  - type: "Bitcoin"
    address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
  - type: "Ethereum"
    address: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F"
  - type: "Monero"
    address: "48daf1rG3hE1Txap..."
```

**Output:** The "Authorship & Support" page appears after the copyright page and displays:
- Section header "AUTHORSHIP VERIFICATION" with the PGP key fingerprint
- Section header "SUPPORT THE AUTHOR" with each wallet type and address

### Audio-Specific Metadata

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `genre` | string | Audiobook genre | "Educational", "Science" |
| `narrator_voice` | string | TTS voice identifier | "en-us-standard-c" |
| `reading_speed` | string | Reading speed | "slow", "medium", "fast" |
| `narrator` | string | Narrator name | "AI Narrator" |

## Usage Examples

### Academic Paper
```yaml
---
title: "Quantum Entanglement in Bell's Theorem"
author: "Dr. Jane Smith"
date: "2025-01-15"
description: "A comprehensive analysis of quantum entanglement phenomena"
language: "en"

format: "article"
section: "physics"
no_numbers: false
toc: true
toc_depth: 3
footer: "© 2025 University Physics Department"
header_footer_policy: "default"

genre: "Educational"
narrator_voice: "en-us-standard-c"
reading_speed: "medium"
---
```

### Technical Documentation
```yaml
---
title: "API Reference Guide"
author: "Development Team"
date: "2025-01-15"
description: "Complete API documentation and examples"
language: "en"

format: "book"
section: "documentation"
toc: true
toc_depth: 4
no_numbers: false
header_footer_policy: "all"
footer: "© 2025 TechCorp - Internal Use Only"
pageof: true

genre: "Technical"
narrator_voice: "en-us-standard-b"
reading_speed: "slow"
---
```

### Professional Book (Full Front Matter)
```yaml
---
title: "The Unary Language"
subtitle: "Or why there is something instead of nothing"
author: "Author Name"
email: "author@example.com"
date: "January 2025"
description: "A philosophical exploration of mathematics and existence"
language: "en"

format: "book"
toc: true
toc_depth: 2
no_numbers: true
header_footer_policy: "all"
footer: "© 2025 Publisher Name | publisher.com. All rights reserved."
pageof: true
date_footer: true

# Professional book features
half_title: true
copyright_page: true
dedication: "To all seekers of mathematical truth."
epigraph: "No fact can hold or be real unless there is a sufficient reason why it is so."
epigraph_source: "Gottfried Wilhelm Leibniz"
chapters_on_recto: true
drop_caps: true

# Copyright page details
publisher: "Publisher Name"
isbn: "978-0-000-00000-0"
edition: "First Edition"
edition_date: "January 2025"
printing: "First Printing, January 2025"
copyright_year: 2025
copyright_holder: "Author Name"
publisher_address: |
  Publisher Name
  123 Publishing Lane
  City, State 12345
publisher_website: "https://publisher.com"
---
```

### Clean Document (No Numbering)
```yaml
---
title: "Philosophy of Mathematics"
author: "Jane Smith"
date: "2025-01-15"
description: "Philosophical exploration of mathematical foundations"
language: "en"

format: "article"
section: "philosophy"
no_numbers: true
toc: false
no_footer: true
header_footer_policy: "default"

genre: "Philosophy"
narrator_voice: "en-us-standard-a"
reading_speed: "medium"
---
```

### Professional Book with Covers and Authorship
```yaml
---
title: "Book Title"
subtitle: "A Subtitle for the Book"
author: "Author Name"
date: "January 2026"
description: "A comprehensive guide to the subject matter"
language: "en"

format: "book"
toc: true
toc_depth: 2
no_numbers: true
header_footer_policy: "all"
footer: "© 2026 Author Name. All rights reserved."
pageof: true
date_footer: true

# Professional book features
copyright_page: true
dedication: "To those who inspire."
epigraph: "Nature uses only the longest threads..."
epigraph_source: "Richard Feynman"
chapters_on_recto: true
drop_caps: true
publisher: "Publisher Name"
copyright_year: 2026
edition: "First Edition"

# Cover system
cover_image: "img/cover.pdf"
cover_title_color: "white"
cover_subtitle_show: true
cover_author_position: "bottom"
cover_overlay_opacity: 0.3

back_cover_image: "img/back.pdf"
back_cover_content: "quote"
back_cover_quote: "A compelling quote from the book that draws readers in."
back_cover_quote_source: "From the Preface"
back_cover_author_bio: true
back_cover_author_bio_text: "Author Name writes about topics of interest."

# Authorship & support
author_pubkey: "4A2B 8C3D E9F1 7A6B 2C4D 9E8F 1A3B 5C7D 8E9F 0A1B"
author_pubkey_type: "PGP"

donation_wallets:
  - type: "Bitcoin"
    address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
  - type: "Ethereum"
    address: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F"
  - type: "Monero"
    address: "48daf1rG3hE1Txap..."
---
```

## Migration from HTML Comments

If you have existing documents with HTML comment metadata, use the conversion script:

```bash
python convert_metadata.py /path/to/document.md
```

This will automatically convert HTML comments to YAML frontmatter while preserving all metadata values.

## Best Practices

1. **Always include common metadata** - title, author, date, description
2. **Use the 3-section structure** - Keep sections clearly separated with comments
3. **Comment unused fields** - Use `# field: value` for optional fields
4. **Validate YAML syntax** - Ensure proper indentation and formatting
5. **Test with both tools** - Verify metadata works with both mdtexpdf and mdaudiobook

## Troubleshooting

- **YAML parsing errors**: Check indentation and quote usage
- **Missing metadata**: Ensure required fields (title, author) are present
- **Boolean values**: Use `true`/`false`, not `yes`/`no`
- **Date formats**: Use ISO format (YYYY-MM-DD) for consistency
