#!/bin/bash
# =============================================================================
# mdtexpdf PDF Conversion Module
# PDF generation: template resolution, Lua filters, pandoc execution
# =============================================================================

# Source core if not already loaded
if [ -z "$MDTEXPDF_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=core.sh
    source "$SCRIPT_DIR/core.sh"
fi

# =============================================================================
# Module-level variables (shared between helper functions)
# =============================================================================
_PDF_TEMPLATE_PATH=""
_PDF_TEMPLATE_IN_CURRENT_DIR=false
_PDF_CUSTOM_TEMPLATE_USED=false
_PDF_DATE_FOOTER_TEXT=""
_PDF_PANDOC_OPTS=""
_PDF_FILTER_OPTION=""
_PDF_TOC_OPTION=""
_PDF_SECTION_NUMBERING_OPTION=""
_PDF_FOOTER_VARS=()
_PDF_HEADER_FOOTER_VARS=()
_PDF_BOOK_FEATURE_VARS=()
_PDF_BIBLIOGRAPHY_VARS=()
_PDF_TRIM_VARS=()
_PDF_PROCESSED_INPUT_FILE=""
_PDF_BIB_TEMP_DIR=""

# =============================================================================
# Helper: Resolve PDF Template
# =============================================================================
# Resolves which LaTeX template to use for PDF generation.
# Handles custom templates, current-directory templates, and template creation.
# Sets: _PDF_TEMPLATE_PATH, _PDF_TEMPLATE_IN_CURRENT_DIR,
#        _PDF_CUSTOM_TEMPLATE_USED, _PDF_DATE_FOOTER_TEXT, _PDF_PANDOC_OPTS
# Uses: INPUT_FILE, ARG_TEMPLATE, ARG_TITLE, ARG_AUTHOR, ARG_DATE, ARG_NO_DATE,
#       ARG_FOOTER, ARG_NO_FOOTER, ARG_DATE_FOOTER, ARG_SECTION_NUMBERS,
#       ARG_FORMAT, ARG_HEADER_FOOTER_POLICY
# Returns: 0 on success, 1 on failure
resolve_pdf_template() {
    _PDF_PANDOC_OPTS=""
    _PDF_TEMPLATE_IN_CURRENT_DIR=false
    _PDF_CUSTOM_TEMPLATE_USED=false

    if [ -n "$ARG_TEMPLATE" ]; then
        # User provided custom template
        if [ -f "$ARG_TEMPLATE" ]; then
            _PDF_TEMPLATE_PATH=$(realpath "$ARG_TEMPLATE")
            _PDF_CUSTOM_TEMPLATE_USED=true
            echo -e "${GREEN}Using custom template: $_PDF_TEMPLATE_PATH${NC}"
        else
            # Check relative to input file directory
            local input_dir
            input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$input_dir/$ARG_TEMPLATE" ]; then
                _PDF_TEMPLATE_PATH=$(realpath "$input_dir/$ARG_TEMPLATE")
                _PDF_CUSTOM_TEMPLATE_USED=true
                echo -e "${GREEN}Using custom template: $_PDF_TEMPLATE_PATH${NC}"
            else
                echo -e "${RED}Error: Custom template '$ARG_TEMPLATE' not found${NC}"
                return 1
            fi
        fi
    fi

    # If no custom template, check for template.tex in the current directory
    if [ "$_PDF_CUSTOM_TEMPLATE_USED" = false ]; then
        _PDF_TEMPLATE_PATH="$(pwd)/template.tex"
    fi

    if [ "$_PDF_CUSTOM_TEMPLATE_USED" = true ]; then
        # Custom template provided - use it directly
        _PDF_TEMPLATE_IN_CURRENT_DIR=false
    elif [ -f "$_PDF_TEMPLATE_PATH" ]; then
        _PDF_TEMPLATE_IN_CURRENT_DIR=true
    else
        # Not found in current directory, check other locations
        _PDF_TEMPLATE_PATH=""

        # Check in templates subdirectory
        if [ -f "$(pwd)/templates/template.tex" ]; then
            _PDF_TEMPLATE_PATH="$(pwd)/templates/template.tex"
        # Check in script directory
        elif [ -f "$(dirname "$(readlink -f "$0")")/templates/template.tex" ]; then
            _PDF_TEMPLATE_PATH="$(dirname "$(readlink -f "$0")")/templates/template.tex"
        elif [ -f "$(dirname "$(readlink -f "$0")")/template.tex" ]; then
            _PDF_TEMPLATE_PATH="$(dirname "$(readlink -f "$0")")/template.tex"
        # Check in system directory
        elif [ -f "/usr/local/share/mdtexpdf/templates/template.tex" ]; then
            _PDF_TEMPLATE_PATH="/usr/local/share/mdtexpdf/templates/template.tex"
        fi
    fi

    # Log template path when verbose mode is enabled
    if [ "$ARG_VERBOSE" = true ]; then
        echo -e "${BLUE}Template path: $_PDF_TEMPLATE_PATH${NC}"
        echo -e "${BLUE}Template in current dir: $_PDF_TEMPLATE_IN_CURRENT_DIR${NC}"
    fi

    # Check if we found a template in the current directory or custom template
    if [ "$_PDF_CUSTOM_TEMPLATE_USED" = true ]; then
        # Custom template already set - nothing more to do
        :
    elif [ "$_PDF_TEMPLATE_IN_CURRENT_DIR" = true ]; then
        echo -e "Using template: ${GREEN}$_PDF_TEMPLATE_PATH${NC}"
    else
        # Template not found in current directory
        if [ -n "$_PDF_TEMPLATE_PATH" ]; then
            # Use the template from another location
            echo -e "${YELLOW}No template.tex found in current directory.${NC}"
            echo -e "${GREEN}Do you want to create a template.tex now and update your file with the proper header? (y/n) [y]:${NC}"
        else
            # No template found anywhere
            echo -e "${YELLOW}No template.tex found.${NC}"
            echo -e "${GREEN}A template.tex file is required. Create one now? (y/n) [y]:${NC}"
        fi

        # Skip prompt if arguments were provided
        local CREATE_TEMPLATE
        if [ -n "$ARG_TITLE" ] || [ -n "$ARG_AUTHOR" ] || [ -n "$ARG_DATE" ] || [ "$ARG_NO_FOOTER" = true ]; then
            CREATE_TEMPLATE="y"
            echo -e "${BLUE}Using command-line arguments, automatically creating template...${NC}"
        else
            read -r CREATE_TEMPLATE
            CREATE_TEMPLATE=${CREATE_TEMPLATE:-"y"}
        fi

        if [ "$ARG_VERBOSE" = true ]; then
            echo -e "${BLUE}User chose to create template: $CREATE_TEMPLATE${NC}"
        fi

        # Create template if user chose to
        if [[ $CREATE_TEMPLATE =~ ^[Yy]$ ]]; then
            _resolve_template_interactive || return 1
        else
            # User chose not to create a template
            if [ -n "$_PDF_TEMPLATE_PATH" ]; then
                # Use the template from another location
                echo -e "Using template: ${GREEN}$_PDF_TEMPLATE_PATH${NC}"
            else
                echo -e "${RED}Cannot proceed without a template.${NC}"
                return 1
            fi
        fi
    fi

    return 0
}

# Internal helper: Interactive template creation flow
# Called when no template exists and user opts to create one
_resolve_template_interactive() {
    if [ "$ARG_VERBOSE" = true ]; then
        echo -e "${BLUE}Creating template...${NC}"
    fi
    # Get document details for both template and YAML frontmatter
    echo -e "${YELLOW}Setting up document preferences...${NC}"

    # Check if the file has a first-level heading (# Title) before asking for title
    local FIRST_HEADING
    FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')

    local TITLE AUTHOR DOC_DATE FOOTER_TEXT

    # Set title based on command-line argument or prompt user
    if [ -n "$ARG_TITLE" ]; then
        TITLE="$ARG_TITLE"
        echo -e "${GREEN}Using title from command-line argument: '$TITLE'${NC}"
    elif [ -n "$FIRST_HEADING" ]; then
        # If a first-level heading was found, use it as the default title
        echo -e "${BLUE}Found title in document: '$FIRST_HEADING'${NC}"
        echo -e "${GREEN}Enter document title (press Enter to use the found title) [${FIRST_HEADING}]:${NC}"
        local USER_TITLE
        read -r USER_TITLE

        if [ -z "$USER_TITLE" ]; then
            # User pressed Enter, use the found title
            TITLE="$FIRST_HEADING"
            echo -e "${GREEN}Using found title: '$FIRST_HEADING'${NC}"
        else
            # User entered a different title, use that instead
            TITLE="$USER_TITLE"
            echo -e "${GREEN}Using custom title: '$USER_TITLE'${NC}"
        fi
    else
        # Otherwise use filename as default
        local DEFAULT_TITLE
        DEFAULT_TITLE=$(basename "$INPUT_FILE" .md | sed 's/_/ /g' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
        echo -e "${GREEN}Enter document title [${DEFAULT_TITLE}]:${NC}"
        read -r TITLE
        TITLE=${TITLE:-"$DEFAULT_TITLE"}
    fi

    # Set author based on command-line argument or prompt user
    if [ -n "$ARG_AUTHOR" ]; then
        AUTHOR="$ARG_AUTHOR"
        echo -e "${GREEN}Using author from command-line argument: '$AUTHOR'${NC}"
    else
        echo -e "${GREEN}Enter author name [$(whoami)]:${NC}"
        read -r AUTHOR
        AUTHOR=${AUTHOR:-"$(whoami)"}
    fi

    # Set date based on command-line argument or prompt user
    if [ "$ARG_NO_DATE" = true ]; then
        DOC_DATE=""
        echo -e "${GREEN}Date is disabled${NC}"
    elif [ -n "$ARG_DATE" ]; then
        DOC_DATE="$ARG_DATE"
        echo -e "${GREEN}Using date from command-line argument: '$DOC_DATE'${NC}"
    else
        echo -e "${GREEN}Enter document date [$(date +"%B %d, %Y")]:${NC}"
        read -r DOC_DATE
        DOC_DATE=${DOC_DATE:-"$(date +"%B %d, %Y")"}
    fi

    # Set footer preferences based on command-line arguments or prompt user
    if [ "$ARG_NO_FOOTER" = true ]; then
        FOOTER_TEXT=""
        echo -e "${GREEN}Footer disabled via command-line argument${NC}"
    elif [ -n "$ARG_FOOTER" ]; then
        FOOTER_TEXT="$ARG_FOOTER"
        echo -e "${GREEN}Using footer text from command-line argument: '$FOOTER_TEXT'${NC}"
    else
        echo -e "${GREEN}Do you want to add a footer to your document? (y/n) [y]:${NC}"
        local ADD_FOOTER
        read -r ADD_FOOTER
        ADD_FOOTER=${ADD_FOOTER:-"y"}

        if [[ $ADD_FOOTER =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Enter footer text (press Enter for default ' All rights reserved $(date +"%Y")'):${NC}"
            read -r FOOTER_TEXT
            FOOTER_TEXT=${FOOTER_TEXT:-" All rights reserved $(date +"%Y")"}
        else
            FOOTER_TEXT=""
        fi
    fi

    # Format the date footer if specified
    _PDF_DATE_FOOTER_TEXT=""
    if [ -n "$ARG_DATE_FOOTER" ]; then # Check if --date-footer was used at all
        if [ -n "$ARG_DATE" ] && [ "$ARG_DATE" != "no" ]; then
            # Attempt to parse ARG_DATE and format as YY/MM/DD
            local PARSED_DATE_FOOTER
            PARSED_DATE_FOOTER=$(date -d "$ARG_DATE" +"%y/%m/%d" 2>/dev/null)
            if [ -n "$PARSED_DATE_FOOTER" ]; then
                _PDF_DATE_FOOTER_TEXT="$PARSED_DATE_FOOTER"
                echo -e "${GREEN}Using document date for footer (YY/MM/DD): $_PDF_DATE_FOOTER_TEXT${NC}"
            else
                # Fallback to current date if ARG_DATE is not parsable
                _PDF_DATE_FOOTER_TEXT="$(date +"%y/%m/%d")"
                echo -e "${YELLOW}Warning: Could not parse date '$ARG_DATE'. Using current date for footer (YY/MM/DD): $_PDF_DATE_FOOTER_TEXT${NC}"
            fi
        else
            # If -d was not used or was 'no', use current date formatted as YY/MM/DD
            _PDF_DATE_FOOTER_TEXT="$(date +"%y/%m/%d")"
        fi
    fi

    # Create a template file in the current directory
    _PDF_TEMPLATE_PATH="$(pwd)/template.tex"
    echo -e "${YELLOW}Creating template file: $_PDF_TEMPLATE_PATH${NC}"
    create_template_file "$_PDF_TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" "$_PDF_DATE_FOOTER_TEXT" "$ARG_SECTION_NUMBERS" "$ARG_FORMAT" "$ARG_HEADER_FOOTER_POLICY"

    if [ ! -f "$_PDF_TEMPLATE_PATH" ]; then
        echo -e "${RED}Error: Failed to create template.tex.${NC}"
        return 1
    fi

    echo -e "${GREEN}Created new template file: $_PDF_TEMPLATE_PATH${NC}"

    # Check if the Markdown file has proper YAML frontmatter
    if ! head -n 1 "$INPUT_FILE" | grep -q "^---"; then
        echo -e "${YELLOW}Updating $INPUT_FILE with proper YAML frontmatter...${NC}"

        # Check if the file has a first-level heading (# Title)
        FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')

        # Create a temporary file with the YAML frontmatter
        local TMP_FILE
        TMP_FILE=$(mktemp)

        # Add YAML frontmatter with the user-specified title
        cat > "$TMP_FILE" << EOF
---
title: "$TITLE"
author: "$AUTHOR"
$([ -n "$DOC_DATE" ] && echo "date: \"$DOC_DATE\"")
output:
  pdf_document:
    template: template.tex
---

EOF

        # If a first-level heading was found and it matches the title we're using,
        # comment it out to avoid duplication
        if [ -n "$FIRST_HEADING" ]; then
            if [ "$FIRST_HEADING" = "$TITLE" ]; then
                # Title is the same as the first heading, comment it out
                echo -e "${GREEN}Commenting out the first heading to avoid duplication.${NC}"
                sed "0,/^# $FIRST_HEADING/s/^# $FIRST_HEADING/<!-- # $FIRST_HEADING -->/" "$INPUT_FILE" >> "$TMP_FILE"
            else
                # Title is different from the first heading, keep both
                echo -e "${GREEN}Keeping the first heading as it differs from the title.${NC}"
                cat "$INPUT_FILE" >> "$TMP_FILE"
            fi
        else
            # No first heading, just append the content
            cat "$INPUT_FILE" >> "$TMP_FILE"
        fi

        # Replace the original file
        mv "$TMP_FILE" "$INPUT_FILE"

        echo -e "${GREEN}Updated $INPUT_FILE with proper YAML frontmatter.${NC}"
    fi

    return 0
}

# =============================================================================
# Helper: Setup Lua Filters
# =============================================================================
# Discovers and configures Lua filters for pandoc using find_lua_filter()
# from lib/pdf.sh.
# Sets: _PDF_FILTER_OPTION
# Uses: ARG_FORMAT, ARG_INDEX, META_DROP_CAPS, find_lua_filter()
# Returns: 0 always

# Internal: Find a filter and add it to the LUA_FILTERS array with logging.
# Arguments: $1=filter_name, $2=description, $3=warning_if_missing
_add_lua_filter() {
    local filter_name="$1"
    local description="$2"
    local warning="$3"

    local path
    path=$(find_lua_filter "$filter_name")
    if [ -n "$path" ]; then
        _PDF_LUA_FILTERS+=("$path")
        echo -e "${BLUE}Using Lua filter for ${description}: $path${NC}"
    else
        echo -e "${YELLOW}Warning: ${filter_name} not found. ${warning}${NC}"
    fi
}

setup_lua_filters() {
    _PDF_LUA_FILTERS=()

    # Core filters (always attempted)
    _add_lua_filter "heading_fix_filter.lua" \
        "heading line break fix" \
        "Level 4 and 5 headings may run inline."

    _add_lua_filter "long_equation_filter.lua" \
        "long equation handling" \
        "Long equations may not wrap properly."

    _add_lua_filter "image_size_filter.lua" \
        "automatic image sizing" \
        "Images may not be properly sized."

    _add_lua_filter "table_size_filter.lua" \
        "wide table sizing" \
        "Wide tables may overflow page margins."

    # Conditional filters
    if [ "$ARG_FORMAT" = "book" ]; then
        _add_lua_filter "book_structure.lua" \
            "book structure" \
            "Book format may not work correctly."
    fi

    if [ "$ARG_INDEX" = true ]; then
        _add_lua_filter "index_filter.lua" \
            "index generation" \
            "Index markers will not be processed."
    fi

    if [ "$META_DROP_CAPS" = "true" ]; then
        _add_lua_filter "drop_caps_filter.lua" \
            "drop caps" \
            "Drop caps will not be applied."
    fi

    if [ "$META_EQUATION_NUMBERS" = "true" ]; then
        _add_lua_filter "equation_number_filter.lua" \
            "equation numbering" \
            "Equation numbering will not be applied."
    fi

    # Build filter options string
    _PDF_FILTER_OPTION=""
    for filter in "${_PDF_LUA_FILTERS[@]}"; do
        _PDF_FILTER_OPTION="$_PDF_FILTER_OPTION --lua-filter=$filter"
    done

    return 0
}

# =============================================================================
# Helper: Build Pandoc Variables
# =============================================================================

# Internal: Build footer and header/footer policy variables.
# Sets: _PDF_FOOTER_VARS, _PDF_HEADER_FOOTER_VARS
_build_footer_vars() {
    _PDF_FOOTER_VARS=()
    if [ "$ARG_NO_FOOTER" = true ]; then
        _PDF_FOOTER_VARS+=("--variable=no_footer=true")
    else
        [ -n "$ARG_FOOTER" ] && _PDF_FOOTER_VARS+=("--variable=center_footer_content=$ARG_FOOTER")
        [ "$ARG_PAGE_OF" = true ] && _PDF_FOOTER_VARS+=("--variable=page_of_format=true")
        [ -n "$_PDF_DATE_FOOTER_TEXT" ] && _PDF_FOOTER_VARS+=("--variable=date_footer_content=$_PDF_DATE_FOOTER_TEXT")
    fi

    _PDF_HEADER_FOOTER_VARS=()
    if [ "$ARG_HEADER_FOOTER_POLICY" = "all" ]; then
        _PDF_HEADER_FOOTER_VARS+=("--variable=header_footer_policy_all=true")
    elif [ "$ARG_HEADER_FOOTER_POLICY" = "partial" ]; then
        _PDF_HEADER_FOOTER_VARS+=("--variable=header_footer_policy_partial=true")
    else
        _PDF_HEADER_FOOTER_VARS+=("--variable=header_footer_policy_default=true")
    fi

    if [ "$ARG_FORMAT" = "book" ]; then
        _PDF_HEADER_FOOTER_VARS+=("--variable=format_book=true")
        # Tell pandoc the document class is book so # = \chapter, ## = \section
        # (the template hardcodes \documentclass{book} but pandoc needs this
        # flag to map heading levels correctly for non-Lua-filtered headers)
        _PDF_PANDOC_OPTS="$_PDF_PANDOC_OPTS --top-level-division=chapter"
    else
        _PDF_HEADER_FOOTER_VARS+=("--variable=format_article=true")
    fi
}

# Internal: Helper to conditionally add a pandoc variable from a META_* value.
# Arguments: $1=variable_name, $2=meta_value
_add_meta_var() {
    if [ -n "$2" ] && [ "$2" != "null" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=$1=$2")
    fi
}

# Internal: Helper to conditionally add a boolean pandoc variable from a META_* value.
# Arguments: $1=variable_name, $2=meta_value
_add_meta_bool() {
    if [ "$2" = "true" ] || [ "$2" = "True" ] || [ "$2" = "TRUE" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=$1=true")
    fi
}

# Internal: Build book feature variables (front matter, publishing, authorship).
# Appends to: _PDF_BOOK_FEATURE_VARS
_build_book_feature_vars() {
    [ "$ARG_INDEX" = true ] && _PDF_BOOK_FEATURE_VARS+=("--variable=index=true")

    # Front matter
    _add_meta_bool "no_title_page" "$META_NO_TITLE_PAGE"
    _add_meta_bool "no_figure_numbers" "$META_NO_FIGURE_NUMBERS"
    _add_meta_bool "half_title" "$META_HALF_TITLE"
    _add_meta_bool "copyright_page" "$META_COPYRIGHT_PAGE"
    _add_meta_var "dedication" "$META_DEDICATION"
    _add_meta_var "epigraph" "$META_EPIGRAPH"
    _add_meta_var "epigraph_source" "$META_EPIGRAPH_SOURCE"
    _add_meta_bool "chapters_on_recto" "$META_CHAPTERS_ON_RECTO"
    _add_meta_bool "drop_caps" "$META_DROP_CAPS"
    _add_meta_bool "equation_numbers" "$META_EQUATION_NUMBERS"

    # Publishing
    _add_meta_var "publisher" "$META_PUBLISHER"
    _add_meta_var "isbn" "$META_ISBN"
    _add_meta_var "edition" "$META_EDITION"
    _add_meta_var "copyright_year" "$META_COPYRIGHT_YEAR"
    _add_meta_var "copyright_holder" "$META_COPYRIGHT_HOLDER"
    _add_meta_var "edition_date" "$META_EDITION_DATE"
    _add_meta_var "printing" "$META_PRINTING"
    _add_meta_var "publisher_address" "$META_PUBLISHER_ADDRESS"
    _add_meta_var "publisher_website" "$META_PUBLISHER_WEBSITE"

    # Authorship & support
    if [ -n "$META_AUTHOR_PUBKEY" ] && [ "$META_AUTHOR_PUBKEY" != "null" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=author_pubkey=$META_AUTHOR_PUBKEY")
        _PDF_BOOK_FEATURE_VARS+=("--variable=author_pubkey_type=$META_AUTHOR_PUBKEY_TYPE")
    fi
    [ -n "$META_DONATION_WALLETS" ] && _PDF_BOOK_FEATURE_VARS+=("--variable=donation_wallets=$META_DONATION_WALLETS")
}

# Internal: Build cover system variables (front cover, back cover).
# Appends to: _PDF_BOOK_FEATURE_VARS
_build_cover_vars() {
    local INPUT_DIR
    INPUT_DIR=$(dirname "$INPUT_FILE")

    # Front cover image (with auto-detection fallback)
    local COVER_IMAGE_PATH="$META_COVER_IMAGE"
    if [ -z "$COVER_IMAGE_PATH" ]; then
        COVER_IMAGE_PATH=$(detect_cover_image "$INPUT_DIR" "cover")
        [ -n "$COVER_IMAGE_PATH" ] && echo -e "${GREEN}Auto-detected front cover image: $COVER_IMAGE_PATH${NC}"
    fi
    if [ -n "$COVER_IMAGE_PATH" ] && [ -f "$COVER_IMAGE_PATH" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=cover_image=$COVER_IMAGE_PATH")
    elif [ -n "$META_COVER_IMAGE" ]; then
        local RELATIVE_COVER="$INPUT_DIR/$META_COVER_IMAGE"
        if [ -f "$RELATIVE_COVER" ]; then
            _PDF_BOOK_FEATURE_VARS+=("--variable=cover_image=$RELATIVE_COVER")
        else
            echo -e "${YELLOW}Warning: Cover image not found: $META_COVER_IMAGE${NC}"
        fi
    fi

    # Cover styling
    [ -n "$META_COVER_TITLE_COLOR" ] && _PDF_BOOK_FEATURE_VARS+=("--variable=cover_title_color=$META_COVER_TITLE_COLOR")
    _add_meta_bool "cover_title_show" "$META_COVER_TITLE_SHOW"
    _add_meta_bool "cover_subtitle_show" "$META_COVER_SUBTITLE_SHOW"
    if [ -n "$META_COVER_AUTHOR_POSITION" ] && [ "$META_COVER_AUTHOR_POSITION" != "none" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=cover_author_position=$META_COVER_AUTHOR_POSITION")
    fi
    [ -n "$META_COVER_AUTHOR_OFFSET" ] && _PDF_BOOK_FEATURE_VARS+=("--variable=cover_author_offset=$META_COVER_AUTHOR_OFFSET")
    [ -n "$META_COVER_OVERLAY_OPACITY" ] && _PDF_BOOK_FEATURE_VARS+=("--variable=cover_overlay_opacity=$META_COVER_OVERLAY_OPACITY")
    [ "$META_COVER_FIT" = "cover" ] && _PDF_BOOK_FEATURE_VARS+=("--variable=cover_fit_cover=true")

    # Back cover image (with auto-detection fallback)
    local BACK_COVER_IMAGE_PATH="$META_BACK_COVER_IMAGE"
    if [ -z "$BACK_COVER_IMAGE_PATH" ]; then
        BACK_COVER_IMAGE_PATH=$(detect_cover_image "$INPUT_DIR" "back")
        [ -n "$BACK_COVER_IMAGE_PATH" ] && echo -e "${GREEN}Auto-detected back cover image: $BACK_COVER_IMAGE_PATH${NC}"
    fi
    if [ -n "$BACK_COVER_IMAGE_PATH" ] && [ -f "$BACK_COVER_IMAGE_PATH" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=back_cover_image=$BACK_COVER_IMAGE_PATH")
    elif [ -n "$META_BACK_COVER_IMAGE" ]; then
        local RELATIVE_BACK_COVER="$INPUT_DIR/$META_BACK_COVER_IMAGE"
        if [ -f "$RELATIVE_BACK_COVER" ]; then
            _PDF_BOOK_FEATURE_VARS+=("--variable=back_cover_image=$RELATIVE_BACK_COVER")
        else
            echo -e "${YELLOW}Warning: Back cover image not found: $META_BACK_COVER_IMAGE${NC}"
        fi
    fi

    # Back cover content
    _add_meta_var "back_cover_content" "$META_BACK_COVER_CONTENT"
    _add_meta_var "back_cover_quote" "$META_BACK_COVER_QUOTE"
    _add_meta_var "back_cover_quote_source" "$META_BACK_COVER_QUOTE_SOURCE"
    _add_meta_var "back_cover_summary" "$META_BACK_COVER_SUMMARY"
    _add_meta_var "back_cover_text" "$META_BACK_COVER_TEXT"
    _add_meta_bool "back_cover_author_bio" "$META_BACK_COVER_AUTHOR_BIO"
    _add_meta_var "back_cover_author_bio_text" "$META_BACK_COVER_AUTHOR_BIO_TEXT"
    _add_meta_bool "back_cover_isbn_barcode" "$META_BACK_COVER_ISBN_BARCODE"
    _add_meta_bool "back_cover_text_background" "$META_BACK_COVER_TEXT_BACKGROUND"
    _add_meta_var "back_cover_text_background_opacity" "$META_BACK_COVER_TEXT_BACKGROUND_OPACITY"
    _add_meta_var "back_cover_text_color" "$META_BACK_COVER_TEXT_COLOR"

    # Spine text control (mainly used in lulu.sh, but available as variable)
    _add_meta_var "spine_text" "$META_SPINE_TEXT"

    # Helper booleans for template fill-color inversion logic
    # (white text → black rectangle, non-white text → white rectangle)
    local _effective_title_color="${META_COVER_TITLE_COLOR:-white}"
    if [ "$_effective_title_color" = "white" ]; then
        _PDF_BOOK_FEATURE_VARS+=("--variable=cover_title_color_is_white=true")
    fi
    if [ -n "$META_BACK_COVER_TEXT_COLOR" ]; then
        if [ "$META_BACK_COVER_TEXT_COLOR" = "white" ]; then
            _PDF_BOOK_FEATURE_VARS+=("--variable=back_cover_text_color_is_white=true")
        fi
    fi
}

# Internal: Resolve trim size preset to geometry dimensions.
# Sets: _PDF_TRIM_VARS array with --variable= entries for pandoc
# Uses: ARG_TRIM_SIZE, ARG_LULU, META_TRIM_SIZE
_build_trim_vars() {
    _PDF_TRIM_VARS=()

    # Determine effective trim size: CLI flag > metadata > default
    local trim_size=""
    if [ -n "$ARG_TRIM_SIZE" ]; then
        trim_size="$ARG_TRIM_SIZE"
    elif [ "$ARG_LULU" = true ] && [ -n "$META_TRIM_SIZE" ]; then
        trim_size="$META_TRIM_SIZE"
    fi

    # If --lulu is set but no trim size, default to 5.5x8.5 (Lulu Digest)
    if [ "$ARG_LULU" = true ] && [ -z "$trim_size" ]; then
        trim_size="5.5x8.5"
    fi

    # Pass lulu_mode variable if --lulu flag is set
    if [ "$ARG_LULU" = true ]; then
        _PDF_TRIM_VARS+=("--variable=lulu_mode=true")
        echo -e "${BLUE}Lulu mode: covers will be suppressed from interior PDF${NC}"
    fi

    # No custom trim size — use default a4/1in geometry from template
    if [ -z "$trim_size" ] || [ "$trim_size" = "a4" ]; then
        return 0
    fi

    # Resolve trim size presets
    local paper_w paper_h top bottom outer inner fontsize
    case "$trim_size" in
        5.5x8.5)
            paper_w="5.5in"; paper_h="8.5in"
            top="0.75in"; bottom="0.75in"
            outer="0.625in"; inner="0.625in"
            fontsize="11pt"
            ;;
        6x9)
            paper_w="6in"; paper_h="9in"
            top="0.75in"; bottom="0.75in"
            outer="0.75in"; inner="0.75in"
            fontsize="11pt"
            ;;
        7x10)
            paper_w="7in"; paper_h="10in"
            top="0.8in"; bottom="0.8in"
            outer="0.75in"; inner="0.75in"
            fontsize="12pt"
            ;;
        a5)
            paper_w="5.83in"; paper_h="8.27in"
            top="0.7in"; bottom="0.7in"
            outer="0.6in"; inner="0.6in"
            fontsize="11pt"
            ;;
        *)
            echo -e "${YELLOW}Warning: Unknown trim size '$trim_size'. Using default geometry.${NC}"
            return 0
            ;;
    esac

    # Calculate gutter addition based on estimated page count
    # Lulu gutter spec: <60pp: +0", 61-150: +0.125", 151-400: +0.5", 401-600: +0.625", 600+: +0.75"
    local gutter_add="0"
    if [ "$ARG_LULU" = true ]; then
        # Estimate page count from word count (rough: ~250 words/page for smaller trim)
        local word_count
        word_count=$(wc -w < "$INPUT_FILE" 2>/dev/null || echo "0")
        local est_pages=$(( word_count / 250 ))
        if [ "$est_pages" -le 60 ]; then
            gutter_add="0"
        elif [ "$est_pages" -le 150 ]; then
            gutter_add="0.125"
        elif [ "$est_pages" -le 400 ]; then
            gutter_add="0.5"
        elif [ "$est_pages" -le 600 ]; then
            gutter_add="0.625"
        else
            gutter_add="0.75"
        fi

        if [ "$gutter_add" != "0" ]; then
            # Add gutter to inner margin (strip "in" suffix, add, re-add suffix)
            local inner_val="${inner%in}"
            inner=$(awk "BEGIN {printf \"%.3fin\", $inner_val + $gutter_add}")
            echo -e "${BLUE}Lulu gutter: +${gutter_add}\" for ~${est_pages} estimated pages (inner margin: ${inner})${NC}"
        fi
    fi

    echo -e "${GREEN}Trim size: ${trim_size} (${paper_w} x ${paper_h}), margins: top=${top} bottom=${bottom} outer=${outer} inner=${inner}, font=${fontsize}${NC}"

    _PDF_TRIM_VARS+=("--variable=trim_paperwidth=$paper_w")
    _PDF_TRIM_VARS+=("--variable=trim_paperheight=$paper_h")
    _PDF_TRIM_VARS+=("--variable=trim_top=$top")
    _PDF_TRIM_VARS+=("--variable=trim_bottom=$bottom")
    _PDF_TRIM_VARS+=("--variable=trim_outer=$outer")
    _PDF_TRIM_VARS+=("--variable=trim_inner=$inner")
    _PDF_TRIM_VARS+=("--variable=trim_fontsize=$fontsize")
    _PDF_TRIM_VARS+=("--variable=trim_size=$trim_size")
}

# Assembles all pandoc variables for PDF generation.
# Sets: _PDF_TOC_OPTION, _PDF_SECTION_NUMBERING_OPTION, _PDF_FOOTER_VARS,
#       _PDF_HEADER_FOOTER_VARS, _PDF_BOOK_FEATURE_VARS, _PDF_TRIM_VARS
# Returns: 0 always
build_pandoc_vars() {
    echo -e "${BLUE}Using enhanced equation line breaking for text-heavy equations${NC}"

    _PDF_TOC_OPTION=""
    [ "$ARG_TOC" = true ] && _PDF_TOC_OPTION="--toc"

    _PDF_SECTION_NUMBERING_OPTION=""
    [ "$ARG_SECTION_NUMBERS" = false ] && _PDF_SECTION_NUMBERING_OPTION="--variable=numbersections=false"

    _build_footer_vars
    _PDF_BOOK_FEATURE_VARS=()
    _build_book_feature_vars
    _build_cover_vars
    _build_trim_vars

    return 0
}

# =============================================================================
# Helper: Setup PDF Bibliography
# =============================================================================
# Configures bibliography and citation options for PDF generation.
# Sets: _PDF_BIBLIOGRAPHY_VARS, _PDF_PROCESSED_INPUT_FILE, _PDF_BIB_TEMP_DIR
# Uses: INPUT_FILE, ARG_BIBLIOGRAPHY, ARG_CSL
# Returns: 0 always
setup_pdf_bibliography() {
    _PDF_BIBLIOGRAPHY_VARS=()
    _PDF_BIB_TEMP_DIR=""
    local bib_path=""
    local using_inline_bib=false
    _PDF_PROCESSED_INPUT_FILE="$INPUT_FILE"

    # Check for inline bibliography first (if no external bibliography specified)
    if [ -z "$ARG_BIBLIOGRAPHY" ] && type has_inline_bibliography &>/dev/null; then
        if has_inline_bibliography "$INPUT_FILE"; then
            echo -e "${BLUE}Detected inline bibliography in document${NC}"
            _PDF_BIB_TEMP_DIR=$(mktemp -d)

            if bib_path=$(process_inline_bibliography "$INPUT_FILE" "$_PDF_BIB_TEMP_DIR"); then
                # Use the content file without bibliography section
                _PDF_PROCESSED_INPUT_FILE="$_PDF_BIB_TEMP_DIR/content.md"
                using_inline_bib=true
                _PDF_BIBLIOGRAPHY_VARS+=("--citeproc")
                _PDF_BIBLIOGRAPHY_VARS+=("--bibliography=$bib_path")
                echo -e "${GREEN}Using inline bibliography (extracted to $bib_path)${NC}"
            else
                echo -e "${YELLOW}Warning: Could not process inline bibliography${NC}"
                rm -rf "$_PDF_BIB_TEMP_DIR"
                _PDF_BIB_TEMP_DIR=""
            fi
        fi
    fi

    # Handle external bibliography file (if specified and not using inline)
    if [ -n "$ARG_BIBLIOGRAPHY" ] && [ "$using_inline_bib" = false ]; then
        local external_bib_path=""
        # Check if bibliography file exists (try absolute path first)
        if [ -f "$ARG_BIBLIOGRAPHY" ]; then
            external_bib_path=$(realpath "$ARG_BIBLIOGRAPHY")
        else
            # Check relative to input file directory
            local input_dir
            input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$input_dir/$ARG_BIBLIOGRAPHY" ]; then
                external_bib_path=$(realpath "$input_dir/$ARG_BIBLIOGRAPHY")
            fi
        fi

        if [ -n "$external_bib_path" ]; then
            # Check if it's a simple markdown bibliography
            if type is_simple_bibliography &>/dev/null && is_simple_bibliography "$external_bib_path"; then
                echo -e "${BLUE}Converting simple markdown bibliography...${NC}"
                [ -z "$_PDF_BIB_TEMP_DIR" ] && _PDF_BIB_TEMP_DIR=$(mktemp -d)

                if bib_path=$(process_bibliography_file "$external_bib_path" "$_PDF_BIB_TEMP_DIR"); then
                    _PDF_BIBLIOGRAPHY_VARS+=("--citeproc")
                    _PDF_BIBLIOGRAPHY_VARS+=("--bibliography=$bib_path")
                    echo -e "${GREEN}Using simple bibliography: $external_bib_path${NC}"
                else
                    echo -e "${YELLOW}Warning: Could not convert simple bibliography${NC}"
                fi
            else
                # Traditional .bib or CSL-JSON file
                bib_path="$external_bib_path"
                _PDF_BIBLIOGRAPHY_VARS+=("--citeproc")
                _PDF_BIBLIOGRAPHY_VARS+=("--bibliography=$bib_path")
                echo -e "${GREEN}Using bibliography: $bib_path${NC}"
            fi
        else
            echo -e "${YELLOW}Warning: Bibliography file '$ARG_BIBLIOGRAPHY' not found${NC}"
        fi
    fi
    if [ -n "$ARG_CSL" ]; then
        local csl_path=""
        if [ -f "$ARG_CSL" ]; then
            csl_path=$(realpath "$ARG_CSL")
        else
            local input_dir
            input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$input_dir/$ARG_CSL" ]; then
                csl_path=$(realpath "$input_dir/$ARG_CSL")
            fi
        fi
        if [ -n "$csl_path" ]; then
            _PDF_BIBLIOGRAPHY_VARS+=("--csl=$csl_path")
            echo -e "${GREEN}Using citation style: $csl_path${NC}"
        else
            echo -e "${YELLOW}Warning: CSL file '$ARG_CSL' not found${NC}"
        fi
    fi

    return 0
}

# =============================================================================
# Helper: Execute Pandoc and Cleanup
# =============================================================================
# Runs the pandoc command and performs post-conversion cleanup.
# Uses: _PDF_PROCESSED_INPUT_FILE, OUTPUT_FILE, _PDF_TEMPLATE_PATH, PDF_ENGINE,
#       _PDF_PANDOC_OPTS, _PDF_FILTER_OPTION, _PDF_BIBLIOGRAPHY_VARS,
#       _PDF_TOC_OPTION, _PDF_SECTION_NUMBERING_OPTION, _PDF_FOOTER_VARS,
#       _PDF_HEADER_FOOTER_VARS, _PDF_BOOK_FEATURE_VARS, _PDF_TRIM_VARS,
#       _PDF_BIB_TEMP_DIR, BACKUP_FILE, COMBINED_FILE, INPUT_FILE
# Returns: 0 on success, 1 on failure
execute_pandoc() {
    # shellcheck disable=SC2086 # Word splitting is intentional for _PDF_PANDOC_OPTS/_PDF_FILTER_OPTION/_PDF_TOC_OPTION/_PDF_SECTION_NUMBERING_OPTION

    # When --index is used, we need a multi-step build: pandoc→latex, then
    # xelatex + makeindex + xelatex to generate the index with page numbers.
    # Pandoc's --to pdf doesn't run makeindex between LaTeX passes.
    if [ "$ARG_INDEX" = true ]; then
        _execute_pandoc_with_index
        return $?
    fi

    if pandoc "$_PDF_PROCESSED_INPUT_FILE" \
        --from markdown \
        --to pdf \
        --output "$OUTPUT_FILE" \
        --template="$_PDF_TEMPLATE_PATH" \
        --pdf-engine="$PDF_ENGINE" \
        $_PDF_PANDOC_OPTS \
        $_PDF_FILTER_OPTION \
        "${_PDF_BIBLIOGRAPHY_VARS[@]}" \
        --variable=geometry:margin=1in \
        --highlight-style=tango \
        --listings \
        $_PDF_TOC_OPTION \
        $_PDF_SECTION_NUMBERING_OPTION \
        "${_PDF_FOOTER_VARS[@]}" \
        "${_PDF_HEADER_FOOTER_VARS[@]}" \
        "${_PDF_BOOK_FEATURE_VARS[@]}" \
        "${_PDF_TRIM_VARS[@]}" \
        --standalone; then
        echo -e "${GREEN}Success! PDF created as $OUTPUT_FILE${NC}"

        # Additional message for CJK documents
        if detect_unicode_characters "$INPUT_FILE" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ CJK characters (Chinese, Japanese, Korean) have been properly rendered in the PDF.${NC}"
        fi

        _cleanup_pdf_artifacts
        return 0
    else
        echo -e "${RED}Error: PDF conversion failed.${NC}"
        _cleanup_pdf_artifacts
        return 1
    fi
}

# Internal: Multi-step build for documents with an index.
# Works in the source directory so xelatex can find images and fonts.
# 1. pandoc → .tex  2. xelatex (pass 1)  3. makeindex  4. xelatex (pass 2+3)
_execute_pandoc_with_index() {
    local src_dir
    src_dir=$(dirname "$_PDF_PROCESSED_INPUT_FILE")
    local base_name="${OUTPUT_FILE%.pdf}"
    local tex_file="${base_name}.tex"
    local job_name
    job_name=$(basename "$base_name")
    local out_dir
    out_dir=$(dirname "$OUTPUT_FILE")

    echo -e "${BLUE}Index enabled: using multi-step LaTeX build${NC}"

    # Step 1: Generate .tex file via pandoc (in the source directory)
    if ! pandoc "$_PDF_PROCESSED_INPUT_FILE" \
        --from markdown \
        --to latex \
        --output "$tex_file" \
        --template="$_PDF_TEMPLATE_PATH" \
        $_PDF_PANDOC_OPTS \
        $_PDF_FILTER_OPTION \
        "${_PDF_BIBLIOGRAPHY_VARS[@]}" \
        --variable=geometry:margin=1in \
        --highlight-style=tango \
        --listings \
        $_PDF_TOC_OPTION \
        $_PDF_SECTION_NUMBERING_OPTION \
        "${_PDF_FOOTER_VARS[@]}" \
        "${_PDF_HEADER_FOOTER_VARS[@]}" \
        "${_PDF_BOOK_FEATURE_VARS[@]}" \
        "${_PDF_TRIM_VARS[@]}" \
        --standalone; then
        echo -e "${RED}Error: pandoc LaTeX generation failed.${NC}"
        _cleanup_pdf_artifacts
        return 1
    fi

    # Step 2: First xelatex pass (generates .idx, .aux, .toc with preliminary page numbers)
    echo -e "${BLUE}  Pass 1/6: xelatex (generating index entries)...${NC}"
    $PDF_ENGINE -interaction=nonstopmode -output-directory="$out_dir" "$tex_file" > /dev/null 2>&1 || true

    # Step 3: First makeindex pass (builds index from preliminary page numbers)
    if [ -f "${base_name}.idx" ]; then
        echo -e "${BLUE}  Pass 2/6: makeindex (building preliminary index)...${NC}"
        makeindex "${base_name}.idx" > /dev/null 2>&1
    else
        echo -e "${YELLOW}  Warning: No .idx file generated. Index may be empty.${NC}"
    fi

    # Step 4: Second xelatex pass (includes index, which shifts pagination)
    echo -e "${BLUE}  Pass 3/6: xelatex (including index, updating pagination)...${NC}"
    $PDF_ENGINE -interaction=nonstopmode -output-directory="$out_dir" "$tex_file" > /dev/null 2>&1 || true

    # Step 5: Second makeindex pass (rebuilds index with corrected page numbers)
    if [ -f "${base_name}.idx" ]; then
        echo -e "${BLUE}  Pass 4/6: makeindex (rebuilding with final page numbers)...${NC}"
        makeindex "${base_name}.idx" > /dev/null 2>&1
    fi

    # Step 6: Third xelatex pass (includes corrected index)
    echo -e "${BLUE}  Pass 5/6: xelatex (including corrected index)...${NC}"
    $PDF_ENGINE -interaction=nonstopmode -output-directory="$out_dir" "$tex_file" > /dev/null 2>&1 || true

    # Step 7: Final xelatex pass (resolves all cross-references)
    echo -e "${BLUE}  Pass 6/6: xelatex (finalizing references)...${NC}"
    $PDF_ENGINE -interaction=nonstopmode -output-directory="$out_dir" "$tex_file" > /dev/null 2>&1 || true

    # Check result and clean up LaTeX artifacts
    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "${GREEN}Success! PDF created as $OUTPUT_FILE${NC}"

        if detect_unicode_characters "$INPUT_FILE" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ CJK characters (Chinese, Japanese, Korean) have been properly rendered in the PDF.${NC}"
        fi

        # Clean up LaTeX intermediate files
        rm -f "${base_name}.tex" "${base_name}.aux" "${base_name}.log" \
              "${base_name}.toc" "${base_name}.lof" "${base_name}.lot" \
              "${base_name}.idx" "${base_name}.ind" "${base_name}.ilg" \
              "${base_name}.out"
        _cleanup_pdf_artifacts
        return 0
    else
        echo -e "${RED}Error: PDF was not generated.${NC}"
        rm -f "${base_name}.tex" "${base_name}.aux" "${base_name}.log" \
              "${base_name}.toc" "${base_name}.lof" "${base_name}.lot" \
              "${base_name}.idx" "${base_name}.ind" "${base_name}.ilg" \
              "${base_name}.out"
        _cleanup_pdf_artifacts
        return 1
    fi
}

# Internal helper: Clean up temporary files after PDF generation
_cleanup_pdf_artifacts() {
    # Clean up bibliography temp directory
    if [ -n "$_PDF_BIB_TEMP_DIR" ] && [ -d "$_PDF_BIB_TEMP_DIR" ]; then
        rm -rf "$_PDF_BIB_TEMP_DIR"
    fi

    # Clean up: Remove template.tex file if it was created in the current directory
    if [ -f "$(pwd)/template.tex" ]; then
        echo -e "${BLUE}Cleaning up: Removing template.tex${NC}"
        rm -f "$(pwd)/template.tex"
    fi

    # Restore the original markdown file from backup
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "${BLUE}Restoring original markdown file from backup${NC}"
        mv "$BACKUP_FILE" "$INPUT_FILE"
    fi

    # Clean up combined file if multi-file project
    if [ -n "$COMBINED_FILE" ] && [ -f "$COMBINED_FILE" ]; then
        rm -f "$COMBINED_FILE"
    fi

    echo -e "${GREEN}Cleanup complete. Only the PDF and original markdown file remain.${NC}"
}

# =============================================================================
# Main PDF Generation Orchestrator
# =============================================================================

# Generate PDF output from markdown via pandoc + LaTeX
# Uses global variables: INPUT_FILE, OUTPUT_FILE, ARG_*, META_*, PDF_ENGINE,
#                        BACKUP_FILE, COMBINED_FILE
# Returns: 0 on success, 1 on failure
generate_pdf() {
    # Preprocess the markdown file for better LaTeX compatibility
    preprocess_markdown "$INPUT_FILE"

    # Image captions are now handled by the image_size_filter.lua Lua filter

    # Convert markdown to PDF using pandoc with our template
    echo -e "${YELLOW}Converting $INPUT_FILE to PDF...${NC}"
    echo -e "Using PDF engine: ${GREEN}$PDF_ENGINE${NC}"

    # Step 1: Resolve template (creates template if needed)
    resolve_pdf_template || return 1

    # Step 2: Discover and configure Lua filters
    setup_lua_filters

    # Step 3: Build pandoc variables (footer, header, book features)
    build_pandoc_vars

    # Step 4: Configure bibliography and citations
    setup_pdf_bibliography

    # Step 5: Execute pandoc and clean up
    execute_pandoc
    return $?
}
