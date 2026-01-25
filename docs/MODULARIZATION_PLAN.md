# Modularization Plan: Phase D2

## Objective

Reduce `mdtexpdf.sh` from 2,818 lines to ~600-800 lines by extracting the remaining inline logic into library modules.

## Current State

### Main Script Breakdown (2,818 lines)

| Function | Lines | Notes |
|----------|-------|-------|
| `convert()` | 1,599 | CLI parsing + EPUB + PDF generation |
| `parse_yaml_metadata()` | 247 | Should be in lib/metadata.sh |
| `parse_html_metadata()` | 142 | Should be in lib/metadata.sh |
| `create()` | 133 | Template creation command |
| `fix_epub_spine_order()` | 126 | Duplicate - already in lib/epub.sh |
| `install()` | 123 | System installation |
| `help()` | 104 | Help text |
| `apply_metadata_args()` | 77 | Should be in lib/metadata.sh |
| Small functions + main | ~267 | Logging, checks, dispatch |

### Inside `convert()` (1,599 lines)

| Section | Lines |
|---------|-------|
| CLI argument parsing | 340 |
| EPUB generation | 453 |
| PDF generation | 806 |

## Target State

### Main Script (~600-800 lines)

The main script should only contain:
- Version/constants (~20 lines)
- Module loading (~20 lines)
- Global flag parsing (~30 lines)
- Command dispatch (~80 lines)
- `convert()` orchestration (~150 lines) - calls module functions
- `create()` command (~130 lines)
- `install()`/`uninstall()` (~140 lines)
- `help()` (~100 lines)

### Module Changes

#### 1. lib/args.sh (NEW - ~350 lines)
Extract CLI argument parsing from `convert()`.

```bash
# Functions to add:
parse_convert_args()    # Parse --title, --author, --format, etc.
validate_convert_args() # Validate required args, file existence
```

#### 2. lib/metadata.sh (EXPAND - 447 → ~870 lines)
Move metadata parsing functions from main script.

```bash
# Functions to move from mdtexpdf.sh:
parse_yaml_metadata()   # 247 lines
parse_html_metadata()   # 142 lines
apply_metadata_args()   # 77 lines
```

#### 3. lib/epub.sh (EXPAND - 280 → ~730 lines)
Move EPUB generation logic from `convert()`.

```bash
# Functions to add:
generate_epub()         # Main EPUB generation (~450 lines)

# Already exists but duplicated in main:
fix_epub_spine_order()  # Remove duplicate from mdtexpdf.sh
```

#### 4. lib/convert.sh (NEW - ~800 lines)
Extract PDF generation logic from `convert()`.

```bash
# Functions to add:
convert_to_pdf()        # Main PDF conversion
build_pandoc_command()  # Build pandoc CLI arguments
detect_template()       # Find/create template.tex
setup_lua_filters()     # Configure Lua filters
run_pandoc()            # Execute pandoc with error handling
```

## Implementation Steps

### Step 1: Create lib/args.sh
1. Create new file with argument parsing logic
2. Extract CLI parsing from `convert()` (lines 1-340)
3. Add `parse_convert_args()` function
4. Update `convert()` to call `parse_convert_args "$@"`
5. Run tests

### Step 2: Expand lib/metadata.sh
1. Move `parse_yaml_metadata()` from mdtexpdf.sh
2. Move `parse_html_metadata()` from mdtexpdf.sh
3. Move `apply_metadata_args()` from mdtexpdf.sh
4. Update main script to remove these functions
5. Run tests

### Step 3: Expand lib/epub.sh
1. Extract EPUB generation section from `convert()`
2. Create `generate_epub()` function
3. Remove duplicate `fix_epub_spine_order()` from main
4. Update `convert()` to call `generate_epub()`
5. Run tests

### Step 4: Create lib/convert.sh
1. Create new file with PDF conversion logic
2. Extract PDF generation from `convert()` (~806 lines)
3. Create `convert_to_pdf()` as main entry point
4. Create helper functions for modularity
5. Update `convert()` to call `convert_to_pdf()`
6. Run tests

### Step 5: Refactor convert() to orchestrator
1. `convert()` becomes thin orchestration layer:
   ```bash
   convert() {
       parse_convert_args "$@" || return 1
       validate_convert_args || return 1
       
       if [ "$ARG_EPUB" = true ]; then
           generate_epub
       else
           convert_to_pdf
       fi
   }
   ```
2. Final cleanup and testing

## Expected Final Line Counts

| File | Current | After |
|------|---------|-------|
| mdtexpdf.sh | 2,818 | ~650 |
| lib/args.sh | - | ~350 |
| lib/metadata.sh | 447 | ~870 |
| lib/epub.sh | 280 | ~730 |
| lib/convert.sh | - | ~800 |
| lib/template.sh | 1,041 | 1,041 |
| lib/pdf.sh | 228 | 228 |
| lib/bibliography.sh | 514 | 514 |
| lib/preprocess.sh | 167 | 167 |
| lib/core.sh | 127 | 127 |
| lib/check.sh | 104 | 104 |
| **Total** | 5,726 | ~5,581 |

## Verification

After each step:
1. Run `bash -n` syntax check on all modified files
2. Run full test suite: `./tests/run_tests.sh`
3. Manual smoke test: convert a sample document

## Rollback Plan

Keep `mdtexpdf.sh.backup` until all tests pass. If issues arise:
```bash
cp mdtexpdf.sh.backup mdtexpdf.sh
```

## Notes

- All functions use global variables for state (existing pattern)
- Module load order matters: core.sh must load first
- New modules should follow existing style (header comments, function docs)
- No new features - pure refactoring for maintainability
