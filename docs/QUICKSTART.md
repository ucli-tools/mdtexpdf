# Quick Start Guide

Get from zero to your first PDF in 5 minutes.

## Step 1: Install (1 minute)

### Option A: Docker (Recommended)

```bash
docker pull uclitools/mdtexpdf
```

### Option B: Native Installation

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install pandoc texlive-latex-recommended texlive-latex-extra

# Install mdtexpdf
git clone https://github.com/ucli-tools/mdtexpdf.git
cd mdtexpdf
sudo make install
```

## Step 2: Create Your Document (2 minutes)

Create a file called `my-document.md`:

```markdown
---
title: "My First Document"
author: "Your Name"
date: "2026-01-24"
toc: true
---

# Introduction

Welcome to my first document created with mdtexpdf!

## Features

You can write:

- **Bold text**
- *Italic text*
- `Code snippets`

## Math Support

Einstein's famous equation: $E = mc^2$

A more complex integral:

$$\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}$$

## Code Blocks

```python
def greet(name):
    return f"Hello, {name}!"

print(greet("World"))
```

## Conclusion

That's it! Your document is ready.
```

## Step 3: Convert to PDF (30 seconds)

### Using Docker:

```bash
docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert my-document.md --read-metadata
```

### Using native installation:

```bash
mdtexpdf convert my-document.md --read-metadata
```

## Step 4: View Your PDF

Open `my-document.pdf` - you now have a professionally formatted PDF!

---

## What's Next?

### Convert to EPUB

```bash
mdtexpdf convert my-document.md --read-metadata --epub
```

### Create a Full Book

See the [Book Tutorial](BOOK_TUTORIAL.md) for creating books with:
- Cover images
- Copyright page
- Dedication
- Table of contents
- Multiple chapters

### Customize Your Document

See [METADATA.md](METADATA.md) for all available options:
- Custom headers/footers
- Section numbering
- Page formats
- Front matter

### Troubleshooting

If something doesn't work, check:
1. `mdtexpdf check` - Verify dependencies
2. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
3. [FAQ.md](FAQ.md) - Frequently asked questions

---

## Quick Reference

### Common Commands

```bash
# Convert to PDF
mdtexpdf convert document.md --read-metadata

# Convert to EPUB
mdtexpdf convert document.md --read-metadata --epub

# With table of contents
mdtexpdf convert document.md --read-metadata --toc

# Check dependencies
mdtexpdf check

# Show help
mdtexpdf help
```

### Essential YAML Frontmatter

```yaml
---
title: "Document Title"
author: "Author Name"
date: "2026-01-24"
toc: true                    # Include table of contents
section_numbers: true        # Number sections (1.1, 1.2, etc.)
format: "article"            # or "book"
---
```

### Math Examples

```markdown
Inline: $x^2 + y^2 = z^2$

Display:
$$\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}$$

Chemistry:
Water is \ce{H2O}
```

---

**Time to first PDF: ~5 minutes**

For more advanced usage, see the full [documentation](../README.md).
