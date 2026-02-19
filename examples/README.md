# mdtexpdf Examples

This directory contains example documents demonstrating various use cases for mdtexpdf.

## Examples

| Example | Description | Key Features |
|---------|-------------|--------------|
| [academic-paper](academic-paper/) | Research paper with citations | Math, tables, code, appendices |
| [novel](novel/) | Fiction book with chapters | Front matter, parts, scenes |
| [technical-docs](technical-docs/) | API reference documentation | Code blocks, HTTP examples, tables |
| [cookbook](cookbook/) | Recipe book | Recipe format, ingredient lists, tips |
| [multilingual](multilingual/) | Multi-language document | CJK, Cyrillic, Arabic, Greek |

## Quick Start

Build any example with:

```bash
cd <example-directory>
mdtexpdf convert *.md --read-metadata
```

Or using Docker:

```bash
cd <example-directory>
docker run --rm -v "$(pwd):/data" logismosis/mdtexpdf convert *.md --read-metadata
```

## Building All Examples

From this directory:

```bash
for dir in */; do
    echo "Building $dir..."
    (cd "$dir" && mdtexpdf convert *.md --read-metadata 2>/dev/null)
done
```

## Use Cases

### Academic Writing
→ See `academic-paper/`

Best for: Research papers, theses, technical reports
- Section numbering
- Mathematical equations
- Tables and figures
- Bibliography references

### Fiction/Creative Writing
→ See `novel/`

Best for: Novels, short stories, memoirs
- Professional front matter
- Chapter formatting
- Scene breaks
- No section numbers

### Technical Documentation
→ See `technical-docs/`

Best for: API docs, user manuals, specifications
- Code syntax highlighting
- Multiple languages
- Tables for structured data
- Clear section hierarchy

### Cookbooks/Instructional
→ See `cookbook/`

Best for: Recipe books, how-to guides, tutorials
- Consistent formatting
- Ingredient/materials lists
- Step-by-step instructions
- Quick reference tables

### Multilingual Content
→ See `multilingual/`

Best for: International documents, language learning
- Multiple scripts
- CJK support
- Unicode handling

## Creating Your Own

Use these examples as templates:

1. Copy the example closest to your needs
2. Modify the YAML frontmatter
3. Replace the content
4. Build with `mdtexpdf convert`

See [METADATA.md](../docs/METADATA.md) for all available options.
