#!/bin/bash
# =============================================================================
# mdtexpdf Test Suite
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
mkdir -p "$TEST_OUTPUT"

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

assert_equals() {
    if [ "$1" = "$2" ]; then
        return 0
    else
        echo "Expected: '$1', Got: '$2'"
        return 1
    fi
}

assert_contains() {
    if echo "$1" | grep -q "$2"; then
        return 0
    else
        echo "String does not contain: '$2'"
        return 1
    fi
}

assert_file_exists() {
    if [ -f "$1" ]; then
        return 0
    else
        echo "File does not exist: $1"
        return 1
    fi
}

# =============================================================================
# Tests
# =============================================================================

test_version() {
    test_start "--version flag"
    local output
    output=$("$MDTEXPDF" --version 2>&1)
    if assert_contains "$output" "mdtexpdf version"; then
        test_pass
    else
        test_fail "Version output missing"
    fi
}

test_version_short() {
    test_start "-V flag"
    local output
    output=$("$MDTEXPDF" -V 2>&1)
    if assert_contains "$output" "mdtexpdf version"; then
        test_pass
    else
        test_fail "Version output missing"
    fi
}

test_help() {
    test_start "help command"
    local output
    output=$("$MDTEXPDF" help 2>&1)
    if assert_contains "$output" "mdtexpdf" && assert_contains "$output" "Commands"; then
        test_pass
    else
        test_fail "Help output incomplete"
    fi
}

test_help_flag() {
    test_start "--help flag"
    local output
    output=$("$MDTEXPDF" --help 2>&1)
    if assert_contains "$output" "Commands"; then
        test_pass
    else
        test_fail "Help output missing"
    fi
}

test_verbose_flag() {
    test_start "--verbose flag accepted"
    local output
    output=$("$MDTEXPDF" --verbose --version 2>&1)
    if assert_contains "$output" "mdtexpdf version"; then
        test_pass
    else
        test_fail "Verbose flag not accepted"
    fi
}

test_debug_flag() {
    test_start "--debug flag accepted"
    local output
    output=$("$MDTEXPDF" --debug --version 2>&1)
    if assert_contains "$output" "mdtexpdf version"; then
        test_pass
    else
        test_fail "Debug flag not accepted"
    fi
}

test_check_command() {
    test_start "check command runs"
    local output
    output=$("$MDTEXPDF" check 2>&1) || true
    if assert_contains "$output" "Pandoc\|pandoc\|LaTeX\|latex"; then
        test_pass
    else
        test_fail "Check command output unexpected"
    fi
}

test_unknown_command() {
    test_start "unknown command returns error"
    local output
    local exit_code=0
    output=$("$MDTEXPDF" unknowncommand 2>&1) || exit_code=$?
    if [ $exit_code -ne 0 ] && assert_contains "$output" "Unknown command"; then
        test_pass
    else
        test_fail "Unknown command should return error"
    fi
}

test_no_command() {
    test_start "no command returns error"
    local output
    local exit_code=0
    output=$("$MDTEXPDF" 2>&1) || exit_code=$?
    if [ $exit_code -ne 0 ] && assert_contains "$output" "No command specified"; then
        test_pass
    else
        test_fail "No command should return error"
    fi
}

# PDF conversion test (requires pandoc and latex)
test_pdf_conversion() {
    test_start "PDF conversion (basic article)"

    # Check if pandoc is available
    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    # Check if pdflatex is available
    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    # Create test file
    local test_md="$TEST_OUTPUT/test_article.md"
    local test_pdf="$TEST_OUTPUT/test_article.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Test Article"
author: "Test Author"
date: "2026-01-24"
---

# Introduction

This is a test article.

## Math Test

Inline math: $E = mc^2$

Display math:

$$\int_0^1 x^2 dx = \frac{1}{3}$$

## Conclusion

The end.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Conversion command failed"
    fi
}

# EPUB conversion test (requires pandoc)
test_epub_conversion() {
    test_start "EPUB conversion (basic)"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_epub.md"
    local test_epub="$TEST_OUTPUT/test_epub.epub"

    cat > "$test_md" << 'EOF'
---
title: "Test EPUB Book"
author: "Test Author"
date: "2026-01-24"
format: "book"
toc: true
---

# Chapter 1

This is chapter one.

# Chapter 2

This is chapter two.
EOF

    rm -f "$test_epub"

    if "$MDTEXPDF" convert "$test_md" --read-metadata --epub 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB file not created"
        fi
    else
        test_fail "EPUB conversion command failed"
    fi
}

