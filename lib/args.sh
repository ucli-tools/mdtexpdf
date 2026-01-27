#!/bin/bash
# =============================================================================
# mdtexpdf - Arguments Module
# =============================================================================
# CLI argument parsing for the convert command
#
# This module provides:
#   - init_convert_args() - Initialize argument variables
#   - parse_convert_args() - Parse CLI arguments for convert command
#   - show_convert_usage() - Display usage help for convert command
#
# Dependencies: lib/core.sh (for color variables)
# =============================================================================

# Initialize all convert command argument variables
# Sets global ARG_* variables to default values
init_convert_args() {
    ARG_TITLE=""
    ARG_AUTHOR=""
    ARG_DATE=""
    ARG_FOOTER=""
    ARG_NO_FOOTER=false
    ARG_DATE_FOOTER=""
    ARG_NO_DATE=false
    ARG_TOC_DEPTH=$DEFAULT_TOC_DEPTH
    ARG_TOC=$DEFAULT_TOC
    ARG_SECTION_NUMBERS=$DEFAULT_SECTION_NUMBERS
    ARG_PAGE_OF=false
    ARG_READ_METADATA=false
    ARG_FORMAT=""
    ARG_HEADER_FOOTER_POLICY="default"
    ARG_EPUB=false
    ARG_VALIDATE=false
    ARG_BIBLIOGRAPHY=""
    ARG_CSL=""
    ARG_TEMPLATE=""
    ARG_EPUB_CSS=""
    ARG_INCLUDE=()
    ARG_INDEX=false
    ARG_LULU=false
    ARG_TRIM_SIZE=""

    # Reset file variables
    INPUT_FILE=""
    OUTPUT_FILE=""
}

# Display usage help for convert command
show_convert_usage() {
    echo -e "Usage: mdtexpdf convert [options] <input.md> [output.pdf]"
    echo -e "Options:"
    echo -e "  -t, --title TITLE     Set document title"
    echo -e "  -a, --author AUTHOR   Set document author"
    echo -e "  --toc                 Include table of contents"
    echo -e "  --toc-depth DEPTH     Set table of contents depth (1-5, default: $DEFAULT_TOC_DEPTH)"
    echo -e "  --no-numbers          Disable section numbering (1.1, 1.2, etc.)"
    echo -e "  -d, --date [VALUE]    Set document date. Special values:"
    echo -e "                          - no argument: current date in default format"
    echo -e "                          - \"no\": disable date"
    echo -e "                          - \"yes\": current date in default format"
    echo -e "                          - \"YYYY-MM-DD\": current date in YYYY-MM-DD format"
    echo -e "                          - \"DD/MM/YY\": current date in DD/MM/YY format"
    echo -e "                          - \"Month Day, Year\": current date in Month Day, Year format"
    echo -e "                          - any other value: use as custom date text"
    echo -e "  --no-date             Disable date (same as -d \"no\")"
    echo -e "  -f, --footer TEXT     Set footer text"
    echo -e "  --no-footer           Disable footer"
    echo -e "  --pageof              Use 'Page X of Y' format in footer"
    echo -e "  --date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\""
    echo -e "  --read-metadata       Read metadata from HTML comments in markdown file"
    echo -e "  --format FORMAT       Set document format (article or book)"
    echo -e "  --header-footer-policy POLICY Set header/footer policy (default, partial, all). Default: default"
    echo -e "  --epub                Output EPUB format instead of PDF"
    echo -e "  --validate            Validate EPUB with epubcheck (requires epubcheck)"
    echo -e "  -b, --bibliography FILE  Use bibliography file (.bib, .json, .yaml, .md)"
    echo -e "  --csl FILE            Use CSL citation style file"
    echo -e "  --template FILE       Use custom LaTeX template for PDF"
    echo -e "  --epub-css FILE       Use custom CSS for EPUB"
    echo -e "  -i, --include FILE    Include additional markdown file (can be used multiple times)"
    echo -e "  --index               Generate index from [index:term] markers"
    echo -e "  --lulu                Generate Lulu.com print-ready output (interior + cover spread)"
    echo -e "  --trim-size SIZE      Set trim size: 5.5x8.5, 6x9, 7x10, a5, a4 (default: from metadata or a4)"
}

