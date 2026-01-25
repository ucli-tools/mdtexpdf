# Changelog

All notable changes to mdtexpdf will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Bibliography & Citations support (`--bibliography`, `--csl` flags)
  - BibTeX/BibLaTeX `.bib` files
  - CSL citation styles
  - Simple Markdown bibliography format (see docs/SIMPLE_BIBLIOGRAPHY.md)
- Index Generation (`--index` flag)
  - `[index:term]` markers in text
  - Sub-entries with `[index:term|subterm]` syntax
  - Lua filter for index processing
- Custom Templates support
  - `--template FILE` for custom LaTeX templates
  - `--epub-css FILE` for custom EPUB styling
- EPUB Validation (`--validate` flag, `mdtexpdf validate` command)
  - Integration with epubcheck
- Multi-file Projects (`--include`/`-i` flag)
  - Combine multiple markdown files
  - Repeatable flag for chapter-per-file organization
- Modular architecture with extracted libraries:
  - `lib/core.sh` - Common functions, logging, utilities
  - `lib/check.sh` - Prerequisites checking
  - `lib/metadata.sh` - YAML/HTML parsing and metadata handling
  - `lib/preprocess.sh` - Markdown preprocessing, Unicode detection
  - `lib/epub.sh` - EPUB helpers (spine reorder, chemistry)
  - `lib/bibliography.sh` - Simple markdown bibliography format conversion
- Expanded test suite (176 tests total):
  - 79 integration tests
  - 83 module unit tests
  - 14 regression tests

### Documentation
- docs/SIMPLE_BIBLIOGRAPHY.md: Human-readable bibliography format guide
- Expanded examples: academic paper, novel, cookbook, technical docs, multilingual

## [1.0.0] - 2026-01-24

### Added
- EPUB3 output format with `--epub` flag
- EPUB cover generation with text overlay (requires ImageMagick)
- EPUB front matter: title page, copyright, dedication, epigraph
- `--version` / `-V` flag to display version
- `--verbose` / `-v` flag for detailed output
- `--debug` flag for troubleshooting
- Logging functions (log_verbose, log_debug, log_error, log_warn, log_success)
- Makefile template for book projects (`templates/Makefile.book`)
- Comprehensive ROADMAP.md with prioritized improvements
- Authorship verification documentation with Ed25519/PGP signing guide
- Anonymous publishing guide

### Changed
- Help output now shows version number
- Help output updated with global options section
- Help output includes --epub flag documentation

### Documentation
- README.md: Added EPUB generation section
- docs/mdtexpdf_guide.md: Added EPUB chapter with full documentation
- docs/METADATA.md: Added EPUB notes and output formats table
- docs/AUTHORSHIP.md: Complete rewrite with Ed25519 focus and signing workflow

## [0.9.0] - 2026-01-22

### Added
- Professional book features (half-title, copyright page, dedication, epigraph)
- Cover system with front and back cover support
- Text overlay on covers with configurable colors and opacity
- Drop caps for chapter openings
- Authorship & Support page with PGP fingerprint and donation wallets
- Chemical equations with mhchem package (`\ce{}` command)
- CJK (Chinese, Japanese, Korean) support via XeLaTeX
- Header/footer policy (default, partial, all)
- Unicode subscript/superscript support
- Long equation line-breaking filter

### Changed
- Improved table of contents handling
- Better chapter and part formatting for book format

## [0.8.0] - 2026-01-15

### Added
- Initial public release
- Markdown to PDF conversion via Pandoc and LaTeX
- YAML frontmatter metadata support
- LaTeX math support (inline and display)
- Code syntax highlighting
- Table of contents generation
- Custom header/footer text
- Multiple PDF engines (pdfLaTeX, XeLaTeX, LuaLaTeX)
- Prerequisites checker (`mdtexpdf check`)
- System-wide installation (`mdtexpdf install`)

[Unreleased]: https://github.com/ucli-tools/mdtexpdf/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ucli-tools/mdtexpdf/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/ucli-tools/mdtexpdf/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/ucli-tools/mdtexpdf/releases/tag/v0.8.0