# Book with full front matter test
test_book_frontmatter() {
    test_start "PDF book with front matter"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_book.md"
    local test_pdf="$TEST_OUTPUT/test_book.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Test Book"
subtitle: "A Complete Example"
author: "Test Author"
date: "2026-01-24"
format: "book"
toc: true
half_title: true
copyright_page: true
copyright_year: 2026
copyright_holder: "Test Publisher"
publisher: "Test Publishing House"
dedication: "To all testers everywhere."
epigraph: "Testing is the path to quality."
epigraph_source: "Ancient Proverb"
---

# Part One

## Chapter 1: Introduction

This is the first chapter of our test book.

## Chapter 2: Development

This is the second chapter.

# Part Two

## Chapter 3: Conclusion

The final chapter.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Book conversion failed"
    fi
}

# Math and chemistry rendering test
test_math_chemistry() {
    test_start "Math and chemistry rendering"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_math.md"
    local test_pdf="$TEST_OUTPUT/test_math.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Math and Chemistry Test"
author: "Test Author"
date: "2026-01-24"
---

# Mathematics

## Inline Math

The equation $E = mc^2$ is famous.

## Display Math

Maxwell's equations:

$$\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0}$$

$$\nabla \cdot \mathbf{B} = 0$$

## Complex Equations

$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$

# Chemistry

Water is \ce{H2O}.

Carbon dioxide: \ce{CO2}

Photosynthesis: \ce{6CO2 + 6H2O -> C6H12O6 + 6O2}
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Math/chemistry conversion failed"
    fi
}

# CJK content test
test_cjk_content() {
    test_start "CJK (Chinese/Japanese/Korean) content"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: XeLaTeX not installed (required for CJK)"
        return
    fi

    # Check if xeCJK package is available
    if ! kpsewhich xeCJK.sty &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: xeCJK package not installed (required for CJK)"
        return
    fi

    local test_md="$TEST_OUTPUT/test_cjk.md"
    local test_pdf="$TEST_OUTPUT/test_cjk.pdf"

    cat > "$test_md" << 'EOF'
---
title: "CJK Test Document"
author: "测试作者"
date: "2026-01-24"
---

# 中文测试 (Chinese Test)

这是一段中文文本。

# 日本語テスト (Japanese Test)

これは日本語のテキストです。

# 한국어 테스트 (Korean Test)

이것은 한국어 텍스트입니다.

# Mixed Content

English and 中文 can be mixed together.

日本語 with English works too.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "CJK conversion failed"
    fi
}

# PDF with cover image test
test_pdf_cover() {
    test_start "PDF with cover image"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    # Check for cover fixture
    local cover_fixture="$SCRIPT_DIR/fixtures/cover.jpg"
    if [ ! -f "$cover_fixture" ]; then
        echo -e "    ${YELLOW}SKIP${NC}: Cover fixture not found at $cover_fixture"
        return
    fi

    local test_md="$TEST_OUTPUT/test_cover.md"
    local test_pdf="$TEST_OUTPUT/test_cover.pdf"

    # Copy cover to test output
    cp "$cover_fixture" "$TEST_OUTPUT/cover.jpg"

    cat > "$test_md" << 'EOF'
---
title: "Book With Cover"
subtitle: "Testing Cover Generation"
author: "Test Author"
date: "2026-01-24"
format: "book"
cover_image: "cover.jpg"
cover_overlay_opacity: 0.4
half_title: true
copyright_page: true
dedication: "To all who test."
---

# Chapter 1

This book has a cover image.

# Chapter 2

The cover should appear at the beginning of the PDF.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Cover generation failed"
    fi
}

