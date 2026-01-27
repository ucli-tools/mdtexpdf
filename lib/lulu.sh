#!/bin/bash
# =============================================================================
# mdtexpdf - Lulu.com Print Module
# =============================================================================
# Generates Lulu.com print-ready output:
#   - Interior PDF (correct trim size, no covers)
#   - Cover spread PDF (back + spine + front as single page)
#
# This module provides:
#   - calculate_spine_width() - Compute spine width from page count + paper stock
#   - generate_cover_spread() - Build TikZ-based cover spread and compile to PDF
#   - generate_lulu_output()  - Orchestrator: interior + cover into output directory
#
# Dependencies: lib/core.sh, lib/metadata.sh, lib/convert.sh
# =============================================================================

# Paper thickness per page (inches) by stock type
# Sources: Lulu.com specifications
_LULU_PAPER_CREAM60=0.0025
_LULU_PAPER_WHITE60=0.002
_LULU_PAPER_WHITE80=0.003

# Bleed for Lulu covers (inches on each outside edge)
_LULU_BLEED=0.125

# Calculate spine width from page count and paper stock.
# Arguments:
#   $1 - page_count (integer)
#   $2 - paper_stock (cream60, white60, white80) — default: cream60
# Outputs: spine width in inches (e.g., "0.235")
calculate_spine_width() {
    local page_count="${1:-0}"
    local paper_stock="${2:-cream60}"

    local thickness_per_page
    case "$paper_stock" in
        cream60)  thickness_per_page="$_LULU_PAPER_CREAM60" ;;
        white60)  thickness_per_page="$_LULU_PAPER_WHITE60" ;;
        white80)  thickness_per_page="$_LULU_PAPER_WHITE80" ;;
        *)
            echo -e "${YELLOW}Warning: Unknown paper stock '$paper_stock', using cream60${NC}" >&2
            thickness_per_page="$_LULU_PAPER_CREAM60"
            ;;
    esac

    awk "BEGIN {printf \"%.4f\", $page_count * $thickness_per_page}"
}

# Count pages in an existing PDF file.
# Arguments: $1 - path to PDF file
# Outputs: page count (integer)
_count_pdf_pages() {
    local pdf_file="$1"
    if command -v pdfinfo &>/dev/null; then
        pdfinfo "$pdf_file" 2>/dev/null | grep -i "^Pages:" | awk '{print $2}'
    elif command -v qpdf &>/dev/null; then
        qpdf --show-npages "$pdf_file" 2>/dev/null
    else
        # Fallback: grep the PDF for page count
        grep -c "/Type\s*/Page[^s]" "$pdf_file" 2>/dev/null || echo "0"
    fi
}