# Parse command-line arguments for convert command
# Arguments: All command-line arguments passed to convert
# Returns: 0 on success, 1 on error
# Sets: Global ARG_* variables, INPUT_FILE, OUTPUT_FILE
parse_convert_args() {
    # Initialize all argument variables
    init_convert_args

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)
                ARG_TITLE="$2"
                shift 2
                ;;
            --toc-depth)
                ARG_TOC_DEPTH="$2"
                shift 2
                ;;
            --toc)
                ARG_TOC=true
                shift
                ;;
            --no-numbers|--no-section-numbers)
                ARG_SECTION_NUMBERS=false
                shift
                ;;
            -a|--author)
                ARG_AUTHOR="$2"
                shift 2
                ;;
            -d|--date)
                if [[ "$2" == -* ]] || [ -z "$2" ]; then
                    # No argument provided or next argument is another option
                    ARG_DATE="$(date +"%B %d, %Y")"
                    echo -e "${GREEN}Using current date: $ARG_DATE${NC}"
                    shift
                else
                    # Argument provided
                    case "$2" in
                        "no")
                            ARG_NO_DATE=true
                            echo -e "${GREEN}Date will be disabled${NC}"
                            ;;
                        "yes")
                            ARG_DATE="$(date +"%B %d, %Y")"
                            echo -e "${GREEN}Using current date: $ARG_DATE${NC}"
                            ;;
                        "YYYY-MM-DD")
                            ARG_DATE="$(date +"%Y-%m-%d")"
                            echo -e "${GREEN}Using current date in YYYY-MM-DD format: $ARG_DATE${NC}"
                            ;;
                        "DD/MM/YY")
                            ARG_DATE="$(date +"%d/%m/%y")"
                            echo -e "${GREEN}Using current date in DD/MM/YY format: $ARG_DATE${NC}"
                            ;;
                        "Month Day, Year"|"month day, year")
                            ARG_DATE="$(date +"%B %d, %Y")"
                            echo -e "${GREEN}Using current date in Month Day, Year format: $ARG_DATE${NC}"
                            ;;
                        *)
                            # Use the provided value as the date
                            ARG_DATE="$2"
                            echo -e "${GREEN}Using custom date: $ARG_DATE${NC}"
                            ;;
                    esac
                    shift 2
                fi
                ;;
            --no-date)
                ARG_NO_DATE=true
                echo -e "${GREEN}Date will be disabled${NC}"
                shift
                ;;
            -f|--footer)
                ARG_FOOTER="$2"
                shift 2
                ;;
            --no-footer)
                ARG_NO_FOOTER=true
                shift
                ;;
            --date-footer)
                if [[ "$2" == -* ]] || [ -z "$2" ]; then
                    # No argument provided or next argument is another option
                    ARG_DATE_FOOTER="DD/MM/YY"
                    shift
                else
                    # Argument provided
                    ARG_DATE_FOOTER="$2"
                    shift 2
                fi
                ;;
            --pageof)
                ARG_PAGE_OF=true
                shift
                ;;
            --read-metadata)
                ARG_READ_METADATA=true
                shift
                ;;
            --epub)
                ARG_EPUB=true
                shift
                ;;
            --validate)
                ARG_VALIDATE=true
                shift
                ;;
            --bibliography|-b)
                ARG_BIBLIOGRAPHY="$2"
                shift 2
                ;;
            --csl)
                ARG_CSL="$2"
                shift 2
                ;;
            --template)
                ARG_TEMPLATE="$2"
                shift 2
                ;;
            --epub-css)
                ARG_EPUB_CSS="$2"
                shift 2
                ;;
            --include|-i)
                ARG_INCLUDE+=("$2")
                shift 2
                ;;
            --index)
                ARG_INDEX=true
                shift
                ;;
            --lulu)
                ARG_LULU=true
                shift
                ;;
            --trim-size)
                ARG_TRIM_SIZE="$2"
                shift 2
                ;;
            --format)
                ARG_FORMAT="$2"
                shift 2
                ;;
            --header-footer-policy)
                case "$2" in
                    "default"|"partial"|"all")
                        ARG_HEADER_FOOTER_POLICY="$2"
                        ;;
                    *)
                        echo -e "${RED}Error: Invalid header-footer-policy '$2'. Valid options: default, partial, all${NC}"
                        return 1
                        ;;
                esac
                shift 2
                ;;
            *)
                # First non-option argument is the input file
                if [ -z "$INPUT_FILE" ]; then
                    INPUT_FILE="$1"
                # Second non-option argument is the output file
                elif [ -z "$OUTPUT_FILE" ]; then
                    OUTPUT_FILE="$1"
                else
                    echo -e "${RED}Error: Unexpected argument '$1'.${NC}"
                    show_convert_usage
                    return 1
                fi
                shift
                ;;
        esac
    done

    return 0
}

