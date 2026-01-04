# YAML Frontmatter Metadata Guide

## Overview

mdtexpdf uses YAML frontmatter for document metadata. This standardized format is shared with mdaudiobook for unified metadata handling across both tools.

## Template Structure

The metadata is organized into four distinct sections:

1. **Common Metadata** - Used by both mdtexpdf and mdaudiobook
2. **PDF-Specific Metadata** - Used only by mdtexpdf
3. **Professional Book Features** - Book format front/back matter options
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
| `author` | string | Author name | "Example Press" |
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
author: "Example Press"
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