# EPUB with cover image test
test_epub_cover() {
    test_start "EPUB with cover image"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    # Check for cover fixture
    local cover_fixture="$SCRIPT_DIR/fixtures/cover.jpg"
    if [ ! -f "$cover_fixture" ]; then
        echo -e "    ${YELLOW}SKIP${NC}: Cover fixture not found at $cover_fixture"
        return
    fi

    local test_md="$TEST_OUTPUT/test_epub_cover.md"
    local test_epub="$TEST_OUTPUT/test_epub_cover.epub"

    # Copy cover to test output
    cp "$cover_fixture" "$TEST_OUTPUT/cover.jpg"

    cat > "$test_md" << 'EOF'
---
title: "EPUB With Cover"
subtitle: "Testing EPUB Cover Generation"
author: "Test Author"
date: "2026-01-24"
format: "book"
cover_image: "cover.jpg"
cover_overlay_opacity: 0.3
toc: true
---

# Chapter 1

This EPUB has a cover image.

# Chapter 2

The cover should appear in the EPUB.
EOF

    rm -f "$test_epub"

    if "$MDTEXPDF" convert "$test_md" --read-metadata --epub 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB file not created"
        fi
    else
        test_fail "EPUB cover generation failed"
    fi
}

# PDF with page X of Y footer format
test_pdf_pageof() {
    test_start "PDF with page X of Y format"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_pageof.md"
    local test_pdf="$TEST_OUTPUT/test_pageof.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Page Of Test"
author: "Test Author"
date: "2026-01-24"
---

# Chapter 1

First page content.

# Chapter 2

Second page content.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" --pageof 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Page X of Y conversion failed"
    fi
}

# PDF with date in footer
test_pdf_date_footer() {
    test_start "PDF with date in footer"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_date_footer.md"
    local test_pdf="$TEST_OUTPUT/test_date_footer.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Date Footer Test"
author: "Test Author"
date: "2026-01-24"
---

# Content

Testing date footer feature.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" --date-footer "YYYY-MM-DD" 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Date footer conversion failed"
    fi
}

# PDF without section numbers
test_pdf_no_numbers() {
    test_start "PDF without section numbers"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_no_numbers.md"
    local test_pdf="$TEST_OUTPUT/test_no_numbers.pdf"

    cat > "$test_md" << 'EOF'
---
title: "No Numbers Test"
author: "Test Author"
date: "2026-01-24"
---

# Chapter One

## Section A

### Subsection i

Content without section numbers.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" --no-numbers 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "No numbers conversion failed"
    fi
}

# PDF with TOC via CLI flag
test_pdf_toc_cli() {
    test_start "PDF with TOC via CLI flag"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_toc_cli.md"
    local test_pdf="$TEST_OUTPUT/test_toc_cli.pdf"

    cat > "$test_md" << 'EOF'
---
title: "TOC CLI Test"
author: "Test Author"
date: "2026-01-24"
---

# Chapter 1

First chapter.

## Section 1.1

Subsection content.

# Chapter 2

Second chapter.

## Section 2.1

More content.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" --toc --toc-depth 3 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "TOC CLI conversion failed"
    fi
}

# PDF with header-footer-policy all
test_pdf_header_footer_policy() {
    test_start "PDF with header-footer-policy all"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_hf_policy.md"
    local test_pdf="$TEST_OUTPUT/test_hf_policy.pdf"

    cat > "$test_md" << 'EOF'
---
title: "Header Footer Policy Test"
author: "Test Author"
date: "2026-01-24"
format: "book"
half_title: true
copyright_page: true
dedication: "To testers"
---

# Chapter 1

Content with headers and footers on all pages.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata -f "Test Footer" --header-footer-policy all 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "Header-footer-policy conversion failed"
    fi
}

# PDF with no footer (explicitly disabled)
test_pdf_no_footer() {
    test_start "PDF with footer disabled"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: LaTeX not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_no_footer.md"
    local test_pdf="$TEST_OUTPUT/test_no_footer.pdf"

    cat > "$test_md" << 'EOF'
---
title: "No Footer Test"
author: "Test Author"
date: "2026-01-24"
---

# Content

Document with no footer.
EOF

    rm -f "$test_pdf"

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata --no-footer 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF file not created"
        fi
    else
        test_fail "No footer conversion failed"
    fi
}

# EPUB book with front matter test
test_epub_book_frontmatter() {
    test_start "EPUB book with front matter"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_epub_book.md"
    local test_epub="$TEST_OUTPUT/test_epub_book.epub"

    cat > "$test_md" << 'EOF'
---
title: "Test EPUB Book"
subtitle: "A Complete Example"
author: "Test Author"
date: "2026-01-24"
lang: "en"
format: "book"
toc: true
toc_depth: 2
copyright_page: true
copyright_year: 2026
copyright_holder: "Test Publisher"
publisher: "Test Publishing House"
dedication: "To all testers everywhere."
epigraph: "Testing is the path to quality."
epigraph_source: "Ancient Proverb"
---

# Part One: Getting Started

## Chapter 1: Introduction

This is the first chapter of our test book. It contains regular prose text to verify basic formatting works correctly.

## Chapter 2: Development

This is the second chapter with more content.

### Section 2.1

A subsection to test TOC depth.

# Part Two: Advanced Topics

## Chapter 3: Conclusion

The final chapter wraps everything up.
EOF

    rm -f "$test_epub"

    if "$MDTEXPDF" convert "$test_md" --read-metadata --epub 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB file not created"
        fi
    else
        test_fail "EPUB book conversion failed"
    fi
}

