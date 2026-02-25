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
#   - select_pdf_engine() - Select best LaTeX engine based on content
#   - find_lua_filter() - Find Lua filter path across search locations
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
# Searches in order: pwd, pwd/filters, SCRIPT_DIR, SCRIPT_DIR/filters,
#                    ~/.local/share/mdtexpdf, /usr/local/share/mdtexpdf
# Arguments:
#   $1 - filter_name: Name of the filter file (e.g., "index_filter.lua")
# Returns: Full path to filter, or empty string if not found
find_lua_filter() {
    local filter_name="$1"
    local script_dir
    script_dir="$(dirname "$(readlink -f "$0")")"

    # Search order: local paths first, then user-installed, then system-installed.
    # 1. Current directory (root + filters/)
    if [ -f "$(pwd)/$filter_name" ]; then
        echo "$(pwd)/$filter_name"
    elif [ -f "$(pwd)/filters/$filter_name" ]; then
        echo "$(pwd)/filters/$filter_name"
    # 2. Script directory (root + filters/)
    elif [ -f "$script_dir/$filter_name" ]; then
        echo "$script_dir/$filter_name"
    elif [ -f "$script_dir/filters/$filter_name" ]; then
        echo "$script_dir/filters/$filter_name"
    # 3. User-installed paths (~/.local)
    elif [ -f "$HOME/.local/share/mdtexpdf/$filter_name" ]; then
        echo "$HOME/.local/share/mdtexpdf/$filter_name"
    elif [ -f "$HOME/.local/share/mdtexpdf/filters/$filter_name" ]; then
        echo "$HOME/.local/share/mdtexpdf/filters/$filter_name"
    # 4. System-installed paths (/usr/local - legacy fallback)
    elif [ -f "/usr/local/share/mdtexpdf/$filter_name" ]; then
        echo "/usr/local/share/mdtexpdf/$filter_name"
    elif [ -f "/usr/local/share/mdtexpdf/filters/$filter_name" ]; then
        echo "/usr/local/share/mdtexpdf/filters/$filter_name"
    else
        echo ""
    fi
}

# Export functions for use in main script
export -f detect_unicode_characters 2>/dev/null || true
export -f detect_cover_image 2>/dev/null || true
export -f truncate_address 2>/dev/null || true
export -f select_pdf_engine 2>/dev/null || true
export -f find_lua_filter 2>/dev/null || true
