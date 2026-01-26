# mdtexpdf Roadmap

A comprehensive list of improvements to make mdtexpdf a perfect, production-ready tool.

---

## Implementation Plan

We take a quality-first approach, completing each phase thoroughly before moving to the next.

### Phase A: Quick Wins (< 1 hour each) ✓ COMPLETE
- [x] A1. Add CI badge to README showing build status
- [x] A2. Consistent error codes (1=user error, 2=missing dependency, 3=conversion failure)
- [x] A3. Improve `--help` output for all commands and flags
- [x] A4. Document existing uninstall command

### Phase B: Testing & Quality (2-4 hours) ✓ COMPLETE
- [x] B1. Shellcheck compliance - fix all warnings locally
- [x] B2. More integration tests:
  - [x] Book with full front matter PDF
  - [x] Cover generation (with cover image fixture)
  - [x] Math/chemistry rendering
  - [x] CJK content (skips if xeCJK not installed)
- [x] B3. Regression tests (14 tests in tests/test_regression.sh)
- [x] B4. Unit tests for modules (83 tests in tests/test_modules.sh)
- [x] B5. Create CONTRIBUTING.md with code style guide

### Phase C: Documentation (3-5 hours) ✓ COMPLETE
- [x] C1. Troubleshooting guide with common errors
- [x] C2. FAQ section
- [x] C3. Quick start tutorial (5 minutes to first PDF)
- [x] C4. Book project tutorial (complete workflow)
- [x] C5. More examples:
  - [x] Academic paper with citations
  - [x] Novel/fiction book
  - [x] Technical documentation
  - [x] Cookbook with images
  - [x] Multi-language document

### Phase D: Modularization ✓ COMPLETE
- [x] D1. Extract `lib/pdf.sh` - PDF generation helpers (Unicode detection, cover detection, cleanup)
- [x] D2. Extract `lib/epub.sh` - EPUB generation logic (spine reorder, frontmatter, chemistry)
- [x] D3. Extract `lib/metadata.sh` - YAML/HTML parsing and metadata handling
- [x] D4. Extract `lib/preprocess.sh` - Markdown preprocessing, Unicode detection
- [x] D5. Extract `lib/template.sh` - LaTeX template generation (1041 lines)
- [x] D6. Update main `mdtexpdf.sh` to source modules
- [x] D7. Make each module independently testable (51 unit tests in tests/test_modules.sh)

### Phase D2: Deep Modularization ✓ COMPLETE
Reduced `mdtexpdf.sh` from 2,818 → 813 lines (71% reduction):
- [x] D2.1. Extract `lib/args.sh` - CLI argument parsing (334 lines)
- [x] D2.2. Expand `lib/metadata.sh` - Move metadata parsing functions (447 → 461 lines)
- [x] D2.3. Expand `lib/epub.sh` - Add `generate_epub()` function (280 → 670 lines)
- [x] D2.4. Create `lib/convert.sh` - PDF conversion logic (827 lines)
- [x] D2.5. Refactor `convert()` to 60-line thin orchestrator
- [x] All 38 tests passing after each step

### Phase E: New Features (4-8 hours each) ✓ COMPLETE
- [x] E1. Bibliography & Citations support
- [x] E2. Index Generation
- [x] E3. Custom Templates (LaTeX and EPUB CSS)
- [x] E4. EPUB Validation (epubcheck integration)
- [x] E5. Multi-file Projects support

### Phase F: Future Enhancements (deferred)
- Editor integrations (VS Code, Vim, Emacs)
- Package manager distribution (Homebrew, APT, AUR)
- Print-ready PDF options (bleed, CMYK, PDF/X)
- Performance optimizations (caching, incremental builds)
- Additional output formats (DOCX, HTML)

---

## Current Status

### Completed
- [x] Core PDF generation
- [x] EPUB3 generation with cover and front matter
- [x] EPUB spine reordering (TOC after front matter)
- [x] `--version`, `--verbose`, `--debug` flags
- [x] CHANGELOG.md
- [x] Comprehensive test suite (176 tests total):
  - [x] 79 integration tests (run_tests.sh)
  - [x] 83 module unit tests (test_modules.sh)
  - [x] 14 regression tests (test_regression.sh)
