# Simple Bibliography Format

A human-readable, Markdown-native bibliography format for mdtexpdf.

## Overview

mdtexpdf supports three bibliography formats:

1. **BibTeX format** (`.bib`) - Traditional academic format, complex syntax
2. **Simple Bibliography file** (`.md`) - Human-readable Markdown in a separate file
3. **Inline Bibliography** - References section embedded directly in your document

This document describes the Simple Bibliography format (options 2 and 3).

---

## Quick Start: Inline Bibliography (Recommended)

The simplest approach: put your references directly in your book.

```markdown
---
title: "The Example Book"
author: "Jane Smith"
---

# Introduction

Research methodology has a long history [@smith1950].

# The Science

Recent studies confirm these effects [@research2018; @report2024].

# Conclusion

States are now taking action [@news2025].

# References

- Author: Schaefer, Vincent J. and Vonnegut, Bernard
  Title: Method of Crystal Formation and Precipitation
  Year: 1950

- Key: report2024
  Author: U.S. Government Accountability Office
  Title: Data Analysis: Science and Policy Considerations
  Year: 2024

- Author: Jiang, Shu-Ye and Ma, Ali and Ramachandran, Srinivasan
  Title: Negative Air Ions and Their Effects
  Year: 2018

- Key: news2025
  Author: Florida Phoenix
  Title: Florida Senate approves ban on scientific methods
  Year: 2025
```

**That's it!** mdtexpdf automatically:
1. Detects the `# References` section
2. Extracts the bibliography entries
3. Generates citation keys (or uses your custom `Key:` values)
4. Processes `[@...]` citations throughout the document
5. Formats the references in your chosen citation style

---

## Two Ways to Use Simple Bibliography

### Option 1: Inline (Recommended)

Put a `# References` or `# Bibliography` section in your document:

```markdown
---
title: "My Book"
---

Your content with [@citations] here...

# References

- Author: Smith, John
  Title: A Great Book
  Year: 2024
```

**Auto-detected** - no configuration needed.

### Option 2: External File

Keep references in a separate file:

**book.md:**
```markdown
---
title: "My Book"
bibliography: references.md
---

Your content with [@citations] here...
```

**references.md:**
```markdown
- Author: Smith, John
  Title: A Great Book
  Year: 2024
```

Use this when:
- Sharing references across multiple documents
- Very large bibliographies
- Team collaboration on references

---

## How Citations Work

### In Your Text

Use Pandoc citation syntax:

```markdown
According to Smith [@smith2024], this is true.

Multiple sources agree [@smith2024; @jones2023].

See the original work [@smith2024, p. 42].
```

### Citation Keys

Each bibliography entry needs a citation key. You have two options:

**Auto-generated (default):** Based on author surname + year
```markdown
- Author: Smith, John        # Key: smith2024
  Title: A Great Book
  Year: 2024
```

**Custom key:** Specify with `Key:` field
```markdown
- Key: great-book            # Key: great-book
  Author: Smith, John
  Title: A Great Book
  Year: 2024
```

Use custom keys for:
- Institutional authors (`Key: report2024` instead of `usgovernmentaccountabilityoffice2024`)
- Memorable shortcuts (`Key: bible` instead of `various authors`)
- Disambiguation (two papers by same author in same year)

---

## Three Modes of Use

### Mode 1: Bibliography Only (No Citations)

Just list sources without citing them - for "Further Reading" sections:

```markdown
# Further Reading

- Author: Hawking, Stephen
  Title: A Brief History of Time
  Year: 1988

- Author: Sagan, Carl
  Title: Cosmos
  Year: 1980
```

These appear in the output but aren't cited with `[@...]` in the text.

### Mode 2: Auto-Generated Keys

Let mdtexpdf generate citation keys automatically:

```markdown
# References

- Author: Knuth, Donald E.
  Title: The Art of Computer Programming
  Year: 1968
```

Auto-generates key `knuth1968`. Use as `[@knuth1968]` in your text.

### Mode 3: Custom Keys

Specify your own keys for awkward or memorable names:

```markdown
# References

- Key: taocp
  Author: Knuth, Donald E.
  Title: The Art of Computer Programming
  Year: 1968
```

Use as `[@taocp]` in your text.

---

## What the Reader Sees

Depending on your citation style (CSL file):

**Author-Year Style (Chicago, APA):**
> According to Smith (2024), this is important. Others agree (Jones, 2023; Brown, 2022).

**Numeric Style (IEEE, Vancouver):**
> According to Smith [1], this is important. Others agree [2, 3].

**Footnote Style (Chicago Notes):**
> According to Smith¹, this is important.

The References section is automatically formatted:
> **References**
>
> Brown, Alice (2022). *Another Study*. Academic Press.
>
> Jones, Bob (2023). Research findings. *Journal of Science*, 42, 100-115.
>
> Smith, John (2024). *A Great Book*. Publisher.

---

## Entry Format

### Required Fields

| Field | Description |
|-------|-------------|
| `Author` | Author name(s). Format: "Surname, Given". Multiple: "Smith, John and Jones, Mary" |
| `Title` | Title of the work |
| `Year` | Publication year |

### Optional Fields