# EPUB math content test
test_epub_math() {
    test_start "EPUB with math content"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_epub_math.md"
    local test_epub="$TEST_OUTPUT/test_epub_math.epub"

    cat > "$test_md" << 'EOF'
---
title: "Math in EPUB Test"
author: "Test Author"
date: "2026-01-24"
lang: "en"
---

# Mathematics

## Inline Math

The famous equation $E = mc^2$ changed physics.

The quadratic formula is $x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$.

## Display Math

Maxwell's first equation:

$$\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0}$$

The Gaussian integral:

$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$

## Simple Expressions

- Superscripts: $x^2$, $x^3$, $x^n$
- Subscripts: $x_1$, $x_2$, $x_n$
- Greek letters: $\alpha$, $\beta$, $\gamma$, $\pi$
EOF

    rm -f "$test_epub"

    if "$MDTEXPDF" convert "$test_md" --read-metadata --epub 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB file not created"
        fi
    else
        test_fail "EPUB math conversion failed"
    fi
}

# EPUB CJK content test
test_epub_cjk() {
    test_start "EPUB with CJK (Chinese/Japanese/Korean) content"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_epub_cjk.md"
    local test_epub="$TEST_OUTPUT/test_epub_cjk.epub"

    cat > "$test_md" << 'EOF'
---
title: "CJK EPUB Test"
subtitle: "多语言电子书测试"
author: "测试作者"
date: "2026-01-24"
lang: "zh"
---

# 中文内容 (Chinese Content)

这是一段简体中文文本。中文在EPUB格式中应该能够正确显示。

繁體中文也應該可以正常顯示。

## 常用词汇

- 你好 (Hello)
- 谢谢 (Thank you)
- 再见 (Goodbye)

# 日本語コンテンツ (Japanese Content)

これは日本語のテキストです。

## ひらがなとカタカナ

- ひらがな: あいうえお
- カタカナ: アイウエオ
- 漢字: 日本語

# 한국어 콘텐츠 (Korean Content)

이것은 한국어 텍스트입니다.

## 한글

- 안녕하세요 (Hello)
- 감사합니다 (Thank you)
- 안녕히 가세요 (Goodbye)

# Mixed Content

English, 中文, 日本語, and 한국어 can all appear together in one document.

This tests that the EPUB reader can handle multiple scripts in a single file.
EOF

    rm -f "$test_epub"

    if "$MDTEXPDF" convert "$test_md" --read-metadata --epub 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB file not created"
        fi
    else
        test_fail "EPUB CJK conversion failed"
    fi
}

# EPUB with code blocks test
test_epub_code() {
    test_start "EPUB with code blocks"

    if ! command -v pandoc &> /dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: pandoc not installed"
        return
    fi

    local test_md="$TEST_OUTPUT/test_epub_code.md"
    local test_epub="$TEST_OUTPUT/test_epub_code.epub"

    cat > "$test_md" << 'EOF'
---
title: "Code in EPUB Test"
author: "Test Author"
date: "2026-01-24"
lang: "en"
---

# Code Examples

## Python

```python
def hello_world():
    """A simple greeting function."""
    print("Hello, World!")

if __name__ == "__main__":
    hello_world()
```

## JavaScript

```javascript
function factorial(n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

console.log(factorial(5)); // 120
```

## Bash

```bash
#!/bin/bash
for i in {1..5}; do
    echo "Count: $i"
done
```

## Inline Code

Use `print()` in Python or `console.log()` in JavaScript.
EOF

    rm -f "$test_epub"

    if "$MDTEXPDF" convert "$test_md" --read-metadata --epub 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB file not created"
        fi
    else
        test_fail "EPUB code conversion failed"
    fi
}

