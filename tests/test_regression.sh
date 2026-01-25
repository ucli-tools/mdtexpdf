#!/bin/bash
# =============================================================================
# mdtexpdf Regression Tests
# Compares output characteristics to detect unexpected changes
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MDTEXPDF="$PROJECT_DIR/mdtexpdf.sh"

# Test output directory
TEST_OUTPUT="$SCRIPT_DIR/output"
BASELINE_DIR="$SCRIPT_DIR/baselines"
mkdir -p "$TEST_OUTPUT"
mkdir -p "$BASELINE_DIR"

# =============================================================================
# Test Helpers
# =============================================================================

test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}[$TESTS_RUN]${NC} Testing: $1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "    ${GREEN}PASS${NC}"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "    ${RED}FAIL${NC}: $1"
}

test_skip() {
    echo -e "    ${YELLOW}SKIP${NC}: $1"
}

# Get PDF page count using pdfinfo
get_pdf_pages() {
    local pdf_file="$1"
    if command -v pdfinfo &> /dev/null; then
        pdfinfo "$pdf_file" 2>/dev/null | grep "Pages:" | awk '{print $2}'
    else
        echo "unknown"
    fi
}

# Get PDF file size category (small/medium/large)
get_size_category() {
    local file="$1"
    local size
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)

    if [ "$size" -lt 50000 ]; then
        echo "small"
    elif [ "$size" -lt 500000 ]; then
        echo "medium"
    else
        echo "large"
    fi
}

# Get EPUB structure info
get_epub_info() {
    local epub_file="$1"
    local temp_dir
    temp_dir=$(mktemp -d)

    unzip -q "$epub_file" -d "$temp_dir" 2>/dev/null

    # Count chapters
    local chapter_count
    chapter_count=$(find "$temp_dir" -name "ch*.xhtml" 2>/dev/null | wc -l)

    # Check for nav
    local has_nav="no"
    [ -f "$temp_dir/EPUB/nav.xhtml" ] && has_nav="yes"

    # Check for cover
    local has_cover="no"
    grep -q "cover" "$temp_dir/EPUB/content.opf" 2>/dev/null && has_cover="yes"

    rm -rf "$temp_dir"

    echo "chapters:$chapter_count,nav:$has_nav,cover:$has_cover"
}

# =============================================================================
# Regression Tests
# =============================================================================

# Test: Basic article produces consistent output
test_regression_basic_article() {
    test_start "Regression: Basic article structure"

    if ! command -v pandoc &> /dev/null; then
        test_skip "pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        test_skip "LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/reg_article.md"
    local test_pdf="$TEST_OUTPUT/reg_article.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Regression Test Article"
author: "Test Author"
date: "2026-01-01"
---

# Introduction

This is a test paragraph.

# Section Two

Another paragraph here.

## Subsection

Final content.
EOF

    rm -f "$test_pdf"
    "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test" &>/dev/null

    if [ ! -f "$test_pdf" ]; then
        test_fail "PDF not created"
        return
    fi

    # Check page count (should be 1-2 pages for this content)
    local pages
    pages=$(get_pdf_pages "$test_pdf")

    if [ "$pages" = "unknown" ]; then
        # pdfinfo not available, just check file exists and has content
        local size
        size=$(stat -c%s "$test_pdf" 2>/dev/null || stat -f%z "$test_pdf" 2>/dev/null)
        if [ "$size" -gt 1000 ]; then
            test_pass
        else
            test_fail "PDF too small: $size bytes"
        fi
    elif [ "$pages" -ge 1 ] && [ "$pages" -le 3 ]; then
        test_pass
    else
        test_fail "Unexpected page count: $pages (expected 1-3)"
    fi
}

# Test: Book format produces more pages than article
test_regression_book_format() {
    test_start "Regression: Book format structure"

    if ! command -v pandoc &> /dev/null; then
        test_skip "pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        test_skip "LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/reg_book.md"
    local test_pdf="$TEST_OUTPUT/reg_book.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Regression Test Book"
author: "Test Author"
date: "2026-01-01"
format: "book"
toc: true
half_title: true
copyright_page: true
dedication: "To testers"
---

# Chapter 1

First chapter content.

# Chapter 2

Second chapter content.

# Chapter 3

Third chapter content.
EOF

    rm -f "$test_pdf"
    "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test" &>/dev/null

    if [ ! -f "$test_pdf" ]; then
        test_fail "PDF not created"
        return
    fi

    # Book with front matter should have more pages
    local pages
    pages=$(get_pdf_pages "$test_pdf")

    if [ "$pages" = "unknown" ]; then
        local size
        size=$(stat -c%s "$test_pdf" 2>/dev/null || stat -f%z "$test_pdf" 2>/dev/null)
        if [ "$size" -gt 5000 ]; then
            test_pass
        else
            test_fail "PDF too small for book: $size bytes"
        fi
    elif [ "$pages" -ge 4 ]; then
        test_pass
    else
        test_fail "Book should have 4+ pages, got: $pages"
    fi
}

