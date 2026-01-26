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
# Main PDF Generation Function
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

    # No additional options needed for pdflatex
    PANDOC_OPTS=""

    # Check for custom template first (highest priority)
    TEMPLATE_IN_CURRENT_DIR=false
    CUSTOM_TEMPLATE_USED=false

    if [ -n "$ARG_TEMPLATE" ]; then
        # User provided custom template
        if [ -f "$ARG_TEMPLATE" ]; then
            TEMPLATE_PATH=$(realpath "$ARG_TEMPLATE")
            CUSTOM_TEMPLATE_USED=true
            echo -e "${GREEN}Using custom template: $TEMPLATE_PATH${NC}"
        else
            # Check relative to input file directory
            local input_dir
            input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$input_dir/$ARG_TEMPLATE" ]; then
                TEMPLATE_PATH=$(realpath "$input_dir/$ARG_TEMPLATE")
                CUSTOM_TEMPLATE_USED=true
                echo -e "${GREEN}Using custom template: $TEMPLATE_PATH${NC}"
            else
                echo -e "${RED}Error: Custom template '$ARG_TEMPLATE' not found${NC}"
                return 1
            fi
        fi
    fi

    # If no custom template, check for template.tex in the current directory
    if [ "$CUSTOM_TEMPLATE_USED" = false ]; then
        TEMPLATE_PATH="$(pwd)/template.tex"
    fi

    if [ "$CUSTOM_TEMPLATE_USED" = true ]; then
        # Custom template provided - use it directly
        TEMPLATE_IN_CURRENT_DIR=false
    elif [ -f "$TEMPLATE_PATH" ]; then
        TEMPLATE_IN_CURRENT_DIR=true
    else
        # Not found in current directory, check other locations
        TEMPLATE_PATH=""

        # Check in templates subdirectory
        if [ -f "$(pwd)/templates/template.tex" ]; then
            TEMPLATE_PATH="$(pwd)/templates/template.tex"
        # Check in script directory
        elif [ -f "$(dirname "$(readlink -f "$0")")/templates/template.tex" ]; then
            TEMPLATE_PATH="$(dirname "$(readlink -f "$0")")/templates/template.tex"
        elif [ -f "$(dirname "$(readlink -f "$0")")/template.tex" ]; then
            TEMPLATE_PATH="$(dirname "$(readlink -f "$0")")/template.tex"
        # Check in system directory
        elif [ -f "/usr/local/share/mdtexpdf/templates/template.tex" ]; then
            TEMPLATE_PATH="/usr/local/share/mdtexpdf/templates/template.tex"
        fi
    fi

    # Debug output to show which template is being used
    echo -e "${BLUE}Debug: Template path is $TEMPLATE_PATH${NC}"
    echo -e "${BLUE}Debug: Template in current dir: $TEMPLATE_IN_CURRENT_DIR${NC}"

    # Check if we found a template in the current directory or custom template
    if [ "$CUSTOM_TEMPLATE_USED" = true ]; then
        # Custom template already set - nothing more to do
        :
    elif [ "$TEMPLATE_IN_CURRENT_DIR" = true ]; then
        echo -e "Using template: ${GREEN}$TEMPLATE_PATH${NC}"
    else
        # Template not found in current directory
        if [ -n "$TEMPLATE_PATH" ]; then
            # Use the template from another location
            echo -e "${YELLOW}No template.tex found in current directory.${NC}"
            echo -e "${GREEN}Do you want to create a template.tex now and update your file with the proper header? (y/n) [y]:${NC}"
        else
            # No template found anywhere
            echo -e "${YELLOW}No template.tex found.${NC}"
            echo -e "${GREEN}A template.tex file is required. Create one now? (y/n) [y]:${NC}"
        fi

        # Skip prompt if arguments were provided
        if [ -n "$ARG_TITLE" ] || [ -n "$ARG_AUTHOR" ] || [ -n "$ARG_DATE" ] || [ -n "$ARG_FOOTER" ] || [ "$ARG_NO_FOOTER" = true ]; then
            CREATE_TEMPLATE="y"
            echo -e "${BLUE}Using command-line arguments, automatically creating template...${NC}"
        else
            read -r CREATE_TEMPLATE
            CREATE_TEMPLATE=${CREATE_TEMPLATE:-"y"}
        fi

        echo -e "${BLUE}Debug: User chose to create template: $CREATE_TEMPLATE${NC}"

        # Create template if user chose to
        if [[ $CREATE_TEMPLATE =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Debug: Creating template...${NC}"
            # Get document details for both template and YAML frontmatter
            echo -e "${YELLOW}Setting up document preferences...${NC}"

            # Check if the file has a first-level heading (# Title) before asking for title
            FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')

            # Set title based on command-line argument or prompt user
            if [ -n "$ARG_TITLE" ]; then
                TITLE="$ARG_TITLE"
                echo -e "${GREEN}Using title from command-line argument: '$TITLE'${NC}"
            elif [ -n "$FIRST_HEADING" ]; then
                # If a first-level heading was found, use it as the default title
                echo -e "${BLUE}Found title in document: '$FIRST_HEADING'${NC}"
                echo -e "${GREEN}Enter document title (press Enter to use the found title) [${FIRST_HEADING}]:${NC}"
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
            DATE_FOOTER_TEXT=""
            if [ -n "$ARG_DATE_FOOTER" ]; then # Check if --date-footer was used at all
                if [ -n "$ARG_DATE" ] && [ "$ARG_DATE" != "no" ]; then
                    # Attempt to parse ARG_DATE and format as YY/MM/DD
                    PARSED_DATE_FOOTER=$(date -d "$ARG_DATE" +"%y/%m/%d" 2>/dev/null)
                    if [ -n "$PARSED_DATE_FOOTER" ]; then
                        DATE_FOOTER_TEXT="$PARSED_DATE_FOOTER"
                        echo -e "${GREEN}Using document date for footer (YY/MM/DD): $DATE_FOOTER_TEXT${NC}"
                    else
                        # Fallback to current date if ARG_DATE is not parsable
                        DATE_FOOTER_TEXT="$(date +"%y/%m/%d")"
                        echo -e "${YELLOW}Warning: Could not parse date '$ARG_DATE'. Using current date for footer (YY/MM/DD): $DATE_FOOTER_TEXT${NC}"
                    fi
                else
                    # If -d was not used or was 'no', use current date formatted as YY/MM/DD
                    DATE_FOOTER_TEXT="$(date +"%y/%m/%d")"
                fi
            fi

            # Create a template file in the current directory
            TEMPLATE_PATH="$(pwd)/template.tex"
            echo -e "${YELLOW}Creating template file: $TEMPLATE_PATH${NC}"
            create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" "$DATE_FOOTER_TEXT" "$ARG_SECTION_NUMBERS" "$ARG_FORMAT" "$ARG_HEADER_FOOTER_POLICY"

            if [ ! -f "$TEMPLATE_PATH" ]; then
                echo -e "${RED}Error: Failed to create template.tex.${NC}"
                return 1
            fi

            echo -e "${GREEN}Created new template file: $TEMPLATE_PATH${NC}"

            # Check if the Markdown file has proper YAML frontmatter
            if ! head -n 1 "$INPUT_FILE" | grep -q "^---"; then
                echo -e "${YELLOW}Updating $INPUT_FILE with proper YAML frontmatter...${NC}"

                # Check if the file has a first-level heading (# Title)
                FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')

                # Create a temporary file with the YAML frontmatter
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
        else
            # User chose not to create a template
            if [ -n "$TEMPLATE_PATH" ]; then
                # Use the template from another location
                echo -e "Using template: ${GREEN}$TEMPLATE_PATH${NC}"
            else
                echo -e "${RED}Cannot proceed without a template.${NC}"
                return 1
            fi
        fi
    fi

    # Find the path to the Lua filters
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    LUA_FILTERS=()

    # Check for heading fix filter (add this first to process headings before other filters)
    if [ -f "$(pwd)/heading_fix_filter.lua" ]; then
        LUA_FILTERS+=("$(pwd)/heading_fix_filter.lua")
        echo -e "${BLUE}Using Lua filter for heading line break fix: $(pwd)/heading_fix_filter.lua${NC}"
    elif [ -f "$SCRIPT_DIR/heading_fix_filter.lua" ]; then
        LUA_FILTERS+=("$SCRIPT_DIR/heading_fix_filter.lua")
        echo -e "${BLUE}Using Lua filter for heading line break fix: $SCRIPT_DIR/heading_fix_filter.lua${NC}"
    elif [ -f "/usr/local/share/mdtexpdf/heading_fix_filter.lua" ]; then
        LUA_FILTERS+=("/usr/local/share/mdtexpdf/heading_fix_filter.lua")
        echo -e "${BLUE}Using Lua filter for heading line break fix: /usr/local/share/mdtexpdf/heading_fix_filter.lua${NC}"
    else
        echo -e "${YELLOW}Warning: heading_fix_filter.lua not found. Level 4 and 5 headings may run inline.${NC}"
    fi

    # Check for long equation filter
    if [ -f "$(pwd)/filters/long_equation_filter.lua" ]; then
        LUA_FILTERS+=("$(pwd)/filters/long_equation_filter.lua")
        echo -e "${BLUE}Using Lua filter for long equation handling: $(pwd)/filters/long_equation_filter.lua${NC}"
    elif [ -f "$SCRIPT_DIR/filters/long_equation_filter.lua" ]; then
        LUA_FILTERS+=("$SCRIPT_DIR/filters/long_equation_filter.lua")
        echo -e "${BLUE}Using Lua filter for long equation handling: $SCRIPT_DIR/filters/long_equation_filter.lua${NC}"
    elif [ -f "/usr/local/share/mdtexpdf/filters/long_equation_filter.lua" ]; then
        LUA_FILTERS+=("/usr/local/share/mdtexpdf/filters/long_equation_filter.lua")
        echo -e "${BLUE}Using Lua filter for long equation handling: /usr/local/share/mdtexpdf/filters/long_equation_filter.lua${NC}"
    else
        echo -e "${YELLOW}Warning: long_equation_filter.lua not found. Long equations may not wrap properly.${NC}"
    fi

    # Check for image size filter
    if [ -f "$(pwd)/image_size_filter.lua" ]; then
        LUA_FILTERS+=("$(pwd)/image_size_filter.lua")
        echo -e "${BLUE}Using Lua filter for automatic image sizing: $(pwd)/image_size_filter.lua${NC}"
    elif [ -f "$SCRIPT_DIR/image_size_filter.lua" ]; then
        LUA_FILTERS+=("$SCRIPT_DIR/image_size_filter.lua")
        echo -e "${BLUE}Using Lua filter for automatic image sizing: $SCRIPT_DIR/image_size_filter.lua${NC}"
    elif [ -f "/usr/local/share/mdtexpdf/image_size_filter.lua" ]; then
        LUA_FILTERS+=("/usr/local/share/mdtexpdf/image_size_filter.lua")
        echo -e "${BLUE}Using Lua filter for automatic image sizing: /usr/local/share/mdtexpdf/image_size_filter.lua${NC}"
    else
        echo -e "${YELLOW}Warning: image_size_filter.lua not found. Images may not be properly sized.${NC}"
    fi

    # Add book structure filter if format is book
    if [ "$ARG_FORMAT" = "book" ]; then
        local book_filter_path=""
        if [ -f "$(pwd)/filters/book_structure.lua" ]; then
            book_filter_path="$(pwd)/filters/book_structure.lua"
        elif [ -f "$SCRIPT_DIR/filters/book_structure.lua" ]; then
            book_filter_path="$SCRIPT_DIR/filters/book_structure.lua"
        elif [ -f "/usr/local/share/mdtexpdf/book_structure.lua" ]; then
            book_filter_path="/usr/local/share/mdtexpdf/book_structure.lua"
        fi

        if [ -n "$book_filter_path" ]; then
            LUA_FILTERS+=("$book_filter_path")
            echo -e "${BLUE}Using Lua filter for book structure: $book_filter_path${NC}"
        else
            echo -e "${YELLOW}Warning: book_structure.lua not found. Book format may not work correctly.${NC}"
        fi
    fi

    # Add index filter if --index is enabled
    if [ "$ARG_INDEX" = true ]; then
        local index_filter_path=""
        if [ -f "$(pwd)/filters/index_filter.lua" ]; then
            index_filter_path="$(pwd)/filters/index_filter.lua"
        elif [ -f "$SCRIPT_DIR/filters/index_filter.lua" ]; then
            index_filter_path="$SCRIPT_DIR/filters/index_filter.lua"
        elif [ -f "/usr/local/share/mdtexpdf/filters/index_filter.lua" ]; then
            index_filter_path="/usr/local/share/mdtexpdf/filters/index_filter.lua"
        fi

        if [ -n "$index_filter_path" ]; then
            LUA_FILTERS+=("$index_filter_path")
            echo -e "${BLUE}Using Lua filter for index generation: $index_filter_path${NC}"
        else
            echo -e "${YELLOW}Warning: index_filter.lua not found. Index markers will not be processed.${NC}"
        fi
    fi

    # Add drop caps filter if drop_caps is enabled
    if [ "$META_DROP_CAPS" = "true" ]; then
        local drop_caps_filter_path=""
        if [ -f "$(pwd)/filters/drop_caps_filter.lua" ]; then
            drop_caps_filter_path="$(pwd)/filters/drop_caps_filter.lua"
        elif [ -f "$SCRIPT_DIR/filters/drop_caps_filter.lua" ]; then
            drop_caps_filter_path="$SCRIPT_DIR/filters/drop_caps_filter.lua"
        elif [ -f "/usr/local/share/mdtexpdf/drop_caps_filter.lua" ]; then
            drop_caps_filter_path="/usr/local/share/mdtexpdf/drop_caps_filter.lua"
        fi

        if [ -n "$drop_caps_filter_path" ]; then
            LUA_FILTERS+=("$drop_caps_filter_path")
            echo -e "${BLUE}Using Lua filter for drop caps: $drop_caps_filter_path${NC}"
        else
            echo -e "${YELLOW}Warning: drop_caps_filter.lua not found. Drop caps will not be applied.${NC}"
        fi
    fi

    # Build filter options
    FILTER_OPTION=""
    for filter in "${LUA_FILTERS[@]}"; do
        FILTER_OPTION="$FILTER_OPTION --lua-filter=$filter"
    done

    # Run pandoc with the selected PDF engine
    echo -e "${BLUE}Using enhanced equation line breaking for text-heavy equations${NC}"

    # Add TOC option if requested
    TOC_OPTION=""
    if [ "$ARG_TOC" = true ]; then
        TOC_OPTION="--toc"
    fi

    # Generate section numbering variable for pandoc if needed
    SECTION_NUMBERING_OPTION=""
    if [ "$ARG_SECTION_NUMBERS" = false ]; then
        SECTION_NUMBERING_OPTION="--variable=numbersections=false"
    fi

    FOOTER_VARS=()
    if [ "$ARG_NO_FOOTER" = true ]; then
        FOOTER_VARS+=("--variable=no_footer=true")
    else
        # Center footer content from -f option
        if [ -n "$ARG_FOOTER" ]; then # ARG_FOOTER is the value from -f option
             FOOTER_VARS+=("--variable=center_footer_content=$ARG_FOOTER")
        fi

        # Page X of Y format for right footer
        if [ "$ARG_PAGE_OF" = true ]; then
            FOOTER_VARS+=("--variable=page_of_format=true")
        fi

        # Left footer content (date)
        # DATE_FOOTER_TEXT is determined around lines 916-934 based on ARG_DATE_FOOTER
        if [ -n "$DATE_FOOTER_TEXT" ]; then # DATE_FOOTER_TEXT is a shell variable in convert()
            FOOTER_VARS+=("--variable=date_footer_content=$DATE_FOOTER_TEXT")
        fi
    fi

    # Add header/footer policy variables
    HEADER_FOOTER_VARS=()
    if [ "$ARG_HEADER_FOOTER_POLICY" = "all" ]; then
        HEADER_FOOTER_VARS+=("--variable=header_footer_policy_all=true")
    elif [ "$ARG_HEADER_FOOTER_POLICY" = "partial" ]; then
        HEADER_FOOTER_VARS+=("--variable=header_footer_policy_partial=true")
    else
        # default policy - no special variables needed (plain pages will have no headers/footers)
        HEADER_FOOTER_VARS+=("--variable=header_footer_policy_default=true")
    fi

    # Add format variable for template logic
    if [ "$ARG_FORMAT" = "book" ]; then
        HEADER_FOOTER_VARS+=("--variable=format_book=true")
    else
        HEADER_FOOTER_VARS+=("--variable=format_article=true")
    fi

    # Professional book features (passed to template)
    BOOK_FEATURE_VARS=()

    # Index generation
    if [ "$ARG_INDEX" = true ]; then
        BOOK_FEATURE_VARS+=("--variable=index=true")
    fi

    # Half-title page
    if [ "$META_HALF_TITLE" = "true" ] || [ "$META_HALF_TITLE" = "True" ] || [ "$META_HALF_TITLE" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=half_title=true")
    fi

    # Copyright page
    if [ "$META_COPYRIGHT_PAGE" = "true" ] || [ "$META_COPYRIGHT_PAGE" = "True" ] || [ "$META_COPYRIGHT_PAGE" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=copyright_page=true")
    fi

    # Dedication (from metadata - string value)
    if [ -n "$META_DEDICATION" ] && [ "$META_DEDICATION" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=dedication=$META_DEDICATION")
    fi

    # Epigraph (from metadata - string value)
    if [ -n "$META_EPIGRAPH" ] && [ "$META_EPIGRAPH" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=epigraph=$META_EPIGRAPH")
    fi

    # Epigraph source
    if [ -n "$META_EPIGRAPH_SOURCE" ] && [ "$META_EPIGRAPH_SOURCE" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=epigraph_source=$META_EPIGRAPH_SOURCE")
    fi

    # Chapters on recto (odd pages only)
    if [ "$META_CHAPTERS_ON_RECTO" = "true" ] || [ "$META_CHAPTERS_ON_RECTO" = "True" ] || [ "$META_CHAPTERS_ON_RECTO" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=chapters_on_recto=true")
    fi

    # Drop caps
    if [ "$META_DROP_CAPS" = "true" ] || [ "$META_DROP_CAPS" = "True" ] || [ "$META_DROP_CAPS" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=drop_caps=true")
    fi

    # Publisher
    if [ -n "$META_PUBLISHER" ] && [ "$META_PUBLISHER" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=publisher=$META_PUBLISHER")
    fi

    # ISBN
    if [ -n "$META_ISBN" ] && [ "$META_ISBN" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=isbn=$META_ISBN")
    fi

    # Edition
    if [ -n "$META_EDITION" ] && [ "$META_EDITION" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=edition=$META_EDITION")
    fi

    # Copyright year
    if [ -n "$META_COPYRIGHT_YEAR" ] && [ "$META_COPYRIGHT_YEAR" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=copyright_year=$META_COPYRIGHT_YEAR")
    fi

    # Copyright holder (takes precedence over publisher and author)
    if [ -n "$META_COPYRIGHT_HOLDER" ] && [ "$META_COPYRIGHT_HOLDER" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=copyright_holder=$META_COPYRIGHT_HOLDER")
    fi

    # Enhanced copyright page fields (industry standard)
    # Edition date
    if [ -n "$META_EDITION_DATE" ] && [ "$META_EDITION_DATE" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=edition_date=$META_EDITION_DATE")
    fi

    # Printing info
    if [ -n "$META_PRINTING" ] && [ "$META_PRINTING" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=printing=$META_PRINTING")
    fi

    # Publisher address
    if [ -n "$META_PUBLISHER_ADDRESS" ] && [ "$META_PUBLISHER_ADDRESS" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=publisher_address=$META_PUBLISHER_ADDRESS")
    fi

    # Publisher website
    if [ -n "$META_PUBLISHER_WEBSITE" ] && [ "$META_PUBLISHER_WEBSITE" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=publisher_website=$META_PUBLISHER_WEBSITE")
    fi

    # === COVER SYSTEM VARIABLES ===
    # Get input file directory for auto-detection
    local INPUT_DIR
    INPUT_DIR=$(dirname "$INPUT_FILE")

    # Front cover image (with auto-detection fallback)
    local COVER_IMAGE_PATH="$META_COVER_IMAGE"
    if [ -z "$COVER_IMAGE_PATH" ]; then
        COVER_IMAGE_PATH=$(detect_cover_image "$INPUT_DIR" "cover")
        if [ -n "$COVER_IMAGE_PATH" ]; then
            echo -e "${GREEN}Auto-detected front cover image: $COVER_IMAGE_PATH${NC}"
        fi
    fi
    if [ -n "$COVER_IMAGE_PATH" ] && [ -f "$COVER_IMAGE_PATH" ]; then
        BOOK_FEATURE_VARS+=("--variable=cover_image=$COVER_IMAGE_PATH")
    elif [ -n "$META_COVER_IMAGE" ]; then
        # Try relative to input file
        local RELATIVE_COVER="$INPUT_DIR/$META_COVER_IMAGE"
        if [ -f "$RELATIVE_COVER" ]; then
            BOOK_FEATURE_VARS+=("--variable=cover_image=$RELATIVE_COVER")
        else
            echo -e "${YELLOW}Warning: Cover image not found: $META_COVER_IMAGE${NC}"
        fi
    fi

    # Cover title color
    if [ -n "$META_COVER_TITLE_COLOR" ]; then
        BOOK_FEATURE_VARS+=("--variable=cover_title_color=$META_COVER_TITLE_COLOR")
    fi

    # Cover subtitle show
    if [ "$META_COVER_SUBTITLE_SHOW" = "true" ] || [ "$META_COVER_SUBTITLE_SHOW" = "True" ] || [ "$META_COVER_SUBTITLE_SHOW" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=cover_subtitle_show=true")
    fi

    # Cover author position
    if [ -n "$META_COVER_AUTHOR_POSITION" ] && [ "$META_COVER_AUTHOR_POSITION" != "none" ]; then
        BOOK_FEATURE_VARS+=("--variable=cover_author_position=$META_COVER_AUTHOR_POSITION")
    fi

    # Cover overlay opacity
    if [ -n "$META_COVER_OVERLAY_OPACITY" ]; then
        BOOK_FEATURE_VARS+=("--variable=cover_overlay_opacity=$META_COVER_OVERLAY_OPACITY")
    fi

    # Cover fit mode (contain or cover)
    if [ "$META_COVER_FIT" = "cover" ]; then
        BOOK_FEATURE_VARS+=("--variable=cover_fit_cover=true")
    fi

    # Back cover image (with auto-detection fallback)
    local BACK_COVER_IMAGE_PATH="$META_BACK_COVER_IMAGE"
    if [ -z "$BACK_COVER_IMAGE_PATH" ]; then
        BACK_COVER_IMAGE_PATH=$(detect_cover_image "$INPUT_DIR" "back")
        if [ -n "$BACK_COVER_IMAGE_PATH" ]; then
            echo -e "${GREEN}Auto-detected back cover image: $BACK_COVER_IMAGE_PATH${NC}"
        fi
    fi
    if [ -n "$BACK_COVER_IMAGE_PATH" ] && [ -f "$BACK_COVER_IMAGE_PATH" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_image=$BACK_COVER_IMAGE_PATH")
    elif [ -n "$META_BACK_COVER_IMAGE" ]; then
        # Try relative to input file
        local RELATIVE_BACK_COVER="$INPUT_DIR/$META_BACK_COVER_IMAGE"
        if [ -f "$RELATIVE_BACK_COVER" ]; then
            BOOK_FEATURE_VARS+=("--variable=back_cover_image=$RELATIVE_BACK_COVER")
        else
            echo -e "${YELLOW}Warning: Back cover image not found: $META_BACK_COVER_IMAGE${NC}"
        fi
    fi

    # Back cover content type
    if [ -n "$META_BACK_COVER_CONTENT" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_content=$META_BACK_COVER_CONTENT")
    fi

    # Back cover quote
    if [ -n "$META_BACK_COVER_QUOTE" ] && [ "$META_BACK_COVER_QUOTE" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_quote=$META_BACK_COVER_QUOTE")
    fi

    # Back cover quote source
    if [ -n "$META_BACK_COVER_QUOTE_SOURCE" ] && [ "$META_BACK_COVER_QUOTE_SOURCE" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_quote_source=$META_BACK_COVER_QUOTE_SOURCE")
    fi

    # Back cover summary
    if [ -n "$META_BACK_COVER_SUMMARY" ] && [ "$META_BACK_COVER_SUMMARY" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_summary=$META_BACK_COVER_SUMMARY")
    fi

    # Back cover custom text
    if [ -n "$META_BACK_COVER_TEXT" ] && [ "$META_BACK_COVER_TEXT" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_text=$META_BACK_COVER_TEXT")
    fi

    # Back cover author bio
    if [ "$META_BACK_COVER_AUTHOR_BIO" = "true" ] || [ "$META_BACK_COVER_AUTHOR_BIO" = "True" ] || [ "$META_BACK_COVER_AUTHOR_BIO" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_author_bio=true")
    fi

    # Back cover author bio text
    if [ -n "$META_BACK_COVER_AUTHOR_BIO_TEXT" ] && [ "$META_BACK_COVER_AUTHOR_BIO_TEXT" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_author_bio_text=$META_BACK_COVER_AUTHOR_BIO_TEXT")
    fi

    # Back cover ISBN barcode placeholder
    if [ "$META_BACK_COVER_ISBN_BARCODE" = "true" ] || [ "$META_BACK_COVER_ISBN_BARCODE" = "True" ] || [ "$META_BACK_COVER_ISBN_BARCODE" = "TRUE" ]; then
        BOOK_FEATURE_VARS+=("--variable=back_cover_isbn_barcode=true")
    fi

    # === AUTHORSHIP & SUPPORT SYSTEM VARIABLES ===
    # Author public key
    if [ -n "$META_AUTHOR_PUBKEY" ] && [ "$META_AUTHOR_PUBKEY" != "null" ]; then
        BOOK_FEATURE_VARS+=("--variable=author_pubkey=$META_AUTHOR_PUBKEY")
        BOOK_FEATURE_VARS+=("--variable=author_pubkey_type=$META_AUTHOR_PUBKEY_TYPE")
    fi

    # Donation wallets (pre-formatted LaTeX string)
    if [ -n "$META_DONATION_WALLETS" ]; then
        BOOK_FEATURE_VARS+=("--variable=donation_wallets=$META_DONATION_WALLETS")
    fi

    # === BIBLIOGRAPHY & CITATIONS ===
    local -a BIBLIOGRAPHY_VARS=()
    local bib_temp_dir=""
    local bib_path=""
    local using_inline_bib=false
    local processed_input_file="$INPUT_FILE"

    # Check for inline bibliography first (if no external bibliography specified)
    if [ -z "$ARG_BIBLIOGRAPHY" ] && type has_inline_bibliography &>/dev/null; then
        if has_inline_bibliography "$INPUT_FILE"; then
            echo -e "${BLUE}Detected inline bibliography in document${NC}"
            bib_temp_dir=$(mktemp -d)

            if bib_path=$(process_inline_bibliography "$INPUT_FILE" "$bib_temp_dir"); then
                # Use the content file without bibliography section
                processed_input_file="$bib_temp_dir/content.md"
                using_inline_bib=true
                BIBLIOGRAPHY_VARS+=("--citeproc")
                BIBLIOGRAPHY_VARS+=("--bibliography=$bib_path")
                echo -e "${GREEN}Using inline bibliography (extracted to $bib_path)${NC}"
            else
                echo -e "${YELLOW}Warning: Could not process inline bibliography${NC}"
                rm -rf "$bib_temp_dir"
                bib_temp_dir=""
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
                [ -z "$bib_temp_dir" ] && bib_temp_dir=$(mktemp -d)

                if bib_path=$(process_bibliography_file "$external_bib_path" "$bib_temp_dir"); then
                    BIBLIOGRAPHY_VARS+=("--citeproc")
                    BIBLIOGRAPHY_VARS+=("--bibliography=$bib_path")
                    echo -e "${GREEN}Using simple bibliography: $external_bib_path${NC}"
                else
                    echo -e "${YELLOW}Warning: Could not convert simple bibliography${NC}"
                fi
            else
                # Traditional .bib or CSL-JSON file
                bib_path="$external_bib_path"
                BIBLIOGRAPHY_VARS+=("--citeproc")
                BIBLIOGRAPHY_VARS+=("--bibliography=$bib_path")
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
            BIBLIOGRAPHY_VARS+=("--csl=$csl_path")
            echo -e "${GREEN}Using citation style: $csl_path${NC}"
        else
            echo -e "${YELLOW}Warning: CSL file '$ARG_CSL' not found${NC}"
        fi
    fi

    # shellcheck disable=SC2086 # Word splitting is intentional for PANDOC_OPTS/FILTER_OPTION/TOC_OPTION/SECTION_NUMBERING_OPTION
    if pandoc "$processed_input_file" \
        --from markdown \
        --to pdf \
        --output "$OUTPUT_FILE" \
        --template="$TEMPLATE_PATH" \
        --pdf-engine="$PDF_ENGINE" \
        $PANDOC_OPTS \
        $FILTER_OPTION \
        "${BIBLIOGRAPHY_VARS[@]}" \
        --variable=geometry:margin=1in \
        --highlight-style=tango \
        --listings \
        $TOC_OPTION \
        $SECTION_NUMBERING_OPTION \
        "${FOOTER_VARS[@]}" \
        "${HEADER_FOOTER_VARS[@]}" \
        "${BOOK_FEATURE_VARS[@]}" \
        --standalone; then
        echo -e "${GREEN}Success! PDF created as $OUTPUT_FILE${NC}"

        # Additional message for CJK documents
        if detect_unicode_characters "$INPUT_FILE" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ CJK characters (Chinese, Japanese, Korean) have been properly rendered in the PDF.${NC}"
        fi

        # Clean up bibliography temp directory
        if [ -n "$bib_temp_dir" ] && [ -d "$bib_temp_dir" ]; then
            rm -rf "$bib_temp_dir"
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
        return 0
    else
        echo -e "${RED}Error: PDF conversion failed.${NC}"

        # Clean up bibliography temp directory
        if [ -n "$bib_temp_dir" ] && [ -d "$bib_temp_dir" ]; then
            rm -rf "$bib_temp_dir"
        fi

        # Clean up: Remove template.tex file if it was created in the current directory
        if [ -f "$(pwd)/template.tex" ]; then
            echo -e "${BLUE}Cleaning up: Removing template.tex${NC}"
            rm -f "$(pwd)/template.tex"
        fi

        # Restore the original markdown file from backup even if conversion failed
        if [ -f "$BACKUP_FILE" ]; then
            echo -e "${BLUE}Restoring original markdown file from backup${NC}"
            mv "$BACKUP_FILE" "$INPUT_FILE"
        fi

        # Clean up combined file if multi-file project
        if [ -n "$COMBINED_FILE" ] && [ -f "$COMBINED_FILE" ]; then
            rm -f "$COMBINED_FILE"
        fi

        return 1
    fi
}