- [x] CI/CD pipeline (GitHub Actions)
- [x] Docker image with all dependencies
- [x] Makefile template for book projects
- [x] Phase A: Quick Wins - COMPLETE
- [x] Phase B: Testing & Quality - COMPLETE
- [x] Phase C: Documentation - COMPLETE
- [x] Modularization (10 modules, main script 813 lines):
  - [x] `lib/core.sh` - Common functions, logging, utilities (127 lines)
  - [x] `lib/check.sh` - Prerequisites checking (104 lines)
  - [x] `lib/metadata.sh` - YAML/HTML metadata parsing (461 lines)
  - [x] `lib/preprocess.sh` - Markdown preprocessing, Unicode detection (167 lines)
  - [x] `lib/epub.sh` - EPUB generation with cover, front matter, chemistry (670 lines)
  - [x] `lib/bibliography.sh` - Simple markdown bibliography format conversion (514 lines)
  - [x] `lib/pdf.sh` - PDF engine selection, cover detection (228 lines)
  - [x] `lib/template.sh` - LaTeX template generation (1,041 lines)
  - [x] `lib/convert.sh` - PDF conversion: template, filters, pandoc execution (827 lines)
  - [x] `lib/args.sh` - CLI argument parsing and validation (334 lines)
- [x] Unicode detection for typographic characters (em-dash, smart quotes, fractions)

- [x] Phase D: Modularization - COMPLETE (8 lib modules, 51 unit tests)
- [x] Phase D2: Deep Modularization - COMPLETE (10 lib modules, main script 71% smaller)
- [x] Phase E: New Features - ALL COMPLETE
  - [x] E1: Bibliography & Citations (--bibliography, --csl flags)
  - [x] E2: Index Generation (--index flag, [index:term] markers, Lua filter)
  - [x] E3: Custom Templates (--template, --epub-css flags)
  - [x] E4: EPUB Validation (--validate flag, validate command)
  - [x] E5: Multi-file Projects (--include/-i flag, repeatable)

### Next Up
- Phase F: Future Enhancements (editor integrations, package managers, print-ready PDF)
  - Configuration files (~/.mdtexpdf/config.yaml, .mdtexpdf.yaml)
  - Cross-references (figure/table/chapter references)
  - Print-ready PDF options (bleed, CMYK, PDF/X)

---

## Detailed Feature List

### 1. Code Architecture

#### 1.1 Modularization ✓ COMPLETE (Phase D + D2)
- [x] `lib/core.sh` - Common functions, color codes, utilities (127 lines)
- [x] `lib/check.sh` - Prerequisites checking (104 lines)
- [x] `lib/metadata.sh` - YAML/HTML parsing and metadata handling (461 lines)
- [x] `lib/preprocess.sh` - Markdown preprocessing, Unicode detection (167 lines)
- [x] `lib/epub.sh` - EPUB generation with cover, front matter, chemistry (670 lines)
- [x] `lib/bibliography.sh` - Simple markdown bibliography format conversion (514 lines)
- [x] `lib/pdf.sh` - PDF engine selection, cover detection (228 lines)
- [x] `lib/template.sh` - LaTeX template generation (1,041 lines)
- [x] `lib/convert.sh` - PDF conversion: template, filters, pandoc execution (827 lines)
- [x] `lib/args.sh` - CLI argument parsing and validation (334 lines)
- [x] Main `mdtexpdf.sh` reduced to 813-line orchestrator (from 2,818)
- [x] `convert()` is a 60-line thin orchestrator delegating to modules
- [x] Each module independently testable (51 unit tests)
- [x] Total codebase: 5,286 lines across 11 files

#### 1.2 Configuration
- [ ] Support `~/.mdtexpdf/config.yaml` for user defaults
- [ ] Support `.mdtexpdf.yaml` in project directory
- [ ] Environment variable overrides (`MDTEXPDF_DEFAULT_FORMAT`, etc.)

#### 1.3 Error Handling
- [ ] Consistent error codes (1=user error, 2=missing dependency, 3=conversion failure)
- [ ] Better error messages with suggested fixes
- [x] `--verbose` and `--debug` flags
- [x] Logging functions (log_verbose, log_debug, log_error, log_warn, log_success)
- [ ] Log file option (`--log output.log`)

---

### 2. Testing & Quality

#### 2.1 Automated Test Suite
- [x] `tests/` directory with test runner
- [x] Integration tests (79 tests in run_tests.sh):
  - [x] Basic article PDF
  - [x] EPUB generation
  - [x] Book with full front matter PDF
  - [x] Cover generation (PDF and EPUB)
  - [x] Math/chemistry rendering
  - [x] CJK content (skips if xeCJK not available)
  - [x] PDF feature tests (pageof, date-footer, no-numbers, toc-cli, header-footer-policy, no-footer)
  - [x] Bibliography and index tests
  - [x] Multi-file project tests
