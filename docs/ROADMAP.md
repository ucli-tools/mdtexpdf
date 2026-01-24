# mdtexpdf Roadmap

A comprehensive list of improvements to make mdtexpdf a perfect, production-ready tool.

---

## 1. Code Architecture

### 1.1 Modularization
- [ ] Split `mdtexpdf.sh` (3,273 lines) into separate modules:
  - `lib/core.sh` - Common functions, color codes, utilities
  - `lib/pdf.sh` - PDF generation logic
  - `lib/epub.sh` - EPUB generation logic
  - `lib/cover.sh` - Cover generation (PDF and EPUB)
  - `lib/metadata.sh` - YAML parsing and metadata handling
  - `lib/frontmatter.sh` - Front matter generation (copyright, dedication, etc.)
  - `lib/check.sh` - Prerequisites checking
- [ ] Main `mdtexpdf.sh` becomes a thin dispatcher that sources modules
- [ ] Each module independently testable

### 1.2 Configuration
- [ ] Support `~/.mdtexpdf/config.yaml` for user defaults
- [ ] Support `.mdtexpdf.yaml` in project directory for project-specific settings
- [ ] Environment variable overrides (`MDTEXPDF_DEFAULT_FORMAT`, etc.)

### 1.3 Error Handling
- [ ] Consistent error codes (1=user error, 2=missing dependency, 3=conversion failure, etc.)
- [ ] Better error messages with suggested fixes
- [ ] `--verbose` and `--debug` flags for troubleshooting
- [ ] Log file option (`--log output.log`)

---

## 2. Testing & Quality

### 2.1 Automated Test Suite
- [ ] Create `tests/` directory with test runner
- [ ] Unit tests for each module/function
- [ ] Integration tests for full conversions:
  - [ ] Basic article PDF
  - [ ] Book with full front matter PDF
  - [ ] EPUB generation
  - [ ] Cover generation
  - [ ] Math/chemistry rendering
  - [ ] CJK content
- [ ] Regression tests (compare output hashes)
- [ ] Test runner script: `make test`

### 2.2 CI/CD Pipeline
- [ ] GitHub Actions workflow for:
  - [ ] Linting (shellcheck)
  - [ ] Running test suite
  - [ ] Building example documents
  - [ ] Release automation
- [ ] Badge in README showing build status

### 2.3 Code Quality
- [ ] Pass shellcheck with no warnings
- [ ] Consistent code style (document in CONTRIBUTING.md)
- [ ] Function documentation (comments explaining purpose, args, return)

---

## 3. Versioning & Releases

### 3.1 Version Management
- [ ] Add `--version` flag
- [ ] Semantic versioning (MAJOR.MINOR.PATCH)
- [ ] Version defined in single location (`VERSION` file or variable)
- [ ] CHANGELOG.md following Keep a Changelog format

### 3.2 Release Process
- [ ] Git tags for releases (v1.0.0, v1.1.0, etc.)
- [ ] GitHub Releases with release notes
- [ ] Installation instructions for specific versions

---

## 4. New Features

### 4.1 Bibliography & Citations
- [ ] Support for `.bib` files (BibTeX/BibLaTeX)
- [ ] Citation styles (APA, MLA, Chicago, IEEE, etc.)
- [ ] Metadata field: `bibliography: "references.bib"`
- [ ] Metadata field: `citation_style: "apa"`
- [ ] Auto-generate References/Bibliography section
- [ ] Works in both PDF and EPUB

### 4.2 Index Generation
- [ ] Markup for index entries: `{.index}` or `\index{term}`
- [ ] Auto-generate Index section at end of book
- [ ] Sub-entries and cross-references
- [ ] Metadata field: `index: true`

### 4.3 Cross-References
- [ ] Figure/table numbering and references
- [ ] Chapter/section references (`see Chapter 3`)
- [ ] Clickable links in PDF and EPUB

### 4.4 Glossary Enhancement
- [ ] Structured glossary format in YAML or markdown
- [ ] Auto-link glossary terms in text
- [ ] Glossary as appendix with proper formatting

### 4.5 Custom Templates
- [ ] User-provided LaTeX templates (`--template custom.tex`)
- [ ] User-provided EPUB CSS (`--epub-css custom.css`)
- [ ] Template variables documentation
- [ ] Example templates in `templates/`

### 4.6 Multiple Output Formats
- [ ] DOCX output (Word) - complete the experimental branch
- [ ] HTML output (single page or multi-page)
- [ ] Plain text output
- [ ] Markdown cleanup/normalization output

### 4.7 Multi-File Projects
- [ ] Support for `includes:` metadata to combine multiple .md files
- [ ] Chapter-per-file organization
- [ ] Shared metadata file for multi-file projects
- [ ] Build order configuration

### 4.8 Image Handling
- [ ] Auto-resize images to fit page
- [ ] Image compression for EPUB
- [ ] SVG support
- [ ] Figure captions and numbering
- [ ] Image placement options (here, top, bottom, page)

---

## 5. EPUB Improvements

### 5.1 Math in EPUB
- [ ] MathML output option for better e-reader support
- [ ] SVG rendering of equations as fallback
- [ ] Document which e-readers support what

### 5.2 EPUB Validation
- [ ] Run epubcheck automatically after generation
- [ ] Report and fix common issues
- [ ] `--validate` flag

### 5.3 EPUB Metadata
- [ ] Full EPUB3 metadata support (series, collection, etc.)
- [ ] ISBN embedding
- [ ] Rights/license metadata
- [ ] Reading order for complex layouts

### 5.4 EPUB Styling
- [ ] Built-in CSS themes (default, serif, sans, high-contrast)
- [ ] Custom CSS injection
- [ ] Font embedding option
- [ ] Responsive typography

