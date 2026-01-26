#!/bin/bash

# =============================================================================
# mdtexpdf - Markdown to PDF/EPUB converter using LaTeX
# =============================================================================
VERSION="1.0.0"
MDTEXPDF_VERSION="$VERSION"

# =============================================================================
# Module Loading
# =============================================================================
# Determine script directory for module loading
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source modules if available (for installed version, modules are in lib/)
if [ -d "$SCRIPT_DIR/lib" ]; then
    # Source in order of dependency
    [ -f "$SCRIPT_DIR/lib/core.sh" ] && source "$SCRIPT_DIR/lib/core.sh"
    [ -f "$SCRIPT_DIR/lib/check.sh" ] && source "$SCRIPT_DIR/lib/check.sh"
    [ -f "$SCRIPT_DIR/lib/metadata.sh" ] && source "$SCRIPT_DIR/lib/metadata.sh"
    [ -f "$SCRIPT_DIR/lib/preprocess.sh" ] && source "$SCRIPT_DIR/lib/preprocess.sh"
    [ -f "$SCRIPT_DIR/lib/epub.sh" ] && source "$SCRIPT_DIR/lib/epub.sh"
    [ -f "$SCRIPT_DIR/lib/bibliography.sh" ] && source "$SCRIPT_DIR/lib/bibliography.sh"
    [ -f "$SCRIPT_DIR/lib/template.sh" ] && source "$SCRIPT_DIR/lib/template.sh"
    [ -f "$SCRIPT_DIR/lib/pdf.sh" ] && source "$SCRIPT_DIR/lib/pdf.sh"
    [ -f "$SCRIPT_DIR/lib/convert.sh" ] && source "$SCRIPT_DIR/lib/convert.sh"
    [ -f "$SCRIPT_DIR/lib/args.sh" ] && source "$SCRIPT_DIR/lib/args.sh"
fi

# =============================================================================
# Exit Codes
# =============================================================================
# 0 = Success
# 1 = User error (invalid arguments, missing input file)
# 2 = Missing dependency (pandoc, latex, etc.)
# 3 = Conversion failure (pandoc or latex error)
# 4 = File system error (cannot read/write files)
# 5 = Configuration error (invalid metadata, bad YAML)
EXIT_SUCCESS=0
EXIT_USER_ERROR=1
EXIT_MISSING_DEP=2
EXIT_CONVERSION_FAIL=3
EXIT_FILE_ERROR=4
EXIT_CONFIG_ERROR=5

# Verbosity levels
VERBOSE=false
DEBUG=false

