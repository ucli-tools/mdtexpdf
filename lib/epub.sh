#!/bin/bash
# =============================================================================
# mdtexpdf EPUB Module
# EPUB generation and post-processing
# =============================================================================

# Source core if not already loaded
if [ -z "$MDTEXPDF_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=core.sh
    source "$SCRIPT_DIR/core.sh"
fi

# =============================================================================
# EPUB Spine Reordering
# =============================================================================

# Fix EPUB spine order (move TOC after front matter)
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

    # Check if nav is in the spine
    if ! grep -q '<itemref idref="nav"' "$content_opf"; then
        echo -e "${BLUE}No nav item in spine, nothing to reorder${NC}"
        rm -rf "$temp_dir"
        return 0
    fi

    # Create a modified content.opf
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
        # If nav was never inserted (fm_count > total chapters), it stays where it was
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

# =============================================================================
# EPUB Front Matter Generation
# =============================================================================

# Generate EPUB front matter markdown content
# Returns the markdown string to be inserted after YAML frontmatter
generate_epub_frontmatter() {
    local epub_title="$1"
    local epub_subtitle="$2"
    local epub_author="$3"
    local epub_date="$4"

    local frontmatter_md=""
    local has_frontmatter=false

    # 0. Custom title page (simpler than pandoc's default - no publisher)
    if [ -n "$epub_title" ]; then
        has_frontmatter=true
        frontmatter_md="$frontmatter_md\n\n# ​ {.unnumbered .unlisted .title-page}\n\n"
        frontmatter_md="$frontmatter_md::: {.titlepage}\n"
        frontmatter_md="$frontmatter_md## $epub_title {.unnumbered .unlisted}\n\n"
        [ -n "$epub_subtitle" ] && frontmatter_md="$frontmatter_md*$epub_subtitle*\n\n"
        [ -n "$epub_author" ] && frontmatter_md="$frontmatter_md$epub_author\n\n"
        [ -n "$epub_date" ] && frontmatter_md="$frontmatter_md$epub_date\n"
        frontmatter_md="$frontmatter_md:::\n"
    fi

    # 1. Copyright page (if META_COPYRIGHT_PAGE is set)
    if [ "$META_COPYRIGHT_PAGE" = "true" ] || [ "$META_COPYRIGHT_PAGE" = "True" ] || [ "$META_COPYRIGHT_PAGE" = "TRUE" ]; then
        has_frontmatter=true
        local copyright_year="${META_COPYRIGHT_YEAR:-$(date +%Y)}"
        local copyright_holder="${META_COPYRIGHT_HOLDER:-${META_PUBLISHER:-$epub_author}}"

        frontmatter_md="$frontmatter_md\n\n# ​ {.unnumbered .unlisted .copyright-page}\n\n"
        frontmatter_md="$frontmatter_md::: {.copyright}\n"
        frontmatter_md="$frontmatter_md**$epub_title**\n\n"
        [ -n "$epub_subtitle" ] && frontmatter_md="$frontmatter_md*$epub_subtitle*\n\n"
        frontmatter_md="$frontmatter_md by $epub_author\n\n"
        frontmatter_md="$frontmatter_md---\n\n"
        frontmatter_md="$frontmatter_md Copyright © $copyright_year $copyright_holder\n\n"
        frontmatter_md="$frontmatter_md All rights reserved.\n\n"
        [ -n "$META_PUBLISHER" ] && frontmatter_md="$frontmatter_md Published by $META_PUBLISHER\n\n"
        [ -n "$META_EDITION" ] && [ -n "$META_EDITION_DATE" ] && frontmatter_md="$frontmatter_md $META_EDITION — $META_EDITION_DATE\n\n"
        [ -n "$META_PRINTING" ] && frontmatter_md="$frontmatter_md $META_PRINTING\n\n"
        frontmatter_md="$frontmatter_md:::\n"
    fi

    # 2. Authorship & Support page (if META_AUTHOR_PUBKEY is set)
    if [ -n "$META_AUTHOR_PUBKEY" ]; then
        has_frontmatter=true
        frontmatter_md="$frontmatter_md\n\n# Authorship & Support {.unnumbered .unlisted}\n\n**Authorship Verification**\n\n${META_AUTHOR_PUBKEY_TYPE:-PGP}: \`$META_AUTHOR_PUBKEY\`\n"
    fi

    # 3. Dedication (own page)
    if [ -n "$META_DEDICATION" ]; then
        has_frontmatter=true
        frontmatter_md="$frontmatter_md\n\n# ​ {.unnumbered .unlisted .dedication-page}\n\n::: {.dedication}\n*$META_DEDICATION*\n:::\n"
    fi

    # 4. Epigraph (own page)
    if [ -n "$META_EPIGRAPH" ]; then
        has_frontmatter=true
        frontmatter_md="$frontmatter_md\n\n# ​ {.unnumbered .unlisted .epigraph-page}\n\n::: {.epigraph}\n> $META_EPIGRAPH"
        if [ -n "$META_EPIGRAPH_SOURCE" ]; then
            frontmatter_md="$frontmatter_md\n>\n> — $META_EPIGRAPH_SOURCE"
        fi
        frontmatter_md="$frontmatter_md\n:::\n"
    fi

    if [ "$has_frontmatter" = true ]; then
        echo -e "$frontmatter_md"
    fi
}

# =============================================================================
# EPUB Chemistry Preprocessing
# =============================================================================

# Convert LaTeX chemistry notation to Unicode for EPUB readability
preprocess_epub_chemistry() {
    local input_file="$1"

    # Common chemistry conversions
    sed -i 's/\\ce{H2O}/H₂O/g' "$input_file"
    sed -i 's/\\ce{CO2}/CO₂/g' "$input_file"
    sed -i 's/\\ce{O2}/O₂/g' "$input_file"
    sed -i 's/\\ce{H2}/H₂/g' "$input_file"
    sed -i 's/\\ce{N2}/N₂/g' "$input_file"
    sed -i 's/\\ce{H+}/H⁺/g' "$input_file"
    sed -i 's/\\ce{OH-}/OH⁻/g' "$input_file"
    sed -i 's/\\ce{O2-}/O₂⁻/g' "$input_file"
    sed -i 's/\\ce{CO3-}/CO₃⁻/g' "$input_file"
    sed -i 's/\\ce{H3O+}/H₃O⁺/g' "$input_file"
    sed -i 's/\\ce{CH3COOH}/CH₃COOH/g' "$input_file"
    sed -i 's/\\ce{CH3COO-}/CH₃COO⁻/g' "$input_file"
    sed -i 's/\\ce{Ca(OH)2}/Ca(OH)₂/g' "$input_file"
    sed -i 's/\\ce{CaCO3}/CaCO₃/g' "$input_file"
    sed -i 's/\\ce{Al2O3}/Al₂O₃/g' "$input_file"
    sed -i 's/\\ce{AgI}/AgI/g' "$input_file"

    # Generic \ce{} removal (fallback)
    sed -i 's/\\ce{\([^}]*\)}/\1/g' "$input_file"

    # Arrow conversions
    sed -i 's/→/→/g' "$input_file"
    sed -i 's/⇌/⇌/g' "$input_file"
    sed -i 's/->/→/g' "$input_file"
    sed -i 's/<=>/⇌/g' "$input_file"
}

# =============================================================================
# EPUB Validation (if epubcheck is available)
# =============================================================================

# Validate EPUB file using epubcheck
validate_epub() {
    local epub_file="$1"

    if ! command -v epubcheck &> /dev/null; then
        echo -e "${YELLOW}epubcheck not installed, skipping validation${NC}"
        return 0
    fi

    echo -e "${BLUE}Validating EPUB with epubcheck...${NC}"

    local result
    result=$(epubcheck "$epub_file" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}EPUB validation passed${NC}"
        return 0
    else
        echo -e "${YELLOW}EPUB validation warnings/errors:${NC}"
        echo "$result" | grep -E "(ERROR|WARNING)" | head -20
        return 1
    fi
}

# =============================================================================
# Main EPUB Generation Function
# =============================================================================

# Generate EPUB output
# Uses global variables: INPUT_FILE, OUTPUT_FILE, ARG_*, META_*, BACKUP_FILE, COMBINED_FILE
# Returns: 0 on success, 1 on failure
generate_epub() {
    echo -e "${YELLOW}Converting $INPUT_FILE to EPUB...${NC}"

    # Build EPUB options
    EPUB_OPTS=""

    # Table of contents
    if [ "$ARG_TOC" = true ] || [ "$META_TOC" = "true" ]; then
        EPUB_OPTS="$EPUB_OPTS --toc"
        local toc_depth="${ARG_TOC_DEPTH:-${META_TOC_DEPTH:-2}}"
        EPUB_OPTS="$EPUB_OPTS --toc-depth=$toc_depth"
        EPUB_OPTS="$EPUB_OPTS --metadata toc-title=\"Contents\""
    fi

    # Metadata
    local epub_title="${ARG_TITLE:-$META_TITLE}"
    local epub_author="${ARG_AUTHOR:-$META_AUTHOR}"
    local epub_date="${ARG_DATE:-$META_DATE}"
    local epub_description="$META_DESCRIPTION"
    local epub_language="${META_LANGUAGE:-en}"

    # Cover image - find base image first
    local epub_cover_base=""
    if [ -n "$META_COVER_IMAGE" ] && [ -f "$META_COVER_IMAGE" ]; then
        epub_cover_base="$META_COVER_IMAGE"
    else
        # Try to auto-detect cover image
        local input_dir
        input_dir=$(dirname "$INPUT_FILE")
        for ext in jpg jpeg png; do
            for dir in "$input_dir/img" "$input_dir/images" "$input_dir"; do
                if [ -f "$dir/cover.$ext" ]; then
                    epub_cover_base="$dir/cover.$ext"
                    break 2
                fi
            done
        done
    fi

    # Generate cover with text overlay using ImageMagick (matching PDF style)
    local epub_cover=""
    local epub_cover_generated=""
    if [ -n "$epub_cover_base" ] && command -v convert &> /dev/null; then
        # Make paths absolute
        local input_dir
        input_dir=$(dirname "$INPUT_FILE")
        if [[ ! "$epub_cover_base" = /* ]]; then
            epub_cover_base="$input_dir/$epub_cover_base"
        fi
        epub_cover_generated="${INPUT_FILE%.md}_epub_cover.png"
        local cover_title="${ARG_TITLE:-$META_TITLE}"
        local cover_subtitle="${META_SUBTITLE:-}"
        local cover_author="${ARG_AUTHOR:-$META_AUTHOR}"
        local cover_overlay="${META_COVER_OVERLAY_OPACITY:-0.3}"
        local cover_title_color="${META_COVER_TITLE_COLOR:-white}"

        echo -e "${YELLOW}Generating EPUB cover with text overlay...${NC}"

        # Get image dimensions
        local img_width img_height
        img_width=$(identify -format "%w" "$epub_cover_base" 2>/dev/null)
        img_height=$(identify -format "%h" "$epub_cover_base" 2>/dev/null)

        # Calculate font sizes relative to image height
        local title_size=$((img_height / 12))
        local subtitle_size=$((img_height / 32))
        local author_size=$((img_height / 20))
        local text_width=$((img_width * 85 / 100))

        # Build cover using composite approach with text wrapping
        local temp_base temp_title temp_subtitle temp_author
        temp_base=$(mktemp --suffix=.png)
        /usr/bin/convert "$epub_cover_base" \
            -fill "rgba(0,0,0,$cover_overlay)" -draw "rectangle 0,0,$img_width,$img_height" \
            "$temp_base"

        temp_title=$(mktemp --suffix=.png)
        /usr/bin/convert -background none -fill "$cover_title_color" \
            -font LMRoman10-Bold -pointsize $title_size \
            -size ${text_width}x -gravity Center caption:"$cover_title" \
            "$temp_title" 2>/dev/null || \
        /usr/bin/convert -background none -fill "$cover_title_color" \
            -font DejaVu-Serif-Bold -pointsize $title_size \
            -size ${text_width}x -gravity Center caption:"$cover_title" \
            "$temp_title"

        local title_actual_height
        title_actual_height=$(identify -format "%h" "$temp_title" 2>/dev/null)

        temp_subtitle=""
        local subtitle_width=$((img_width * 80 / 100))
        if [ -n "$cover_subtitle" ]; then
            temp_subtitle=$(mktemp --suffix=.png)
            /usr/bin/convert -background none -fill "$cover_title_color" \
                -font LMRoman10-Italic -pointsize $subtitle_size \
                -size ${subtitle_width}x -gravity Center caption:"$cover_subtitle" \
                "$temp_subtitle" 2>/dev/null || \
            /usr/bin/convert -background none -fill "$cover_title_color" \
                -font DejaVu-Serif-Italic -pointsize $subtitle_size \
                -size ${subtitle_width}x -gravity Center caption:"$cover_subtitle" \
                "$temp_subtitle"
        fi

        temp_author=$(mktemp --suffix=.png)
        /usr/bin/convert -background none -fill "$cover_title_color" \
            -font LMRoman10-Regular -pointsize $author_size \
            -size ${text_width}x -gravity Center caption:"$cover_author" \
            "$temp_author" 2>/dev/null || \
        /usr/bin/convert -background none -fill "$cover_title_color" \
            -font DejaVu-Serif -pointsize $author_size \
            -size ${text_width}x -gravity Center caption:"$cover_author" \
            "$temp_author"

        local title_y=$((img_height / 8))
        /usr/bin/convert "$temp_base" \
            "$temp_title" -gravity North -geometry +0+${title_y} -composite \
            "$temp_author" -gravity South -geometry +0+$((img_height / 10)) -composite \
            "$epub_cover_generated"

        if [ -n "$temp_subtitle" ]; then
            local title_subtitle_gap=$((img_height / 40))
            local subtitle_y=$((title_y + title_actual_height + title_subtitle_gap))
            /usr/bin/convert "$epub_cover_generated" \
                "$temp_subtitle" -gravity North -geometry +0+${subtitle_y} -composite \
                "$epub_cover_generated"
        fi

        rm -f "$temp_base" "$temp_title" "$temp_subtitle" "$temp_author"

        if [ -f "$epub_cover_generated" ]; then
            epub_cover="$epub_cover_generated"
            echo -e "${GREEN}Cover generated: $epub_cover_generated${NC}"
        else
            epub_cover="$epub_cover_base"
            echo -e "${YELLOW}Cover generation failed, using base image${NC}"
        fi
    elif [ -n "$epub_cover_base" ]; then
        epub_cover="$epub_cover_base"
    fi

    # Create temporary file for EPUB preprocessing
    local epub_temp_input="${INPUT_FILE%.md}_epub_temp.md"
    cp "$INPUT_FILE" "$epub_temp_input"

    # Preprocess chemistry notation
    preprocess_epub_chemistry "$epub_temp_input"

    # Generate front matter and insert into temp file
    local epub_frontmatter_md=""
    local has_frontmatter=false

    # Title page
    if [ -n "$epub_title" ]; then
        has_frontmatter=true
        epub_frontmatter_md="$epub_frontmatter_md\n\n# ​ {.unnumbered .unlisted .title-page}\n\n"
        epub_frontmatter_md="$epub_frontmatter_md::: {.titlepage}\n"
        epub_frontmatter_md="$epub_frontmatter_md## $epub_title {.unnumbered .unlisted}\n\n"
        [ -n "${META_SUBTITLE:-}" ] && epub_frontmatter_md="$epub_frontmatter_md*${META_SUBTITLE}*\n\n"
        [ -n "$epub_author" ] && epub_frontmatter_md="$epub_frontmatter_md$epub_author\n\n"
        [ -n "$epub_date" ] && epub_frontmatter_md="$epub_frontmatter_md$epub_date\n"
        epub_frontmatter_md="$epub_frontmatter_md:::\n"
    fi

    # Copyright page
    if [ "$META_COPYRIGHT_PAGE" = "true" ] || [ "$META_COPYRIGHT_PAGE" = "True" ] || [ "$META_COPYRIGHT_PAGE" = "TRUE" ]; then
        has_frontmatter=true
        local epub_copyright_year="${META_COPYRIGHT_YEAR:-$(date +%Y)}"
        local epub_copyright_holder="${META_COPYRIGHT_HOLDER:-${META_PUBLISHER:-$epub_author}}"

        epub_frontmatter_md="$epub_frontmatter_md\n\n# ​ {.unnumbered .unlisted .copyright-page}\n\n"
        epub_frontmatter_md="$epub_frontmatter_md::: {.copyright}\n"
        epub_frontmatter_md="$epub_frontmatter_md**$epub_title**\n\n"
        [ -n "${META_SUBTITLE:-}" ] && epub_frontmatter_md="$epub_frontmatter_md*${META_SUBTITLE}*\n\n"
        epub_frontmatter_md="$epub_frontmatter_md by $epub_author\n\n"
        epub_frontmatter_md="$epub_frontmatter_md---\n\n"
        epub_frontmatter_md="$epub_frontmatter_md Copyright © $epub_copyright_year $epub_copyright_holder\n\n"
        epub_frontmatter_md="$epub_frontmatter_md All rights reserved.\n\n"
        [ -n "$META_PUBLISHER" ] && epub_frontmatter_md="$epub_frontmatter_md Published by $META_PUBLISHER\n\n"
        [ -n "$META_EDITION" ] && [ -n "$META_EDITION_DATE" ] && epub_frontmatter_md="$epub_frontmatter_md $META_EDITION — $META_EDITION_DATE\n\n"
        [ -n "$META_PRINTING" ] && epub_frontmatter_md="$epub_frontmatter_md $META_PRINTING\n\n"
        epub_frontmatter_md="$epub_frontmatter_md:::\n"
    fi

    # Authorship & Support
    if [ -n "$META_AUTHOR_PUBKEY" ]; then
        has_frontmatter=true
        epub_frontmatter_md="$epub_frontmatter_md\n\n# Authorship & Support {.unnumbered .unlisted}\n\n**Authorship Verification**\n\n${META_AUTHOR_PUBKEY_TYPE:-PGP}: \`$META_AUTHOR_PUBKEY\`\n"

        # Re-parse donation wallets from YAML
        local temp_yaml
        temp_yaml=$(mktemp)
        sed -n '/^---$/,/^---$/p' "$INPUT_FILE" | tail -n +2 | head -n -1 > "$temp_yaml"
        local wallet_count
        wallet_count=$(yq eval '.donation_wallets | length' "$temp_yaml" 2>/dev/null)
        if [ -n "$wallet_count" ] && [ "$wallet_count" != "0" ] && [ "$wallet_count" != "null" ]; then
            epub_frontmatter_md="$epub_frontmatter_md\n**Support the Author**\n\n"
            for i in $(seq 0 $((wallet_count - 1))); do
                local wallet_type wallet_address
                wallet_type=$(yq eval ".donation_wallets[$i].type" "$temp_yaml" 2>/dev/null | sed 's/^null$//')
                wallet_address=$(yq eval ".donation_wallets[$i].address" "$temp_yaml" 2>/dev/null | sed 's/^null$//')
                if [ -n "$wallet_type" ] && [ -n "$wallet_address" ]; then
                    epub_frontmatter_md="$epub_frontmatter_md${wallet_type}: \`${wallet_address}\`\n\n"
                fi
            done
        fi
        rm -f "$temp_yaml"
    fi

    # Dedication
    if [ -n "$META_DEDICATION" ]; then
        has_frontmatter=true
        epub_frontmatter_md="$epub_frontmatter_md\n\n# ​ {.unnumbered .unlisted .dedication-page}\n\n::: {.dedication}\n*$META_DEDICATION*\n:::\n"
    fi

    # Epigraph
    if [ -n "$META_EPIGRAPH" ]; then
        has_frontmatter=true
        epub_frontmatter_md="$epub_frontmatter_md\n\n# ​ {.unnumbered .unlisted .epigraph-page}\n\n::: {.epigraph}\n> $META_EPIGRAPH"
        if [ -n "$META_EPIGRAPH_SOURCE" ]; then
            epub_frontmatter_md="$epub_frontmatter_md\n>\n> — $META_EPIGRAPH_SOURCE"
        fi
        epub_frontmatter_md="$epub_frontmatter_md\n:::\n"
    fi

    # Insert front matter into temp file
    if [ "$has_frontmatter" = true ] && [ -n "$epub_frontmatter_md" ]; then
        local yaml_end_line
        yaml_end_line=$(awk '/^---$/{n++; if(n==2) {print NR; exit}}' "$epub_temp_input")
        if [ -n "$yaml_end_line" ]; then
            local temp_with_frontmatter
            temp_with_frontmatter=$(mktemp)
            head -n "$yaml_end_line" "$epub_temp_input" > "$temp_with_frontmatter"
            echo -e "$epub_frontmatter_md" >> "$temp_with_frontmatter"
            tail -n +$((yaml_end_line + 1)) "$epub_temp_input" >> "$temp_with_frontmatter"
            mv "$temp_with_frontmatter" "$epub_temp_input"
        fi
    fi

    # Build pandoc command
    EPUB_CMD="pandoc \"$epub_temp_input\" --from markdown --to epub3 --output \"$OUTPUT_FILE\" --epub-title-page=false --mathml"

    [ -n "$epub_title" ] && EPUB_CMD="$EPUB_CMD --metadata title=\"$epub_title\""
    [ -n "$epub_author" ] && EPUB_CMD="$EPUB_CMD --metadata author=\"$epub_author\""
    [ -n "$epub_date" ] && EPUB_CMD="$EPUB_CMD --metadata date=\"$epub_date\""
    [ -n "$epub_description" ] && EPUB_CMD="$EPUB_CMD --metadata description=\"$epub_description\""
    [ -n "$epub_language" ] && EPUB_CMD="$EPUB_CMD --metadata lang=\"$epub_language\""
    [ -n "$epub_cover" ] && EPUB_CMD="$EPUB_CMD --epub-cover-image=\"$epub_cover\""

    # Handle bibliography
    local epub_bib_temp_dir="" epub_bib_path="" epub_using_inline_bib=false

    if [ -z "$ARG_BIBLIOGRAPHY" ] && type has_inline_bibliography &>/dev/null; then
        if has_inline_bibliography "$epub_temp_input"; then
            echo -e "${BLUE}Detected inline bibliography in document${NC}"
            epub_bib_temp_dir=$(mktemp -d)
            if epub_bib_path=$(process_inline_bibliography "$epub_temp_input" "$epub_bib_temp_dir"); then
                cp "$epub_bib_temp_dir/content.md" "$epub_temp_input"
                epub_using_inline_bib=true
                EPUB_CMD="$EPUB_CMD --citeproc --bibliography=\"$epub_bib_path\""
                echo -e "${GREEN}Using inline bibliography${NC}"
            else
                echo -e "${YELLOW}Warning: Could not process inline bibliography${NC}"
                rm -rf "$epub_bib_temp_dir"
                epub_bib_temp_dir=""
            fi
        fi
    fi

    if [ -n "$ARG_BIBLIOGRAPHY" ] && [ "$epub_using_inline_bib" = false ]; then
        local external_bib_path=""
        if [ -f "$ARG_BIBLIOGRAPHY" ]; then
            external_bib_path=$(realpath "$ARG_BIBLIOGRAPHY")
        else
            local input_dir
            input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$input_dir/$ARG_BIBLIOGRAPHY" ]; then
                external_bib_path=$(realpath "$input_dir/$ARG_BIBLIOGRAPHY")
            fi
        fi

        if [ -n "$external_bib_path" ]; then
            if type is_simple_bibliography &>/dev/null && is_simple_bibliography "$external_bib_path"; then
                echo -e "${BLUE}Converting simple markdown bibliography...${NC}"
                [ -z "$epub_bib_temp_dir" ] && epub_bib_temp_dir=$(mktemp -d)
                if epub_bib_path=$(process_bibliography_file "$external_bib_path" "$epub_bib_temp_dir"); then
                    EPUB_CMD="$EPUB_CMD --citeproc --bibliography=\"$epub_bib_path\""
                    echo -e "${GREEN}Using simple bibliography: $external_bib_path${NC}"
                else
                    echo -e "${YELLOW}Warning: Could not convert simple bibliography${NC}"
                fi
            else
                EPUB_CMD="$EPUB_CMD --citeproc --bibliography=\"$external_bib_path\""
                echo -e "${GREEN}Using bibliography: $external_bib_path${NC}"
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
            EPUB_CMD="$EPUB_CMD --csl=\"$csl_path\""
            echo -e "${GREEN}Using citation style: $csl_path${NC}"
        else
            echo -e "${YELLOW}Warning: CSL file '$ARG_CSL' not found${NC}"
        fi
    fi

    # Custom EPUB CSS
    if [ -n "$ARG_EPUB_CSS" ]; then
        local css_path=""
        if [ -f "$ARG_EPUB_CSS" ]; then
            css_path=$(realpath "$ARG_EPUB_CSS")
        else
            local input_dir
            input_dir=$(dirname "$INPUT_FILE")
            if [ -f "$input_dir/$ARG_EPUB_CSS" ]; then
                css_path=$(realpath "$input_dir/$ARG_EPUB_CSS")
            fi
        fi
        if [ -n "$css_path" ]; then
            EPUB_CMD="$EPUB_CMD --css=\"$css_path\""
            echo -e "${GREEN}Using custom EPUB CSS: $css_path${NC}"
        else
            echo -e "${YELLOW}Warning: EPUB CSS file '$ARG_EPUB_CSS' not found${NC}"
        fi
    fi

    EPUB_CMD="$EPUB_CMD $EPUB_OPTS --standalone"

    # Execute pandoc
    echo -e "${BLUE}Running: $EPUB_CMD${NC}"
    eval "$EPUB_CMD"
    local epub_result=$?

    # Cleanup temp files
    rm -f "$epub_temp_input"
    [ -n "$epub_cover_generated" ] && rm -f "$epub_cover_generated"
    [ -n "$epub_bib_temp_dir" ] && [ -d "$epub_bib_temp_dir" ] && rm -rf "$epub_bib_temp_dir"

    if [ $epub_result -eq 0 ]; then
        echo -e "${GREEN}Success! EPUB created as $OUTPUT_FILE${NC}"

        # Fix spine order
        fix_epub_spine_order "$OUTPUT_FILE"

        # Validate if requested
        if [ "$ARG_VALIDATE" = true ]; then
            validate_epub "$OUTPUT_FILE"
        fi

        # Restore backup
        if [ -f "$BACKUP_FILE" ]; then
            mv "$BACKUP_FILE" "$INPUT_FILE"
        fi

        # Clean up combined file
        if [ -n "$COMBINED_FILE" ] && [ -f "$COMBINED_FILE" ]; then
            rm -f "$COMBINED_FILE"
        fi
        return 0
    else
        echo -e "${RED}Error: EPUB conversion failed.${NC}"
        if [ -f "$BACKUP_FILE" ]; then
            mv "$BACKUP_FILE" "$INPUT_FILE"
        fi
        if [ -n "$COMBINED_FILE" ] && [ -f "$COMBINED_FILE" ]; then
            rm -f "$COMBINED_FILE"
        fi
        return 1
    fi
}
