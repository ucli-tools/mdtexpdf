# Novel/Fiction Example

This example demonstrates how to create a fiction book with:

- Professional front matter (half-title, copyright, dedication, epigraph)
- Parts and chapters
- Scene breaks
- Dialogue formatting
- Poetry/verse
- Acknowledgments and author bio

## Build

```bash
# PDF
mdtexpdf convert novel.md --read-metadata

# EPUB (for e-readers)
mdtexpdf convert novel.md --read-metadata --epub
```

## Features Demonstrated

- `format: "book"` - Book format with proper chapter headings
- `half_title: true` - Traditional half-title page
- `copyright_page: true` - Full copyright with publisher, ISBN
- `dedication:` - Centered dedication page
- `epigraph:` - Opening quote with attribution
- `section_numbers: false` - No numbered sections (fiction style)
- `chapters_on_recto: true` - Chapters start on odd (right) pages
- Scene breaks with `---`
- Dialogue and narrative formatting
- Embedded poetry

## Tips for Fiction

1. **Scene breaks**: Use `---` for horizontal rules between scenes
2. **Dialogue**: Standard quote marks work well
3. **Emphasis**: Use *italics* for internal thoughts
4. **Parts**: Use `# Part One` for major divisions
5. **Chapters**: Use `## Chapter 1` for chapters

## Adding a Cover

Place a cover image at `img/cover.jpg` and add to metadata:

```yaml
cover_image: "img/cover.jpg"
cover_overlay_opacity: 0.3
```
