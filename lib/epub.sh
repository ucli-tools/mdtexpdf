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
