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

# Source modules if available
# Check script dir first (dev), then ~/.local (user), then /usr/local (system)
LIB_DIR=""
if [ -d "$SCRIPT_DIR/lib" ]; then
    LIB_DIR="$SCRIPT_DIR/lib"
elif [ -d "$HOME/.local/share/mdtexpdf/lib" ]; then
    LIB_DIR="$HOME/.local/share/mdtexpdf/lib"
elif [ -d "/usr/local/share/mdtexpdf/lib" ]; then
    LIB_DIR="/usr/local/share/mdtexpdf/lib"
fi

if [ -n "$LIB_DIR" ]; then
    # Source in order of dependency
    [ -f "$LIB_DIR/core.sh" ] && source "$LIB_DIR/core.sh"
    [ -f "$LIB_DIR/check.sh" ] && source "$LIB_DIR/check.sh"
    [ -f "$LIB_DIR/metadata.sh" ] && source "$LIB_DIR/metadata.sh"
    [ -f "$LIB_DIR/preprocess.sh" ] && source "$LIB_DIR/preprocess.sh"
    [ -f "$LIB_DIR/epub.sh" ] && source "$LIB_DIR/epub.sh"
    [ -f "$LIB_DIR/bibliography.sh" ] && source "$LIB_DIR/bibliography.sh"
    [ -f "$LIB_DIR/template.sh" ] && source "$LIB_DIR/template.sh"
    [ -f "$LIB_DIR/pdf.sh" ] && source "$LIB_DIR/pdf.sh"
    [ -f "$LIB_DIR/convert.sh" ] && source "$LIB_DIR/convert.sh"
    [ -f "$LIB_DIR/lulu.sh" ] && source "$LIB_DIR/lulu.sh"
    [ -f "$LIB_DIR/args.sh" ] && source "$LIB_DIR/args.sh"
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