# ANSI color codes
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_verbose() {
    if [ "$VERBOSE" = true ] || [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[INFO]${NC} $*"
    fi
}

log_debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $*"
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

# Default TOC depth (3 = subsubsection level)
DEFAULT_TOC_DEPTH=2

# Default TOC setting (false = no TOC)
DEFAULT_TOC=false

# Default section numbering (true = numbered sections)
DEFAULT_SECTION_NUMBERS=true

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

# Function to check if a LaTeX package is available
check_latex_package() {
    if kpsewhich "$1.sty" &> /dev/null; then
        echo -e "${GREEN}✓ LaTeX package $1 is available${NC}"
        return 0
    else
        echo -e "${RED}✗ LaTeX package $1 is not available${NC}"
        return 1
    fi
}

# Note: parse_html_metadata(), parse_yaml_metadata(), and apply_metadata_args()
# are now in lib/metadata.sh

# Function to validate EPUB with epubcheck
# Returns 0 if valid, 1 if invalid or epubcheck not available
validate_epub() {
    local epub_file="$1"

    if [ ! -f "$epub_file" ]; then
        echo -e "${RED}Error: EPUB file not found for validation${NC}"
        return 1
    fi

    # Check if epubcheck is available
    if ! command -v epubcheck &> /dev/null; then
        echo -e "${YELLOW}Warning: epubcheck not installed. Install with: sudo apt install epubcheck${NC}"
        echo -e "${YELLOW}Skipping EPUB validation.${NC}"
        return 2
    fi

    echo -e "${BLUE}Validating EPUB with epubcheck...${NC}"

    # Run epubcheck and capture output
    local validation_output
    local validation_result
    validation_output=$(epubcheck "$epub_file" 2>&1)
    validation_result=$?

    if [ $validation_result -eq 0 ]; then
        echo -e "${GREEN}✓ EPUB validation passed - no errors found${NC}"
        return 0
    else
        echo -e "${YELLOW}EPUB validation completed with issues:${NC}"
        # Show only errors and warnings, not info messages
        echo "$validation_output" | grep -E "(ERROR|WARNING)" | head -20
        local error_count
        local warning_count
        error_count=$(echo "$validation_output" | grep -c "ERROR" || echo "0")
        warning_count=$(echo "$validation_output" | grep -c "WARNING" || echo "0")
        echo -e "${YELLOW}Summary: $error_count errors, $warning_count warnings${NC}"

        if [ "$error_count" -gt 0 ]; then
            echo -e "${RED}✗ EPUB has validation errors${NC}"
            return 1
        else
            echo -e "${GREEN}✓ EPUB valid (warnings only)${NC}"
            return 0
        fi
    fi
}

# Function to fix EPUB spine order (move TOC after front matter)
# In standard book conventions, the TOC should come after title, copyright, dedication, epigraph
fix_epub_spine_order() {
    local epub_file="$1"

    if [ ! -f "$epub_file" ]; then
        echo -e "${YELLOW}Warning: EPUB file not found for spine reordering${NC}"
        return 1
    fi

    # Convert to absolute path for later use after cd
    local epub_file_abs
    epub_file_abs=$(realpath "$epub_file")

    echo -e "${BLUE}Reordering EPUB spine (moving TOC after front matter)...${NC}"

    # Create temp directory for extraction
    local temp_dir
    temp_dir=$(mktemp -d)
    local original_dir
    original_dir=$(pwd)

    # Extract EPUB
    unzip -q "$epub_file_abs" -d "$temp_dir" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warning: Could not extract EPUB for spine reordering${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    local content_opf="$temp_dir/EPUB/content.opf"
    if [ ! -f "$content_opf" ]; then
        echo -e "${YELLOW}Warning: content.opf not found in EPUB${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    # Count how many front matter chapters we have (title-page, copyright-page, dedication-page, epigraph-page)
    # These are marked with specific classes in our generated XHTML files
    local frontmatter_count=0
    for xhtml_file in "$temp_dir"/EPUB/text/ch*.xhtml; do
        if [ -f "$xhtml_file" ]; then
            # Check if this chapter is a front matter page (has specific classes)
            if grep -q 'class=".*\(title-page\|copyright-page\|dedication-page\|epigraph-page\)' "$xhtml_file" 2>/dev/null; then
                frontmatter_count=$((frontmatter_count + 1))
            else
                # Stop counting when we hit non-frontmatter content
                break
            fi
        fi
    done

    if [ "$frontmatter_count" -eq 0 ]; then
        echo -e "${BLUE}No front matter pages detected, keeping default spine order${NC}"
        rm -rf "$temp_dir"
        return 0
    fi

    echo -e "${BLUE}Found $frontmatter_count front matter pages${NC}"

    # Use sed/awk to reorder the spine in content.opf
    # We need to move <itemref idref="nav" /> to come after the front matter itemrefs

    # Check if nav is in the spine
    if ! grep -q '<itemref idref="nav"' "$content_opf"; then
        echo -e "${BLUE}No nav item in spine, nothing to reorder${NC}"
        rm -rf "$temp_dir"
        return 0
    fi

    # Create a modified content.opf
    # Strategy: Extract spine section, reorder it, put it back
    local temp_opf
    temp_opf=$(mktemp)

    # Use awk to reorder: move nav itemref after the first N chapter itemrefs (where N = frontmatter_count)
    awk -v fm_count="$frontmatter_count" '
    BEGIN { in_spine = 0; nav_line = ""; ch_count = 0; buffer = "" }
    /<spine/ { in_spine = 1 }
    /<\/spine>/ { in_spine = 0 }
    {
        if (in_spine) {
            if (match($0, /<itemref idref="nav"/)) {
                # Store nav line, do not print yet
                nav_line = $0
            } else if (match($0, /<itemref idref="ch[0-9]+_xhtml"/)) {
                ch_count++
                print $0
                # After printing fm_count chapters, insert the nav line
                if (ch_count == fm_count && nav_line != "") {
                    print nav_line
                    nav_line = ""
                }
            } else {
                print $0
            }
        } else {
            print $0
        }
    }
    END {
        # If nav was never inserted (fm_count > total chapters), append it
        if (nav_line != "") {
            # This should not happen in normal cases
        }
    }
    ' "$content_opf" > "$temp_opf"

    # Replace original content.opf
    mv "$temp_opf" "$content_opf"

    # Repackage EPUB (must maintain proper structure)
    # EPUB requires mimetype to be first and uncompressed
    rm -f "$epub_file_abs"
    cd "$temp_dir" || return 1

    # Create new EPUB with proper structure (using absolute path)
    zip -X0 "$epub_file_abs" mimetype 2>/dev/null
    zip -Xr9D "$epub_file_abs" META-INF EPUB 2>/dev/null

    cd "$original_dir" || return 1

    # Cleanup
    rm -rf "$temp_dir"

    echo -e "${GREEN}EPUB spine reordered: TOC now appears after front matter${NC}"
    return 0
}

# Function to convert markdown to PDF
convert() {
    # Parse command-line arguments (from lib/args.sh)
    if ! parse_convert_args "$@"; then
        return 1
    fi

    # Validate arguments
    if ! validate_convert_args; then
        return 1
    fi

    # Check prerequisites first
    if ! check_prerequisites; then
        return 1
    fi

    # Handle multi-file projects (--include option) - from lib/args.sh
    if ! handle_include_files; then
        return 1
    fi

    # Parse metadata from YAML frontmatter if --read-metadata flag is set or EPUB output
    if [ "$ARG_READ_METADATA" = true ] || [ "$ARG_EPUB" = true ]; then
        parse_yaml_metadata "$INPUT_FILE"
        apply_metadata_args "$ARG_READ_METADATA"
    fi

    # Select PDF engine based on document content (Unicode detection)
    if ! select_pdf_engine "$INPUT_FILE"; then
        return 1
    fi
    echo -e "Using PDF engine: ${GREEN}$PDF_ENGINE${NC}"

    # Create a backup of the original markdown file
    BACKUP_FILE="${INPUT_FILE}.bak"
    echo -e "${BLUE}Creating backup of original markdown file: $BACKUP_FILE${NC}"
    cp "$INPUT_FILE" "$BACKUP_FILE"

    # If output file is not specified, derive from input file
    if [ -z "$OUTPUT_FILE" ]; then
        if [ "$ARG_EPUB" = true ]; then
            OUTPUT_FILE="${INPUT_FILE%.md}.epub"
        else
            OUTPUT_FILE="${INPUT_FILE%.md}.pdf"
        fi
    fi

    # ============== EPUB OUTPUT ==============
    if [ "$ARG_EPUB" = true ]; then
        # EPUB generation is handled by lib/epub.sh
        generate_epub
        return $?
    fi
    # ============== END EPUB OUTPUT ==============

    # ============== PDF OUTPUT ==============
    # PDF generation is handled by lib/convert.sh
    generate_pdf
    return $?

}

# Function to create a new markdown document with LaTeX template
create() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: No output file specified.${NC}"
        echo -e "Usage: mdtexpdf create <output.md> [title] [author]"
        return 1
    fi

    OUTPUT_FILE="$1"

    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "${RED}Error: File '$OUTPUT_FILE' already exists.${NC}"
        echo -e "Use a different filename or delete the existing file."
        return 1
    fi

    echo -e "${YELLOW}Creating new markdown document: $OUTPUT_FILE${NC}"

    # Interactive mode - ask for document details
    if [ -z "$2" ]; then
        echo -e "${GREEN}Enter document title:${NC}"
        read -r TITLE
        TITLE=${TITLE:-"My Document"}
    else
        TITLE="$2"
    fi

    if [ -z "$3" ]; then
        echo -e "${GREEN}Enter author name:${NC}"
        read -r AUTHOR
        AUTHOR=${AUTHOR:-"$(whoami)"}
    else
        AUTHOR="$3"
    fi

    echo -e "${GREEN}Enter document date [$(date +"%B %d, %Y")]:${NC}"
    read -r DOC_DATE
    DOC_DATE=${DOC_DATE:-"$(date +"%B %d, %Y")"}

    # Always ask about footer preferences
    echo -e "${GREEN}Do you want to add a footer to your document? (y/n) [y]:${NC}"
    read -r ADD_FOOTER
    ADD_FOOTER=${ADD_FOOTER:-"y"}

    if [[ $ADD_FOOTER =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Enter footer text (press Enter for default '© All rights reserved $(date +"%Y")'):${NC}"
        read -r FOOTER_TEXT
        FOOTER_TEXT=${FOOTER_TEXT:-"© All rights reserved $(date +"%Y")"}
    else
        FOOTER_TEXT=""
    fi

    # Always create a new template.tex in the current directory
    TEMPLATE_PATH="$(pwd)/template.tex"
    echo -e "${YELLOW}Creating template file: $TEMPLATE_PATH${NC}"

    # Create the template file
    create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" "" "true" "article" "content-only"

    if [ ! -f "$TEMPLATE_PATH" ]; then
        echo -e "${RED}Error: Failed to create template.tex.${NC}"
        return 1
    fi

    echo -e "${GREEN}Created new template file: $TEMPLATE_PATH${NC}"

    # Debug output to show which template is being used
    echo -e "${BLUE}Debug: Template path is $TEMPLATE_PATH${NC}"

    # Create the markdown file with YAML frontmatter and example content
    cat > "$OUTPUT_FILE" << EOF
---
title: "$TITLE"
author: "$AUTHOR"
$([ -n "$DOC_DATE" ] && echo "date: \"$DOC_DATE\"")
output:
  pdf_document:
    template: template.tex
---

# $TITLE

## Introduction

This is a sample document created with mdtexpdf. You can write regular Markdown text here.

## LaTeX Math Support

You can include inline math equations like this: \$E = mc^2\$ or \\\(F = ma\\\).

For display equations, use double dollar signs:

\$\$\\int_{a}^{b} f(x) \\, dx = F(b) - F(a)\$\$

## Formatting

You can use **bold text**, *italic text*, and \`code\`.

- Bullet points
- Work as expected

1. Numbered lists
2. Also work well

> Blockquotes are supported too.

## Tables

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

## Code Blocks

\`\`\`python
def hello_world():
    print("Hello, world!")
\`\`\`

---
EOF

    local create_result=$?
    if [ $create_result -eq 0 ]; then
        echo -e "${GREEN}Success! Markdown document created as $OUTPUT_FILE${NC}"
        echo -e "You can now edit this file and convert it to PDF using:"
        echo -e "${BLUE}mdtexpdf convert $OUTPUT_FILE${NC}"
        return 0
    else
        echo -e "${RED}Error: Failed to create markdown document.${NC}"
        return 1
    fi
}

# Function to install the script
install() {
    echo
    echo -e "${GREEN}Installing mdtexpdf...${NC}"
    if sudo -v; then
        # Create directories for templates and resources
        sudo mkdir -p /usr/local/share/mdtexpdf/templates
        sudo mkdir -p /usr/local/share/mdtexpdf/examples

        # Copy the script to /usr/local/bin
        sudo cp "$0" /usr/local/bin/mdtexpdf
        sudo chmod 755 /usr/local/bin/mdtexpdf

        # Copy the Lua filters if they exist
        SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

        # Copy heading fix filter
        if [ -f "$SCRIPT_DIR/heading_fix_filter.lua" ]; then
            sudo cp "$SCRIPT_DIR/heading_fix_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/heading_fix_filter.lua
            echo -e "${GREEN}✓ Installed heading_fix_filter.lua for fixing heading line breaks${NC}"
        elif [ -f "$(pwd)/heading_fix_filter.lua" ]; then
            sudo cp "$(pwd)/heading_fix_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/heading_fix_filter.lua
            echo -e "${GREEN}✓ Installed heading_fix_filter.lua for fixing heading line breaks${NC}"
        else
            echo -e "${YELLOW}Warning: heading_fix_filter.lua not found. Level 4 and 5 headings may run inline.${NC}"
        fi

        # Copy long equation filter
        # Install filters directory
        sudo mkdir -p /usr/local/share/mdtexpdf/filters
        if [ -f "$SCRIPT_DIR/filters/long_equation_filter.lua" ]; then
            sudo cp "$SCRIPT_DIR/filters/long_equation_filter.lua" /usr/local/share/mdtexpdf/filters/
            sudo chmod 644 /usr/local/share/mdtexpdf/filters/long_equation_filter.lua
            echo -e "${GREEN}✓ Installed long_equation_filter.lua for handling text-heavy equations${NC}"
        elif [ -f "$(pwd)/filters/long_equation_filter.lua" ]; then
            sudo cp "$(pwd)/filters/long_equation_filter.lua" /usr/local/share/mdtexpdf/filters/
            sudo chmod 644 /usr/local/share/mdtexpdf/filters/long_equation_filter.lua
            echo -e "${GREEN}✓ Installed long_equation_filter.lua for handling text-heavy equations${NC}"
        else
            echo -e "${YELLOW}Warning: long_equation_filter.lua not found. Long equations may not wrap properly.${NC}"
        fi

        # Copy image size filter
        if [ -f "$SCRIPT_DIR/image_size_filter.lua" ]; then
            sudo cp "$SCRIPT_DIR/image_size_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/image_size_filter.lua
            echo -e "${GREEN}✓ Installed image_size_filter.lua for automatic image sizing${NC}"
        elif [ -f "$(pwd)/image_size_filter.lua" ]; then
            sudo cp "$(pwd)/image_size_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/image_size_filter.lua
            echo -e "${GREEN}✓ Installed image_size_filter.lua for automatic image sizing${NC}"
        else
            echo -e "${YELLOW}Warning: image_size_filter.lua not found. Images may not be properly sized.${NC}"
        fi

        # Install book_structure.lua filter
        local book_filter_src=""
        if [ -f "$SCRIPT_DIR/filters/book_structure.lua" ]; then
            book_filter_src="$SCRIPT_DIR/filters/book_structure.lua"
        elif [ -f "$(pwd)/filters/book_structure.lua" ]; then
            book_filter_src="$(pwd)/filters/book_structure.lua"
        fi

        if [ -n "$book_filter_src" ]; then
            sudo cp "$book_filter_src" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/book_structure.lua
            echo -e "${GREEN}✓ Installed book_structure.lua for book format${NC}"
        else
            echo -e "${YELLOW}Warning: book_structure.lua not found. Book format may not work correctly.${NC}"
        fi

        # Install drop_caps_filter.lua filter
        local drop_caps_filter_src=""
        if [ -f "$SCRIPT_DIR/filters/drop_caps_filter.lua" ]; then
            drop_caps_filter_src="$SCRIPT_DIR/filters/drop_caps_filter.lua"
        elif [ -f "$(pwd)/filters/drop_caps_filter.lua" ]; then
            drop_caps_filter_src="$(pwd)/filters/drop_caps_filter.lua"
        fi

        if [ -n "$drop_caps_filter_src" ]; then
            sudo cp "$drop_caps_filter_src" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/drop_caps_filter.lua
            echo -e "${GREEN}✓ Installed drop_caps_filter.lua for drop caps${NC}"
        else
            echo -e "${YELLOW}Warning: drop_caps_filter.lua not found. Drop caps will not be available.${NC}"
        fi

        # Copy templates to the shared directory

        # Look for templates in various locations
        if [ -d "$SCRIPT_DIR/templates" ]; then
            sudo cp -r "$SCRIPT_DIR/templates/"* /usr/local/share/mdtexpdf/templates/
            sudo chmod 644 /usr/local/share/mdtexpdf/templates/*
        elif [ -f "$SCRIPT_DIR/template.tex" ]; then
            sudo cp "$SCRIPT_DIR/template.tex" /usr/local/share/mdtexpdf/templates/
            sudo chmod 644 /usr/local/share/mdtexpdf/templates/template.tex
        fi

        # Copy example files
        if [ -d "$SCRIPT_DIR/examples" ]; then
            sudo cp -r "$SCRIPT_DIR/examples/"* /usr/local/share/mdtexpdf/examples/
            sudo chmod 644 /usr/local/share/mdtexpdf/examples/*
        elif [ -f "$SCRIPT_DIR/document.md" ] || [ -f "$SCRIPT_DIR/example.md" ]; then
            [ -f "$SCRIPT_DIR/document.md" ] && sudo cp "$SCRIPT_DIR/document.md" /usr/local/share/mdtexpdf/examples/
            [ -f "$SCRIPT_DIR/example.md" ] && sudo cp "$SCRIPT_DIR/example.md" /usr/local/share/mdtexpdf/examples/
            sudo chmod 644 /usr/local/share/mdtexpdf/examples/*
        else
            echo -e "${YELLOW}Warning: template.tex not found in the script directory.${NC}"
            echo -e "You'll need to provide your own template.tex file when converting documents."
        fi

        echo
        echo -e "${PURPLE}mdtexpdf has been installed successfully.${NC}"
        echo -e "You can now use ${GREEN}mdtexpdf${NC} command from anywhere."
        echo
        echo -e "Use ${BLUE}mdtexpdf help${NC} to see the commands."
        echo
    else
        log_error "Failed to obtain sudo privileges. Installation aborted."
        exit $EXIT_USER_ERROR
    fi
}

# Function to uninstall the script
uninstall() {
    echo
    echo -e "${GREEN}Uninstalling mdtexpdf...${NC}"
    if sudo -v; then
        echo -e "${YELLOW}Removing executable...${NC}"
        sudo rm -f /usr/local/bin/mdtexpdf

        echo -e "${YELLOW}Removing shared files...${NC}"
        sudo rm -rf /usr/local/share/mdtexpdf

        echo -e "${PURPLE}mdtexpdf has been uninstalled successfully.${NC}"
        echo
    else
        log_error "Failed to obtain sudo privileges. Uninstallation aborted."
        exit $EXIT_USER_ERROR
    fi
}

# Function to display help information
help() {
    echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}      mdtexpdf - Markdown to PDF/EPUB       ${NC}"
    echo -e "${YELLOW}              Version $VERSION              ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

    echo -e "${PURPLE}Description:${NC} mdtexpdf is a tool for converting Markdown documents to PDF and EPUB using LaTeX."
    echo -e "${PURPLE}             It supports LaTeX math equations, custom templates, and more.${NC}"
    echo -e "${PURPLE}Usage:${NC}       mdtexpdf [global-options] <command> [arguments]"
    echo -e "${PURPLE}License:${NC}     Apache 2.0"
    echo -e "${PURPLE}Code:${NC}        https://github.com/ucli-tools/mdtexpdf\n"

    echo -e "${PURPLE}Global Options:${NC}"
    echo -e "  ${GREEN}--version, -V${NC}     Show version number"
    echo -e "  ${GREEN}--verbose, -v${NC}     Enable verbose output"
    echo -e "  ${GREEN}--debug${NC}           Enable debug output (includes verbose)\n"

    echo -e "${PURPLE}Commands:${NC}"
    echo -e "  ${GREEN}convert [options] <input.md> [output.pdf]${NC}"
    echo -e "                  ${BLUE}Convert a Markdown file to PDF using LaTeX${NC}"
    echo -e "                  ${BLUE}Options:${NC}"
    echo -e "                    ${BLUE}-t, --title TITLE     Set document title${NC}"
    echo -e "                    ${BLUE}-a, --author AUTHOR   Set document author${NC}"
    echo -e "                    ${BLUE}--toc                 Include table of contents${NC}"
    echo -e "                    ${BLUE}--toc-depth DEPTH     Set table of contents depth (1-5, default: $DEFAULT_TOC_DEPTH)${NC}"
    echo -e "                    ${BLUE}--no-numbers          Disable section numbering (1.1, 1.2, etc.)${NC}"
    echo -e "                    ${BLUE}-d, --date [VALUE]    Set document date. Special values:${NC}"
    echo -e "                    ${BLUE}                        - no argument: current date in default format${NC}"
    echo -e "                    ${BLUE}                        - \"no\": disable date${NC}"
    echo -e "                    ${BLUE}                        - \"yes\": current date in default format${NC}"
    echo -e "                    ${BLUE}                        - \"YYYY-MM-DD\": current date in YYYY-MM-DD format${NC}"
    echo -e "                    ${BLUE}                        - \"DD/MM/YY\": current date in DD/MM/YY format${NC}"
    echo -e "                    ${BLUE}                        - \"Month Day, Year\": current date in Month Day, Year format${NC}"
    echo -e "                    ${BLUE}                        - any other value: use as custom date text${NC}"
    echo -e "                    ${BLUE}--no-date             Disable date (same as -d \"no\")${NC}"
    echo -e "                    ${BLUE}-f, --footer TEXT     Set footer text${NC}"
    echo -e "                    ${BLUE}--no-footer           Disable footer${NC}"
    echo -e "                    ${BLUE}--pageof              Use 'Page X of Y' format in footer${NC}"
    echo -e "                    ${BLUE}--date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\"${NC}"
    echo -e "                    ${BLUE}--read-metadata       Read metadata from HTML comments in markdown file${NC}"
    echo -e "                    ${BLUE}--format FORMAT       Set document format (article or book)${NC}"
    echo -e "                    ${BLUE}--header-footer-policy POLICY Set header/footer policy (default, partial, all). Default: default${NC}"
    echo -e "                    ${BLUE}--epub                Output EPUB format instead of PDF${NC}"
    echo -e "                    ${BLUE}--validate            Validate EPUB with epubcheck (requires epubcheck)${NC}"
    echo -e "                    ${BLUE}-b, --bibliography FILE  Use bibliography file (.bib, .json, .yaml, .md)${NC}"
    echo -e "                    ${BLUE}--csl FILE            Use CSL citation style file${NC}"
    echo -e "                    ${BLUE}--template FILE       Use custom LaTeX template for PDF${NC}"
    echo -e "                    ${BLUE}--epub-css FILE       Use custom CSS for EPUB${NC}"
    echo -e "                    ${BLUE}-i, --include FILE    Include additional markdown file (repeatable)${NC}"
    echo -e "                    ${BLUE}--index               Generate index from [index:term] markers${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf convert document.md"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf convert -a \"John Doe\" -t \"My Document\" --toc --toc-depth 3 document.md output.pdf\n"

    echo -e "  ${GREEN}create <output.md> [title] [author]${NC}"
    echo -e "                  ${BLUE}Create a new Markdown document with LaTeX template${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf create document.md"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf create document.md \"My Title\" \"Author Name\"\n"

    echo -e "  ${GREEN}check${NC}"
    echo -e "                  ${BLUE}Check if all prerequisites are installed${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf check\n"

    echo -e "  ${GREEN}validate <file.epub>${NC}"
    echo -e "                  ${BLUE}Validate an EPUB file with epubcheck${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf validate book.epub\n"

    echo -e "  ${GREEN}install${NC}"
    echo -e "                  ${BLUE}Install mdtexpdf system-wide${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf install\n"

    echo -e "  ${GREEN}uninstall${NC}"
    echo -e "                  ${BLUE}Remove mdtexpdf from the system${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf uninstall\n"

    echo -e "  ${GREEN}help${NC}"
    echo -e "                  ${BLUE}Display this help information${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf help\n"

    echo -e "  ${GREEN}version${NC}"
    echo -e "                  ${BLUE}Display version information${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf version\n"

    echo -e "${PURPLE}Exit Codes:${NC}"
    echo -e "  0 - Success"
    echo -e "  1 - User error (invalid arguments, missing input)"
    echo -e "  2 - Missing dependency (pandoc, latex, etc.)"
    echo -e "  3 - Conversion failure"
    echo -e "  4 - File system error"
    echo -e "  5 - Configuration error\n"

    echo -e "${PURPLE}Prerequisites:${NC}"
    echo -e "  - Pandoc: Document conversion tool"
    echo -e "  - LaTeX: PDF generation engine (pdflatex, xelatex, or lualatex)"
    echo -e "  - LaTeX Packages: Various packages for formatting and math support"
    echo -e "  - ImageMagick (optional): For EPUB cover generation with text overlay\n"

    echo -e "${PURPLE}Documentation:${NC}"
    echo -e "  README.md          - Overview and quick start"
    echo -e "  docs/METADATA.md   - Complete metadata field reference"
    echo -e "  docs/AUTHORSHIP.md - Cryptographic authorship guide"
    echo -e "  docs/ROADMAP.md    - Planned features\n"

    echo -e "${PURPLE}For more information:${NC} https://github.com/ucli-tools/mdtexpdf\n"
}

# Parse global flags first
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version|-V)
            echo "mdtexpdf version $VERSION"
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --debug)
            DEBUG=true
            VERBOSE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Main script execution
case "$1" in
    convert)
        shift
        convert "$@"
        ;;
    create)
        shift
        create "$@"
        ;;
    check)
        check_prerequisites
        ;;
    validate)
        shift
        if [ -z "$1" ]; then
            log_error "No EPUB file specified."
            echo -e "Usage: ${BLUE}mdtexpdf validate <file.epub>${NC}"
            exit $EXIT_USER_ERROR
        fi
        if [ ! -f "$1" ]; then
            log_error "EPUB file '$1' not found."
            exit $EXIT_USER_ERROR
        fi
        validate_epub "$1"
        ;;
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    help|--help|-h)
        help
        ;;
    version)
        echo "mdtexpdf version $VERSION"
        ;;
    *)
        if [ -z "$1" ]; then
            log_error "No command specified."
        else
            log_error "Unknown command '$1'."
        fi
        echo -e "Use ${BLUE}mdtexpdf help${NC} to see the commands."
        exit $EXIT_USER_ERROR
        ;;
esac

exit $EXIT_SUCCESS
