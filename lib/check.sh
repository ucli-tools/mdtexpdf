#!/bin/bash
# =============================================================================
# mdtexpdf Check Module
# Prerequisites verification
# =============================================================================

# Source core if not already loaded
if [ -z "$MDTEXPDF_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
fi

# =============================================================================
# Prerequisites Check
# =============================================================================

check_prerequisites() {
    echo -e "\n${YELLOW}=== LaTeX-Markdown PDF Generator Prerequisites Check ===${NC}\n"

    local all_good=true

    # Check for Pandoc
    echo -e "${PURPLE}Checking for Pandoc...${NC}"
    if ! check_command pandoc; then
        all_good=false
    fi

    # Check for LaTeX engines
    echo -e "\n${PURPLE}Checking for LaTeX engines...${NC}"
    local latex_found=false

    # Initialize engine availability flags (global)
    LUALATEX_AVAILABLE=false
    XELATEX_AVAILABLE=false
    PDFLATEX_AVAILABLE=false

    if command -v lualatex &> /dev/null; then
        echo -e "${GREEN}✓ lualatex is installed${NC}"
        LUALATEX_AVAILABLE=true
        latex_found=true
    fi

    if command -v xelatex &> /dev/null; then
        echo -e "${GREEN}✓ xelatex is installed${NC}"
        XELATEX_AVAILABLE=true
        latex_found=true
    fi

    if command -v pdflatex &> /dev/null; then
        echo -e "${GREEN}✓ pdflatex is installed${NC}"
        PDFLATEX_AVAILABLE=true
        latex_found=true
    fi

    if [ "$latex_found" = false ]; then
        echo -e "${RED}✗ No LaTeX engine found (pdflatex, xelatex, or lualatex)${NC}"
        all_good=false
    fi

    # Check for required LaTeX packages
    echo -e "\n${PURPLE}Checking for required LaTeX packages...${NC}"
    local packages=(
        "geometry" "fancyhdr" "graphicx" "amsmath" "amssymb"
        "hyperref" "xcolor" "booktabs" "longtable" "amsthm"
        "fancyvrb" "framed" "listings" "array" "enumitem"
        "etoolbox" "float" "lmodern" "textcomp" "upquote"
        "microtype" "mhchem" "breqn"
    )

    for pkg in "${packages[@]}"; do
        if ! check_latex_package "$pkg"; then
            all_good=false
        fi
    done

    # Summary
    echo ""
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}All prerequisites are installed!${NC}\n"
        return 0
    else
        echo -e "${RED}Some prerequisites are missing. Please install them before using mdtexpdf.${NC}\n"
        return 1
    fi
}

# Optional dependencies check
check_optional_deps() {
    echo -e "\n${PURPLE}Checking optional dependencies...${NC}"

    # ImageMagick for cover generation
    if command -v convert &> /dev/null; then
        echo -e "${GREEN}✓ ImageMagick is installed (EPUB cover generation)${NC}"
    else
        echo -e "${YELLOW}○ ImageMagick not installed (EPUB covers will use image without text overlay)${NC}"
    fi

    # epubcheck for EPUB validation
    if command -v epubcheck &> /dev/null; then
        echo -e "${GREEN}✓ epubcheck is installed (EPUB validation)${NC}"
    else
        echo -e "${YELLOW}○ epubcheck not installed (EPUB validation disabled)${NC}"
    fi
}
