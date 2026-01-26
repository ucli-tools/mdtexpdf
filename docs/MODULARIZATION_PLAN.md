# Modularization Plan: Phase D2 — COMPLETE

## Objective

Reduce `mdtexpdf.sh` from 2,818 lines to ~600-800 lines by extracting the remaining inline logic into library modules.

**Result: 2,818 → 813 lines (71% reduction). All 38 tests passing.**

## Before / After

### Main Script

| Metric | Before | After |
|--------|--------|-------|
| `mdtexpdf.sh` | 2,818 lines | 813 lines |
| `convert()` function | 1,599 lines | 60 lines (orchestrator) |
| Total codebase | ~5,726 lines | 5,286 lines |

### convert() — Before (1,599 lines inline)

| Section | Lines |
|---------|-------|
| CLI argument parsing | 340 |
| EPUB generation | 453 |
| PDF generation | 806 |

### convert() — After (60-line orchestrator)

```bash
convert() {
    parse_convert_args "$@" || return 1      # lib/args.sh
    validate_convert_args || return 1         # lib/args.sh
    check_prerequisites || return 1           # lib/check.sh
    handle_include_files || return 1          # lib/args.sh

    if [ "$ARG_READ_METADATA" = true ] || [ "$ARG_EPUB" = true ]; then
        parse_yaml_metadata "$INPUT_FILE"     # lib/metadata.sh
        apply_metadata_args "$ARG_READ_METADATA"
    fi

    select_pdf_engine "$INPUT_FILE" || return 1  # lib/pdf.sh

    # Setup backup, output file...

    if [ "$ARG_EPUB" = true ]; then
        generate_epub                         # lib/epub.sh
        return $?
    fi

    generate_pdf                              # lib/convert.sh
    return $?
}
```

## Final Line Counts

| File | Before | After | Change |
|------|--------|-------|--------|
| mdtexpdf.sh | 2,818 | 813 | -2,005 |
| lib/args.sh | — | 334 | NEW |
| lib/convert.sh | — | 827 | NEW |
| lib/metadata.sh | 447 | 461 | +14 |
| lib/epub.sh | 280 | 670 | +390 |
| lib/bibliography.sh | 514 | 514 | — |
| lib/template.sh | 1,041 | 1,041 | — |
| lib/pdf.sh | 228 | 228 | — |
| lib/preprocess.sh | 167 | 167 | — |
| lib/core.sh | 127 | 127 | — |
| lib/check.sh | 104 | 104 | — |
| **Total** | **5,726** | **5,286** | **-440** |

Net reduction of 440 lines (removed duplication between main script and modules).

## Implementation Steps — All Complete

### Step 1: Create lib/args.sh ✓
- Created `lib/args.sh` (334 lines)
- Functions: `init_convert_args()`, `parse_convert_args()`, `validate_convert_args()`, `show_convert_usage()`, `handle_include_files()`
- Replaced ~250 lines of inline argument parsing in `convert()`
- Tests: 38/38 passing

### Step 2: Expand lib/metadata.sh ✓
- Added `META_BIBLIOGRAPHY`, `META_CSL`, `META_COVER_FIT` variables
- Added bibliography/CSL parsing to `parse_yaml_metadata()`
- Added bibliography/CSL handling to `apply_metadata_args()`
- Removed ~470 lines of duplicate metadata functions from main script
- Tests: 38/38 passing

### Step 3: Expand lib/epub.sh ✓
- Added `generate_epub()` function (~390 lines) to `lib/epub.sh`
- Handles: cover generation, chemistry preprocessing, front matter, bibliography, pandoc execution
- Replaced ~453 lines of inline EPUB code in `convert()`
- Tests: 38/38 passing

### Step 4: Create lib/convert.sh ✓
- Created `lib/convert.sh` (827 lines) with `generate_pdf()` function
- Handles: template resolution, Lua filter discovery, pandoc variable assembly, bibliography, pandoc execution, cleanup
- Replaced ~806 lines of inline PDF code in `convert()`
- Tests: 38/38 passing

### Step 5: Refactor convert() to orchestrator ✓
- `convert()` reduced to 60-line orchestrator
- Delegates all work to module functions
- Clear, readable flow: parse → validate → prerequisites → metadata → dispatch
- Tests: 38/38 passing

## Module Load Order

```
lib/core.sh          # Logging, utilities (no dependencies)
lib/check.sh         # Prerequisites checking
lib/metadata.sh      # YAML/HTML metadata parsing
lib/preprocess.sh    # Markdown preprocessing
lib/epub.sh          # EPUB generation
lib/bibliography.sh  # Bibliography format conversion
lib/template.sh      # LaTeX template generation
lib/pdf.sh           # PDF engine selection, cover detection
lib/convert.sh       # PDF conversion orchestration
lib/args.sh          # CLI argument parsing
```

## Architecture Notes

- All functions use global variables for state (existing pattern: `ARG_*`, `META_*`)
- Module load order matters: `core.sh` must load first
- Each module has a source guard for standalone testing
- No new features introduced — pure refactoring for maintainability
- Main script retains: version/constants, module loading, logging, `create()`, `install()`, `help()`, command dispatch
