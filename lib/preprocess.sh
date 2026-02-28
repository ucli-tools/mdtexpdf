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

    # Normalize escaped angle brackets often produced by copied equations.
    # LaTeX treats \< and \> as control sequences (undefined in many contexts),
    # while raw < and > are valid relation symbols in math mode.
    perl -i -pe 's/\x5c</</g; s/\x5c>/>/g' "$temp_file"

    # Normalize doubly-escaped LaTeX math commands copied from some editors/docs
    # (e.g., \epsilon, \nabla, \frac) to their proper single-backslash form.
    perl -i -pe 's/\\\\(alpha|beta|gamma|delta|epsilon|varepsilon|zeta|eta|theta|vartheta|iota|kappa|lambda|mu|nu|xi|pi|rho|sigma|tau|upsilon|phi|varphi|chi|psi|omega|Gamma|Delta|Theta|Lambda|Xi|Pi|Sigma|Upsilon|Phi|Psi|Omega|nabla|partial|frac|sqrt|sum|prod|int|oint|infty|cdot|times|pm|mp|leq|geq|neq|approx|sim|propto|to|rightarrow|leftarrow|leftrightarrow|Rightarrow|Leftarrow|Leftrightarrow|perp|parallel|mathbf|mathrm|mathcal|mathbb|text|left|right)\b/\\$1/g' "$temp_file"
    
        # Normalize markdown-style escaping that leaks into math expressions
        # (e.g., r\_L \= ...), which can break LaTeX parsing.
        perl -i -pe 's/\\=+/=/g; s/\\\++/+/g; s/\\_([A-Za-z0-9])/_$1/g; s/\\\^([A-Za-z0-9])/^$1/g' "$temp_file"

        # Collapse doubled backslashes before command names (e.g., \\ll, \\gtrsim,
        # \\epsilon) to proper LaTeX command form.
        perl -i -pe 's/\\\\([A-Za-z]{2,})/\\$1/g' "$temp_file"

    # Move the temp file back to the original
    mv "$temp_file" "$input_file"

    echo -e "${GREEN}Preprocessing complete${NC}"
}