- [x] Unit tests for each module (83 tests in test_modules.sh)
- [x] Regression tests (14 tests in test_regression.sh)
- [x] Test runner script: `make test`

#### 2.2 CI/CD Pipeline
- [x] GitHub Actions workflow:
  - [x] Linting (shellcheck)
  - [x] Running test suite
  - [x] Building example documents
  - [x] Release automation
- [ ] Badge in README showing build status

#### 2.3 Code Quality
- [x] Pass shellcheck with no warnings
- [x] CONTRIBUTING.md with code style guide
- [ ] Function documentation (comments explaining purpose, args, return)

---

### 3. Versioning & Releases

#### 3.1 Version Management
- [x] `--version` flag
- [x] Semantic versioning (MAJOR.MINOR.PATCH)
- [x] Version in single location (`VERSION` variable)
- [x] CHANGELOG.md (Keep a Changelog format)

#### 3.2 Release Process
- [x] Git tags for releases (via CI)
- [x] GitHub Releases with notes (via CI)
- [ ] Installation instructions for specific versions

---

### 4. New Features

#### 4.1 Bibliography & Citations
- [x] Support for `.bib` files (BibTeX/BibLaTeX)
- [x] Citation styles via CSL files
- [x] Metadata: `bibliography: "references.bib"`
- [x] Metadata: `csl: "style.csl"`
- [x] CLI: `--bibliography FILE` and `--csl FILE`
- [x] Auto-generate References/Bibliography section
- [x] Works in both PDF and EPUB
- [x] Simple Markdown bibliography format (alternative to BibTeX)
  - [x] Human-readable `.md` format for bibliographies
  - [x] Auto-generated citation keys (author+year)
  - [x] Custom key override with `Key:` field
  - [x] Three modes: bibliography-only, auto-key citations, custom-key citations
  - [x] See [SIMPLE_BIBLIOGRAPHY.md](SIMPLE_BIBLIOGRAPHY.md) for documentation

#### 4.2 Index Generation
- [x] Markup for index entries: `[index:term]` or `[index:term|subterm]`
- [x] Auto-generate Index section via `\printindex`
- [x] Sub-entries support via `|` separator
- [x] CLI: `--index` flag to enable index generation

#### 4.3 Cross-References
- [ ] Figure/table numbering and references
- [ ] Chapter/section references (`see Chapter 3`)
- [ ] Clickable links in PDF and EPUB

#### 4.4 Glossary Enhancement
- [ ] Structured glossary format in YAML or markdown
- [ ] Auto-link glossary terms in text
- [ ] Glossary as appendix with proper formatting

#### 4.5 Custom Templates
- [x] User-provided LaTeX templates (`--template custom.tex`)
- [x] User-provided EPUB CSS (`--epub-css custom.css`)
- [ ] Template variables documentation
- [x] Example templates in `tests/fixtures/`

#### 4.6 Multiple Output Formats
- [ ] DOCX output (Word)
- [ ] HTML output (single page or multi-page)
- [ ] Plain text output
- [ ] Markdown cleanup/normalization