# Generate a cover spread PDF (back + spine + front) using TikZ.
# Arguments:
#   $1 - output_pdf: Path for the output cover spread PDF
#   $2 - page_count: Number of interior pages (for spine calculation)
#   $3 - trim_size: Trim size preset (5.5x8.5, 6x9, 7x10, a5)
#   $4 - paper_stock: Paper stock (cream60, white60, white80)
#   $5 - input_dir: Directory containing the book source (for image paths)
# Uses: META_* variables for cover content
# Returns: 0 on success, 1 on failure
generate_cover_spread() {
    local output_pdf="$1"
    local page_count="$2"
    local trim_size="${3:-5.5x8.5}"
    local paper_stock="${4:-cream60}"
    local input_dir="$5"

    # Resolve trim dimensions (inches)
    local trim_w trim_h
    case "$trim_size" in
        5.5x8.5) trim_w="5.5";  trim_h="8.5" ;;
        6x9)     trim_w="6";    trim_h="9" ;;
        7x10)    trim_w="7";    trim_h="10" ;;
        a5)      trim_w="5.83"; trim_h="8.27" ;;
        *)
            echo -e "${RED}Error: Unsupported trim size '$trim_size' for cover spread${NC}"
            return 1
            ;;
    esac

    # Calculate spine width
    local spine_w
    spine_w=$(calculate_spine_width "$page_count" "$paper_stock")
    echo -e "${BLUE}Cover spread: spine width = ${spine_w}\" (${page_count} pages on ${paper_stock})${NC}"

    # Lulu minimum spine width is 0.0625" — if smaller, warn
    local spine_ok
    spine_ok=$(awk "BEGIN {print ($spine_w >= 0.0625) ? 1 : 0}")
    if [ "$spine_ok" = "0" ]; then
        echo -e "${YELLOW}Warning: Spine width ${spine_w}\" is below Lulu minimum (0.0625\"). Spine text may not be printed.${NC}"
    fi

    # Full spread dimensions (with bleed)
    local bleed="$_LULU_BLEED"
    local spread_w spread_h
    spread_w=$(awk "BEGIN {printf \"%.4f\", $trim_w + $spine_w + $trim_w + 2 * $bleed}")
    spread_h=$(awk "BEGIN {printf \"%.4f\", $trim_h + 2 * $bleed}")

    echo -e "${BLUE}Cover spread dimensions: ${spread_w}\" x ${spread_h}\" (trim: ${trim_w}x${trim_h}, spine: ${spine_w}, bleed: ${bleed})${NC}"

    # Resolve cover image paths
    local front_cover_path="" back_cover_path=""

    # Front cover
    if [ -n "$META_COVER_IMAGE" ]; then
        if [ -f "$META_COVER_IMAGE" ]; then
            front_cover_path="$META_COVER_IMAGE"
        elif [ -f "$input_dir/$META_COVER_IMAGE" ]; then
            front_cover_path="$input_dir/$META_COVER_IMAGE"
        fi
    fi
    if [ -z "$front_cover_path" ]; then
        front_cover_path=$(detect_cover_image "$input_dir" "cover" 2>/dev/null)
    fi

    # Back cover
    if [ -n "$META_BACK_COVER_IMAGE" ]; then
        if [ -f "$META_BACK_COVER_IMAGE" ]; then
            back_cover_path="$META_BACK_COVER_IMAGE"
        elif [ -f "$input_dir/$META_BACK_COVER_IMAGE" ]; then
            back_cover_path="$input_dir/$META_BACK_COVER_IMAGE"
        fi
    fi
    if [ -z "$back_cover_path" ]; then
        back_cover_path=$(detect_cover_image "$input_dir" "back" 2>/dev/null)
    fi

    if [ -z "$front_cover_path" ]; then
        echo -e "${RED}Error: No front cover image found for cover spread${NC}"
        return 1
    fi
    if [ -z "$back_cover_path" ]; then
        echo -e "${YELLOW}Warning: No back cover image found, using front cover for back${NC}"
        back_cover_path="$front_cover_path"
    fi

    # Make paths absolute
    front_cover_path=$(realpath "$front_cover_path")
    back_cover_path=$(realpath "$back_cover_path")

    echo -e "${GREEN}Front cover: $front_cover_path${NC}"
    echo -e "${GREEN}Back cover:  $back_cover_path${NC}"

    # Prepare cover text variables (escape LaTeX special characters)
    local cover_title cover_author cover_subtitle
    cover_title=$(echo "$META_TITLE" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
    cover_author=$(echo "$META_AUTHOR" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
    cover_subtitle=""
    if [ -n "$META_SUBTITLE" ] && [ "$META_SUBTITLE" != "null" ]; then
        cover_subtitle=$(echo "$META_SUBTITLE" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
    fi

    # Back cover text content
    local back_text=""
    if [ -n "$META_BACK_COVER_QUOTE" ] && [ "$META_BACK_COVER_QUOTE" != "null" ]; then
        local escaped_quote
        escaped_quote=$(echo "$META_BACK_COVER_QUOTE" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
        back_text="\\textit{\\char\`\`{}${escaped_quote}\\char\`\\'{}}"
        if [ -n "$META_BACK_COVER_QUOTE_SOURCE" ] && [ "$META_BACK_COVER_QUOTE_SOURCE" != "null" ]; then
            local escaped_source
            escaped_source=$(echo "$META_BACK_COVER_QUOTE_SOURCE" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
            back_text="${back_text}\\\\[0.3cm]--- ${escaped_source}"
        fi
    elif [ -n "$META_BACK_COVER_SUMMARY" ] && [ "$META_BACK_COVER_SUMMARY" != "null" ]; then
        back_text=$(echo "$META_BACK_COVER_SUMMARY" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
    elif [ -n "$META_BACK_COVER_TEXT" ] && [ "$META_BACK_COVER_TEXT" != "null" ]; then
        back_text=$(echo "$META_BACK_COVER_TEXT" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
    fi

    # Author bio for back cover
    local back_bio=""
    if [ "$META_BACK_COVER_AUTHOR_BIO" = "true" ] && [ -n "$META_BACK_COVER_AUTHOR_BIO_TEXT" ] && [ "$META_BACK_COVER_AUTHOR_BIO_TEXT" != "null" ]; then
        back_bio=$(echo "$META_BACK_COVER_AUTHOR_BIO_TEXT" | sed 's/&/\\&/g; s/%/\\%/g; s/#/\\#/g; s/\$/\\$/g')
    fi

    # Cover title color
    local title_color="${META_COVER_TITLE_COLOR:-white}"

    # Back cover text color: back_cover_text_color > cover_title_color > white
    local back_text_color="${META_BACK_COVER_TEXT_COLOR:-$title_color}"
    # Auto-inverse fill color for rectangles (white text → black fill, else white fill)
    local back_fill_color="white"
    if [ "$back_text_color" = "white" ]; then
        back_fill_color="black"
    fi
    # Background opacity (configurable, default 0.18)
    local back_bg_opacity="${META_BACK_COVER_TEXT_BACKGROUND_OPACITY:-0.18}"

    # Calculate panel positions (in inches from left edge)
    # Layout: [bleed][back_cover][spine][front_cover][bleed]
    local back_left back_right spine_left spine_right front_left front_right
    back_left="$bleed"
    back_right=$(awk "BEGIN {printf \"%.4f\", $bleed + $trim_w}")
    spine_left="$back_right"
    spine_right=$(awk "BEGIN {printf \"%.4f\", $back_right + $spine_w}")
    front_left="$spine_right"
    front_right=$(awk "BEGIN {printf \"%.4f\", $spine_right + $trim_w}")

    # Center points for panels
    local back_cx back_cy front_cx front_cy spine_cx spine_cy
    back_cx=$(awk "BEGIN {printf \"%.4f\", ($back_left + $back_right) / 2}")
    front_cx=$(awk "BEGIN {printf \"%.4f\", ($front_left + $front_right) / 2}")
    spine_cx=$(awk "BEGIN {printf \"%.4f\", ($spine_left + $spine_right) / 2}")
    back_cy=$(awk "BEGIN {printf \"%.4f\", $spread_h / 2}")
    front_cy="$back_cy"
    spine_cy="$back_cy"

    # Generate the LaTeX document
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local tex_file="$tmp_dir/cover_spread.tex"

    # Pre-compute text overlay positions
    # Front cover: title at 15% from top, author at 12% from bottom
    local front_title_y front_author_y
    front_title_y=$(awk "BEGIN {printf \"%.4f\", $spread_h - $bleed - $trim_h * 0.15}")
    front_author_y=$(awk "BEGIN {printf \"%.4f\", $bleed + $trim_h * 0.12}")

    # Back cover: quote/text at 10% from top, bio at 12% from bottom (wide spacing to avoid overlap)
    local back_title_y back_bio_y
    back_title_y=$(awk "BEGIN {printf \"%.4f\", $spread_h - $bleed - $trim_h * 0.10}")
    back_bio_y=$(awk "BEGIN {printf \"%.4f\", $bleed + $trim_h * 0.12}")

    # Text width for overlays (80% of trim for front, 65% for back)
    local front_text_w back_text_w
    front_text_w=$(awk "BEGIN {printf \"%.4f\", $trim_w * 0.8}")
    back_text_w=$(awk "BEGIN {printf \"%.4f\", $trim_w * 0.65}")

    # Image layout strategy:
    # - Back cover image: fills from 0 to spine_left (back panel only)
    # - Front cover image: fills from spine_left to spread_w (front panel + spine)
    #   This makes the front cover image extend seamlessly through the spine,
    #   so narrow spines show a continuous image rather than a jarring split.

    # Back half: 0 to spine_left
    local back_half_w back_half_cx
    back_half_w=$(awk "BEGIN {printf \"%.4f\", $spine_left}")
    back_half_cx=$(awk "BEGIN {printf \"%.4f\", $spine_left / 2}")

    # Front half: spine_left to spread_w (covers spine + front panel + right bleed)
    local front_half_w front_half_cx
    front_half_w=$(awk "BEGIN {printf \"%.4f\", $spread_w - $spine_left}")
    front_half_cx=$(awk "BEGIN {printf \"%.4f\", $spine_left + ($spread_w - $spine_left) / 2}")

    cat > "$tex_file" << COVEREOF
\\documentclass[12pt]{article}
\\usepackage[paperwidth=${spread_w}in, paperheight=${spread_h}in, margin=0pt]{geometry}
\\usepackage{tikz}
\\usepackage{graphicx}
\\usepackage{fontspec}
\\setmainfont{Latin Modern Roman}
\\pagestyle{empty}

\\begin{document}
\\noindent%
\\begin{tikzpicture}[x=1in, y=1in, every node/.style={inner sep=0pt, outer sep=0pt}]

% === BACK COVER IMAGE (fills back panel: 0 to spine_left) ===
\\begin{scope}
  \\clip (0, 0) rectangle (${spine_left}, ${spread_h});
  \\node at (${back_half_cx}, ${back_cy}) {
    \\includegraphics[width=${back_half_w}in]{${back_cover_path}}
  };
\\end{scope}

% === FRONT COVER IMAGE (extends from spine_left through spine and front panel) ===
\\begin{scope}
  \\clip (${spine_left}, 0) rectangle (${spread_w}, ${spread_h});
  \\node at (${front_half_cx}, ${front_cy}) {
    \\includegraphics[width=${front_half_w}in]{${front_cover_path}}
  };
\\end{scope}
COVEREOF

    # === SPINE TEXT LOGIC ===
    # spine_text metadata: "auto" (default), "true" (force on), "false" (force off)
    # auto: show spine text only if spine width >= 0.5"
    # true: force spine text on, but warn and skip if spine < 0.25" (physically impossible)
    # false: never show spine text
    local spine_text_setting="${META_SPINE_TEXT:-auto}"
    local render_spine_text=false

    case "$spine_text_setting" in
        false)
            echo -e "${BLUE}Spine text: disabled by metadata (spine_text: false)${NC}"
            render_spine_text=false
            ;;
        true)
            local spine_hard_min
            spine_hard_min=$(awk "BEGIN {print ($spine_w >= 0.25) ? 1 : 0}")
            if [ "$spine_hard_min" = "1" ]; then
                render_spine_text=true
                echo -e "${BLUE}Spine text: forced on by metadata (spine width: ${spine_w}\")${NC}"
            else
                echo -e "${YELLOW}Warning: spine_text: true but spine width ${spine_w}\" is below hard minimum (0.25\"). Skipping spine text.${NC}"
                render_spine_text=false
            fi
            ;;
        auto|*)
            local spine_auto_ok
            spine_auto_ok=$(awk "BEGIN {print ($spine_w >= 0.5) ? 1 : 0}")
            if [ "$spine_auto_ok" = "1" ]; then
                render_spine_text=true
                echo -e "${BLUE}Spine text: auto-enabled (spine width: ${spine_w}\" >= 0.5\")${NC}"
            else
                echo -e "${BLUE}Spine text: auto-skipped (spine width: ${spine_w}\" < 0.5\")${NC}"
                render_spine_text=false
            fi
            ;;
    esac

    if [ "$render_spine_text" = "true" ]; then
        # Choose font size based on spine width
        local spine_font="\\small\\bfseries"
        local spine_narrow
        spine_narrow=$(awk "BEGIN {print ($spine_w < 0.75) ? 1 : 0}")
        if [ "$spine_narrow" = "1" ]; then
            spine_font="\\scriptsize\\bfseries"
        fi
        cat >> "$tex_file" << SPINEEOF
% Spine text (rotated 90° clockwise — reads top to bottom per industry standard)
\\node[rotate=-90, text=${title_color}, font=${spine_font}] at (${spine_cx}, ${spine_cy}) {
  ${cover_title} \\hspace{1.5em} ${cover_author}
};
SPINEEOF
    fi

    cat >> "$tex_file" << COVEREOF2

% === FRONT COVER TEXT OVERLAYS ===
% Title (upper portion of front cover)
\\node[text=${title_color}, font=\\Huge\\bfseries, align=center, text width=${front_text_w}in, anchor=north]
  at (${front_cx}, ${front_title_y}) {
  ${cover_title}
COVEREOF2

    # Add subtitle if present
    if [ -n "$cover_subtitle" ]; then
        cat >> "$tex_file" << SUBTITLEEOF
  \\\\[0.4cm]{\\LARGE\\itshape ${cover_subtitle}}
SUBTITLEEOF
    fi

    cat >> "$tex_file" << COVEREOF3
};
COVEREOF3

    # Front cover author (bottom portion)
    local author_pos="${META_COVER_AUTHOR_POSITION:-bottom}"
    if [ "$author_pos" != "none" ]; then
        cat >> "$tex_file" << AUTHOREOF
% Author name (lower portion of front cover)
\\node[text=${title_color}, font=\\Large, anchor=south]
  at (${front_cx}, ${front_author_y}) {
  ${cover_author}
};
AUTHOREOF
    fi

    # === BACK COVER TEXT OVERLAYS ===
    # Conditionally use frosted glass boxes (controlled by back_cover_text_background metadata)
    local use_text_bg="${META_BACK_COVER_TEXT_BACKGROUND:-true}"

    if [ -n "$back_text" ]; then
        if [ "$use_text_bg" = "true" ]; then
            cat >> "$tex_file" << BACKTEXTEOF
% Back cover quote with frosted glass background
\\node[fill=${back_fill_color}, fill opacity=${back_bg_opacity}, text opacity=1, rounded corners=6pt,
  inner sep=0.25in, text=${back_text_color}, font=\\footnotesize, align=center,
  text width=${back_text_w}in, anchor=north]
  at (${back_cx}, ${back_title_y}) {
  ${back_text}
};
BACKTEXTEOF
        else
            cat >> "$tex_file" << BACKTEXTEOF
% Back cover quote (no background)
\\node[text=${back_text_color}, font=\\footnotesize, align=center,
  text width=${back_text_w}in, anchor=north]
  at (${back_cx}, ${back_title_y}) {
  ${back_text}
};
BACKTEXTEOF
        fi
    fi

    if [ -n "$back_bio" ]; then
        if [ "$use_text_bg" = "true" ]; then
            cat >> "$tex_file" << BACKBIOEOF
% Back cover bio with frosted glass background
\\node[fill=${back_fill_color}, fill opacity=${back_bg_opacity}, text opacity=1, rounded corners=6pt,
  inner sep=0.25in, text=${back_text_color}, font=\\scriptsize, align=left,
  text width=${back_text_w}in, anchor=south]
  at (${back_cx}, ${back_bio_y}) {
  {\\small\\bfseries About the Author}\\\\[0.15cm]
  ${back_bio}
};
BACKBIOEOF
        else
            cat >> "$tex_file" << BACKBIOEOF
% Back cover bio (no background)
\\node[text=${back_text_color}, font=\\scriptsize, align=left,
  text width=${back_text_w}in, anchor=south]
  at (${back_cx}, ${back_bio_y}) {
  {\\small\\bfseries About the Author}\\\\[0.15cm]
  ${back_bio}
};
BACKBIOEOF
        fi
    fi

    # Close TikZ and document
    cat >> "$tex_file" << ENDEOF

\\end{tikzpicture}
\\end{document}
ENDEOF

    # Compile to PDF
    echo -e "${YELLOW}Compiling cover spread...${NC}"
    local compile_log="$tmp_dir/compile.log"

    if ! xelatex -interaction=nonstopmode -output-directory="$tmp_dir" "$tex_file" > "$compile_log" 2>&1; then
        echo -e "${RED}Error: Cover spread compilation failed${NC}"
        echo -e "${YELLOW}Log file: $compile_log${NC}"
        tail -20 "$compile_log"
        return 1
    fi

    # Copy output
    local compiled_pdf="$tmp_dir/cover_spread.pdf"
    if [ -f "$compiled_pdf" ]; then
        cp "$compiled_pdf" "$output_pdf"
        echo -e "${GREEN}Cover spread PDF created: $output_pdf${NC}"
    else
        echo -e "${RED}Error: Cover spread PDF not generated${NC}"
        return 1
    fi

    # Cleanup
    rm -rf "$tmp_dir"
    return 0
}

# Generate complete Lulu.com print-ready output.
# Generate lulu_info.txt with Lulu.com setup instructions.
# Arguments:
#   $1 - output_dir: Path to _lulu output directory
#   $2 - base_name: Book base name
#   $3 - trim_size: Trim size code (e.g., "5.5x8.5")
#   $4 - paper_stock: Paper stock code (e.g., "cream60")
#   $5 - page_count: Interior page count
_generate_lulu_info() {
    local output_dir="$1"
    local base_name="$2"
    local trim_size="$3"
    local paper_stock="$4"
    local page_count="$5"

    local info_file="$output_dir/lulu_info.txt"

    # Map trim size to Lulu format name
    local lulu_format lulu_dimensions_in lulu_dimensions_mm
    case "$trim_size" in
        5.5x8.5)
            lulu_format="Digest"
            lulu_dimensions_in="5.5 x 8.5 in"
            lulu_dimensions_mm="140 x 216 mm"
            ;;
        6x9)
            lulu_format="US Trade"
            lulu_dimensions_in="6 x 9 in"
            lulu_dimensions_mm="152 x 229 mm"
            ;;
        7x10)
            lulu_format="Executive"
            lulu_dimensions_in="7 x 10 in"
            lulu_dimensions_mm="178 x 254 mm"
            ;;
        a5)
            lulu_format="A5"
            lulu_dimensions_in="5.83 x 8.27 in"
            lulu_dimensions_mm="148 x 210 mm"
            ;;
        *)
            lulu_format="Custom ($trim_size)"
            lulu_dimensions_in="$trim_size"
            lulu_dimensions_mm=""
            ;;
    esac

    # Map paper stock to Lulu paper description
    local lulu_paper
    case "$paper_stock" in
        cream60) lulu_paper="Cream paper (60# / standard uncoated cream)" ;;
        white60) lulu_paper="White paper (60# / standard uncoated white)" ;;
        white80) lulu_paper="White paper (80# / premium coated white)" ;;
        *) lulu_paper="$paper_stock" ;;
    esac

    # Get book title and author from metadata
    local book_title="${META_TITLE:-$base_name}"
    local book_author="${META_AUTHOR:-}"

    # Calculate spine width for reference
    local spine_width
    spine_width=$(calculate_spine_width "$page_count" "$paper_stock")

    # Determine spine text status for the info file
    local spine_text_info
    local spine_text_setting="${META_SPINE_TEXT:-auto}"
    case "$spine_text_setting" in
        false) spine_text_info="Disabled (spine_text: false)" ;;
        true)
            local _st_ok
            _st_ok=$(awk "BEGIN {print ($spine_width >= 0.25) ? 1 : 0}")
            if [ "$_st_ok" = "1" ]; then
                spine_text_info="Forced on (spine_text: true)"
            else
                spine_text_info="Forced on but skipped — spine too narrow (< 0.25\")"
            fi
            ;;
        *)
            local _st_auto
            _st_auto=$(awk "BEGIN {print ($spine_width >= 0.5) ? 1 : 0}")
            if [ "$_st_auto" = "1" ]; then
                spine_text_info="Auto-enabled (spine >= 0.5\")"
            else
                spine_text_info="Auto-skipped (spine < 0.5\")"
            fi
            ;;
    esac

    cat > "$info_file" << INFOEOF