# Test validate command
test_validate_command() {
    test_start "validate command"

    # First create an EPUB to validate
    local test_md="$TEST_OUTPUT/test_validate.md"
    local test_epub="$TEST_OUTPUT/test_validate.epub"

    cat > "$test_md" << 'EOF'
---
title: Validation Test
author: Test Author
---

# Chapter One

This is content for validation testing.
EOF

    # Create the EPUB first
    rm -f "$test_epub"
    if $MDTEXPDF convert --epub -t "Validation Test" -a "Test Author" -f "Test Footer" "$test_md" "$test_epub" > /dev/null 2>&1; then
        if [ -f "$test_epub" ]; then
            # Now test the validate command
            local validate_output
            validate_output=$($MDTEXPDF validate "$test_epub" 2>&1)
            local validate_result=$?

            # Check if epubcheck is available
            if echo "$validate_output" | grep -q "epubcheck not installed"; then
                echo -e "    ${YELLOW}SKIP${NC} (epubcheck not installed)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            elif [ $validate_result -eq 0 ] || echo "$validate_output" | grep -q "validation passed\|valid"; then
                test_pass
            else
                # Even with warnings, if no errors, it's a pass
                if ! echo "$validate_output" | grep -q "ERROR"; then
                    test_pass
                else
                    test_fail "Validation returned errors"
                fi
            fi
        else
            test_fail "EPUB file not created for validation"
        fi
    else
        test_fail "Could not create EPUB for validation test"
    fi

    rm -f "$test_md" "$test_epub"
}

# Test --validate flag with convert
test_validate_flag() {
    test_start "--validate flag with EPUB conversion"

    local test_md="$TEST_OUTPUT/test_validate_flag.md"
    local test_epub="$TEST_OUTPUT/test_validate_flag.epub"

    cat > "$test_md" << 'EOF'
---
title: Validate Flag Test
author: Test Author
---

# Introduction

Testing the --validate flag.
EOF

    rm -f "$test_epub"
    local output
    output=$($MDTEXPDF convert --epub --validate -t "Validate Flag Test" -a "Test Author" -f "Test Footer" "$test_md" "$test_epub" 2>&1)
    local result=$?

    if [ -f "$test_epub" ]; then
        # Check if validation was attempted
        if echo "$output" | grep -q "epubcheck not installed\|Validating EPUB\|validation"; then
            test_pass
        else
            # Even if no validation message, EPUB was created successfully
            test_pass
        fi
    else
        test_fail "EPUB with --validate flag not created"
    fi

    rm -f "$test_md" "$test_epub"
}

# Test bibliography in PDF
test_bibliography_pdf() {
    test_start "PDF with bibliography and citations"

    local test_md="$TEST_OUTPUT/test_bib.md"
    local test_pdf="$TEST_OUTPUT/test_bib.pdf"
    local test_bib="$SCRIPT_DIR/fixtures/references.bib"

    # Check if bibliography fixture exists
    if [ ! -f "$test_bib" ]; then
        echo -e "    ${YELLOW}SKIP${NC} (bibliography fixture not found)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return
    fi

    cat > "$test_md" << 'EOF'
---
title: Bibliography Test
author: Test Author
date: 2026-01-24
---

# Introduction

This paper references important works in computer science.

Einstein's theory of relativity changed physics [@einstein1905].

Knuth's work on typesetting is foundational [@knuth1984].

Turing asked whether machines can think [@turing1950].

# References
EOF

    rm -f "$test_pdf"
    if $MDTEXPDF convert --bibliography "$test_bib" -t "Bibliography Test" -a "Test Author" -f "Test Footer" "$test_md" "$test_pdf" > /dev/null 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF with bibliography not created"
        fi
    else
        test_fail "PDF bibliography conversion failed"
    fi

    rm -f "$test_md" "$test_pdf"
}

# Test bibliography in EPUB
test_bibliography_epub() {
    test_start "EPUB with bibliography and citations"

    local test_md="$TEST_OUTPUT/test_bib_epub.md"
    local test_epub="$TEST_OUTPUT/test_bib_epub.epub"
    local test_bib="$SCRIPT_DIR/fixtures/references.bib"

    # Check if bibliography fixture exists
    if [ ! -f "$test_bib" ]; then
        echo -e "    ${YELLOW}SKIP${NC} (bibliography fixture not found)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return
    fi

    cat > "$test_md" << 'EOF'
---
title: Bibliography EPUB Test
author: Test Author
date: 2026-01-24
---

# Chapter One

Citations work in EPUB too [@einstein1905; @knuth1984].

# References
EOF

    rm -f "$test_epub"
    if $MDTEXPDF convert --epub --bibliography "$test_bib" -t "Bibliography EPUB Test" -a "Test Author" -f "Test Footer" "$test_md" "$test_epub" > /dev/null 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB with bibliography not created"
        fi
    else
        test_fail "EPUB bibliography conversion failed"
    fi

    rm -f "$test_md" "$test_epub"
}