#### 4.7 Multi-File Projects
- [x] `--include FILE` CLI option to combine .md files (repeatable)
- [x] Chapter-per-file organization
- [x] Shared metadata from main file (included files' frontmatter stripped)
- [x] Build order follows CLI argument order

#### 4.8 Image Handling
- [ ] Auto-resize images to fit page
- [ ] Image compression for EPUB
- [ ] SVG support
- [ ] Figure captions and numbering
- [ ] Image placement options (here, top, bottom, page)

---

### 5. EPUB Improvements

#### 5.1 Math in EPUB
- [ ] MathML output option
- [ ] SVG rendering of equations as fallback
- [ ] Document e-reader compatibility

#### 5.2 EPUB Validation
- [x] Run epubcheck automatically
- [x] Report and fix common issues
- [x] `--validate` flag
- [x] `mdtexpdf validate <file.epub>` command

#### 5.3 EPUB Metadata
- [ ] Full EPUB3 metadata (series, collection)
- [ ] ISBN embedding
- [ ] Rights/license metadata
- [ ] Reading order for complex layouts

#### 5.4 EPUB Styling
- [ ] Built-in CSS themes (default, serif, sans, high-contrast)
- [ ] Custom CSS injection
- [ ] Font embedding option
- [ ] Responsive typography

#### 5.5 Cover Improvements
- [ ] Multiple cover templates
- [ ] Back cover for EPUB
- [ ] Spine image generation
- [ ] Cover without ImageMagick (pure CSS)

---

### 6. PDF Improvements

#### 6.1 Print-Ready Output
- [ ] Bleed and trim marks
- [ ] CMYK color output
- [ ] PDF/X compliance
- [ ] Crop marks and registration marks

#### 6.2 Layout Options
- [ ] Two-column layout
- [ ] Custom margins per section
- [ ] Landscape pages for wide content
- [ ] Page size presets (A4, Letter, 6x9)

#### 6.3 Typography
- [ ] Font selection metadata (serif, sans, mono)
- [ ] Custom font embedding
- [ ] Microtypography options
- [ ] Widow/orphan control

---

### 7. Documentation

#### 7.1 Documentation Completeness
- [ ] Man page (`man mdtexpdf`)
- [ ] `--help` output for all commands
- [ ] Troubleshooting guide
- [ ] FAQ section

#### 7.2 Tutorials
- [ ] Quick start (5 minutes to first PDF)
- [ ] Book project tutorial
- [ ] Migration guide from other tools

#### 7.3 Examples
- [ ] Academic paper with citations
- [ ] Technical documentation
- [ ] Novel/fiction book
- [ ] Cookbook with images
- [ ] Multi-language document
- [ ] Each with source and rendered PDF/EPUB

---

### 8. Installation & Distribution

#### 8.1 Docker
- [x] Dockerfile with full dependencies
- [x] Docker Hub publishing (via CI)
- [x] Usage documentation in README
- [x] Multi-arch support (amd64, arm64)
- [ ] Slim variant without full TexLive
- [ ] Docker Compose template

#### 8.2 Package Managers
- [ ] Homebrew formula (macOS)
- [ ] APT package (Debian/Ubuntu)
- [ ] AUR package (Arch Linux)
- [ ] npm/pip wrapper

#### 8.3 Native Installation
- [ ] `install.sh` one-line installation
- [ ] `mdtexpdf setup` dependency installer
- [ ] `mdtexpdf upgrade` version upgrade
- [ ] Document uninstall command

---

### 9. Performance

#### 9.1 Speed Optimization
- [ ] Cache LaTeX preamble
- [ ] Incremental builds
- [ ] Parallel processing
- [ ] Benchmark suite

#### 9.2 Resource Usage
- [ ] Memory optimization
- [ ] Temp file cleanup on all exit paths
- [ ] Progress indicator for long conversions

---

### 10. Integrations

#### 10.1 Editor Integration
- [ ] VS Code extension with preview
- [ ] Vim/Neovim plugin
- [ ] Emacs integration

#### 10.2 Build Tool Integration
- [x] Make integration (Makefile template)
- [x] GitHub Actions workflow template
- [ ] GitLab CI template
- [ ] Pre-commit hook

#### 10.3 External Services
- [ ] Kindle Direct Publishing (KDP) format check
- [ ] Apple Books format check
- [ ] ISBN barcode generation
- [ ] DOI support for academic papers

---

## Version Targets

### v1.0.0 - Feature Complete ✓ ACHIEVED (Current)
All phases A through E complete in a single comprehensive release:
- [x] Phase A: Quick Wins - CI badge, error codes, help output
- [x] Phase B: Testing & Quality - 176 tests, shellcheck, CONTRIBUTING.md
- [x] Phase C: Documentation - Tutorials, FAQ, troubleshooting, 5 examples
- [x] Phase D: Modularization - 8 lib modules, 51 unit tests
- [x] Phase E: New Features - Bibliography, index, templates, validation, multi-file
- [x] Core PDF/EPUB functionality with cover generation
- [x] Docker and CI/CD pipeline
- [x] Comprehensive test suite (176 tests)

### v1.1.0 - Future (Planned)
- [ ] Configuration files (~/.mdtexpdf/config.yaml, .mdtexpdf.yaml)
- [ ] Cross-references (figure/table/chapter references)
- [ ] Template variables documentation

### v2.0.0 - Future (Planned)
- [ ] Print-ready PDF options (bleed, CMYK, PDF/X)
- [ ] Package manager distribution (Homebrew, APT, AUR)
- [ ] Editor integrations (VS Code, Vim, Emacs)

---

*Quality over speed. Each phase completed thoroughly before moving on.*