================================================================================
  LULU.COM PRINT SETUP GUIDE
================================================================================

  Book:         ${book_title}
  Author:       ${book_author}
  Generated:    $(date '+%Y-%m-%d %H:%M')

================================================================================
  FILES
================================================================================

  Interior:     ${base_name}_interior.pdf
                Upload as the book interior / manuscript file.

  Cover:        ${base_name}_cover.pdf
                Upload as the cover file (select "I have my own cover").

================================================================================
  LULU.COM SETTINGS
================================================================================

  Book Size:    ${lulu_format} (${lulu_dimensions_in} / ${lulu_dimensions_mm})
  Page Count:   ${page_count}
  Binding:      Perfect Bound (paperback)
  Paper:        ${lulu_paper}
  Cover Finish: Matte or Glossy (your preference)
  Color:        Black & White interior (or Premium Color if images are present)

================================================================================
  STEP-BY-STEP
================================================================================

  1. Go to https://www.lulu.com/create/print
  2. Select "Print Book"
  3. Book Size: Choose "${lulu_format} (${lulu_dimensions_in} / ${lulu_dimensions_mm})"
  4. Page Count: Enter ${page_count}
  5. Binding: Select "Perfect Bound"
  6. Paper Type: Select appropriate paper (${lulu_paper})
  7. Upload Interior: Upload ${base_name}_interior.pdf
  8. Upload Cover: Select "I have my own cover" and upload ${base_name}_cover.pdf
  9. Review the preview — check margins, spine alignment, and bleed
  10. Proceed to pricing and ordering

