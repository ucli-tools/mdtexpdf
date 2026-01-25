# Book Project Tutorial

Create a professional book with cover, front matter, chapters, and more.

## Project Structure

```
my-book/
├── book.md           # Main content
├── img/
│   ├── cover.jpg     # Front cover (auto-detected)
│   └── back.jpg      # Back cover (optional)
└── Makefile          # Build automation
```

## Step 1: Create Project Directory

```bash
mkdir my-book
cd my-book
mkdir img
```

## Step 2: Add Cover Image

Place a cover image at `img/cover.jpg` (or `cover.png`).

Recommended dimensions: 1600x2400 pixels (2:3 ratio)

mdtexpdf will automatically detect it and add text overlay with title/author.

## Step 3: Create Your Book

Create `book.md`:

```markdown
---
# === BASIC METADATA ===
title: "The Art of Writing"
subtitle: "A Complete Guide"
author: "Jane Smith"
date: "2026"
format: "book"

# === COVER ===
cover_image: "img/cover.jpg"
cover_overlay_opacity: 0.4
cover_title_color: "white"

# === FRONT MATTER ===
half_title: true
copyright_page: true
copyright_year: 2026
copyright_holder: "Jane Smith"
publisher: "Independent Press"
isbn: "978-0-000000-00-0"

dedication: "To all aspiring writers"
epigraph: "The first draft is just you telling yourself the story."
epigraph_source: "Terry Pratchett"

# === TABLE OF CONTENTS ===
toc: true
toc_depth: 2
---

# Part One: Getting Started

## Chapter 1: Why Write?

Every writer begins with a question: Why do I want to write?

For some, it's the desire to share stories. For others, it's to process experiences or preserve memories. Whatever your reason, understanding your motivation will guide your journey.

### Finding Your Voice

Your voice is what makes your writing uniquely yours. It's not something you create—it's something you discover.

## Chapter 2: The Writing Process

Writing is rewriting. This chapter explores the stages of creation.

### First Drafts

Give yourself permission to write badly. The first draft is about getting ideas on paper.

### Revision

This is where the real writing happens. Cut ruthlessly. Every word must earn its place.

# Part Two: Craft

## Chapter 3: Structure

A story needs bones. This chapter covers:

- Beginning, middle, end
- Scene structure
- Pacing

### The Three-Act Structure

Act One: Setup
Act Two: Confrontation  
Act Three: Resolution

## Chapter 4: Style

Style is how you say what you say.

### Show, Don't Tell

> The sun was setting.

versus

> Orange light spilled across the kitchen table, stretching shadows toward the door.

# Conclusion

Writing is a journey, not a destination. Keep writing.

---

## About the Author

Jane Smith is a writer and teacher with twenty years of experience.
```

## Step 4: Create Makefile (Optional)

Create `Makefile`:

```makefile
# Book project Makefile
BOOK = book
MDTEXPDF = mdtexpdf

.PHONY: all pdf epub clean

all: pdf epub

pdf: $(BOOK).pdf

epub: $(BOOK).epub

$(BOOK).pdf: $(BOOK).md img/cover.jpg
	$(MDTEXPDF) convert $(BOOK).md --read-metadata

$(BOOK).epub: $(BOOK).md img/cover.jpg
	$(MDTEXPDF) convert $(BOOK).md --read-metadata --epub

clean:
	rm -f $(BOOK).pdf $(BOOK).epub *.aux *.log *.out *.toc

view: pdf
	xdg-open $(BOOK).pdf 2>/dev/null || open $(BOOK).pdf
```

## Step 5: Build Your Book

### Build PDF:

```bash
make pdf
# or
mdtexpdf convert book.md --read-metadata
```

### Build EPUB:

```bash
make epub
# or
mdtexpdf convert book.md --read-metadata --epub
```

### Build both:

```bash
make all
```

## What You Get

### PDF Features:

1. **Front Cover** - Full-bleed image with title overlay
2. **Half-Title Page** - Just the title, traditional style
3. **Title Page** - Title, subtitle, author, date
4. **Copyright Page** - Publisher info, ISBN, copyright
5. **Dedication Page** - Centered, italicized
6. **Epigraph Page** - Quote with attribution
7. **Table of Contents** - Auto-generated
8. **Content** - Your chapters with consistent formatting
9. **Headers/Footers** - Author/title, page numbers

### EPUB Features:

1. **Cover** - Generated with same style as PDF
2. **Title Page** - Clean, simple
3. **Copyright Page** - All metadata included
4. **Dedication & Epigraph** - Properly formatted
5. **Navigation TOC** - Works in all e-readers
6. **Clean HTML** - Validates with epubcheck

## Advanced Options

### Back Cover

Add a back cover with quote or summary:

```yaml
back_cover_image: "img/back.jpg"
back_cover_quote: "A must-read for anyone who wants to write."
back_cover_quote_source: "Famous Reviewer"
```

### Authorship Verification

For pseudonymous publishing:

```yaml
author_pubkey: "ssh-ed25519 AAAAC3..."
author_pubkey_type: "Ed25519"
donation_wallets:
  - type: "Bitcoin"
    address: "bc1q..."
  - type: "Ethereum"
    address: "0x..."
```

### Chapters on Odd Pages

For print-ready books:

```yaml
chapters_on_recto: true
```

### Drop Caps

For decorative first letters:

```yaml
drop_caps: true
```

## Tips

### Images in Chapters

```markdown
![Figure caption](img/diagram.png)
```

### Footnotes

```markdown
This needs clarification[^1].

[^1]: Here's the footnote text.
```

### Block Quotes

```markdown
> This is a block quote.
> It can span multiple lines.
>
> — Attribution
```

### Tables

```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
```

## Complete Metadata Reference

See [METADATA.md](METADATA.md) for all available options including:

- Page layout
- Header/footer customization
- Typography options
- Multiple output formats

---

**Result: A professional book ready for self-publishing or printing.**