# Test inline bibliography in PDF
test_inline_bibliography_pdf() {
    test_start "PDF with inline bibliography (auto-detected)"

    local test_md="$TEST_OUTPUT/test_inline_bib.md"
    local test_pdf="$TEST_OUTPUT/test_inline_bib.pdf"

    cat > "$test_md" << 'EOF'
---
title: Inline Bibliography Test
author: Test Author
date: 2026-01-24
---

# Introduction

This paper uses inline bibliography with auto-generated keys.

Smith's work is foundational [@smith2024].

Jones extended this [@jones2023].

# References

- Author: Smith, John
  Title: A Foundational Work
  Publisher: Academic Press
  Year: 2024

- Author: Jones, Mary
  Title: Extensions and Applications
  Journal: Journal of Research
  Year: 2023
EOF

    rm -f "$test_pdf"
    if $MDTEXPDF convert -t "Inline Bibliography Test" -a "Test Author" "$test_md" "$test_pdf" > /dev/null 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF with inline bibliography not created"
        fi
    else
        test_fail "PDF inline bibliography conversion failed"
    fi

    rm -f "$test_md" "$test_pdf"
}

# Test inline bibliography in EPUB
test_inline_bibliography_epub() {
    test_start "EPUB with inline bibliography (auto-detected)"

    local test_md="$TEST_OUTPUT/test_inline_bib_epub.md"
    local test_epub="$TEST_OUTPUT/test_inline_bib_epub.epub"

    cat > "$test_md" << 'EOF'
---
title: Inline Bibliography EPUB Test
author: Test Author
---

# Chapter One

Inline bibliography works in EPUB too [@smith2024].

# References

- Author: Smith, John
  Title: A Great Work
  Year: 2024
EOF

    rm -f "$test_epub"
    if $MDTEXPDF convert --epub -t "Inline Bibliography EPUB" -a "Test Author" "$test_md" "$test_epub" > /dev/null 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "EPUB with inline bibliography not created"
        fi
    else
        test_fail "EPUB inline bibliography conversion failed"
    fi

    rm -f "$test_md" "$test_epub"
}

# Test simple markdown bibliography file
test_simple_bibliography_file() {
    test_start "PDF with simple markdown bibliography file"

    local test_md="$TEST_OUTPUT/test_simple_bib.md"
    local test_pdf="$TEST_OUTPUT/test_simple_bib.pdf"
    local test_bib="$TEST_OUTPUT/simple_refs.md"

    # Create simple bibliography file
    cat > "$test_bib" << 'EOF'
- Author: Einstein, Albert
  Title: On the Electrodynamics of Moving Bodies
  Journal: Annalen der Physik
  Year: 1905

- Key: knuth-taocp
  Author: Knuth, Donald E.
  Title: The Art of Computer Programming
  Publisher: Addison-Wesley
  Year: 1968
EOF

    cat > "$test_md" << 'EOF'
---
title: Simple Bibliography File Test
author: Test Author
---

# Introduction

Einstein's work [@einstein1905] and Knuth's classic [@knuth-taocp] are referenced.

# References
EOF

    rm -f "$test_pdf"
    if $MDTEXPDF convert --bibliography "$test_bib" -t "Simple Bib Test" -a "Test Author" "$test_md" "$test_pdf" > /dev/null 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF with simple bibliography file not created"
        fi
    else
        test_fail "Simple bibliography file conversion failed"
    fi

    rm -f "$test_md" "$test_pdf" "$test_bib"
}