================================================================================
  SPECIFICATIONS
================================================================================

  Trim Size:    ${lulu_dimensions_in} (${lulu_dimensions_mm})
  Spine Width:  ${spine_width}" (calculated from ${page_count} pages on ${paper_stock})
  Spine Text:   ${spine_text_info}
  Bleed:        0.125" (3.175mm) on all edges
  Cover Spread: Back + Spine + Front in a single PDF

================================================================================
INFOEOF

    echo -e "${GREEN}Setup guide: $info_file${NC}"
}

# Creates output directory with interior PDF and cover spread PDF.
# Arguments:
#   $1 - input_file: Path to the markdown source
#   $2 - base_output_name: Base name for output (e.g., "my_book")
# Uses: ARG_*, META_* variables
# Returns: 0 on success, 1 on failure
generate_lulu_output() {
    local input_file="$1"
    local base_name="$2"

    # Determine trim size and paper stock
    local trim_size paper_stock
    if [ -n "$ARG_TRIM_SIZE" ]; then
        trim_size="$ARG_TRIM_SIZE"
    elif [ -n "$META_TRIM_SIZE" ]; then
        trim_size="$META_TRIM_SIZE"
    else
        trim_size="5.5x8.5"
    fi

    paper_stock="${META_PAPER_STOCK:-cream60}"

    # Create output directory
    local output_dir
    output_dir="$(dirname "$input_file")/${base_name}_lulu"
    mkdir -p "$output_dir"

    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Generating Lulu.com Print-Ready Output             ║${NC}"
    echo -e "${GREEN}║  Trim: ${trim_size}  Paper: ${paper_stock}                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # --- Step 1: Generate interior PDF (no covers) ---
    echo -e "${YELLOW}Step 1/2: Generating interior PDF...${NC}"
    local interior_pdf="$output_dir/${base_name}_interior.pdf"

    # Set ARG_LULU to ensure covers are suppressed
    ARG_LULU=true
    # Set trim size
    ARG_TRIM_SIZE="$trim_size"
    # Store original output and override
    local original_output="$OUTPUT_FILE"
    OUTPUT_FILE="$interior_pdf"

    # Run the standard PDF generation pipeline (which now uses lulu_mode)
    generate_pdf
    local pdf_result=$?

    # Restore output
    OUTPUT_FILE="$original_output"

    if [ $pdf_result -ne 0 ]; then
        echo -e "${RED}Error: Interior PDF generation failed${NC}"
        return 1
    fi

    if [ ! -f "$interior_pdf" ]; then
        echo -e "${RED}Error: Interior PDF was not created${NC}"
        return 1
    fi

    echo -e "${GREEN}Interior PDF: $interior_pdf${NC}"

    # --- Step 2: Generate cover spread PDF ---
    echo -e "${YELLOW}Step 2/2: Generating cover spread PDF...${NC}"
    local cover_pdf="$output_dir/${base_name}_cover.pdf"

    # Count pages in the interior PDF
    local page_count
    page_count=$(_count_pdf_pages "$interior_pdf")
    if [ -z "$page_count" ] || [ "$page_count" = "0" ]; then
        echo -e "${YELLOW}Warning: Could not count pages in interior PDF, estimating from word count${NC}"
        local word_count
        word_count=$(wc -w < "$input_file" 2>/dev/null || echo "0")
        page_count=$(( word_count / 250 ))
    fi

    echo -e "${BLUE}Interior page count: ${page_count}${NC}"

    local input_dir
    input_dir=$(dirname "$input_file")

    generate_cover_spread "$cover_pdf" "$page_count" "$trim_size" "$paper_stock" "$input_dir"
    local cover_result=$?

    if [ $cover_result -ne 0 ]; then
        echo -e "${RED}Error: Cover spread generation failed${NC}"
        echo -e "${YELLOW}Interior PDF is still available at: $interior_pdf${NC}"
        return 1
    fi

    # --- Generate lulu_info.txt ---
    _generate_lulu_info "$output_dir" "$base_name" "$trim_size" "$paper_stock" "$page_count"

    # --- Summary ---
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Lulu Output Complete!                              ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Directory: ${output_dir}${NC}"
    echo -e "${GREEN}║  Interior:  ${base_name}_interior.pdf (${page_count} pages)${NC}"
    echo -e "${GREEN}║  Cover:     ${base_name}_cover.pdf${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Upload both files to lulu.com to order prints.     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    return 0
}
