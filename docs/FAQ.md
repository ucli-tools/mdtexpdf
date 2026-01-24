# Frequently Asked Questions

## General

### What is mdtexpdf?

mdtexpdf is a command-line tool that converts Markdown documents to professional-quality PDFs and EPUBs using LaTeX. It supports advanced features like mathematical equations, chemistry notation, CJK characters, cover images, and professional book formatting.

### What are the system requirements?

- Bash 4.0+
- Pandoc 2.0+
- TexLive (any recent version)
- Optional: Docker (for containerized usage)
- Optional: yq (for YAML metadata parsing)
- Optional: ImageMagick (for cover generation)

### Is mdtexpdf free?

Yes, mdtexpdf is open-source software released under the Apache 2.0 license.

---

## Installation

### What's the easiest way to install?

Use Docker - it includes all dependencies:

```bash
docker pull uclitools/mdtexpdf
docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert input.md
```

### Can I install without Docker?

Yes:

```bash
git clone https://github.com/ucli-tools/mdtexpdf.git
cd mdtexpdf
sudo make install
```

You'll need to install Pandoc and TexLive separately.

### How do I uninstall?

```bash
sudo make uninstall
```

Or manually:

```bash
sudo rm /usr/local/bin/mdtexpdf
sudo rm -rf /usr/local/share/mdtexpdf
```

---

## Usage

### How do I convert a Markdown file to PDF?

```bash
mdtexpdf convert document.md
```

### How do I convert to EPUB?

```bash
mdtexpdf convert document.md --epub
```

### How do I add a table of contents?

Add to your YAML frontmatter:

```yaml
---
title: "My Document"
toc: true
toc_depth: 2
---
```

Or use command line:

```bash
mdtexpdf convert document.md --toc
```

### How do I add a cover image?

Add to your YAML frontmatter:

```yaml
---
title: "My Book"
cover_image: "img/cover.jpg"
---
```

The image path is relative to your markdown file.

### How do I disable section numbering?

```yaml
---
section_numbers: false
---
```

Or:

```bash
mdtexpdf convert document.md --no-numbers
```

---

## Features

### Does mdtexpdf support math equations?

Yes! Use standard LaTeX math syntax:

- Inline: `$E = mc^2$`
- Display: `$$\int_0^1 x^2 dx = \frac{1}{3}$$`

### Does it support chemistry notation?

Yes, using mhchem syntax:

```markdown
Water is \ce{H2O}.
Reaction: \ce{2H2 + O2 -> 2H2O}
```

### Can I include Chinese/Japanese/Korean text?

Yes, mdtexpdf automatically detects CJK content and uses XeLaTeX with appropriate fonts.

### What about code syntax highlighting?

Supported. Use fenced code blocks with language identifier:

````markdown
```python
def hello():
    print("Hello, world!")
```
````

### Can I create professional books with front matter?

Yes! mdtexpdf supports:

- Half-title page
- Title page with subtitle
- Copyright page
- Dedication
- Epigraph
- Table of contents
- Front and back cover images

See [METADATA.md](METADATA.md) for all available options.

---

## Output Quality

### What paper sizes are supported?

Default is A4. The template can be customized for Letter, 6x9, or other sizes.

### Can I customize fonts?

Yes, when using XeLaTeX or LuaLaTeX. The template uses Latin Modern by default.

### What PDF engine should I use?

- **pdfLaTeX** (default): Best compatibility, fastest
- **XeLaTeX**: Required for CJK, supports custom fonts
- **LuaLaTeX**: Most flexible, supports custom fonts

mdtexpdf automatically selects the appropriate engine based on content.

---

## Troubleshooting

### Why is my PDF blank?

Check that:
1. Your markdown content is after the YAML frontmatter closing `---`
2. Your YAML syntax is valid
3. Run with `--verbose` to see detailed output

### Why are images not showing?

1. Use paths relative to your markdown file
2. Ensure images exist and are readable
3. Supported formats: PNG, JPG, PDF

### Why is conversion slow?

1. First run caches fonts (normal)
2. Many images increase processing time
3. Complex math equations take longer

### Where can I get more help?

- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions
- Open an issue: https://github.com/ucli-tools/mdtexpdf/issues

---

## Comparison

### How does mdtexpdf compare to Pandoc alone?

mdtexpdf adds:
- Professional LaTeX templates
- Automatic cover generation
- Book front matter (copyright, dedication, etc.)
- Chemistry notation support
- CJK auto-detection
- Consistent styling

### How does it compare to LaTeX directly?

mdtexpdf:
- Uses simpler Markdown syntax
- Handles LaTeX complexity automatically
- Faster iteration for most documents
- Still supports inline LaTeX when needed

### Can I still use raw LaTeX?

Yes, you can include LaTeX commands in your Markdown:

```markdown
This uses \textbf{bold} and \emph{emphasis}.

$$\begin{aligned}
x &= 1 \\
y &= 2
\end{aligned}$$
```