# Test: EPUB structure is valid
test_regression_epub_structure() {
    test_start "Regression: EPUB structure"

    if ! command -v pandoc &> /dev/null; then
        test_skip "pandoc not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/reg_epub.md"
    local test_epub="$TEST_OUTPUT/reg_epub.epub"

    cat > "$test_md" << 'EOF'
---
title: "Regression Test EPUB"
author: "Test Author"
date: "2026-01-01"
format: "book"
toc: true
---

# Chapter 1

First chapter.

# Chapter 2

Second chapter.

# Chapter 3

Third chapter.
EOF

    rm -f "$test_epub"
    "$MDTEXPDF" convert "$test_md" --read-metadata --epub &>/dev/null

    if [ ! -f "$test_epub" ]; then
        test_fail "EPUB not created"
        return
    fi

    # Check EPUB structure
    local epub_info
    epub_info=$(get_epub_info "$test_epub")

    # Should have chapters and nav
    if echo "$epub_info" | grep -q "nav:yes"; then
        test_pass
    else
        test_fail "EPUB missing nav: $epub_info"
    fi
}

# Test: TOC increases PDF size
test_regression_toc_effect() {
    test_start "Regression: TOC adds content"

    if ! command -v pandoc &> /dev/null; then
        test_skip "pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        test_skip "LaTeX not installed"
        return
    fi

    local test_md_no_toc="$TEST_OUTPUT/reg_no_toc.md"
    local test_md_toc="$TEST_OUTPUT/reg_toc.md"
    local test_pdf_no_toc="$TEST_OUTPUT/reg_no_toc.pdf"
    local test_pdf_toc="$TEST_OUTPUT/reg_toc.pdf"

    # Create file without TOC
    cat > "$test_md_no_toc" << 'EOF'
---
title: "No TOC Test"
author: "Test Author"
toc: false
---

# Chapter 1
Content.

# Chapter 2
Content.

# Chapter 3
Content.
EOF

    # Create file with TOC
    cat > "$test_md_toc" << 'EOF'
---
title: "With TOC Test"
author: "Test Author"
toc: true
---

# Chapter 1
Content.

# Chapter 2
Content.

# Chapter 3
Content.
EOF

    rm -f "$test_pdf_no_toc" "$test_pdf_toc"
    "$MDTEXPDF" convert "$test_md_no_toc" "$test_pdf_no_toc" --read-metadata -f "Test" &>/dev/null
    "$MDTEXPDF" convert "$test_md_toc" "$test_pdf_toc" --read-metadata -f "Test" &>/dev/null

    if [ ! -f "$test_pdf_no_toc" ] || [ ! -f "$test_pdf_toc" ]; then
        test_fail "PDFs not created"
        return
    fi

    local pages_no_toc pages_toc
    pages_no_toc=$(get_pdf_pages "$test_pdf_no_toc")
    pages_toc=$(get_pdf_pages "$test_pdf_toc")

    if [ "$pages_no_toc" = "unknown" ] || [ "$pages_toc" = "unknown" ]; then
        # Compare file sizes instead
        local size_no_toc size_toc
        size_no_toc=$(stat -c%s "$test_pdf_no_toc" 2>/dev/null || stat -f%z "$test_pdf_no_toc" 2>/dev/null)
        size_toc=$(stat -c%s "$test_pdf_toc" 2>/dev/null || stat -f%z "$test_pdf_toc" 2>/dev/null)

        if [ "$size_toc" -ge "$size_no_toc" ]; then
            test_pass
        else
            test_fail "TOC version should be >= no-TOC version"
        fi
    else
        if [ "$pages_toc" -ge "$pages_no_toc" ]; then
            test_pass
        else
            test_fail "TOC version ($pages_toc pages) should have >= pages than no-TOC ($pages_no_toc)"
        fi
    fi
}

# Test: Math content renders without error
test_regression_math() {
    test_start "Regression: Math rendering"

    if ! command -v pandoc &> /dev/null; then
        test_skip "pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        test_skip "LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/reg_math.md"
    local test_pdf="$TEST_OUTPUT/reg_math.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Math Regression"
author: "Test Author"
---

# Equations

Inline: $E = mc^2$

Display:

$$\int_0^1 x^2 dx = \frac{1}{3}$$

$$\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}$$
EOF

    rm -f "$test_pdf"
    local output
    output=$("$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test" 2>&1)

    if [ ! -f "$test_pdf" ]; then
        test_fail "PDF not created"
        return
    fi

    # Check for LaTeX errors in output
    if echo "$output" | grep -qi "error\|undefined"; then
        test_fail "LaTeX errors detected"
    else
        test_pass
    fi
}

# =============================================================================
# Main
# =============================================================================

echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}      mdtexpdf Regression Tests            ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

# Run tests
test_regression_basic_article
test_regression_book_format
test_regression_epub_structure
test_regression_toc_effect
test_regression_math

# Summary
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}                 Summary                   ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All regression tests passed!${NC}\n"
    exit 0
else
    echo -e "\n${RED}Some regression tests failed.${NC}\n"
    exit 1
fi
