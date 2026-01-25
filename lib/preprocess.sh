#!/bin/bash
# =============================================================================
# mdtexpdf Preprocess Module
# Markdown preprocessing and Unicode detection
# =============================================================================

# Source core if not already loaded
if [ -z "$MDTEXPDF_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=core.sh
    source "$SCRIPT_DIR/core.sh"
fi

# =============================================================================
# Unicode Detection
# =============================================================================

# Detect Unicode characters that require Unicode engines (XeLaTeX/LuaLaTeX)
# Returns 0 if special characters found, 1 if not
detect_unicode_characters() {
    local input_file="$1"

    # Check for CJK characters (Chinese, Japanese, Korean)
    # CJK Unified Ideographs: U+4E00-U+9FFF
    # CJK Extension A: U+3400-U+4DBF
    # CJK Extension B: U+20000-U+2A6DF
    # CJK Extension C: U+2A700-U+2B73F
    # CJK Extension D: U+2B740-U+2B81F
    # CJK Extension E: U+2B820-U+2CEAF
    if grep -qP '[\x{4E00}-\x{9FFF}\x{3400}-\x{4DBF}\x{20000}-\x{2A6DF}\x{2A700}-\x{2B73F}\x{2B740}-\x{2B81F}\x{2B820}-\x{2CEAF}]' "$input_file" 2>/dev/null; then
        return 0  # Found CJK characters
    fi

    # Check for other Unicode characters that might not be supported by pdfLaTeX
    # Arabic: U+0600-U+06FF
    # Hebrew: U+0590-U+05FF
    # Devanagari: U+0900-U+097F
    # And other scripts that pdfLaTeX typically doesn't support well
    if grep -qP '[\x{0600}-\x{06FF}\x{0590}-\x{05FF}\x{0900}-\x{097F}\x{0980}-\x{09FF}\x{0A00}-\x{0A7F}\x{0A80}-\x{0AFF}\x{0B00}-\x{0B7F}\x{0B80}-\x{0BFF}\x{0C00}-\x{0C7F}\x{0C80}-\x{0CFF}\x{0D00}-\x{0D7F}\x{0D80}-\x{0DFF}]' "$input_file" 2>/dev/null; then
        return 0  # Found other complex script characters
    fi

    # Check for typographic characters that cause issues with pdfLaTeX in code blocks
    # Em-dash: U+2014, En-dash: U+2013
    # Smart quotes: U+2018, U+2019, U+201C, U+201D
    # Vulgar fractions: U+00BC-U+00BE (¼½¾), U+2150-U+215F (⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞)
    # Ellipsis: U+2026
    if grep -qP '[\x{2013}-\x{2014}\x{2018}-\x{201D}\x{2026}\x{00BC}-\x{00BE}\x{2150}-\x{215F}]' "$input_file" 2>/dev/null; then
        return 0  # Found typographic characters
    fi

    return 1  # No Unicode characters requiring special handling found
}

# =============================================================================
# Markdown Preprocessing
# =============================================================================

# Preprocess markdown file for better LaTeX compatibility
preprocess_markdown() {
    local input_file="$1"
    local temp_file="${input_file}.temp"

    echo -e "${BLUE}Preprocessing markdown file for better LaTeX compatibility...${NC}"

    # Create a copy of the file
    cp "$input_file" "$temp_file"

    # Remove duplicate title H1 heading if it matches YAML frontmatter title
    if [ -n "$META_TITLE" ]; then
        # Get the first H1 heading from the content (after YAML frontmatter)
        local first_h1
        first_h1=$(awk '/^---$/{if(!yaml) yaml=1; else {yaml=0; next}} yaml{next} /^# /{print substr($0,3); exit}' "$temp_file")

        # Compare with metadata title (remove quotes for comparison)
        local meta_title_clean
        meta_title_clean=$(echo "$META_TITLE" | sed 's/^["\x27]*//; s/["\x27]*$//')

        if [ "$first_h1" = "$meta_title_clean" ] || [[ "$first_h1" == "$meta_title_clean"* ]]; then
            echo -e "${YELLOW}Removing duplicate title H1 heading: '$first_h1'${NC}"
            # Use awk to remove the first H1 heading and following empty lines
            awk '
                BEGIN { yaml=0; removed=0 }
                /^---$/ && !yaml { yaml=1; print; next }
                /^---$/ && yaml { yaml=0; print; next }
                yaml { print; next }
                !removed && /^# / && substr($0,3) == "'"$first_h1"'" {
                    removed=1
                    # Skip this line and any following empty lines
                    while ((getline next_line) > 0 && next_line ~ /^\s*$/) {
                        # Skip empty lines
                    }
                    if (next_line != "") print next_line
                    next
                }
                { print }
            ' "$temp_file" > "${temp_file}.tmp" && mv "${temp_file}.tmp" "$temp_file"
        fi
    fi

    # Replace problematic Unicode characters with LaTeX commands
    if [ "$PDF_ENGINE" = "pdflatex" ]; then
        echo -e "${YELLOW}Using pdfLaTeX engine - Unicode characters handled by template${NC}"

        # Replace combining right harpoon (U+20D1) with \vec command
        sed -i 's/\\overset{⃑}/\\vec/g' "$temp_file"

        # All other Unicode characters are handled by \newunicodechar in the template
    else
        # For LuaLaTeX and XeLaTeX, CJK characters will be handled automatically by xeCJK
        echo -e "${YELLOW}Using Unicode engines - CJK characters will be handled automatically by xeCJK${NC}"
    fi

    # Move the temp file back to the original
    mv "$temp_file" "$input_file"

    echo -e "${GREEN}Preprocessing complete${NC}"
}

# =============================================================================
# Cover Image Detection
# =============================================================================

# Auto-detect cover images at default paths
# Returns the path to the cover image if found, empty string otherwise
detect_cover_image() {
    local input_dir="$1"
    local image_type="$2"  # "cover" or "back"

    # Define search patterns based on image type
    local patterns=()
    if [ "$image_type" = "cover" ]; then
        patterns=("cover" "front" "front_cover" "premiere")
    else
        patterns=("back" "back_cover" "quatrieme")
    fi

    # Define supported extensions
    local extensions=("jpg" "jpeg" "png" "pdf")

    # Define search directories (relative to input file)
    local dirs=("img" "images" "assets" ".")

    # Search for cover image
    for dir in "${dirs[@]}"; do
        for pattern in "${patterns[@]}"; do
            for ext in "${extensions[@]}"; do
                local test_path="$input_dir/$dir/$pattern.$ext"
                if [ -f "$test_path" ]; then
                    echo "$test_path"
                    return 0
                fi
                # Also try uppercase extension
                local test_path_upper="$input_dir/$dir/$pattern.${ext^^}"
                if [ -f "$test_path_upper" ]; then
                    echo "$test_path_upper"
                    return 0
                fi
            done
        done
    done

    echo ""
    return 1
}

# Note: select_pdf_engine() is now in lib/pdf.sh