### 5.5 Cover Improvements
- [ ] Multiple cover templates (centered, top-aligned, minimal)
- [ ] Back cover for EPUB (as final page)
- [ ] Spine image generation for print
- [ ] Cover without ImageMagick (pure Pandoc/CSS solution)

---

## 6. PDF Improvements

### 6.1 Print-Ready Output
- [ ] Bleed and trim marks option
- [ ] CMYK color output option
- [ ] PDF/X compliance for print shops
- [ ] Crop marks and registration marks

### 6.2 Layout Options
- [ ] Two-column layout option
- [ ] Custom margins per section
- [ ] Landscape pages for wide tables/figures
- [ ] Page size presets (A4, Letter, 6x9, etc.)

### 6.3 Typography
- [ ] Font selection metadata (serif, sans, mono)
- [ ] Custom font embedding
- [ ] Microtypography options (protrusion, expansion)
- [ ] Widow/orphan control settings

---

## 7. Documentation

### 7.1 Documentation Completeness
- [ ] Man page (`man mdtexpdf`)
- [ ] `--help` output for all commands and flags
- [ ] Troubleshooting guide with common errors
- [ ] FAQ section

### 7.2 Tutorials
- [ ] Quick start tutorial (5 minutes to first PDF)
- [ ] Book project tutorial (complete workflow)
- [ ] Migration guide from other tools (Pandoc direct, LaTeX, etc.)

### 7.3 Examples
- [ ] Example: Academic paper with citations
- [ ] Example: Technical documentation
- [ ] Example: Novel/fiction book
- [ ] Example: Cookbook/recipe book with images
- [ ] Example: Multi-language document
- [ ] Each example with source and rendered PDF/EPUB

---

## 8. Installation & Distribution

### 8.1 Docker (Recommended for Easy Setup)
Docker bundles all dependencies (Pandoc, LaTeX, ImageMagick, fonts) so users don't need to install anything locally.

- [ ] Create `Dockerfile` with full TexLive, Pandoc, ImageMagick, fonts
- [ ] Publish to Docker Hub (`uclitools/mdtexpdf`)
- [ ] Slim variant without full TexLive for smaller image
- [ ] Usage documentation:
  ```bash
  # Convert a file
  docker run --rm -v $(pwd):/work uclitools/mdtexpdf convert book.md --read-metadata
  
  # Build PDF and EPUB
  docker run --rm -v $(pwd):/work uclitools/mdtexpdf convert book.md --read-metadata
  docker run --rm -v $(pwd):/work uclitools/mdtexpdf convert book.md --read-metadata --epub
  ```
- [ ] Shell alias for convenience:
  ```bash
  alias mdtexpdf='docker run --rm -v $(pwd):/work uclitools/mdtexpdf'
  ```
- [ ] Docker Compose template for complex projects
- [ ] GitHub Actions using the Docker image
- [ ] Multi-arch support (amd64, arm64 for M1/M2 Macs)

### 8.2 Package Managers
- [ ] Homebrew formula (macOS) - wraps Docker or native install
- [ ] APT package (Debian/Ubuntu)
- [ ] AUR package (Arch Linux)
- [ ] npm/pip wrapper for cross-platform install

### 8.3 Native Installation
- [ ] `install.sh` script for one-line installation
- [ ] Dependency checker and installer (`mdtexpdf setup`)
- [ ] Version upgrade command (`mdtexpdf upgrade`)
- [ ] Uninstall command (`mdtexpdf uninstall` or `make uninstall`)

---

## 9. Performance

### 9.1 Speed Optimization
- [ ] Cache LaTeX preamble compilation
- [ ] Incremental builds (only rebuild changed chapters)
- [ ] Parallel processing for multi-file projects
- [ ] Benchmark suite to track performance

### 9.2 Resource Usage
- [ ] Memory usage optimization for large documents
- [ ] Temp file cleanup on all exit paths
- [ ] Progress indicator for long conversions

---

## 10. Integrations

### 10.1 Editor Integration
- [ ] VS Code extension with preview
- [ ] Vim/Neovim plugin
- [ ] Emacs integration

### 10.2 Build Tool Integration
- [ ] Make integration (current Makefile template)
- [ ] GitHub Actions workflow template
- [ ] GitLab CI template
- [ ] Pre-commit hook for validation

### 10.3 External Services
- [ ] Publish to Kindle Direct Publishing (KDP) format check
- [ ] Publish to Apple Books format check
- [ ] ISBN barcode generation
- [ ] DOI support for academic papers

---

## Priority Matrix

### P0 - Critical (Do First)
- Versioning (`--version`, CHANGELOG.md)
- Shellcheck compliance
- Basic test suite
- `--verbose` / `--debug` flags

### P1 - High Priority
- Docker image (simplifies installation dramatically)
- Modularization (split mdtexpdf.sh)
- Bibliography support
- CI/CD pipeline

### P2 - Medium Priority
- EPUB validation
- Custom templates
- Index generation
- More examples

### P3 - Nice to Have
- Editor integrations
- Package manager distribution
- Print-ready PDF options
- Multi-file projects

---

## Version Targets

### v1.0.0 - Stable Release
- All P0 items complete
- Core functionality documented and tested
- No known critical bugs

### v1.1.0 - Bibliography & Citations
- Bibliography support
- Citation styles
- Academic paper example

### v1.2.0 - Better Architecture
- Modularized codebase
- Full test coverage
- CI/CD pipeline

### v2.0.0 - Extended Formats
- DOCX output
- HTML output
- Custom templates
- Multi-file projects

---

*This roadmap is a living document. Items may be reprioritized based on user feedback and project needs.*