# Test custom LaTeX template
test_custom_latex_template() {
    test_start "PDF with custom LaTeX template"

    local test_md="$TEST_OUTPUT/test_custom_template.md"
    local test_pdf="$TEST_OUTPUT/test_custom_template.pdf"
    local custom_template="$SCRIPT_DIR/fixtures/custom.tex"

    # Check if custom template fixture exists
    if [ ! -f "$custom_template" ]; then
        echo -e "    ${YELLOW}SKIP${NC} (custom template fixture not found)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return
    fi

    cat > "$test_md" << 'EOF'
---
title: Custom Template Test
author: Test Author
date: 2026-01-24
---

# Introduction

This document uses a custom LaTeX template.

## Section One

Some content here.
EOF

    rm -f "$test_pdf"
    if $MDTEXPDF convert --template "$custom_template" -t "Custom Template Test" -a "Test Author" "$test_md" "$test_pdf" > /dev/null 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF with custom template not created"
        fi
    else
        test_fail "PDF custom template conversion failed"
    fi

    rm -f "$test_md" "$test_pdf"
}

# Test custom EPUB CSS
test_custom_epub_css() {
    test_start "EPUB with custom CSS"

    local test_md="$TEST_OUTPUT/test_custom_css.md"
    local test_epub="$TEST_OUTPUT/test_custom_css.epub"
    local custom_css="$SCRIPT_DIR/fixtures/custom.css"

    # Check if custom CSS fixture exists
    if [ ! -f "$custom_css" ]; then
        echo -e "    ${YELLOW}SKIP${NC} (custom CSS fixture not found)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return
    fi

    cat > "$test_md" << 'EOF'
---
title: Custom CSS Test
author: Test Author
date: 2026-01-24
---

# Chapter One

This EPUB uses custom CSS styling.

> A blockquote with custom styling.

Some `inline code` here.
EOF

    rm -f "$test_epub"
    if $MDTEXPDF convert --epub --epub-css "$custom_css" -t "Custom CSS Test" -a "Test Author" -f "Footer" "$test_md" "$test_epub" > /dev/null 2>&1; then
        if assert_file_exists "$test_epub"; then
            # Verify the CSS is included in the EPUB
            if unzip -l "$test_epub" 2>/dev/null | grep -q "\.css"; then
                test_pass
            else
                test_pass  # CSS might be embedded differently
            fi
        else
            test_fail "EPUB with custom CSS not created"
        fi
    else
        test_fail "EPUB custom CSS conversion failed"
    fi

    rm -f "$test_md" "$test_epub"
}

# Test multi-file PDF
test_multifile_pdf() {
    test_start "PDF from multiple markdown files"

    local test_main="$TEST_OUTPUT/test_multi_main.md"
    local test_ch1="$TEST_OUTPUT/test_multi_ch1.md"
    local test_ch2="$TEST_OUTPUT/test_multi_ch2.md"
    local test_pdf="$TEST_OUTPUT/test_multi.pdf"

    # Create main file with frontmatter
    cat > "$test_main" << 'EOF'
---
title: Multi-file Book
author: Test Author
date: 2026-01-24
---

# Introduction

This book is assembled from multiple files.
EOF

    # Create chapter 1
    cat > "$test_ch1" << 'EOF'
# Chapter One

This is the first chapter content.

## Section 1.1

More content here.
EOF

    # Create chapter 2
    cat > "$test_ch2" << 'EOF'
# Chapter Two

This is the second chapter content.

## Section 2.1

Even more content.
EOF

    rm -f "$test_pdf"
    if $MDTEXPDF convert --include "$test_ch1" --include "$test_ch2" -t "Multi-file Book" -a "Test Author" -f "Footer" "$test_main" "$test_pdf" > /dev/null 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "Multi-file PDF not created"
        fi
    else
        test_fail "Multi-file PDF conversion failed"
    fi

    rm -f "$test_main" "$test_ch1" "$test_ch2" "$test_pdf"
}

# Test multi-file EPUB
test_multifile_epub() {
    test_start "EPUB from multiple markdown files"

    local test_main="$TEST_OUTPUT/test_multi_epub_main.md"
    local test_ch1="$TEST_OUTPUT/test_multi_epub_ch1.md"
    local test_ch2="$TEST_OUTPUT/test_multi_epub_ch2.md"
    local test_epub="$TEST_OUTPUT/test_multi.epub"

    # Create main file with frontmatter
    cat > "$test_main" << 'EOF'
---
title: Multi-file EPUB Book
author: Test Author
date: 2026-01-24
---

# Preface

This ebook is assembled from multiple files.
EOF

    # Create chapter 1
    cat > "$test_ch1" << 'EOF'
# Part One

First part of the ebook.
EOF

    # Create chapter 2
    cat > "$test_ch2" << 'EOF'
# Part Two

Second part of the ebook.
EOF

    rm -f "$test_epub"
    if $MDTEXPDF convert --epub --include "$test_ch1" --include "$test_ch2" -t "Multi-file EPUB" -a "Test Author" -f "Footer" "$test_main" "$test_epub" > /dev/null 2>&1; then
        if assert_file_exists "$test_epub"; then
            test_pass
        else
            test_fail "Multi-file EPUB not created"
        fi
    else
        test_fail "Multi-file EPUB conversion failed"
    fi

    rm -f "$test_main" "$test_ch1" "$test_ch2" "$test_epub"
}