# Validate parsed arguments
# Returns: 0 if valid, 1 if invalid
validate_convert_args() {
    # Check if input file is specified
    if [ -z "$INPUT_FILE" ]; then
        echo -e "${RED}Error: No input file specified.${NC}"
        show_convert_usage
        return 1
    fi

    # Check if input file exists
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}Error: Input file '$INPUT_FILE' not found.${NC}"
        return 1
    fi

    return 0
}

# Handle multi-file projects (--include option)
# Combines multiple markdown files into a single temporary file
# Returns: 0 on success, 1 on error
# Sets: COMBINED_FILE, INPUT_FILE (updates to combined file), ORIGINAL_INPUT_FILE
handle_include_files() {
    COMBINED_FILE=""
    ORIGINAL_INPUT_FILE=""

    if [ ${#ARG_INCLUDE[@]} -gt 0 ]; then
        echo -e "${BLUE}Combining multiple markdown files...${NC}"

        # Create a temporary combined file
        COMBINED_FILE=$(mktemp --suffix=.md)
        local input_dir
        input_dir=$(dirname "$INPUT_FILE")

        # Start with the main input file
        cat "$INPUT_FILE" > "$COMBINED_FILE"
        echo -e "${GREEN}  Added: $INPUT_FILE (main)${NC}"

        # Append each included file
        for include_file in "${ARG_INCLUDE[@]}"; do
            local resolved_file=""

            # Check if file exists as-is
            if [ -f "$include_file" ]; then
                resolved_file="$include_file"
            # Check relative to input file directory
            elif [ -f "$input_dir/$include_file" ]; then
                resolved_file="$input_dir/$include_file"
            else
                echo -e "${RED}Error: Include file '$include_file' not found${NC}"
                rm -f "$COMBINED_FILE"
                return 1
            fi

            # Add a newline separator and append the file
            echo "" >> "$COMBINED_FILE"
            echo "" >> "$COMBINED_FILE"

            # Skip YAML frontmatter in included files (only use from main file)
            if head -n 1 "$resolved_file" | grep -q "^---\s*$"; then
                # Extract content after the second ---
                sed -n '/^---$/,/^---$/d; p' "$resolved_file" >> "$COMBINED_FILE"
            else
                cat "$resolved_file" >> "$COMBINED_FILE"
            fi

            echo -e "${GREEN}  Added: $resolved_file${NC}"
        done

        echo -e "${GREEN}Combined ${#ARG_INCLUDE[@]} additional file(s) into main document${NC}"

        # Use the combined file as input
        ORIGINAL_INPUT_FILE="$INPUT_FILE"
        INPUT_FILE="$COMBINED_FILE"
    fi

    return 0
}

# Export functions
export -f init_convert_args 2>/dev/null || true
export -f parse_convert_args 2>/dev/null || true
export -f validate_convert_args 2>/dev/null || true
export -f show_convert_usage 2>/dev/null || true
export -f handle_include_files 2>/dev/null || true