| Field | Description |
|-------|-------------|
| `Key` | Custom citation key (overrides auto-generation) |
| `Type` | Entry type: `book`, `article`, `report`, `patent`, `web` |
| `Journal` | Journal name (for articles) |
| `Publisher` | Publisher name (for books) |
| `Volume` | Volume number |
| `Number` | Issue number |
| `Pages` | Page range (e.g., `123--145`) |
| `DOI` | Digital Object Identifier |
| `URL` | Web address |
| `Note` | Additional notes |

---

## Entry Examples

### Book
```markdown
- Author: Knuth, Donald E.
  Title: The Art of Computer Programming
  Type: book
  Publisher: Addison-Wesley
  Year: 1968
```

### Journal Article
```markdown
- Author: Turing, Alan
  Title: On Computable Numbers
  Type: article
  Journal: Proceedings of the London Mathematical Society
  Volume: 42
  Pages: 230--265
  Year: 1936
```

### Technical Report
```markdown
- Key: report2024
  Author: U.S. Government Accountability Office
  Title: Data Analysis: Science and Policy Considerations
  Type: report
  Number: GAO-25-107328
  Year: 2024
  URL: https://www.gao.gov/products/gao-25-107328
```

### Patent
```markdown
- Author: Schaefer, Vincent J. and Vonnegut, Bernard
  Title: Method of Crystal Formation and Precipitation
  Type: patent
  Number: U.S. Patent 2,527,230
  Year: 1950
```

### Web Page
```markdown
- Key: wiki:example
  Author: Wikipedia contributors
  Title: Data analysis
  Type: web
  Year: 2024
  URL: https://en.wikipedia.org/wiki/Cloud_seeding
  Note: Accessed January 2026
```

### News Article
```markdown
- Key: news2025
  Author: Florida Phoenix
  Title: Florida Senate approves ban on scientific methods
  Type: article
  Year: 2025
  URL: https://floridaphoenix.com/2025/04/03/...
```

---

## Organizing Your Bibliography

Use Markdown headings to organize entries (headings are ignored by the parser):

```markdown
# References

## Primary Sources

- Author: Original Author
  Title: The Original Work
  Year: 1900

## Secondary Sources

- Author: Commentator
  Title: Analysis of the Original
  Year: 2020

## News & Media

- Key: nytimes2024
  Author: New York Times
  Title: Breaking Story
  Year: 2024
```

---

## Citation Key Generation Rules

When no `Key:` field is provided:

| Author | Year | Generated Key |
|--------|------|---------------|
| Einstein, Albert | 1905 | `einstein1905` |
| Smith, John and Jones, Mary | 2020 | `smith2020` (first author) |
| Van Gogh, Vincent | 1888 | `vangogh1888` (no spaces) |
| U.S. Government | 2024 | `usgovernment2024` (institutional) |

**Duplicate handling:** Second entry with same key gets `b` suffix:
- `einstein1905` (first paper)
- `einstein1905b` (second paper same year)

---

## Comparison: Simple vs BibTeX

### BibTeX (Traditional)
```bibtex
@article{research2018,
  author = {Jiang, Shu-Ye and Ma, Ali},
  title = {Negative Air Ions},
  journal = {Int. J. Mol. Sci.},
  year = {2018},
  volume = {19},
  pages = {2966}
}
```

### Simple Bibliography (New)
```markdown
- Author: Jiang, Shu-Ye and Ma, Ali
  Title: Negative Air Ions
  Journal: Int. J. Mol. Sci.
  Year: 2018
  Volume: 19
  Pages: 2966
```

**Advantages of Simple Bibliography:**
- No curly braces or commas to balance
- No `@type{key,` syntax to remember
- Human-readable without special tools
- Lives inside your document (inline mode)
- Natural Markdown formatting

**When to use BibTeX:**
- Importing from academic databases
- Existing `.bib` files
- Complex bibliography requirements

---

## CLI Usage

```bash
# Inline bibliography (auto-detected)
mdtexpdf convert book.md

# External simple bibliography file
mdtexpdf convert book.md --bibliography references.md

# With citation style
mdtexpdf convert book.md --csl ieee.csl

# Traditional BibTeX still works
mdtexpdf convert book.md --bibliography refs.bib
```

---

## Detection Rules

mdtexpdf automatically detects inline bibliographies by looking for:

1. A heading matching `# References` or `# Bibliography` (case-insensitive, any heading level)
2. Followed by entries starting with `- Author:` or `- Key:`

If found, the section is extracted, converted to CSL-JSON, and processed.

---

## Tips

1. **Use inline for simplicity** - One file, everything together

2. **Use custom keys for institutions** - `Key: report2024` is better than `usgovernmentaccountabilityoffice2024`

3. **Put Key first** - Makes custom keys visible when scanning:
   ```markdown
   - Key: memorable-name
     Author: ...
   ```

4. **Use `--verbose`** - See generated citation keys during conversion

5. **Organize with headings** - Group by type (Books, Papers, Websites)

---

## See Also

- [mdtexpdf Guide](mdtexpdf_guide.md) - Full documentation
- [METADATA.md](METADATA.md) - All metadata fields
- [Pandoc Citations](https://pandoc.org/MANUAL.html#citations) - Citation syntax details
