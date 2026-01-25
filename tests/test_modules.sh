#!/bin/bash
# =============================================================================
# mdtexpdf Module Unit Tests
# Tests for individual modules in lib/
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
LIB_DIR="$PROJECT_DIR/lib"

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

assert_not_empty() {
    if [ -n "$1" ]; then
        return 0
    else
        echo "Value is empty"
        return 1
    fi
}

assert_empty() {
    if [ -z "$1" ]; then
        return 0
    else
        echo "Expected empty, got: '$1'"
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
# Core Module Tests
# =============================================================================

test_core_loads() {
    test_start "core.sh loads without error"
    (
        source "$LIB_DIR/core.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "core.sh failed to load"
    fi
}

test_core_logging_functions() {
    test_start "core.sh defines logging functions"
    (
        source "$LIB_DIR/core.sh"
        # Check that functions are defined
        type log_verbose &>/dev/null && \
        type log_debug &>/dev/null && \
        type log_error &>/dev/null && \
        type log_warn &>/dev/null && \
        type log_success &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Logging functions not defined"
    fi
}

test_core_colors_defined() {
    test_start "core.sh defines color codes"
    (
        source "$LIB_DIR/core.sh"
        [ -n "$RED" ] && [ -n "$GREEN" ] && [ -n "$BLUE" ] && [ -n "$NC" ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Color codes not defined"
    fi
}

test_core_version_set() {
    test_start "core.sh sets MDTEXPDF_VERSION"
    (
        source "$LIB_DIR/core.sh"
        [ -n "$MDTEXPDF_VERSION" ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "MDTEXPDF_VERSION not set"
    fi
}

test_core_check_command() {
    test_start "core.sh check_command function works"
    (
        source "$LIB_DIR/core.sh"
        # bash should always exist
        check_command bash &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "check_command failed for 'bash'"
    fi
}

# =============================================================================
# Check Module Tests
# =============================================================================

test_check_loads() {
    test_start "check.sh loads without error"
    (
        source "$LIB_DIR/check.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "check.sh failed to load"
    fi
}

test_check_prerequisites_function() {
    test_start "check.sh defines check_prerequisites function"
    (
        source "$LIB_DIR/check.sh"
        type check_prerequisites &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "check_prerequisites not defined"
    fi
}

# =============================================================================
# Metadata Module Tests
# =============================================================================

test_metadata_loads() {
    test_start "metadata.sh loads without error"
    (
        source "$LIB_DIR/metadata.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "metadata.sh failed to load"
    fi
}

test_metadata_init_function() {
    test_start "metadata.sh defines init_metadata_vars function"
    (
        source "$LIB_DIR/metadata.sh"
        type init_metadata_vars &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "init_metadata_vars not defined"
    fi
}

test_metadata_parse_yaml_function() {
    test_start "metadata.sh defines parse_yaml_metadata function"
    (
        source "$LIB_DIR/metadata.sh"
        type parse_yaml_metadata &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "parse_yaml_metadata not defined"
    fi
}

test_metadata_parse_html_function() {
    test_start "metadata.sh defines parse_html_metadata function"
    (
        source "$LIB_DIR/metadata.sh"
        type parse_html_metadata &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "parse_html_metadata not defined"
    fi
}

test_metadata_yaml_parsing() {
    test_start "metadata.sh parses YAML frontmatter correctly"

    # Check if yq is available (required for YAML parsing)
    if ! command -v yq &>/dev/null; then
        echo -e "    ${YELLOW}SKIP${NC}: yq not installed (required for YAML parsing)"
        return
    fi

    # Create test file with YAML frontmatter
    local test_md="$TEST_OUTPUT/test_yaml.md"
    cat > "$test_md" << 'EOF'
---
title: "Test Title"
author: "Test Author"
date: "2026-01-24"
format: "book"
toc: true
---

# Content

Some content here.
EOF

    local result
    result=$(
        source "$LIB_DIR/metadata.sh" 2>/dev/null
        parse_yaml_metadata "$test_md" 2>/dev/null
        echo "TITLE:$META_TITLE|AUTHOR:$META_AUTHOR|FORMAT:$META_FORMAT"
    )

    if echo "$result" | grep -q "TITLE:Test Title" && \
       echo "$result" | grep -q "AUTHOR:Test Author" && \
       echo "$result" | grep -q "FORMAT:book"; then
        test_pass
    else
        test_fail "YAML parsing failed: $result"
    fi

    rm -f "$test_md"
}

test_metadata_init_clears_values() {
    test_start "init_metadata_vars clears all metadata"
    (
        source "$LIB_DIR/metadata.sh"
        META_TITLE="old value"
        META_AUTHOR="old author"
        init_metadata_vars
        [ -z "$META_TITLE" ] && [ -z "$META_AUTHOR" ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "init_metadata_vars did not clear values"
    fi
}

# =============================================================================
# Preprocess Module Tests
# =============================================================================

test_preprocess_loads() {
    test_start "preprocess.sh loads without error"
    (
        source "$LIB_DIR/preprocess.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "preprocess.sh failed to load"
    fi
}

test_preprocess_unicode_function() {
    test_start "preprocess.sh defines detect_unicode_characters function"
    (
        source "$LIB_DIR/preprocess.sh"
        type detect_unicode_characters &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "detect_unicode_characters not defined"
    fi
}

test_preprocess_markdown_function() {
    test_start "preprocess.sh defines preprocess_markdown function"
    (
        source "$LIB_DIR/preprocess.sh"
        type preprocess_markdown &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "preprocess_markdown not defined"
    fi
}

test_preprocess_cover_function() {
    test_start "preprocess.sh defines detect_cover_image function"
    (
        source "$LIB_DIR/preprocess.sh"
        type detect_cover_image &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "detect_cover_image not defined"
    fi
}

test_preprocess_unicode_detection_cjk() {
    test_start "detect_unicode_characters finds CJK content"

    local test_md="$TEST_OUTPUT/test_cjk.md"
    echo "这是中文内容" > "$test_md"

    (
        source "$LIB_DIR/preprocess.sh"
        detect_unicode_characters "$test_md"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Failed to detect CJK characters"
    fi

    rm -f "$test_md"
}

test_preprocess_unicode_detection_ascii() {
    test_start "detect_unicode_characters returns false for ASCII"

    local test_md="$TEST_OUTPUT/test_ascii.md"
    echo "This is plain ASCII content" > "$test_md"

    (
        source "$LIB_DIR/preprocess.sh"
        ! detect_unicode_characters "$test_md"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Incorrectly detected Unicode in ASCII content"
    fi

    rm -f "$test_md"
}

# =============================================================================
# EPUB Module Tests
# =============================================================================

test_epub_loads() {
    test_start "epub.sh loads without error"
    (
        source "$LIB_DIR/epub.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "epub.sh failed to load"
    fi
}

test_epub_spine_function() {
    test_start "epub.sh defines fix_epub_spine_order function"
    (
        source "$LIB_DIR/epub.sh"
        type fix_epub_spine_order &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "fix_epub_spine_order not defined"
    fi
}

test_epub_frontmatter_function() {
    test_start "epub.sh defines generate_epub_frontmatter function"
    (
        source "$LIB_DIR/epub.sh"
        type generate_epub_frontmatter &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "generate_epub_frontmatter not defined"
    fi
}

test_epub_chemistry_function() {
    test_start "epub.sh defines preprocess_epub_chemistry function"
    (
        source "$LIB_DIR/epub.sh"
        type preprocess_epub_chemistry &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "preprocess_epub_chemistry not defined"
    fi
}

test_epub_chemistry_preprocessing() {
    test_start "preprocess_epub_chemistry converts \\ce{} correctly"

    local test_md="$TEST_OUTPUT/test_chem.md"
    echo 'Water is \ce{H2O} and carbon dioxide is \ce{CO2}.' > "$test_md"

    (
        source "$LIB_DIR/epub.sh"
        preprocess_epub_chemistry "$test_md"
        grep -q "H₂O" "$test_md" && grep -q "CO₂" "$test_md"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Chemistry preprocessing failed"
    fi

    rm -f "$test_md"
}

# =============================================================================
# Bibliography Module Tests
# =============================================================================

test_bibliography_loads() {
    test_start "bibliography.sh loads without error"
    (
        source "$LIB_DIR/bibliography.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "bibliography.sh failed to load"
    fi
}

test_bibliography_generate_key_function() {
    test_start "bibliography.sh defines generate_citation_key function"
    (
        source "$LIB_DIR/bibliography.sh"
        type generate_citation_key &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "generate_citation_key not defined"
    fi
}

test_bibliography_key_generation() {
    test_start "generate_citation_key produces correct keys"
    (
        source "$LIB_DIR/bibliography.sh"

        local key1 key2 key3 key4
        key1=$(generate_citation_key "Knuth, Donald E." "1968")
        key2=$(generate_citation_key "Einstein, Albert" "1905")
        key3=$(generate_citation_key "Van Gogh, Vincent" "1888")
        key4=$(generate_citation_key "U.S. Government Accountability Office" "2024")

        [ "$key1" = "knuth1968" ] && \
        [ "$key2" = "einstein1905" ] && \
        [ "$key3" = "vangogh1888" ] && \
        [ "$key4" = "usgovernmentaccountabilityoffice2024" ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Key generation incorrect"
    fi
}

test_bibliography_multi_author_key() {
    test_start "generate_citation_key uses first author for multi-author works"
    (
        source "$LIB_DIR/bibliography.sh"

        local key
        key=$(generate_citation_key "Smith, John and Jones, Mary and Brown, Bob" "2020")
        [ "$key" = "smith2020" ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Multi-author key generation incorrect"
    fi
}

test_bibliography_is_simple_function() {
    test_start "bibliography.sh defines is_simple_bibliography function"
    (
        source "$LIB_DIR/bibliography.sh"
        type is_simple_bibliography &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "is_simple_bibliography not defined"
    fi
}

test_bibliography_detection() {
    test_start "is_simple_bibliography detects markdown bibliography"
    (
        source "$LIB_DIR/bibliography.sh"

        local test_md="$TEST_OUTPUT/test_bib.md"
        echo "- Author: Test Author" > "$test_md"
        echo "  Title: Test Title" >> "$test_md"
        echo "  Year: 2024" >> "$test_md"

        is_simple_bibliography "$test_md"
        local result=$?

        rm -f "$test_md"
        [ $result -eq 0 ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Simple bibliography detection failed"
    fi
}

test_bibliography_convert_function() {
    test_start "bibliography.sh defines convert_simple_bibliography function"
    (
        source "$LIB_DIR/bibliography.sh"
        type convert_simple_bibliography &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "convert_simple_bibliography not defined"
    fi
}

test_bibliography_conversion() {
    test_start "convert_simple_bibliography produces valid JSON"
    (
        source "$LIB_DIR/bibliography.sh"

        local test_md="$TEST_OUTPUT/test_bib_convert.md"
        local test_json="$TEST_OUTPUT/test_bib_convert.json"

        cat > "$test_md" << 'EOF'
- Author: Knuth, Donald E.
  Title: The Art of Computer Programming
  Publisher: Addison-Wesley
  Year: 1968

- Key: custom-key
  Author: Einstein, Albert
  Title: On the Electrodynamics of Moving Bodies
  Journal: Annalen der Physik
  Year: 1905
EOF

        convert_simple_bibliography "$test_md" "$test_json"

        # Check that output is valid JSON with expected content
        [ -f "$test_json" ] && \
        grep -q '"id":"knuth1968"' "$test_json" && \
        grep -q '"id":"custom-key"' "$test_json" && \
        grep -q '"family":"Knuth"' "$test_json" && \
        grep -q '"family":"Einstein"' "$test_json"

        local result=$?
        rm -f "$test_md" "$test_json"
        [ $result -eq 0 ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Simple bibliography conversion failed"
    fi
}

test_bibliography_fixture() {
    test_start "convert_simple_bibliography handles bibliography fixture"

    # Save paths before sourcing (bibliography.sh may override SCRIPT_DIR)
    local fixture="$SCRIPT_DIR/fixtures/simple_bibliography.md"
    local test_json="$TEST_OUTPUT/example_bib.json"

    (
        source "$LIB_DIR/bibliography.sh"

        if [ ! -f "$fixture" ]; then
            echo "Fixture not found: $fixture"
            exit 1
        fi

        convert_simple_bibliography "$fixture" "$test_json"

        # Check for expected keys
        [ -f "$test_json" ] && \
        grep -q '"id":"smith1950"' "$test_json" && \
        grep -q '"id":"report2024"' "$test_json" && \
        grep -q '"id":"research2018"' "$test_json" && \
        grep -q '"id":"news2025"' "$test_json" && \
        grep -q '"id":"wiki:example"' "$test_json"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Bibliography fixture conversion failed"
    fi

    rm -f "$test_json"
}

test_bibliography_has_inline_function() {
    test_start "bibliography.sh defines has_inline_bibliography function"
    (
        source "$LIB_DIR/bibliography.sh"
        type has_inline_bibliography &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "has_inline_bibliography not defined"
    fi
}

test_bibliography_inline_detection() {
    test_start "has_inline_bibliography detects inline references"

    local test_md="$TEST_OUTPUT/test_inline_detect.md"

    cat > "$test_md" << 'EOF'
---
title: Test
---

# Introduction

Some text [@smith2024].

# References

- Author: Smith, John
  Title: A Book
  Year: 2024
EOF

    (
        source "$LIB_DIR/bibliography.sh"
        has_inline_bibliography "$test_md"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Failed to detect inline bibliography"
    fi

    rm -f "$test_md"
}

test_bibliography_extract_function() {
    test_start "bibliography.sh defines extract_inline_bibliography function"
    (
        source "$LIB_DIR/bibliography.sh"
        type extract_inline_bibliography &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "extract_inline_bibliography not defined"
    fi
}

test_bibliography_inline_extraction() {
    test_start "extract_inline_bibliography separates content and bibliography"

    local test_md="$TEST_OUTPUT/test_inline_extract.md"
    local test_bib="$TEST_OUTPUT/test_extracted_bib.md"
    local test_content="$TEST_OUTPUT/test_extracted_content.md"

    cat > "$test_md" << 'EOF'
---
title: Test
---

# Chapter 1

Content here [@smith2024].

# References

- Author: Smith, John
  Title: A Book
  Year: 2024
EOF

    (
        source "$LIB_DIR/bibliography.sh"
        extract_inline_bibliography "$test_md" "$test_bib" "$test_content" && \
        grep -q "Author: Smith" "$test_bib" && \
        grep -q "Chapter 1" "$test_content" && \
        ! grep -q "Author: Smith" "$test_content"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Inline extraction failed"
    fi

    rm -f "$test_md" "$test_bib" "$test_content"
}

test_bibliography_process_inline() {
    test_start "process_inline_bibliography produces CSL-JSON"

    local test_md="$TEST_OUTPUT/test_process_inline.md"

    cat > "$test_md" << 'EOF'
# Intro

Text [@smith2024].

# References

- Author: Smith, John
  Title: A Book
  Year: 2024
EOF

    (
        source "$LIB_DIR/bibliography.sh"
        local json_path
        json_path=$(process_inline_bibliography "$test_md" "$TEST_OUTPUT")
        [ -n "$json_path" ] && \
        [ -f "$json_path" ] && \
        grep -q '"id":"smith2024"' "$json_path"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "process_inline_bibliography failed"
    fi

    rm -f "$test_md" "$TEST_OUTPUT/bibliography.json" "$TEST_OUTPUT/extracted_bib.md" "$TEST_OUTPUT/content.md"
}

# =============================================================================
# Template Module Tests
# =============================================================================

test_template_loads() {
    test_start "template.sh loads without error"
    (
        source "$LIB_DIR/template.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "template.sh failed to load"
    fi
}

test_template_create_function() {
    test_start "template.sh defines create_template_file function"
    (
        source "$LIB_DIR/template.sh"
        type create_template_file &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "create_template_file not defined"
    fi
}

test_template_creation() {
    test_start "create_template_file generates valid LaTeX template"

    local test_template="$TEST_OUTPUT/test_template.tex"

    (
        # Set required globals
        PDF_ENGINE="pdflatex"
        ARG_TOC_DEPTH=2

        source "$LIB_DIR/template.sh"
        create_template_file "$test_template" "Footer" "Test Title" "Test Author" "" "true" "article" "default"

        # Verify template has expected content
        [ -f "$test_template" ] && \
        grep -q '\\documentclass' "$test_template" && \
        grep -q '\\begin{document}' "$test_template" && \
        grep -q '\\end{document}' "$test_template" && \
        grep -q '\\usepackage{geometry}' "$test_template"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Template creation failed"
    fi

    rm -f "$test_template"
}

test_template_book_format() {
    test_start "create_template_file supports book format"

    local test_template="$TEST_OUTPUT/test_book_template.tex"

    (
        PDF_ENGINE="xelatex"
        ARG_TOC_DEPTH=3

        source "$LIB_DIR/template.sh"
        create_template_file "$test_template" "" "Book Title" "Author" "" "true" "book" "all"

        [ -f "$test_template" ] && \
        grep -q '{book}' "$test_template" && \
        grep -q 'titlesec' "$test_template"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Book format template creation failed"
    fi

    rm -f "$test_template"
}

# =============================================================================
# PDF Module Tests
# =============================================================================

test_pdf_loads() {
    test_start "pdf.sh loads without error"
    (
        source "$LIB_DIR/pdf.sh"
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "pdf.sh failed to load"
    fi
}

test_pdf_detect_unicode_function() {
    test_start "pdf.sh defines detect_unicode_characters function"
    (
        source "$LIB_DIR/pdf.sh"
        type detect_unicode_characters &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "detect_unicode_characters not defined"
    fi
}

test_pdf_detect_cover_function() {
    test_start "pdf.sh defines detect_cover_image function"
    (
        source "$LIB_DIR/pdf.sh"
        type detect_cover_image &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "detect_cover_image not defined"
    fi
}

test_pdf_truncate_address_function() {
    test_start "pdf.sh defines truncate_address function"
    (
        source "$LIB_DIR/pdf.sh"
        type truncate_address &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "truncate_address not defined"
    fi
}

test_pdf_truncate_address_output() {
    test_start "truncate_address truncates long addresses correctly"
    (
        source "$LIB_DIR/pdf.sh"

        local result1 result2

        # Long address should be truncated
        result1=$(truncate_address "0x1234567890abcdef1234567890abcdef12345678" 4)
        [ "$result1" = "0x12...5678" ] || exit 1

        # Short address should not be truncated
        result2=$(truncate_address "short" 4)
        [ "$result2" = "short" ] || exit 1
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "truncate_address output incorrect"
    fi
}

test_pdf_find_lua_filter_function() {
    test_start "pdf.sh defines find_lua_filter function"
    (
        source "$LIB_DIR/pdf.sh"
        type find_lua_filter &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "find_lua_filter not defined"
    fi
}

test_pdf_cleanup_function() {
    test_start "pdf.sh defines cleanup_pdf_generation function"
    (
        source "$LIB_DIR/pdf.sh"
        type cleanup_pdf_generation &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "cleanup_pdf_generation not defined"
    fi
}

# =============================================================================
# Module Interaction Tests
# =============================================================================

test_all_modules_load_together() {
    test_start "All modules can be loaded together without conflict"
    (
        source "$LIB_DIR/core.sh"
        source "$LIB_DIR/check.sh"
        source "$LIB_DIR/metadata.sh"
        source "$LIB_DIR/preprocess.sh"
        source "$LIB_DIR/epub.sh"
        source "$LIB_DIR/bibliography.sh"
        source "$LIB_DIR/template.sh"
        source "$LIB_DIR/pdf.sh"

        # Verify key functions from each module are available
        type log_verbose &>/dev/null && \
        type check_prerequisites &>/dev/null && \
        type parse_yaml_metadata &>/dev/null && \
        type fix_epub_spine_order &>/dev/null && \
        type create_template_file &>/dev/null && \
        type detect_unicode_characters &>/dev/null && \
        type detect_cover_image &>/dev/null
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Modules have conflicts when loaded together"
    fi
}

test_module_version_consistency() {
    test_start "MDTEXPDF_VERSION is consistent across modules"
    (
        source "$LIB_DIR/core.sh"
        local core_version="$MDTEXPDF_VERSION"

        # Reset and reload through other modules
        unset MDTEXPDF_VERSION
        source "$LIB_DIR/metadata.sh"
        [ "$MDTEXPDF_VERSION" = "$core_version" ]
    )
    if [ $? -eq 0 ]; then
        test_pass
    else
        test_fail "Version mismatch between modules"
    fi
}

# =============================================================================
# Main
# =============================================================================

echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}      mdtexpdf Module Unit Tests           ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

# Check that lib directory exists
if [ ! -d "$LIB_DIR" ]; then
    echo -e "${RED}Error: lib/ directory not found at $LIB_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}--- Core Module Tests ---${NC}\n"
test_core_loads
test_core_logging_functions
test_core_colors_defined
test_core_version_set
test_core_check_command

echo -e "\n${YELLOW}--- Check Module Tests ---${NC}\n"
test_check_loads
test_check_prerequisites_function

echo -e "\n${YELLOW}--- Metadata Module Tests ---${NC}\n"
test_metadata_loads
test_metadata_init_function
test_metadata_parse_yaml_function
test_metadata_parse_html_function
test_metadata_yaml_parsing
test_metadata_init_clears_values

echo -e "\n${YELLOW}--- Preprocess Module Tests ---${NC}\n"
test_preprocess_loads
test_preprocess_unicode_function
test_preprocess_markdown_function
test_preprocess_cover_function
test_preprocess_unicode_detection_cjk
test_preprocess_unicode_detection_ascii

echo -e "\n${YELLOW}--- EPUB Module Tests ---${NC}\n"
test_epub_loads
test_epub_spine_function
test_epub_frontmatter_function
test_epub_chemistry_function
test_epub_chemistry_preprocessing

echo -e "\n${YELLOW}--- Bibliography Module Tests ---${NC}\n"
test_bibliography_loads
test_bibliography_generate_key_function
test_bibliography_key_generation
test_bibliography_multi_author_key
test_bibliography_is_simple_function
test_bibliography_detection
test_bibliography_convert_function
test_bibliography_conversion
test_bibliography_fixture
test_bibliography_has_inline_function
test_bibliography_inline_detection
test_bibliography_extract_function
test_bibliography_inline_extraction
test_bibliography_process_inline

echo -e "\n${YELLOW}--- Template Module Tests ---${NC}\n"
test_template_loads
test_template_create_function
test_template_creation
test_template_book_format

echo -e "\n${YELLOW}--- PDF Module Tests ---${NC}\n"
test_pdf_loads
test_pdf_detect_unicode_function
test_pdf_detect_cover_function
test_pdf_truncate_address_function
test_pdf_truncate_address_output
test_pdf_find_lua_filter_function
test_pdf_cleanup_function

echo -e "\n${YELLOW}--- Module Interaction Tests ---${NC}\n"
test_all_modules_load_together
test_module_version_consistency

# Summary
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}                 Summary                   ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All module tests passed!${NC}\n"
    exit 0
else
    echo -e "\n${RED}Some module tests failed.${NC}\n"
    exit 1
fi
