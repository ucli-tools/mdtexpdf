#!/bin/bash
# =============================================================================
# mdtexpdf Metadata Module
# YAML and HTML metadata parsing from markdown files
# =============================================================================

# Source core if not already loaded
if [ -z "$MDTEXPDF_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=core.sh
    source "$SCRIPT_DIR/core.sh"
fi

# =============================================================================
# Metadata Variables (global, set by parsing functions)
# =============================================================================

# Initialize all metadata variables
init_metadata_vars() {
    # Core metadata (Dublin Core standard)
    META_TITLE=""
    META_SUBTITLE=""
    META_AUTHOR=""
    META_DATE=""
    META_DESCRIPTION=""
    META_LANGUAGE=""

    # Document structure metadata
    META_SECTION=""
    META_SLUG=""
    META_FORMAT="article"

    # PDF-specific metadata
    META_FOOTER=""
    META_TOC=""
    META_TOC_DEPTH=""
    META_INDEX=""
    META_NO_NUMBERS=""
    META_NO_FOOTER=""
    META_PAGEOF=""
    META_DATE_FOOTER=""
    META_NO_DATE=""
    META_HEADER_FOOTER_POLICY=""

    # Audio-specific metadata (for future compatibility)
    META_GENRE=""
    META_NARRATOR_VOICE=""
    META_READING_SPEED=""

    # Professional book features
    META_NO_TITLE_PAGE=""
    META_HALF_TITLE=""
    META_COPYRIGHT_PAGE=""
    META_DEDICATION=""
    META_EPIGRAPH=""
    META_EPIGRAPH_SOURCE=""
    META_CHAPTERS_ON_RECTO=""
    META_DROP_CAPS=""
    META_EQUATION_NUMBERS=""
    META_PUBLISHER=""
    META_ISBN=""
    META_EDITION=""
    META_COPYRIGHT_YEAR=""
    META_COPYRIGHT_HOLDER=""
    META_EDITION_DATE=""
    META_PRINTING=""
    META_PUBLISHER_ADDRESS=""
    META_PUBLISHER_WEBSITE=""

    # Bibliography and citations
    META_BIBLIOGRAPHY=""
    META_CSL=""

    # Cover system (Front cover - Première de couverture)
    META_COVER_IMAGE=""
    META_COVER_TITLE_COLOR="white"
    META_COVER_TITLE_SHOW="true"
    META_COVER_SUBTITLE_SHOW="true"
    META_COVER_AUTHOR_POSITION="bottom"
    META_COVER_OVERLAY_OPACITY=""
    META_COVER_FIT="contain"

    # Back cover (Quatrième de couverture)
    META_BACK_COVER_IMAGE=""
    META_BACK_COVER_CONTENT=""
    META_BACK_COVER_TEXT=""
    META_BACK_COVER_QUOTE=""
    META_BACK_COVER_QUOTE_SOURCE=""
    META_BACK_COVER_SUMMARY=""
    META_BACK_COVER_AUTHOR_BIO=""
    META_BACK_COVER_AUTHOR_BIO_TEXT=""
    META_BACK_COVER_ISBN_BARCODE=""

    # Print-ready / Lulu settings
    META_TRIM_SIZE=""           # e.g., "5.5x8.5", "6x9", "7x10", "a5", "a4"
    META_PAPER_STOCK="cream60"  # cream60, white60, white80
    META_SPINE_TEXT="auto"      # auto, true, false — controls spine text on cover spread

    # Authorship & Support
    META_AUTHOR_PUBKEY=""
    META_AUTHOR_PUBKEY_TYPE="PGP"
    META_DONATION_WALLETS=""
}

# =============================================================================
# HTML Metadata Parsing (legacy format)
# =============================================================================

parse_html_metadata() {
    local input_file="$1"

    # Initialize metadata variables
    init_metadata_vars

    echo -e "${BLUE}Parsing metadata from HTML comments...${NC}"

    # Extract metadata from multi-line HTML comment block
    local in_comment=false
    while IFS= read -r line; do
        # Check if we're entering a comment block
        if echo "$line" | grep -q "^[[:space:]]*<!--[[:space:]]*$"; then
            in_comment=true
            continue
        fi

        # Check if we're exiting a comment block
        if echo "$line" | grep -q "^[[:space:]]*-->[[:space:]]*$"; then
            in_comment=false
            continue
        fi

        # If we're inside a comment block, parse key: value pairs
        if [ "$in_comment" = true ]; then
            # Check if line contains key: value format
            if echo "$line" | grep -q ":"; then
                local key
                local value
                key=$(echo "$line" | sed -n 's/^[[:space:]]*\([^:]*\):[[:space:]]*.*$/\1/p')
                value=$(echo "$line" | sed -n 's/^[[:space:]]*[^:]*:[[:space:]]*"\?\([^"]*\)"\?[[:space:]]*$/\1/p')

                # If value extraction with quotes failed, try without quotes
                if [ -z "$value" ]; then
                    value=$(echo "$line" | sed -n 's/^[[:space:]]*[^:]*:[[:space:]]*\(.*\)[[:space:]]*$/\1/p')
                fi

                # Trim whitespace from key and value
                key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            else
                continue
            fi
        else
            continue
        fi

        case "$key" in
            "title") META_TITLE="$value"; echo -e "${GREEN}Found metadata - title: $value${NC}" ;;
            "author") META_AUTHOR="$value"; echo -e "${GREEN}Found metadata - author: $value${NC}" ;;
            "date") META_DATE="$value"; echo -e "${GREEN}Found metadata - date: $value${NC}" ;;
            "description") META_DESCRIPTION="$value"; echo -e "${GREEN}Found metadata - description: $value${NC}" ;;
            "section") META_SECTION="$value"; echo -e "${GREEN}Found metadata - section: $value${NC}" ;;
            "slug") META_SLUG="$value"; echo -e "${GREEN}Found metadata - slug: $value${NC}" ;;
            "footer") META_FOOTER="$value"; echo -e "${GREEN}Found metadata - footer: $value${NC}" ;;
            "toc") META_TOC="$value"; echo -e "${GREEN}Found metadata - toc: $value${NC}" ;;
            "toc_depth") META_TOC_DEPTH="$value"; echo -e "${GREEN}Found metadata - toc_depth: $value${NC}" ;;
            "index") META_INDEX="$value"; echo -e "${GREEN}Found metadata - index: $value${NC}" ;;
            "no_numbers") META_NO_NUMBERS="$value"; echo -e "${GREEN}Found metadata - no_numbers: $value${NC}" ;;
            "no_footer") META_NO_FOOTER="$value"; echo -e "${GREEN}Found metadata - no_footer: $value${NC}" ;;
            "pageof") META_PAGEOF="$value"; echo -e "${GREEN}Found metadata - pageof: $value${NC}" ;;
            "date_footer") META_DATE_FOOTER="$value"; echo -e "${GREEN}Found metadata - date_footer: $value${NC}" ;;
            "no_date") META_NO_DATE="$value"; echo -e "${GREEN}Found metadata - no_date: $value${NC}" ;;
            "format") META_FORMAT="$value"; echo -e "${GREEN}Found metadata - format: $value${NC}" ;;
            "header_footer_policy")
                case "$value" in
                    "default"|"partial"|"all")
                        META_HEADER_FOOTER_POLICY="$value"
                        echo -e "${GREEN}Found metadata - header_footer_policy: $value${NC}"
                        ;;
                    *)
                        echo -e "${YELLOW}Warning: Invalid header_footer_policy '$value'. Valid options: default, partial, all${NC}"
                        ;;
                esac
                ;;
        esac
    done < "$input_file"

    # Extract title from first H1 heading if not provided in metadata
    if [ -z "$META_TITLE" ]; then
        META_TITLE=$(grep -m 1 "^# " "$input_file" | sed 's/^# //')
        if [ -n "$META_TITLE" ]; then
            echo -e "${GREEN}Found title from H1 heading: $META_TITLE${NC}"
        fi
    fi
}

