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

    if "$MDTEXPDF" convert "$test_md" "$test_pdf" --read-metadata 2>&1; then
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
test_pdf_conversion
test_epub_conversion

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