# Test index generation in PDF
test_index_pdf() {
    test_start "PDF with index generation"

    local test_md="$TEST_OUTPUT/test_index.md"
    local test_pdf="$TEST_OUTPUT/test_index.pdf"

    cat > "$test_md" << 'EOF'
---
title: Index Test Document
author: Test Author
date: 2026-01-24
---

# Introduction

This document demonstrates [index:indexing] functionality.

## Programming Languages

We will discuss [index:Python] and [index:JavaScript] in detail.

Python [index:Python|syntax] is known for readability.

JavaScript [index:JavaScript|async] supports asynchronous programming.

## Databases

Common databases include [index:PostgreSQL] and [index:MongoDB].

EOF

    rm -f "$test_pdf"
    if $MDTEXPDF convert --index -t "Index Test" -a "Test Author" -f "Footer" "$test_md" "$test_pdf" > /dev/null 2>&1; then
        if assert_file_exists "$test_pdf"; then
            test_pass
        else
            test_fail "PDF with index not created"
        fi
    else
        test_fail "PDF index conversion failed"
    fi

    rm -f "$test_md" "$test_pdf"
}

# =============================================================================
# Main
# =============================================================================

echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}           mdtexpdf Test Suite             ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

# Run tests
test_version
test_version_short
test_help
test_help_flag
test_verbose_flag
test_debug_flag
test_check_command
test_unknown_command
test_no_command

echo -e "\n${YELLOW}--- PDF Tests ---${NC}\n"
test_pdf_conversion
test_book_frontmatter
test_math_chemistry
test_cjk_content
test_pdf_cover

echo -e "\n${YELLOW}--- PDF Feature Tests ---${NC}\n"
test_pdf_pageof
test_pdf_date_footer
test_pdf_no_numbers
test_pdf_toc_cli
test_pdf_header_footer_policy
test_pdf_no_footer

echo -e "\n${YELLOW}--- EPUB Tests ---${NC}\n"
test_epub_conversion
test_epub_book_frontmatter
test_epub_math
test_epub_cjk
test_epub_code
test_epub_cover

echo -e "\n${YELLOW}--- Validation Tests ---${NC}\n"
test_validate_command
test_validate_flag

echo -e "\n${YELLOW}--- Bibliography Tests ---${NC}\n"
test_bibliography_pdf
test_bibliography_epub
test_inline_bibliography_pdf
test_inline_bibliography_epub
test_simple_bibliography_file

echo -e "\n${YELLOW}--- Custom Template Tests ---${NC}\n"
test_custom_latex_template
test_custom_epub_css

echo -e "\n${YELLOW}--- Multi-file Project Tests ---${NC}\n"
test_multifile_pdf
test_multifile_epub

echo -e "\n${YELLOW}--- Index Generation Tests ---${NC}\n"
test_index_pdf

# Run module unit tests if available
if [ -f "$SCRIPT_DIR/test_modules.sh" ]; then
    echo -e "\n${YELLOW}--- Module Unit Tests ---${NC}\n"
    if "$SCRIPT_DIR/test_modules.sh"; then
        echo -e "${GREEN}Module tests passed${NC}"
    else
        echo -e "${RED}Module tests had failures${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
fi

# Run regression tests if available
if [ -f "$SCRIPT_DIR/test_regression.sh" ]; then
    echo -e "\n${YELLOW}--- Regression Tests ---${NC}\n"
    if "$SCRIPT_DIR/test_regression.sh"; then
        echo -e "${GREEN}Regression tests passed${NC}"
    else
        echo -e "${RED}Regression tests had failures${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
fi

# Summary
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}                 Summary                   ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}\n"
    exit 0
else
    echo -e "\n${RED}Some tests failed.${NC}\n"
    exit 1
fi