# =============================================================================
# YAML Frontmatter Parsing (preferred format)
# =============================================================================

parse_yaml_metadata() {
    local input_file="$1"

    # Initialize metadata variables
    init_metadata_vars

    echo -e "${BLUE}Parsing metadata from YAML frontmatter...${NC}"

    # Check if file has YAML frontmatter (starts with ---)
    if ! head -n 1 "$input_file" | grep -q "^---\s*$"; then
        echo -e "${YELLOW}No YAML frontmatter found, trying H1 title extraction...${NC}"
        META_TITLE=$(grep -m 1 "^# " "$input_file" | sed 's/^# //')
        if [ -n "$META_TITLE" ]; then
            echo -e "${GREEN}Found title from H1 heading: $META_TITLE${NC}"
        fi
        return
    fi

    # Extract YAML frontmatter block (between first --- and second ---)
    local yaml_content
    yaml_content=$(sed -n '/^---$/,/^---$/p' "$input_file" | sed '1d;$d')

    if [ -z "$yaml_content" ]; then
        echo -e "${YELLOW}Empty YAML frontmatter block${NC}"
        return
    fi

    # Create temporary YAML file for parsing
    local temp_yaml
    temp_yaml=$(mktemp)
    echo "$yaml_content" > "$temp_yaml"

    # Parse YAML using yq and extract metadata fields
    # Core metadata (Dublin Core standard)
    META_TITLE=$(yq eval '.title // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_SUBTITLE=$(yq eval '.subtitle // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_AUTHOR=$(yq eval '.author // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_DATE=$(yq eval '.date // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_DESCRIPTION=$(yq eval '.description // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_LANGUAGE=$(yq eval '.language // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')

    # Document structure metadata
    META_SECTION=$(yq eval '.section // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_SLUG=$(yq eval '.slug // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_FORMAT=$(yq eval '.format // "article"' "$temp_yaml" 2>/dev/null | sed 's/^null$/article/')

    # PDF-specific metadata
    META_TOC=$(yq eval '.toc // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_TOC_DEPTH=$(yq eval '.toc_depth // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    local index_val
    index_val=$(yq eval '.index // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$index_val" = "true" ] && META_INDEX="true"
    META_FOOTER=$(yq eval '.footer // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_HEADER_FOOTER_POLICY=$(yq eval '.header_footer_policy // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')

    # Bibliography and citations
    META_BIBLIOGRAPHY=$(yq eval '.bibliography // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_CSL=$(yq eval '.csl // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')

    # Boolean flags (convert true/false to appropriate values)
    local section_numbers_val no_numbers_val
    section_numbers_val=$(yq eval '.section_numbers // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    no_numbers_val=$(yq eval '.no_numbers // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$section_numbers_val" = "false" ] && META_NO_NUMBERS="true"
    [ "$no_numbers_val" = "true" ] && META_NO_NUMBERS="true"

    local no_footer_val pageof_val date_footer_val no_date_val
    no_footer_val=$(yq eval '.no_footer // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$no_footer_val" = "true" ] && META_NO_FOOTER="true"

    pageof_val=$(yq eval '.pageof // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$pageof_val" = "true" ] && META_PAGEOF="true"

    date_footer_val=$(yq eval '.date_footer // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$date_footer_val" = "true" ] && META_DATE_FOOTER="true"

    no_date_val=$(yq eval '.no_date // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$no_date_val" = "true" ] && META_NO_DATE="true"

    # Audio-specific metadata
    META_GENRE=$(yq eval '.genre // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_NARRATOR_VOICE=$(yq eval '.narrator_voice // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_READING_SPEED=$(yq eval '.reading_speed // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')

    # Professional book features
    META_NO_TITLE_PAGE=$(yq eval '.no_title_page // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_HALF_TITLE=$(yq eval '.half_title // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_COPYRIGHT_PAGE=$(yq eval '.copyright_page // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_DEDICATION=$(yq eval '.dedication // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_EPIGRAPH=$(yq eval '.epigraph // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_EPIGRAPH_SOURCE=$(yq eval '.epigraph_source // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_CHAPTERS_ON_RECTO=$(yq eval '.chapters_on_recto // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_DROP_CAPS=$(yq eval '.drop_caps // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_EQUATION_NUMBERS=$(yq eval '.equation_numbers // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_PUBLISHER=$(yq eval '.publisher // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_ISBN=$(yq eval '.isbn // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_EDITION=$(yq eval '.edition // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_COPYRIGHT_YEAR=$(yq eval '.copyright_year // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_COPYRIGHT_HOLDER=$(yq eval '.copyright_holder // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_EDITION_DATE=$(yq eval '.edition_date // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_PRINTING=$(yq eval '.printing // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_PUBLISHER_ADDRESS=$(yq eval '.publisher_address // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_PUBLISHER_WEBSITE=$(yq eval '.publisher_website // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')

    # Cover system
    META_COVER_IMAGE=$(yq eval '.cover_image // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_COVER_TITLE_COLOR=$(yq eval '.cover_title_color // "white"' "$temp_yaml" 2>/dev/null | sed 's/^null$/white/')
    META_COVER_TITLE_SHOW=$(yq eval '.cover_title_show' "$temp_yaml" 2>/dev/null | sed 's/^null$/true/')
    META_COVER_SUBTITLE_SHOW=$(yq eval '.cover_subtitle_show' "$temp_yaml" 2>/dev/null | sed 's/^null$/true/')
    META_COVER_AUTHOR_POSITION=$(yq eval '.cover_author_position // "bottom"' "$temp_yaml" 2>/dev/null | sed 's/^null$/bottom/')
    META_COVER_AUTHOR_OFFSET=$(yq eval '.cover_author_offset // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_COVER_OVERLAY_OPACITY=$(yq eval '.cover_overlay_opacity // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_COVER_FIT=$(yq eval '.cover_fit // "contain"' "$temp_yaml" 2>/dev/null | sed 's/^null$/contain/')

    # Back cover
    META_BACK_COVER_IMAGE=$(yq eval '.back_cover_image // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_CONTENT=$(yq eval '.back_cover_content // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_TEXT=$(yq eval '.back_cover_text // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_QUOTE=$(yq eval '.back_cover_quote // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_QUOTE_SOURCE=$(yq eval '.back_cover_quote_source // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_SUMMARY=$(yq eval '.back_cover_summary // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_AUTHOR_BIO=$(yq eval '.back_cover_author_bio // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_AUTHOR_BIO_TEXT=$(yq eval '.back_cover_author_bio_text // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_ISBN_BARCODE=$(yq eval '.back_cover_isbn_barcode // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_TEXT_BACKGROUND=$(yq eval '.back_cover_text_background' "$temp_yaml" 2>/dev/null | sed 's/^null$/true/')
    META_BACK_COVER_TEXT_BACKGROUND_OPACITY=$(yq eval '.back_cover_text_background_opacity // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_BACK_COVER_TEXT_COLOR=$(yq eval '.back_cover_text_color // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')

    # Print-ready / Lulu settings
    META_TRIM_SIZE=$(yq eval '.trim_size // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_PAPER_STOCK=$(yq eval '.paper_stock // "cream60"' "$temp_yaml" 2>/dev/null | sed 's/^null$/cream60/')
    META_SPINE_TEXT=$(yq eval '.spine_text' "$temp_yaml" 2>/dev/null | sed 's/^null$/auto/')

    # Authorship & Support
    META_AUTHOR_PUBKEY=$(yq eval '.author_pubkey // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_AUTHOR_PUBKEY_TYPE=$(yq eval '.author_pubkey_type // "PGP"' "$temp_yaml" 2>/dev/null | sed 's/^null$/PGP/')

    # Parse donation_wallets list - build LaTeX-formatted string
    META_DONATION_WALLETS=""
    local wallet_count
    wallet_count=$(yq eval '.donation_wallets | length' "$temp_yaml" 2>/dev/null)
    if [ -n "$wallet_count" ] && [ "$wallet_count" != "0" ] && [ "$wallet_count" != "null" ]; then
        for i in $(seq 0 $((wallet_count - 1))); do
            local wallet_type wallet_address
            wallet_type=$(yq eval ".donation_wallets[$i].type" "$temp_yaml" 2>/dev/null | sed 's/^null$//')
            wallet_address=$(yq eval ".donation_wallets[$i].address" "$temp_yaml" 2>/dev/null | sed 's/^null$//')
            if [ -n "$wallet_type" ] && [ -n "$wallet_address" ]; then
                META_DONATION_WALLETS="${META_DONATION_WALLETS}${wallet_type}: {\\small\\texttt{${wallet_address}}}\\\\[0.3cm] "
            fi
        done
    fi

    # Clean up temporary file
    rm -f "$temp_yaml"

    # Display found metadata
    _display_metadata_found

    # Extract title from first H1 heading if not provided in metadata
    if [ -z "$META_TITLE" ]; then
        META_TITLE=$(grep -m 1 "^# " "$input_file" | sed 's/^# //')
        if [ -n "$META_TITLE" ]; then
            echo -e "${GREEN}Found title from H1 heading: $META_TITLE${NC}"
        fi
    fi
}

# Helper function to display found metadata
_display_metadata_found() {
    [ -n "$META_TITLE" ] && echo -e "${GREEN}Found metadata - title: $META_TITLE${NC}"
    [ -n "$META_AUTHOR" ] && echo -e "${GREEN}Found metadata - author: $META_AUTHOR${NC}"
    [ -n "$META_DATE" ] && echo -e "${GREEN}Found metadata - date: $META_DATE${NC}"
    [ -n "$META_DESCRIPTION" ] && echo -e "${GREEN}Found metadata - description: $META_DESCRIPTION${NC}"
    [ -n "$META_LANGUAGE" ] && echo -e "${GREEN}Found metadata - language: $META_LANGUAGE${NC}"
    [ -n "$META_SECTION" ] && echo -e "${GREEN}Found metadata - section: $META_SECTION${NC}"
    [ -n "$META_SLUG" ] && echo -e "${GREEN}Found metadata - slug: $META_SLUG${NC}"
    [ -n "$META_FORMAT" ] && echo -e "${GREEN}Found metadata - format: $META_FORMAT${NC}"
    [ -n "$META_TOC" ] && echo -e "${GREEN}Found metadata - toc: $META_TOC${NC}"
    [ -n "$META_TOC_DEPTH" ] && echo -e "${GREEN}Found metadata - toc_depth: $META_TOC_DEPTH${NC}"
    [ -n "$META_FOOTER" ] && echo -e "${GREEN}Found metadata - footer: $META_FOOTER${NC}"
    [ -n "$META_HEADER_FOOTER_POLICY" ] && echo -e "${GREEN}Found metadata - header_footer_policy: $META_HEADER_FOOTER_POLICY${NC}"
    [ -n "$META_NO_NUMBERS" ] && echo -e "${GREEN}Found metadata - section_numbers: false${NC}"
    [ -n "$META_NO_FOOTER" ] && echo -e "${GREEN}Found metadata - no_footer: true${NC}"
    [ -n "$META_PAGEOF" ] && echo -e "${GREEN}Found metadata - pageof: true${NC}"
    [ -n "$META_DATE_FOOTER" ] && echo -e "${GREEN}Found metadata - date_footer: true${NC}"
    [ -n "$META_NO_DATE" ] && echo -e "${GREEN}Found metadata - no_date: true${NC}"
    [ -n "$META_INDEX" ] && echo -e "${GREEN}Found metadata - index: true${NC}"
    [ -n "$META_GENRE" ] && echo -e "${GREEN}Found metadata - genre: $META_GENRE${NC}"
    [ -n "$META_NARRATOR_VOICE" ] && echo -e "${GREEN}Found metadata - narrator_voice: $META_NARRATOR_VOICE${NC}"
    [ -n "$META_READING_SPEED" ] && echo -e "${GREEN}Found metadata - reading_speed: $META_READING_SPEED${NC}"

    # Professional book features
    [ -n "$META_NO_TITLE_PAGE" ] && echo -e "${GREEN}Found metadata - no_title_page: $META_NO_TITLE_PAGE${NC}"
    [ -n "$META_HALF_TITLE" ] && echo -e "${GREEN}Found metadata - half_title: $META_HALF_TITLE${NC}"
    [ -n "$META_COPYRIGHT_PAGE" ] && echo -e "${GREEN}Found metadata - copyright_page: $META_COPYRIGHT_PAGE${NC}"
    [ -n "$META_DEDICATION" ] && echo -e "${GREEN}Found metadata - dedication: $META_DEDICATION${NC}"
    [ -n "$META_EPIGRAPH" ] && echo -e "${GREEN}Found metadata - epigraph: $META_EPIGRAPH${NC}"
    [ -n "$META_EPIGRAPH_SOURCE" ] && echo -e "${GREEN}Found metadata - epigraph_source: $META_EPIGRAPH_SOURCE${NC}"
    [ -n "$META_CHAPTERS_ON_RECTO" ] && echo -e "${GREEN}Found metadata - chapters_on_recto: $META_CHAPTERS_ON_RECTO${NC}"
    [ -n "$META_DROP_CAPS" ] && echo -e "${GREEN}Found metadata - drop_caps: $META_DROP_CAPS${NC}"
    [ -n "$META_EQUATION_NUMBERS" ] && echo -e "${GREEN}Found metadata - equation_numbers: $META_EQUATION_NUMBERS${NC}"
    [ -n "$META_PUBLISHER" ] && echo -e "${GREEN}Found metadata - publisher: $META_PUBLISHER${NC}"
    [ -n "$META_ISBN" ] && echo -e "${GREEN}Found metadata - isbn: $META_ISBN${NC}"
    [ -n "$META_EDITION" ] && echo -e "${GREEN}Found metadata - edition: $META_EDITION${NC}"
    [ -n "$META_COPYRIGHT_YEAR" ] && echo -e "${GREEN}Found metadata - copyright_year: $META_COPYRIGHT_YEAR${NC}"
    [ -n "$META_COPYRIGHT_HOLDER" ] && echo -e "${GREEN}Found metadata - copyright_holder: $META_COPYRIGHT_HOLDER${NC}"
    [ -n "$META_EDITION_DATE" ] && echo -e "${GREEN}Found metadata - edition_date: $META_EDITION_DATE${NC}"
    [ -n "$META_PRINTING" ] && echo -e "${GREEN}Found metadata - printing: $META_PRINTING${NC}"
    [ -n "$META_PUBLISHER_ADDRESS" ] && echo -e "${GREEN}Found metadata - publisher_address: $META_PUBLISHER_ADDRESS${NC}"
    [ -n "$META_PUBLISHER_WEBSITE" ] && echo -e "${GREEN}Found metadata - publisher_website: $META_PUBLISHER_WEBSITE${NC}"

    # Cover system
    [ -n "$META_COVER_IMAGE" ] && echo -e "${GREEN}Found metadata - cover_image: $META_COVER_IMAGE${NC}"
    [ -n "$META_COVER_OVERLAY_OPACITY" ] && echo -e "${GREEN}Found metadata - cover_overlay_opacity: $META_COVER_OVERLAY_OPACITY${NC}"
    [ -n "$META_BACK_COVER_IMAGE" ] && echo -e "${GREEN}Found metadata - back_cover_image: $META_BACK_COVER_IMAGE${NC}"
    [ -n "$META_BACK_COVER_CONTENT" ] && echo -e "${GREEN}Found metadata - back_cover_content: $META_BACK_COVER_CONTENT${NC}"

    # Authorship & support
    [ -n "$META_AUTHOR_PUBKEY" ] && echo -e "${GREEN}Found metadata - author_pubkey: [set]${NC}"
    [ -n "$META_DONATION_WALLETS" ] && echo -e "${GREEN}Found metadata - donation_wallets: [set]${NC}"
}

# =============================================================================
# Apply Metadata to Arguments
# =============================================================================

# Apply parsed metadata to command-line arguments (CLI takes precedence)
apply_metadata_args() {
    local read_metadata="$1"

    if [ "$read_metadata" = true ]; then
        echo -e "${BLUE}Applying metadata to arguments (CLI args take precedence)...${NC}"

        # Apply metadata values only if command-line arguments weren't provided
        [ -z "$ARG_TITLE" ] && [ -n "$META_TITLE" ] && ARG_TITLE="$META_TITLE"
        [ -z "$ARG_AUTHOR" ] && [ -n "$META_AUTHOR" ] && ARG_AUTHOR="$META_AUTHOR"
        [ -z "$ARG_DATE" ] && [ -n "$META_DATE" ] && ARG_DATE="$META_DATE"
        [ -z "$ARG_FOOTER" ] && [ -n "$META_FOOTER" ] && ARG_FOOTER="$META_FOOTER"
        [ -z "$ARG_DATE_FOOTER" ] && [ -n "$META_DATE_FOOTER" ] && ARG_DATE_FOOTER="$META_DATE_FOOTER"
        [ -z "$ARG_FORMAT" ] && [ -n "$META_FORMAT" ] && ARG_FORMAT="$META_FORMAT"

        # Apply header/footer policy only if not explicitly set via CLI
        if [ "$ARG_HEADER_FOOTER_POLICY" = "default" ] && [ -n "$META_HEADER_FOOTER_POLICY" ]; then
            ARG_HEADER_FOOTER_POLICY="$META_HEADER_FOOTER_POLICY"
        fi

        # Apply bibliography and CSL
        [ -z "$ARG_BIBLIOGRAPHY" ] && [ -n "$META_BIBLIOGRAPHY" ] && ARG_BIBLIOGRAPHY="$META_BIBLIOGRAPHY"
        [ -z "$ARG_CSL" ] && [ -n "$META_CSL" ] && ARG_CSL="$META_CSL"

        # Handle boolean flags - only apply if not explicitly set via CLI
        if [ "$ARG_TOC" = "$DEFAULT_TOC" ] && [ -n "$META_TOC" ]; then
            case "$META_TOC" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1") ARG_TOC=true ;;
                "false"|"False"|"FALSE"|"no"|"No"|"NO"|"0") ARG_TOC=false ;;
            esac
        fi

        if [ "$ARG_TOC_DEPTH" = "$DEFAULT_TOC_DEPTH" ] && [ -n "$META_TOC_DEPTH" ]; then
            ARG_TOC_DEPTH="$META_TOC_DEPTH"
        fi

        if [ "$ARG_INDEX" = false ] && [ -n "$META_INDEX" ]; then
            case "$META_INDEX" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1") ARG_INDEX=true ;;
            esac
        fi

        if [ "$ARG_SECTION_NUMBERS" = "$DEFAULT_SECTION_NUMBERS" ] && [ -n "$META_NO_NUMBERS" ]; then
            case "$META_NO_NUMBERS" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1") ARG_SECTION_NUMBERS=false ;;
                "false"|"False"|"FALSE"|"no"|"No"|"NO"|"0") ARG_SECTION_NUMBERS=true ;;
            esac
        fi

        if [ "$ARG_NO_FOOTER" = false ] && [ -n "$META_NO_FOOTER" ]; then
            case "$META_NO_FOOTER" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1") ARG_NO_FOOTER=true ;;
            esac
        fi

        if [ "$ARG_PAGE_OF" = false ] && [ -n "$META_PAGEOF" ]; then
            case "$META_PAGEOF" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1") ARG_PAGE_OF=true ;;
            esac
        fi

        if [ "$ARG_NO_DATE" = false ] && [ -n "$META_NO_DATE" ]; then
            case "$META_NO_DATE" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1") ARG_NO_DATE=true ;;
            esac
        fi

        echo -e "${GREEN}Metadata applied successfully${NC}"
    fi
}
