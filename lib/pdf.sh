#!/bin/bash
# =============================================================================
# mdtexpdf - PDF Module
# =============================================================================
# PDF generation helper functions
#
# This module provides:
#   - detect_unicode_characters() - Check if document needs Unicode engine
#   - detect_cover_image() - Auto-detect cover images
#   - truncate_address() - Truncate long addresses for display
#   - preprocess_markdown() - Prepare markdown for LaTeX
#   - build_pandoc_pdf_command() - Build pandoc command for PDF output
#
# Dependencies: lib/core.sh (for logging functions)
# =============================================================================

# Function to detect Unicode characters that require Unicode engines
# Arguments:
#   $1 - input_file: Path to markdown file
# Returns: 0 if Unicode characters found, 1 otherwise
detect_unicode_characters() {
    local input_file="$1"

    # Check for CJK characters (Chinese, Japanese, Korean)
    # CJK Unified Ideographs: U+4E00-U+9FFF
    # CJK Extension A: U+3400-U+4DBF
    # CJK Extension B: U+20000-U+2A6DF
    # CJK Extension C: U+2A700-U+2B73F
    # CJK Extension D: U+2B740-U+2B81F
    # CJK Extension E: U+2B820-U+2CEAF
    if grep -qP '[\x{4E00}-\x{9FFF}\x{3400}-\x{4DBF}\x{20000}-\x{2A6DF}\x{2A700}-\x{2B73F}\x{2B740}-\x{2B81F}\x{2B820}-\x{2CEAF}]' "$input_file"; then
        return 0  # Found CJK characters
    fi

    # Check for other Unicode characters that might not be supported by pdfLaTeX
    # Arabic: U+0600-U+06FF
    # Hebrew: U+0590-U+05FF
    # Devanagari: U+0900-U+097F
    # And other scripts that pdfLaTeX typically doesn't support well
    if grep -qP '[\x{0600}-\x{06FF}\x{0590}-\x{05FF}\x{0900}-\x{097F}\x{0980}-\x{09FF}\x{0A00}-\x{0A7F}\x{0A80}-\x{0AFF}\x{0B00}-\x{0B7F}\x{0B80}-\x{0BFF}\x{0C00}-\x{0C7F}\x{0C80}-\x{0CFF}\x{0D00}-\x{0D7F}\x{0D80}-\x{0DFF}]' "$input_file"; then
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

# Function to auto-detect cover images at default paths
# Arguments:
#   $1 - input_dir: Directory containing input file
#   $2 - image_type: "cover" or "back"
# Returns: Path to cover image if found, empty string otherwise
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

# Function to truncate long addresses/keys for display
# Arguments:
#   $1 - full_address: The address to truncate
#   $2 - chars_to_show: Number of chars to show on each side (default: 4)
# Returns: Truncated address (e.g., "abc1...xyz9")
truncate_address() {
    local full_address="$1"
    local chars="${2:-4}"  # Default to 4 characters each side

    local length=${#full_address}

    # Only truncate if longer than 2*chars + 3 (for "...")
    if [ "$length" -gt $((chars * 2 + 3)) ]; then
        local start="${full_address:0:$chars}"
        local end="${full_address: -$chars}"
        echo "${start}...${end}"
    else
        echo "$full_address"
    fi
}

# Function to preprocess markdown file for better LaTeX compatibility
# Arguments:
#   $1 - input_file: Path to markdown file
# Side effects: Modifies the file in place
preprocess_markdown() {
    local input_file="$1"
    local temp_file="${input_file}.temp"

    log_verbose "Preprocessing markdown file for better LaTeX compatibility..."

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
            log_verbose "Removing duplicate title H1 heading: '$first_h1'"
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
        log_verbose "Using pdfLaTeX engine - Unicode characters handled by template"

        # Replace combining right harpoon (U+20D1) with \vec command
        # This is tricky because it's a combining character, so we need to capture the character it combines with
        sed -i 's/\\overset{⃑}/\\vec/g' "$temp_file"

        # All other Unicode characters are handled by \newunicodechar in the template
        # No additional preprocessing needed
    else
        # For LuaLaTeX and XeLaTeX, CJK characters will be handled automatically by xeCJK
        log_verbose "Using Unicode engines - CJK characters will be handled automatically by xeCJK"
    fi

    # Move the temp file back to the original
    mv "$temp_file" "$input_file"

    log_verbose "Preprocessing complete"
}

# Function to select the best PDF engine based on document content
# Arguments:
#   $1 - input_file: Path to markdown file
# Sets: PDF_ENGINE global variable
# Returns: 0 on success, 1 if no engine available
select_pdf_engine() {
    local input_file="$1"

    log_verbose "Analyzing document content for Unicode character requirements..."

    if detect_unicode_characters "$input_file"; then
        log_verbose "Unicode characters detected that require advanced LaTeX engine support"
        # Prioritize Unicode-capable engines - XeLaTeX with xeCJK for CJK support
        if [ "$XELATEX_AVAILABLE" = true ]; then
            PDF_ENGINE="xelatex"
            log_success "Selected XeLaTeX engine for Unicode support"
            log_verbose "Note: CJK characters (Chinese, Japanese, Korean) will be handled automatically by xeCJK"
            log_verbose "Some font fallback warnings may appear during compilation, but characters will render correctly."
        elif [ "$LUALATEX_AVAILABLE" = true ]; then
            PDF_ENGINE="lualatex"
            log_success "Selected LuaLaTeX engine for Unicode support"
        elif [ "$PDFLATEX_AVAILABLE" = true ]; then
            PDF_ENGINE="pdflatex"
            log_warn "Using pdfLaTeX with limited Unicode support. Some characters may not render correctly."
        else
            log_error "No LaTeX engine available for Unicode content"
            return 1
        fi
    else
        log_success "No Unicode characters requiring special handling detected"
        # Use default engine selection (pdfLaTeX preferred for compatibility)
        if [ "$PDFLATEX_AVAILABLE" = true ]; then
            PDF_ENGINE="pdflatex"
        elif [ "$XELATEX_AVAILABLE" = true ]; then
            PDF_ENGINE="xelatex"
        elif [ "$LUALATEX_AVAILABLE" = true ]; then
            PDF_ENGINE="lualatex"
        fi
        log_verbose "Using PDF engine: $PDF_ENGINE"
    fi

    return 0
}

# Function to find Lua filter path
# Arguments:
#   $1 - filter_name: Name of the filter file (e.g., "index_filter.lua")
# Returns: Full path to filter, or empty string if not found
find_lua_filter() {
    local filter_name="$1"

    # Check various locations
    if [ -f "$(pwd)/filters/$filter_name" ]; then
        echo "$(pwd)/filters/$filter_name"
    elif [ -f "$SCRIPT_DIR/filters/$filter_name" ]; then
        echo "$SCRIPT_DIR/filters/$filter_name"
    elif [ -f "/usr/local/share/mdtexpdf/filters/$filter_name" ]; then
        echo "/usr/local/share/mdtexpdf/filters/$filter_name"
    else
        echo ""
    fi
}

# Function to cleanup after PDF generation
# Arguments:
#   $1 - backup_file: Path to backup file
#   $2 - input_file: Path to input file
#   $3 - combined_file: Path to combined file (for multi-file projects)
#   $4 - bib_temp_dir: Path to bibliography temp directory
cleanup_pdf_generation() {
    local backup_file="$1"
    local input_file="$2"
    local combined_file="$3"
    local bib_temp_dir="$4"

    # Clean up bibliography temp directory
    if [ -n "$bib_temp_dir" ] && [ -d "$bib_temp_dir" ]; then
        rm -rf "$bib_temp_dir"
    fi

    # Clean up: Remove template.tex file if it was created in the current directory
    if [ -f "$(pwd)/template.tex" ]; then
        log_verbose "Cleaning up: Removing template.tex"
        rm -f "$(pwd)/template.tex"
    fi

    # Restore the original markdown file from backup
    if [ -f "$backup_file" ]; then
        log_verbose "Restoring original markdown file from backup"
        mv "$backup_file" "$input_file"
    fi

    # Clean up combined file if multi-file project
    if [ -n "$combined_file" ] && [ -f "$combined_file" ]; then
        rm -f "$combined_file"
    fi
}

# Export functions for use in main script
export -f detect_unicode_characters 2>/dev/null || true
export -f detect_cover_image 2>/dev/null || true
export -f truncate_address 2>/dev/null || true
export -f preprocess_markdown 2>/dev/null || true
export -f select_pdf_engine 2>/dev/null || true
export -f find_lua_filter 2>/dev/null || true
export -f cleanup_pdf_generation 2>/dev/null || true