# Note: Color codes, logging functions, check_command(), check_latex_package(),
# and default constants (DEFAULT_TOC_DEPTH, etc.) are defined in lib/core.sh
#
# EPUB functions (validate_epub, fix_epub_spine_order, generate_epub)
# are defined in lib/epub.sh
#
# Metadata functions (parse_yaml_metadata, parse_html_metadata, apply_metadata_args)
# are defined in lib/metadata.sh

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
        local _metadata_source=""
        local _metadata_temp=""

        # Priority: --metadata-file > auto-detect metadata.yaml > embedded YAML
        if [ -n "$ARG_METADATA_FILE" ]; then
            if [ -f "$ARG_METADATA_FILE" ]; then
                _metadata_source="$ARG_METADATA_FILE"
                echo -e "${GREEN}Using metadata file: $_metadata_source${NC}"
            else
                echo -e "${RED}Error: Metadata file '$ARG_METADATA_FILE' not found${NC}"
                return 1
            fi
        else
            # Auto-detect metadata.yaml next to the input file
            local _input_dir
            _input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$_input_dir/metadata.yaml" ]; then
                _metadata_source="$_input_dir/metadata.yaml"
                echo -e "${GREEN}Auto-detected metadata file: $_metadata_source${NC}"
            fi
        fi

        if [ -n "$_metadata_source" ]; then
            # Wrap standalone YAML in --- delimiters for parse_yaml_metadata
            _metadata_temp=$(mktemp --suffix=.md)
            printf '%s\n' "---" > "$_metadata_temp"
            cat "$_metadata_source" >> "$_metadata_temp"
            printf '%s\n' "---" >> "$_metadata_temp"
            parse_yaml_metadata "$_metadata_temp"
            rm -f "$_metadata_temp"
        else
            parse_yaml_metadata "$INPUT_FILE"
        fi

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

    # ============== LULU PRINT-READY OUTPUT ==============
    if [ "$ARG_LULU" = true ]; then
        # Lulu mode: generate interior PDF + cover spread into output directory
        local base_name
        base_name=$(basename "$INPUT_FILE" .md)
        generate_lulu_output "$INPUT_FILE" "$base_name"
        return $?
    fi

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

    if [ "$ARG_VERBOSE" = true ]; then
        echo -e "${BLUE}Template path: $TEMPLATE_PATH${NC}"
    fi

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
    local INSTALL_BIN="$HOME/.local/bin"
    local INSTALL_SHARE="$HOME/.local/share/mdtexpdf"

    echo
    echo -e "${GREEN}Installing mdtexpdf to ~/.local (no sudo required)...${NC}"

    # Create directories
    mkdir -p "$INSTALL_BIN"
    mkdir -p "$INSTALL_SHARE/templates"
    mkdir -p "$INSTALL_SHARE/examples"
    mkdir -p "$INSTALL_SHARE/lib"
    mkdir -p "$INSTALL_SHARE/filters"

    # Copy the script
    cp "$0" "$INSTALL_BIN/mdtexpdf"
    chmod 755 "$INSTALL_BIN/mdtexpdf"

    # Copy module libraries
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    if [ -d "$SCRIPT_DIR/lib" ]; then
        cp "$SCRIPT_DIR/lib"/*.sh "$INSTALL_SHARE/lib/"
        echo -e "${GREEN}✓ Installed module libraries${NC}"
    fi

    # Helper to install a filter
    _install_filter() {
        local name="$1" desc="$2" subdir="${3:-filters}"
        local src=""
        if [ -f "$SCRIPT_DIR/filters/$name" ]; then
            src="$SCRIPT_DIR/filters/$name"
        elif [ -f "$(pwd)/filters/$name" ]; then
            src="$(pwd)/filters/$name"
        fi
        if [ -n "$src" ]; then
            cp "$src" "$INSTALL_SHARE/$subdir/"
            echo -e "${GREEN}✓ Installed $name ($desc)${NC}"
        else
            echo -e "${YELLOW}Warning: $name not found.${NC}"
        fi
    }

    # Install all filters
    _install_filter "heading_fix_filter.lua" "heading line breaks"
    _install_filter "long_equation_filter.lua" "long equations"
    _install_filter "image_size_filter.lua" "image sizing"
    _install_filter "table_size_filter.lua" "wide tables"
    _install_filter "book_structure.lua" "book format" "."
    _install_filter "drop_caps_filter.lua" "drop caps" "."
    _install_filter "index_filter.lua" "subject index"
    _install_filter "equation_number_filter.lua" "equation numbering"

    # Copy templates
    if [ -d "$SCRIPT_DIR/templates" ]; then
        cp -r "$SCRIPT_DIR/templates/"* "$INSTALL_SHARE/templates/"
    elif [ -f "$SCRIPT_DIR/template.tex" ]; then
        cp "$SCRIPT_DIR/template.tex" "$INSTALL_SHARE/templates/"
    fi

    # Copy examples
    if [ -d "$SCRIPT_DIR/examples" ]; then
        cp -r "$SCRIPT_DIR/examples/"* "$INSTALL_SHARE/examples/"
    else
        [ -f "$SCRIPT_DIR/document.md" ] && cp "$SCRIPT_DIR/document.md" "$INSTALL_SHARE/examples/"
        [ -f "$SCRIPT_DIR/example.md" ] && cp "$SCRIPT_DIR/example.md" "$INSTALL_SHARE/examples/"
    fi

    echo
    echo -e "${PURPLE}mdtexpdf has been installed successfully.${NC}"
    echo -e "You can now use ${GREEN}mdtexpdf${NC} command from anywhere."
    if [[ ":$PATH:" != *":$INSTALL_BIN:"* ]]; then
        echo -e "${YELLOW}Note: Ensure ~/.local/bin is in your PATH.${NC}"
    fi
    echo
    echo -e "Use ${BLUE}mdtexpdf help${NC} to see the commands."
    echo
}

# Function to uninstall the script
uninstall() {
    local INSTALL_BIN="$HOME/.local/bin"
    local INSTALL_SHARE="$HOME/.local/share/mdtexpdf"

    echo
    echo -e "${GREEN}Uninstalling mdtexpdf...${NC}"

    echo -e "${YELLOW}Removing executable...${NC}"
    rm -f "$INSTALL_BIN/mdtexpdf"

    echo -e "${YELLOW}Removing shared files...${NC}"
    rm -rf "$INSTALL_SHARE"

    # Also clean up old system install if it exists and we have sudo
    if [ -f "/usr/local/bin/mdtexpdf" ]; then
        echo -e "${YELLOW}Old system install detected at /usr/local/bin/mdtexpdf${NC}"
        echo -e "${YELLOW}Run 'sudo rm -f /usr/local/bin/mdtexpdf && sudo rm -rf /usr/local/share/mdtexpdf' to remove it.${NC}"
    fi

    echo -e "${PURPLE}mdtexpdf has been uninstalled successfully.${NC}"
    echo
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
    echo -e "  README.md              - Overview and quick start"
    echo -e "  docs/mdtexpdf_guide.md - Comprehensive guide"
    echo -e "  docs/METADATA.md       - Complete metadata field reference\n"

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
