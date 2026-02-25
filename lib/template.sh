#!/bin/bash
# =============================================================================
# mdtexpdf - Template Module
# =============================================================================
# LaTeX template generation for PDF output
#
# This module provides:
#   - create_template_file() - Generate LaTeX template with all features
#
# Dependencies: lib/core.sh (for logging functions)
# =============================================================================

# Function to create a template.tex file
# Arguments:
#   $1 - template_path: Path where template will be written
#   $2 - footer_text: Custom footer text
#   $3 - doc_title: Document title
#   $4 - doc_author: Document author
#   $5 - date_footer: Date for footer
#   $6 - section_numbers: "true" or "false" (default: true)
#   $7 - format: "article" or "book" (default: article)
#   $8 - header_footer_policy: "default", "partial", or "all" (default: content-only)
#
# Returns: 0 on success, non-zero on failure
create_template_file() {
    local template_path="$1"
    local footer_text="$2"
    local doc_title="$3"
    local doc_author="$4"
    local date_footer="$5"
    local section_numbers="${6:-true}"
    local format="${7:-article}"
    local header_footer_policy="${8:-content-only}"

    # Use default values if not provided
    doc_title=${doc_title:-"Title"}
    doc_author=${doc_author:-"Author"}

    # Determine if we're using XeLaTeX or LuaLaTeX
    local use_unicode_math=false
    if [ "$PDF_ENGINE" = "xelatex" ] || [ "$PDF_ENGINE" = "lualatex" ]; then
        use_unicode_math=true
    fi

    # Determine if we should number sections
    local numbering_commands=""
    if [ "$section_numbers" = "false" ]; then
        # secnumdepth=-2 suppresses all numbering including "Chapter N" prefix
        # \chaptername{} removes the word "Chapter" from chapter headings
        numbering_commands="\\setcounter{secnumdepth}{-2}\\renewcommand{\\chaptername}{}"
    fi

    # Suppress automatic figure numbering when document has its own numbering
    # (e.g., "Figure 1.1.9 --" in alt text from Word documents)
    local figure_numbering_commands=""
    figure_numbering_commands="\$if(no_figure_numbers)\$"
    figure_numbering_commands+="\\renewcommand{\\figurename}{}\\renewcommand{\\thefigure}{}\\captionsetup[figure]{labelformat=empty}"
    figure_numbering_commands+="\$endif\$"

    # Simplified title page logic - always use \maketitle
    local title_page_logic="\$if(title)\$\\maketitle\$endif\$"

    # Set document class and book-specific commands based on format
    local docclass_opts="12pt"
    local docclass="article"
    local book_specific_commands=""
    if [ "$format" = "book" ]; then
        docclass="book"
        # Use openright (chapters on recto/odd pages) or openany based on metadata
        # This will be controlled by Pandoc variable chapters_on_recto
        book_specific_commands=$(cat << 'BOOK_CMDS_EOF'
% Custom styling for book format
\usepackage{titlesec}
\usepackage{titling}

% Style for Part and Chapter headings
\titleformat{\part}[display]
  {\normalfont\huge\bfseries\filcenter\thispagestyle{plain}}
  {\partname~\thepart}
  {20pt}
  {\Huge}
\titlespacing*{\part}{0pt}{50pt}{40pt}

\titleformat{\chapter}[display]
  {\normalfont\huge\bfseries\thispagestyle{plain}}
  {\chaptertitlename~\thechapter}
  {20pt}
  {\Huge}
\titlespacing*{\chapter}{0pt}{50pt}{40pt}

% Style for the main title page (title, author, and date) - centered vertically
\pretitle{\begin{center}\vspace*{\fill}\normalfont\huge\bfseries}
\posttitle{%
  \par
$if(subtitle)$
  \vspace{0.25em}{\LARGE\itshape $subtitle$}\par
$endif$
  \end{center}\vskip 3em}
\preauthor{\begin{center}\normalfont\large}
\postauthor{\par\end{center}\vskip 1em}
\predate{\begin{center}\normalfont\large}
\postdate{\par\end{center}\vspace*{\fill}}
BOOK_CMDS_EOF
)
    else
        # For article format, add custom heading formatting to ensure proper line breaks
        book_specific_commands=""
    fi

    cat > "$template_path" << EOF
    % Document class with conditional font size and openright for chapters on recto (odd pages)
    \$if(chapters_on_recto)\$
    \documentclass[\$if(trim_fontsize)\$\$trim_fontsize\$\$else\$${docclass_opts}\$endif\$, openright]{$docclass}
    \$else\$
    \documentclass[\$if(trim_fontsize)\$\$trim_fontsize\$\$else\$${docclass_opts}\$endif\$, openany]{$docclass}
    \$endif\$

    % Conditional packages based on LaTeX engine
    \\usepackage{iftex}
    \\ifluatex
        % LuaLaTeX-specific setup
        \\usepackage{fontspec}
        % Load fonts with Unicode support
        \\setmainfont{Latin Modern Roman}[Ligatures=TeX]
        \\setsansfont{Latin Modern Sans}[Ligatures=TeX]
        \\setmonofont{Latin Modern Mono}[Ligatures=TeX]
    \\else
        \\ifxetex
            % XeLaTeX-specific setup
            \\usepackage{fontspec}
            % Load fonts with Unicode support
            \\setmainfont{Latin Modern Roman}[Ligatures=TeX]
            \\setsansfont{Latin Modern Sans}[Ligatures=TeX]
            \\setmonofont{Latin Modern Mono}[Ligatures=TeX]

            % Additional Unicode font setup for CJK characters (after packages are loaded)
            % Use xeCJK with minimal punctuation interference to preserve Western quote formatting
            \\usepackage{xeCJK}
            \\setCJKmainfont{Noto Sans CJK SC}
            \\setCJKsansfont{Noto Sans CJK SC}
            \\setCJKmonofont{Noto Sans Mono CJK SC}
            % Configure xeCJK to minimize punctuation effects
            \\xeCJKsetup{
                AutoFakeBold=false,
                AutoFakeSlant=false,
                CheckSingle=false,
                PunctStyle=plain
            }
            % Declare Western quotation marks as Default class so xeCJK doesn't process them
            % This preserves Western quote formatting even when CJK characters are present
            \\xeCJKDeclareCharClass{Default}{"0022}  % ASCII double quote "
            \\xeCJKDeclareCharClass{Default}{"0027}  % ASCII single quote '
            \\xeCJKDeclareCharClass{Default}{"2018}  % Left single quotation mark '
            \\xeCJKDeclareCharClass{Default}{"2019}  % Right single quotation mark '
            \\xeCJKDeclareCharClass{Default}{"201C}  % Left double quotation mark "
            \\xeCJKDeclareCharClass{Default}{"201D}  % Right double quotation mark "
            \\xeCJKDeclareCharClass{Default}{"2032}  % Prime '
            \\xeCJKDeclareCharClass{Default}{"2033}  % Double prime ″
        \\else
            % pdfLaTeX-specific setup
            \\usepackage[utf8]{inputenc}
            \\usepackage[T1]{fontenc}
            \\usepackage{lmodern}  % Load Latin Modern fonts (scalable)
        \\fi
    \\fi
    \\usepackage{geometry}
    \\usepackage{fancyhdr}
    \\usepackage{lastpage} % For page X of Y numbering
    \\usepackage{graphicx}
    \\usepackage{amsmath}
    \\usepackage{mathtools}  % Extends amsmath: paired delimiters, cases*, etc.
    \\usepackage{amssymb}
    \\usepackage{amsthm}   % For theorem and proof environments
    \\usepackage{dutchcal}  % DCTX Calligraphic: extends \\mathcal to lowercase a-z
    \\usepackage{makeidx}  % For index generation (must load before hyperref)
    \\usepackage{hyperref}
    \\usepackage{xcolor}
    \\usepackage{longtable}
    \\usepackage{booktabs}
    \\usepackage{array}
    \\usepackage{calc}
    \\usepackage{etoolbox}
    \\usepackage{upquote}
    \\usepackage{newunicodechar}
    \\usepackage{textcomp}
    \\usepackage{fancyvrb}
    \\usepackage{listings}
    \\usepackage{float}
    \\raggedbottom
    \\usepackage[protrusion=false,expansion=false]{microtype}  % Disable font expansion
    \\usepackage{enumitem}
    \\usepackage[version=4]{mhchem}
    \\usepackage{framed}   % For snugshade environment
    \\usepackage[titles]{tocloft}  % For TOC customization (titles option for titlesec compatibility)

    % TOC page number formatting (book format only — article has no \chapter)
    \$if(format_book)\$
    % Part-level entries always get bold/large page numbers
    \\renewcommand{\\cftpartpagefont}{\\bfseries\\large}
    \$if(has_parts)\$
    % With parts: chapter entries get normal-weight, normal-size page numbers
    \\renewcommand{\\cftchappagefont}{\\normalfont\\normalsize}
    \$else\$
    % Without parts: all entries are chapter-level, make them bold/large
    \\renewcommand{\\cftchappagefont}{\\bfseries\\large}
    \$endif\$
    \$endif\$

    \\usepackage{hyphenat}  % For \\nohyphens command (disable hyphenation in titles)

    % TikZ for cover pages, diagrams, and mathematical illustrations
    \\usepackage{tikz}
    \\usetikzlibrary{positioning,arrows.meta,decorations.markings,decorations.pathreplacing,calc,patterns}
    \\usepackage{pgfplots}
    \\pgfplotsset{compat=1.17}
    \\usepgfplotslibrary{fillbetween}

    % Rotating package for margin provenance text
    \\usepackage{rotating}

    % Drop caps support (conditional)
    \$if(drop_caps)\$
    \\usepackage{lettrine}
    \\setcounter{DefaultLines}{3}
    \\renewcommand{\\DefaultLoversize}{0.1}
    \\renewcommand{\\DefaultLraise}{0}
    \$endif\$
    $book_specific_commands

    % Define \\real command if it doesn't exist (alternative to realnum package)
    \\providecommand{\\real}[1]{#1}

    % Define \\arraybackslash if it doesn't exist
    \\providecommand{\\arraybackslash}{\\let\\\\\\tabularnewline}

    % Define \\pandocbounded command used by Pandoc for complex math expressions
    \\providecommand{\\pandocbounded}[1]{\\ensuremath{#1}}

    % Define \\passthrough command, sometimes used by Pandoc with --listings
    \\providecommand{\\passthrough}[1]{#1}

    % Define common mathematical Unicode characters
    \\ifluatex\\else\\ifxetex\\else
        % These definitions are only needed for pdfLaTeX
        % For XeLaTeX and LuaLaTeX, unicode-math handles these
        \\usepackage{accents}  % For vector arrows and other accents

        % U+20D1 COMBINING RIGHT HARPOON ABOVE
        \\newunicodechar{⃑}{\\vec}

        % Greek letters - lowercase (text mode compatible)
        \\newunicodechar{α}{\\ensuremath{\\alpha}}
        \\newunicodechar{β}{\\ensuremath{\\beta}}
        \\newunicodechar{γ}{\\ensuremath{\\gamma}}
        \\newunicodechar{δ}{\\ensuremath{\\delta}}
        \\newunicodechar{ε}{\\ensuremath{\\varepsilon}}
        \\newunicodechar{ζ}{\\ensuremath{\\zeta}}
        \\newunicodechar{η}{\\ensuremath{\\eta}}
        \\newunicodechar{θ}{\\ensuremath{\\theta}}
        \\newunicodechar{ι}{\\ensuremath{\\iota}}
        \\newunicodechar{κ}{\\ensuremath{\\kappa}}
        \\newunicodechar{λ}{\\ensuremath{\\lambda}}
        \\newunicodechar{μ}{\\ensuremath{\\mu}}
        \\newunicodechar{ν}{\\ensuremath{\\nu}}
        \\newunicodechar{ξ}{\\ensuremath{\\xi}}
        \\newunicodechar{ο}{o}
        \\newunicodechar{π}{\\ensuremath{\\pi}}
        \\newunicodechar{ρ}{\\ensuremath{\\rho}}
        \\newunicodechar{σ}{\\ensuremath{\\sigma}}
        \\newunicodechar{τ}{\\ensuremath{\\tau}}
        \\newunicodechar{υ}{\\ensuremath{\\upsilon}}
        \\newunicodechar{φ}{\\ensuremath{\\phi}}
        \\newunicodechar{χ}{\\ensuremath{\\chi}}
        \\newunicodechar{ψ}{\\ensuremath{\\psi}}
        \\newunicodechar{ω}{\\ensuremath{\\omega}}

        % Greek letters - uppercase (text mode compatible)
        \\newunicodechar{Α}{A}
        \\newunicodechar{Β}{B}
        \\newunicodechar{Γ}{\\ensuremath{\\Gamma}}
        \\newunicodechar{Δ}{\\ensuremath{\\Delta}}
        \\newunicodechar{Ε}{E}
        \\newunicodechar{Ζ}{Z}
        \\newunicodechar{Η}{H}
        \\newunicodechar{Θ}{\\ensuremath{\\Theta}}
        \\newunicodechar{Ι}{I}
        \\newunicodechar{Κ}{K}
        \\newunicodechar{Λ}{\\ensuremath{\\Lambda}}
        \\newunicodechar{Μ}{M}
        \\newunicodechar{Ν}{N}
        \\newunicodechar{Ξ}{\\ensuremath{\\Xi}}
        \\newunicodechar{Ο}{O}
        \\newunicodechar{Π}{\\ensuremath{\\Pi}}
        \\newunicodechar{Ρ}{P}
        \\newunicodechar{Σ}{\\ensuremath{\\Sigma}}
        \\newunicodechar{Τ}{T}
        \\newunicodechar{Υ}{\\ensuremath{\\Upsilon}}
        \\newunicodechar{Φ}{\\ensuremath{\\Phi}}
        \\newunicodechar{Χ}{X}
        \\newunicodechar{Ψ}{\\ensuremath{\\Psi}}
        \\newunicodechar{Ω}{\\ensuremath{\\Omega}}

        % Additional Greek letter variants (text mode compatible)
        \\newunicodechar{ϑ}{\\ensuremath{\\vartheta}}
        \\newunicodechar{ϕ}{\\ensuremath{\\varphi}}
        \\newunicodechar{ϖ}{\\ensuremath{\\varpi}}
        \\newunicodechar{ϱ}{\\ensuremath{\\varrho}}
        \\newunicodechar{ς}{\\ensuremath{\\varsigma}}
        \\newunicodechar{ϵ}{\\ensuremath{\\epsilon}}
        \\newunicodechar{ϰ}{\\ensuremath{\\varkappa}}

        % Greek letters with accents (tonos)
        \\newunicodechar{ά}{\\ensuremath{\\acute{\\alpha}}}
        \\newunicodechar{έ}{\\ensuremath{\\acute{\\varepsilon}}}
        \\newunicodechar{ή}{\\ensuremath{\\acute{\\eta}}}
        \\newunicodechar{ί}{\\ensuremath{\\acute{\\iota}}}
        \\newunicodechar{ό}{\\ensuremath{\\acute{o}}}
        \\newunicodechar{ύ}{\\ensuremath{\\acute{\\upsilon}}}
        \\newunicodechar{ώ}{\\ensuremath{\\acute{\\omega}}}
        \\newunicodechar{Ά}{\\ensuremath{\\acute{A}}}
        \\newunicodechar{Έ}{\\ensuremath{\\acute{E}}}
        \\newunicodechar{Ή}{\\ensuremath{\\acute{H}}}
        \\newunicodechar{Ί}{\\ensuremath{\\acute{I}}}
        \\newunicodechar{Ό}{\\ensuremath{\\acute{O}}}
        \\newunicodechar{Ύ}{\\ensuremath{\\acute{\\Upsilon}}}
        \\newunicodechar{Ώ}{\\ensuremath{\\acute{\\Omega}}}

        % Greek Extended block (U+1F00-U+1FFF) - polytonic diacritics
        % Vowels with smooth breathing (psili)
        \\newunicodechar{ἀ}{\\ensuremath{\\alpha}}
        \\newunicodechar{ἐ}{\\ensuremath{\\varepsilon}}
        \\newunicodechar{ἠ}{\\ensuremath{\\eta}}
        \\newunicodechar{ἰ}{\\ensuremath{\\iota}}
        \\newunicodechar{ὀ}{\\ensuremath{o}}
        \\newunicodechar{ὐ}{\\ensuremath{\\upsilon}}
        \\newunicodechar{ὠ}{\\ensuremath{\\omega}}
        % Vowels with rough breathing (dasia)
        \\newunicodechar{ἁ}{\\ensuremath{\\alpha}}
        \\newunicodechar{ἑ}{\\ensuremath{\\varepsilon}}
        \\newunicodechar{ἡ}{\\ensuremath{\\eta}}
        \\newunicodechar{ἱ}{\\ensuremath{\\iota}}
        \\newunicodechar{ὁ}{\\ensuremath{o}}
        \\newunicodechar{ὑ}{\\ensuremath{\\upsilon}}
        \\newunicodechar{ὡ}{\\ensuremath{\\omega}}
        % Vowels with perispomeni (circumflex)
        \\newunicodechar{ᾶ}{\\ensuremath{\\hat{\\alpha}}}
        \\newunicodechar{ῆ}{\\ensuremath{\\hat{\\eta}}}
        \\newunicodechar{ῖ}{\\ensuremath{\\hat{\\iota}}}
        \\newunicodechar{ῦ}{\\ensuremath{\\hat{\\upsilon}}}
        \\newunicodechar{ῶ}{\\ensuremath{\\hat{\\omega}}}
        % Vowels with acute accent (oxia)
        \\newunicodechar{ά}{\\ensuremath{\\acute{\\alpha}}}
        \\newunicodechar{έ}{\\ensuremath{\\acute{\\varepsilon}}}
        \\newunicodechar{ή}{\\ensuremath{\\acute{\\eta}}}
        \\newunicodechar{ί}{\\ensuremath{\\acute{\\iota}}}
        \\newunicodechar{ό}{\\ensuremath{\\acute{o}}}
        \\newunicodechar{ύ}{\\ensuremath{\\acute{\\upsilon}}}
        \\newunicodechar{ώ}{\\ensuremath{\\acute{\\omega}}}
        % Vowels with grave accent (varia)
        \\newunicodechar{ὰ}{\\ensuremath{\\grave{\\alpha}}}
        \\newunicodechar{ὲ}{\\ensuremath{\\grave{\\varepsilon}}}
        \\newunicodechar{ὴ}{\\ensuremath{\\grave{\\eta}}}
        \\newunicodechar{ὶ}{\\ensuremath{\\grave{\\iota}}}
        \\newunicodechar{ὸ}{\\ensuremath{\\grave{o}}}
        \\newunicodechar{ὺ}{\\ensuremath{\\grave{\\upsilon}}}
        \\newunicodechar{ὼ}{\\ensuremath{\\grave{\\omega}}}
        % Rho with breathing marks
        \\newunicodechar{ῤ}{\\ensuremath{\\rho}}
        \\newunicodechar{ῥ}{\\ensuremath{\\rho}}
        % Iota subscript forms
        \\newunicodechar{ᾳ}{\\ensuremath{\\alpha}}
        \\newunicodechar{ῃ}{\\ensuremath{\\eta}}
        \\newunicodechar{ῳ}{\\ensuremath{\\omega}}

        % Define Unicode box-drawing characters for pdfLaTeX
        \\newunicodechar{├}{\\texttt{|--}}
        \\newunicodechar{│}{\\texttt{|}}
        \\newunicodechar{└}{\\texttt{$(printf %s '\`')--}}
        \\newunicodechar{─}{\\texttt{-}}
        % Mathematical symbols (text mode compatible)
        \\newunicodechar{ℝ}{\\ensuremath{\\mathbb{R}}}
        \\newunicodechar{ℤ}{\\ensuremath{\\mathbb{Z}}}
        \\newunicodechar{ℕ}{\\ensuremath{\\mathbb{N}}}
        \\newunicodechar{ℚ}{\\ensuremath{\\mathbb{Q}}}
        \\newunicodechar{ℂ}{\\ensuremath{\\mathbb{C}}}
        \\newunicodechar{∞}{\\ensuremath{\\infty}}
        \\newunicodechar{∫}{\\ensuremath{\\int}}
        \\newunicodechar{∑}{\\ensuremath{\\sum}}
        \\newunicodechar{∏}{\\ensuremath{\\prod}}
        \\newunicodechar{√}{\\ensuremath{\\sqrt}}
        \\newunicodechar{∂}{\\ensuremath{\\partial}}
        \\newunicodechar{∇}{\\ensuremath{\\nabla}}
        \\newunicodechar{∆}{\\ensuremath{\\Delta}}
        \\newunicodechar{∈}{\\ensuremath{\\in}}
        \\newunicodechar{∉}{\\ensuremath{\\notin}}
        \\newunicodechar{∋}{\\ensuremath{\\ni}}
        \\newunicodechar{⊂}{\\ensuremath{\\subset}}
        \\newunicodechar{⊃}{\\ensuremath{\\supset}}
        \\newunicodechar{⊆}{\\ensuremath{\\subseteq}}
        \\newunicodechar{⊇}{\\ensuremath{\\supseteq}}
        \\newunicodechar{∪}{\\ensuremath{\\cup}}
        \\newunicodechar{∩}{\\ensuremath{\\cap}}
        \\newunicodechar{≠}{\\ensuremath{\\neq}}
        \\newunicodechar{≤}{\\ensuremath{\\leq}}
        \\newunicodechar{≥}{\\ensuremath{\\geq}}
        \\newunicodechar{≈}{\\ensuremath{\\approx}}
        \\newunicodechar{≡}{\\ensuremath{\\equiv}}
        \\newunicodechar{∼}{\\ensuremath{\\sim}}
        \\newunicodechar{∝}{\\ensuremath{\\propto}}
        \\newunicodechar{′}{\\ensuremath{\\prime}}
        \\newunicodechar{″}{\\ensuremath{\\prime\\prime}}
        \\newunicodechar{‴}{\\ensuremath{\\prime\\prime\\prime}}
        \\newunicodechar{→}{\\ensuremath{\\rightarrow}}
        \\newunicodechar{←}{\\ensuremath{\\leftarrow}}
        \\newunicodechar{↔}{\\ensuremath{\\leftrightarrow}}
        \\newunicodechar{⇒}{\\ensuremath{\\Rightarrow}}
        \\newunicodechar{⇐}{\\ensuremath{\\Leftarrow}}
        \\newunicodechar{⇔}{\\ensuremath{\\Leftrightarrow}}
        \\newunicodechar{⇌}{\\ensuremath{\\rightleftharpoons}}

        % Unicode subscript digits (for chemical formulas like H₂O)
        \\newunicodechar{₀}{\\ensuremath{_0}}
        \\newunicodechar{₁}{\\ensuremath{_1}}
        \\newunicodechar{₂}{\\ensuremath{_2}}
        \\newunicodechar{₃}{\\ensuremath{_3}}
        \\newunicodechar{₄}{\\ensuremath{_4}}
        \\newunicodechar{₅}{\\ensuremath{_5}}
        \\newunicodechar{₆}{\\ensuremath{_6}}
        \\newunicodechar{₇}{\\ensuremath{_7}}
        \\newunicodechar{₈}{\\ensuremath{_8}}
        \\newunicodechar{₉}{\\ensuremath{_9}}
        \\newunicodechar{₊}{\\ensuremath{_+}}
        \\newunicodechar{₋}{\\ensuremath{_-}}

        % Unicode superscript digits and symbols
        \\newunicodechar{⁰}{\\ensuremath{^0}}
        \\newunicodechar{¹}{\\ensuremath{^1}}
        \\newunicodechar{²}{\\ensuremath{^2}}
        \\newunicodechar{³}{\\ensuremath{^3}}
        \\newunicodechar{⁴}{\\ensuremath{^4}}
        \\newunicodechar{⁵}{\\ensuremath{^5}}
        \\newunicodechar{⁶}{\\ensuremath{^6}}
        \\newunicodechar{⁷}{\\ensuremath{^7}}
        \\newunicodechar{⁸}{\\ensuremath{^8}}
        \\newunicodechar{⁹}{\\ensuremath{^9}}
        \\newunicodechar{⁺}{\\ensuremath{^+}}
        \\newunicodechar{⁻}{\\ensuremath{^-}}
    \\fi\\fi

    % Configure listings for code blocks
    \\lstset{
      basicstyle=\\ttfamily\\small,
      breaklines=true,          % Enable automatic line breaking
      breakatwhitespace=true,   % Only break at whitespace
      columns=fullflexible,     % More flexible column adjustment for better breaking
      keepspaces=true,
      showstringspaces=false,
      frame=single,
      framesep=5pt,
      framexleftmargin=5pt,
      tabsize=4,
      extendedchars=true        % Allow extended characters (UTF-8)
    }

% Set page geometry
\$if(trim_paperwidth)\$
% Custom trim size geometry (Lulu print or custom dimensions)
\\geometry{paperwidth=\$trim_paperwidth\$, paperheight=\$trim_paperheight\$, top=\$trim_top\$, bottom=\$trim_bottom\$, outer=\$trim_outer\$, inner=\$trim_inner\$}
\$else\$
\\geometry{a4paper, margin=1in}
\$endif\$

% Header and Footer Setup
\$if(lulu_mode)\$
    % Professional print book headers/footers (Lulu mode)
    \\pagestyle{fancy}
    \\fancyhf{} % Clear all
    \\renewcommand{\\headrulewidth}{0pt}
    \\renewcommand{\\footrulewidth}{0pt}
    % Chapter mark: name only, no "CHAPTER N." prefix, normal case
    \\renewcommand{\\chaptermark}[1]{\\markboth{#1}{}}
    % Even (verso) pages: book title centered in header
    \\fancyhead[CE]{\\small\\textit{$doc_title}}
    % Odd (recto) pages: chapter title centered in header
    \\fancyhead[CO]{\\small\\textit{\\leftmark}}
    % Page number always centered at bottom
    \\fancyfoot[C]{\\small \\thepage}
    % Plain style: chapter opening pages — centered page number at bottom, no header
    \\fancypagestyle{plain}{%
        \\fancyhf{}%
        \\renewcommand{\\headrulewidth}{0pt}%
        \\renewcommand{\\footrulewidth}{0pt}%
        \\fancyfoot[C]{\\small \\thepage}%
    }
    % Empty style: blank verso pages — no headers or footers at all
    \\fancypagestyle{empty}{%
        \\fancyhf{}%
        \\renewcommand{\\headrulewidth}{0pt}%
        \\renewcommand{\\footrulewidth}{0pt}%
    }
    % Blank pages inserted by \\cleardoublepage use empty style
    \\makeatletter
    \\renewcommand{\\cleardoublepage}{%
        \\clearpage
        \\if@twoside
            \\ifodd\\c@page\\else
                \\hbox{}\\thispagestyle{empty}\\newpage
                \\if@twocolumn\\hbox{}\\newpage\\fi
            \\fi
        \\fi
    }
    \\makeatother
    % Front matter pages — no headers or footers
    \\fancypagestyle{frontmatter}{%
        \\fancyhf{}%
        \\renewcommand{\\headrulewidth}{0pt}%
        \\renewcommand{\\footrulewidth}{0pt}%
    }
    % Title page — no headers or footers
    \\fancypagestyle{titlepage}{%
        \\fancyhf{}%
        \\renewcommand{\\headrulewidth}{0pt}%
        \\renewcommand{\\footrulewidth}{0pt}%
    }
\$else\$
    \\pagestyle{fancy}
    \\fancyhf{} % Clear all header and footer fields first

    % Setup Header
    \\fancyhead[L]{\\small\\textit{$doc_author}}
    \\fancyhead[R]{\\small\\textit{$doc_title}}
    \\renewcommand{\\headrulewidth}{0.4pt}

    % Setup Footer (conditionally)
    \$if(no_footer)\$
        % All footers (L, C, R) remain empty
        \\renewcommand{\\footrulewidth}{0pt} % No footrule if no_footer is true
    \$else\$
        % Left Footer (Date)
        \$if(date_footer_content)\$
            \\fancyfoot[L]{\$date_footer_content\$}
        \$endif\$

        % Center Footer (Custom text / Copyright)
        \$if(center_footer_content)\$
            \\fancyfoot[C]{\$center_footer_content\$}
        \$else\$
            % Default center footer if -f is not used and not --no-footer
            \\fancyfoot[C]{\\copyright All rights reserved \\the\\year} % Default copyright
        \$endif\$

        % Right Footer (Page number)
        \$if(page_of_format)\$
            \\fancyfoot[R]{\\thepage/\\pageref{LastPage}}
        \$else\$
            \\fancyfoot[R]{\\thepage}
        \$endif\$
        \\renewcommand{\\footrulewidth}{0.4pt} % Footrule active if footers are shown
    \$endif\$

% First page style (plain) - should mirror the above logic
\\fancypagestyle{plain}{
    \\fancyhf{} % Clear header/footer for plain style

    % Conditionally add headers based on header_footer_policy
    \$if(header_footer_policy_all)\$
        % Include headers on all plain pages (title, part, chapter pages) when policy is all
        \\fancyhead[L]{\\small\\textit{$doc_author}}
        \\fancyhead[R]{\\small\\textit{$doc_title}}
        \\renewcommand{\\headrulewidth}{0.4pt}
    \$elseif(header_footer_policy_partial)\$
        % Include headers on part and chapter pages, but not title page when policy is partial
        \\fancyhead[L]{\\small\\textit{$doc_author}}
        \\fancyhead[R]{\\small\\textit{$doc_title}}
        \\renewcommand{\\headrulewidth}{0.4pt}
    \$else\$
        % No headers on plain pages (default behavior)
        \\renewcommand{\\headrulewidth}{0pt}
    \$endif\$

    % Footer logic based on header_footer_policy
    \$if(header_footer_policy_all)\$
        % Include footers on all plain pages when policy is all
        \$if(no_footer)\$
            % All footers remain empty
            \\renewcommand{\\footrulewidth}{0pt}
        \$else\$
            % Left Footer (Date)
            \$if(date_footer_content)\$
                \\fancyfoot[L]{\$date_footer_content\$}
            \$endif\$

            % Center Footer (Custom text / Copyright)
            \$if(center_footer_content)\$
                \\fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \\fancyfoot[C]{\\copyright All rights reserved \\the\\year} % Default copyright
            \$endif\$

            % Right Footer (Page number)
            \$if(page_of_format)\$
                \\fancyfoot[R]{\\thepage/\\pageref{LastPage}}
            \$else\$
                \\fancyfoot[R]{\\thepage}
            \$endif\$
            \\renewcommand{\\footrulewidth}{0.4pt}
        \$endif\$
    \$elseif(header_footer_policy_partial)\$
        % Include footers on part and chapter pages, but not title page when policy is partial
        \$if(no_footer)\$
            % All footers remain empty
            \\renewcommand{\\footrulewidth}{0pt}
        \$else\$
            % Left Footer (Date)
            \$if(date_footer_content)\$
                \\fancyfoot[L]{\$date_footer_content\$}
            \$endif\$

            % Center Footer (Custom text / Copyright)
            \$if(center_footer_content)\$
                \\fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \\fancyfoot[C]{\\copyright All rights reserved \\the\\year} % Default copyright
            \$endif\$

            % Right Footer (Page number)
            \$if(page_of_format)\$
                \\fancyfoot[R]{\\thepage/\\pageref{LastPage}}
            \$else\$
                \\fancyfoot[R]{\\thepage}
            \$endif\$
            \\renewcommand{\\footrulewidth}{0.4pt}
        \$endif\$
    \$else\$
        % No footers on plain pages (default behavior)
        \\renewcommand{\\footrulewidth}{0pt}
    \$endif\$
}

% Title page style - specific handling for title page
\\fancypagestyle{titlepage}{
    \\fancyhf{} % Clear header/footer for title page

    % Only add headers/footers on title page if policy is 'all'
    \$if(header_footer_policy_all)\$
        \\fancyhead[L]{\\small\\textit{$doc_author}}
        \\fancyhead[R]{\\small\\textit{$doc_title}}
        \\renewcommand{\\headrulewidth}{0.4pt}

        \$if(no_footer)\$
            % All footers remain empty
        \$else\$
            % Left Footer (Date)
            \$if(date_footer_content)\$
                \\fancyfoot[L]{\$date_footer_content\$}
            \$endif\$

            % Center Footer (Custom text / Copyright)
            \$if(center_footer_content)\$
                \\fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \\fancyfoot[C]{\\copyright All rights reserved \\the\\year} % Default copyright
            \$endif\$

            % Right Footer (Page number)
            \$if(page_of_format)\$
                \\fancyfoot[R]{\\thepage/\\pageref{LastPage}}
            \$else\$
                \\fancyfoot[R]{\\thepage}
            \$endif\$
            \\renewcommand{\\footrulewidth}{0.4pt}
        \$endif\$
    \$else\$
        % No headers/footers on title page for default and partial policies
        \\renewcommand{\\headrulewidth}{0pt}
        \\renewcommand{\\footrulewidth}{0pt}
    \$endif\$
}

% Front matter page style - for copyright, dedication, epigraph pages
% Uses headers/footers when policy is 'all', otherwise empty
\\fancypagestyle{frontmatter}{
    \\fancyhf{} % Clear header/footer
    \$if(header_footer_policy_all)\$
        \\fancyhead[L]{\\small\\textit{$doc_author}}
        \\fancyhead[R]{\\small\\textit{$doc_title}}
        \\renewcommand{\\headrulewidth}{0.4pt}
        \$if(no_footer)\$
            \\renewcommand{\\footrulewidth}{0pt}
        \$else\$
            \$if(date_footer_content)\$
                \\fancyfoot[L]{\$date_footer_content\$}
            \$endif\$
            \$if(center_footer_content)\$
                \\fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \\fancyfoot[C]{\\copyright All rights reserved \\the\\year}
            \$endif\$
            \$if(page_of_format)\$
                \\fancyfoot[R]{\\thepage/\\pageref{LastPage}}
            \$else\$
                \\fancyfoot[R]{\\thepage}
            \$endif\$
            \\renewcommand{\\footrulewidth}{0.4pt}
        \$endif\$
    \$else\$
        \\renewcommand{\\headrulewidth}{0pt}
        \\renewcommand{\\footrulewidth}{0pt}
    \$endif\$
}

% Custom cleardoublepage that respects header_footer_policy
% When policy is 'all', blank pages have headers/footers
\$if(header_footer_policy_all)\$
\\makeatletter
\\renewcommand{\\cleardoublepage}{%
    \\clearpage
    \\if@twoside
        \\ifodd\\c@page\\else
            \\thispagestyle{frontmatter}%
            \\hbox{}\\newpage
            \\if@twocolumn\\hbox{}\\newpage\\fi
        \\fi
    \\fi
}
\\makeatother

% Also redefine 'empty' page style to have headers/footers when policy is 'all'
% This catches any internally-created blank pages by LaTeX
\\fancypagestyle{empty}{
    \\fancyhf{}
    \\fancyhead[L]{\\small\\textit{$doc_author}}
    \\fancyhead[R]{\\small\\textit{$doc_title}}
    \\renewcommand{\\headrulewidth}{0.4pt}
    \$if(no_footer)\$
        \\renewcommand{\\footrulewidth}{0pt}
    \$else\$
        \$if(date_footer_content)\$
            \\fancyfoot[L]{\$date_footer_content\$}
        \$endif\$
        \$if(center_footer_content)\$
            \\fancyfoot[C]{\$center_footer_content\$}
        \$else\$
            \\fancyfoot[C]{\\copyright All rights reserved \\the\\year}
        \$endif\$
        \$if(page_of_format)\$
            \\fancyfoot[R]{\\thepage/\\pageref{LastPage}}
        \$else\$
            \\fancyfoot[R]{\\thepage}
        \$endif\$
        \\renewcommand{\\footrulewidth}{0.4pt}
    \$endif\$
}
\$endif\$
\$endif\$

% Adjust paragraph spacing: add a full line skip between paragraphs
\\setlength{\\parskip}{\\baselineskip}
% Remove paragraph indentation
\\setlength{\\parindent}{0pt}

% Configure list appearance using enumitem
\\renewlist{itemize}{itemize}{6}  % Explicitly redefine itemize to allow 6 levels
\\setlist[itemize]{label=\\textbullet} % Use a standard bullet for all levels of itemize

% Optionally, do the same for enumerate for consistency if it's ever used deeply
\\renewlist{enumerate}{enumerate}{6} % Explicitly redefine enumerate to allow 6 levels
% Default numbering (1., a., i., etc.) should apply, or we can customize:
% \\setlist[enumerate,1]{label=\\arabic*.}
% \\setlist[enumerate,2]{label=\\alph*.}
% etc. For now, just ensuring depth.

% Define \\tightlist as an empty command.
% This prevents an "Undefined control sequence" error if pandoc emits \\tightlist,
% while avoiding the original \\tightlist definition that might cause issues with deep nesting.
\\providecommand{\\tightlist}{}

% Configure equation handling for better line breaking
% Using the amsmath package which is already loaded

% Equation numbering (chapter-based if enabled)
\$if(equation_numbers)\$
\\numberwithin{equation}{chapter}
\$endif\$

% Adjust the text size for display math to fit more content
\\everymath{\\displaystyle\\small}

% Control section numbering
$numbering_commands

% Define a custom environment for long text-heavy equations
\\newenvironment{longmath}{%
  \\begin{multline*}\\small
}{%
  \\end{multline*}
}

% Increase the line width for equations to allow more content per line
\\setlength{\\multlinegap}{0pt}

% Allow line breaks at certain operators in math mode
\\allowdisplaybreaks[4]
\\sloppy  % Allow more flexible line breaking

% Define a command to handle long text in equations
\\newcommand{\\longtext}[1]{\\text{\\small #1}}

% Define theorem environments
\\newtheorem{theorem}{Theorem}
\\newtheorem{lemma}{Lemma}
\\newtheorem{corollary}{Corollary}
\\newtheorem{definition}{Definition}

% Custom figure caption handling
\\usepackage{caption}
\\captionsetup{font=small,labelfont=bf,textfont=it}
\\renewcommand{\\figurename}{Figure}
$figure_numbering_commands

% Define Pandoc's code highlighting environments
\\definecolor{shadecolor}{RGB}{248,248,248}
\\newenvironment{Shaded}{\\begin{snugshade}}{\\end{snugshade}}
\\newenvironment{Highlighting}{}{}
\\newcommand{\\HighlightingOn}{}
\\newcommand{\\HighlightingOff}{}
\\newcommand{\\KeywordTok}[1]{\\textcolor[rgb]{0.13,0.29,0.53}{\\textbf{#1}}}
\\newcommand{\\DataTypeTok}[1]{\\textcolor[rgb]{0.13,0.29,0.53}{#1}}
\\newcommand{\\DecValTok}[1]{\\textcolor[rgb]{0.00,0.00,0.81}{#1}}
\\newcommand{\\BaseNTok}[1]{\\textcolor[rgb]{0.00,0.00,0.81}{#1}}
\\newcommand{\\FloatTok}[1]{\\textcolor[rgb]{0.00,0.00,0.81}{#1}}
\\newcommand{\\ConstantTok}[1]{\\textcolor[rgb]{0.00,0.00,0.00}{#1}}
\\newcommand{\\CharTok}[1]{\\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\\newcommand{\\SpecialCharTok}[1]{\\textcolor[rgb]{0.00,0.00,0.00}{#1}}
\\newcommand{\\StringTok}[1]{\\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\\newcommand{\\VerbatimStringTok}[1]{\\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\\newcommand{\\SpecialStringTok}[1]{\\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\\newcommand{\\ImportTok}[1]{#1}
\\newcommand{\\CommentTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textit{#1}}}
\\newcommand{\\DocumentationTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textit{#1}}}
\\newcommand{\\AnnotationTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textbf{\\textit{#1}}}}
\\newcommand{\\CommentVarTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textbf{\\textit{#1}}}}
\\newcommand{\\OtherTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{#1}}
\\newcommand{\\FunctionTok}[1]{\\textcolor[rgb]{0.00,0.00,0.00}{#1}}
\\newcommand{\\VariableTok}[1]{\\textcolor[rgb]{0.00,0.00,0.00}{#1}}
\\newcommand{\\ControlFlowTok}[1]{\\textcolor[rgb]{0.13,0.29,0.53}{\\textbf{#1}}}
\\newcommand{\\OperatorTok}[1]{\\textcolor[rgb]{0.81,0.36,0.00}{\\textbf{#1}}}
\\newcommand{\\BuiltInTok}[1]{#1}
\\newcommand{\\ExtensionTok}[1]{#1}
\\newcommand{\\PreprocessorTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textit{#1}}}
\\newcommand{\\AttributeTok}[1]{\\textcolor[rgb]{0.77,0.63,0.00}{#1}}
\\newcommand{\\RegionMarkerTok}[1]{#1}
\\newcommand{\\InformationTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textbf{\\textit{#1}}}}
\\newcommand{\\WarningTok}[1]{\\textcolor[rgb]{0.56,0.35,0.01}{\\textbf{\\textit{#1}}}}
\\newcommand{\\AlertTok}[1]{\\textcolor[rgb]{0.94,0.16,0.16}{#1}}
\\newcommand{\\ErrorTok}[1]{\\textcolor[rgb]{0.64,0.00,0.00}{\\textbf{#1}}}
\\newcommand{\\NormalTok}[1]{#1}

% Title information from YAML frontmatter
% Only set \\title for article format or when not using custom title page
\$if(title)\$
\$if(format_book)\$
\$if(header_footer_policy_all)\$
% For book format with 'all' policy, custom title page is used, don't set \\title
\$else\$
\\title{\$title\$}
\$endif\$
\$else\$
\\title{\$title\$}
\$endif\$
\$endif\$
\$if(author)\$
\$if(format_book)\$
\$if(email)\$
\\author{\$author\$ --- \$email\$}
\$else\$
\\author{\$author\$}
\$endif\$
\$else\$
\\author{\$author\$}
\$endif\$
\$endif\$
\$if(date)\$
\\date{\$date\$}
\$else\$
\\date{}
\$endif\$

% Hyperref setup
\\hypersetup{
  colorlinks=true,
  linkcolor=black,
  filecolor=magenta,
  urlcolor=cyan,
  pdftitle={\$if(title)\$\$title\$\$endif\$},
  pdfauthor={\$if(author)\$\$author\$\$endif\$},
  pdfborder={0 0 0},
  plainpages=false,
  pdfpagelabels=true,
  bookmarksnumbered=true
}

% Bibliography/Citation support (CSL)
\\newlength{\\cslhangindent}
\\setlength{\\cslhangindent}{1.5em}
\\newlength{\\cslentryspacingunit}
\\setlength{\\cslentryspacingunit}{\\parskip}
\\newenvironment{CSLReferences}[2]
 {\\setlength{\\parindent}{0pt}
  \\ifodd #1
  \\let\\oldpar\\par
  \\def\\par{\\hangindent=\\cslhangindent\\oldpar}
  \\fi
  \\setlength{\\parskip}{#2\\cslentryspacingunit}}
 {}
\\newcommand{\\CSLBlock}[1]{#1\\hfill\\break}
\\newcommand{\\CSLLeftMargin}[1]{\\parbox[t]{\\cslhangindent}{#1}}
\\newcommand{\\CSLRightInline}[1]{\\parbox[t]{\\linewidth - \\cslhangindent}{#1}\\break}
\\newcommand{\\CSLIndent}[1]{\\hspace{\\cslhangindent}#1}

% Initialize index if requested
\$if(index)\$
\\makeindex
\$endif\$

% Custom header includes from document metadata
\$for(header-includes)\$
\$header-includes\$
\$endfor\$

\\begin{document}

\$if(format_book)\$
\\frontmatter
\\pagenumbering{arabic}% Keep Arabic numerals throughout (override \\frontmatter's roman)
\$endif\$

% ============== FRONT COVER (Première de Couverture) ==============
% Suppressed in Lulu mode (covers are uploaded separately to lulu.com)
\$if(lulu_mode)\$
\$else\$
\$if(cover_image)\$
\\newgeometry{margin=0pt}
\\thispagestyle{empty}
\\begin{tikzpicture}[remember picture,overlay]
  % Background fill (in case image doesn't fully cover)
  \\fill[black] (current page.south west) rectangle (current page.north east);
  % Background image
  \$if(cover_fit_cover)\$
  % Cover mode: scale uniformly to fill page, crop overflow (like CSS background-size: cover)
  \\begin{scope}
    \\clip (current page.south west) rectangle (current page.north east);
    \\node[inner sep=0pt,outer sep=0pt] at (current page.center) {
      \\includegraphics[width=\\paperwidth]{\$cover_image\$}
    };
  \\end{scope}
  \$else\$
  % Contain mode (default): maintain aspect ratio (may have black strips)
  \\node[inner sep=0pt,outer sep=0pt] at (current page.center) {
    \\includegraphics[width=\\paperwidth,height=\\paperheight,keepaspectratio]{\$cover_image\$}
  };
  \$endif\$
  % Optional dark overlay for text readability
  \$if(cover_overlay_opacity)\$
  \\fill[black,opacity=\$cover_overlay_opacity\$] (current page.south west) rectangle (current page.north east);
  \$endif\$
  % Title text - positioned in upper portion of image area (hyphenation disabled)
  % Using 0.20\\paperheight from top keeps text within image bounds for most aspect ratios
  % Set cover_title_show: false in YAML to hide title/author overlay (e.g. when cover image has them)
  \$if(cover_title_show)\$
  \\node[text=\$if(cover_title_color)\$\$cover_title_color\$\$else\$white\$endif\$,font=\\Huge\\bfseries,align=center,text width=0.8\\paperwidth,anchor=north] at ([yshift=-0.20\\paperheight]current page.north) {
    \\nohyphens{\$title\$}
    \$if(cover_subtitle_show)\$\$if(subtitle)\$\\\\[0.5cm]{\\LARGE\\itshape \\nohyphens{\$subtitle\$}}\$endif\$\$endif\$
  };
  % Author at bottom of image area (if cover_author_position is set)
  % Default offset: 0.20\\paperheight from bottom; override with cover_author_offset (e.g. 0.08)
  \$if(cover_author_position)\$
  \\node[text=\$if(cover_title_color)\$\$cover_title_color\$\$else\$white\$endif\$,font=\\Large,anchor=south] at ([yshift=\$if(cover_author_offset)\$\$cover_author_offset\$\\paperheight\$else\$0.20\\paperheight\$endif\$]current page.south) {
    \$author\$
  };
  \$endif\$
  \$endif\$
\\end{tikzpicture}
\\restoregeometry
\\clearpage
\$endif\$
\$endif\$

% ============== FRONT MATTER PAGES (Professional Book Features) ==============

% Half-title page (just the title, no author/date - traditional book convention)
\$if(half_title)\$
\\thispagestyle{frontmatter}
\\begin{center}
\\vspace*{\\fill}
{\\LARGE \\textbf{\\nohyphens{\$title\$}}}
\\vspace*{\\fill}
\\end{center}
\\cleardoublepage
\$endif\$

% ============== MAIN TITLE PAGE ==============
% Set no_title_page: true in YAML to skip the inner title page (e.g. when cover image has title/author)

\$if(no_title_page)\$
% Title page suppressed via no_title_page: true
\$else\$
\$if(title)\$
\$if(header_footer_policy_all)\$
\$if(format_book)\$
% For book format with 'all' policy, create custom title page that respects headers/footers
\\thispagestyle{titlepage}
\\begin{center}
\\vspace*{\\fill}
{\\Huge \\textbf{\\nohyphens{\$title\$}}}\\\\[0.5cm]
\$if(subtitle)\$
{\\LARGE \\itshape \\nohyphens{\$subtitle\$}}\\\\[1.5cm]
\$endif\$
\$if(author)\$
{\\large \$author\$ \$if(email)\$ --- \$email\$ \$endif\$}\\\\[1cm]
\$endif\$
\$if(date)\$
{\\large \$date\$}
\$endif\$
\\vspace*{\\fill}
\\end{center}
\\cleardoublepage
\$else\$
% For article format with 'all' policy, use standard maketitle but ensure headers/footers work
\\maketitle
\$endif\$
\$else\$
% For default and partial policies, use standard maketitle
\\maketitle
\$endif\$
\$endif\$
\$endif\$

% Copyright page (verso of title page - traditional book convention)
\$if(copyright_page)\$
\\thispagestyle{frontmatter}
\\vspace*{\\fill}
\\begin{flushleft}
\\textbf{\\nohyphens{\$title\$}}\\\\[0.3cm]
\$if(subtitle)\$
\\textit{\\nohyphens{\$subtitle\$}}\\\\[0.5cm]
\$endif\$
\$if(author)\$
by \$author\$\\\\[0.5cm]
\$endif\$
\\rule{0.4\\textwidth}{0.4pt}\\\\[0.5cm]
\$if(copyright_holder)\$
Copyright \\copyright\\ \$if(copyright_year)\$\$copyright_year\$\$else\$\\the\\year\$endif\$ \$copyright_holder\$\\\\[0.3cm]
\$elseif(publisher)\$
Copyright \\copyright\\ \$if(copyright_year)\$\$copyright_year\$\$else\$\\the\\year\$endif\$ \$publisher\$\\\\[0.3cm]
\$elseif(author)\$
Copyright \\copyright\\ \$if(copyright_year)\$\$copyright_year\$\$else\$\\the\\year\$endif\$ \$author\$\\\\[0.3cm]
\$endif\$
All rights reserved.\\\\[0.5cm]
\$if(publisher)\$
Published by \$publisher\$\\\\[0.3cm]
\$endif\$
\$if(isbn)\$
ISBN: \$isbn\$\\\\[0.3cm]
\$endif\$
\$if(edition)\$
\$edition\$\$if(edition_date)\$ --- \$edition_date\$\$endif\$\\\\[0.3cm]
\$endif\$
\$if(printing)\$
\$printing\$\\\\[0.3cm]
\$endif\$
\$if(publisher_address)\$
\\vspace{0.3cm}
\$publisher_address\$\\\\[0.3cm]
\$endif\$
\$if(publisher_website)\$
\\url{\$publisher_website\$}\\\\[0.3cm]
\$endif\$
\\end{flushleft}
\\cleardoublepage
\$endif\$

% Authorship & Support page (after copyright page)
\$if(author_pubkey)\$
\\thispagestyle{frontmatter}
\\vspace*{\\fill}
\\begin{flushleft}
{\\Large\\bfseries Authorship \\& Support}\\\\[1cm]
\\textbf{AUTHORSHIP VERIFICATION}\\\\[0.5cm]
\$author_pubkey_type\$: {\\small\\texttt{\$author_pubkey\$}}\\\\[1cm]
\\rule{0.4\\textwidth}{0.4pt}\\\\[1cm]
\$if(donation_wallets)\$
\\textbf{SUPPORT THE AUTHOR}\\\\[0.5cm]
\$donation_wallets\$
\$endif\$
\\end{flushleft}
\\vspace*{\\fill}
\\cleardoublepage
\$endif\$

% Dedication page (from metadata - centered, italic)
\$if(dedication)\$
\\thispagestyle{frontmatter}
\\vspace*{\\fill}
\\begin{center}
\\textit{\$dedication\$}
\\end{center}
\\vspace*{\\fill}
\\cleardoublepage
\$endif\$

% Epigraph page (from metadata - quote with optional source)
\$if(epigraph)\$
\\thispagestyle{frontmatter}
\\vspace*{\\fill}
\\begin{center}
\\begin{minipage}{0.7\\textwidth}
\\textit{``\$epigraph\$''}
\$if(epigraph_source)\$
\\\\[0.5cm]
\\hfill--- \$epigraph_source\$
\$endif\$
\\end{minipage}
\\end{center}
\\vspace*{\\fill}
\\cleardoublepage
\$endif\$

% Set TOC depth and generate TOC if needed
\\setcounter{tocdepth}{$ARG_TOC_DEPTH}
\$if(toc)\$
\\tableofcontents
\\newpage
\$endif\$

\$if(format_book)\$
\\edef\\currentpage{\\the\\value{page}}% Save current page number
\\mainmatter
\\setcounter{page}{\\currentpage}% Restore page number (prevent reset to 1)
\$endif\$

\$body\$

% ============== BACK MATTER: List of Figures / List of Tables ==============
\$if(lof)\$
\\clearpage
\\phantomsection
\$if(has_parts)\$
\\addcontentsline{toc}{part}{List of Figures}
\$else\$
\\addcontentsline{toc}{chapter}{List of Figures}
\$endif\$
\\listoffigures
\$endif\$

\$if(lot)\$
\\clearpage
\\phantomsection
\$if(has_parts)\$
\\addcontentsline{toc}{part}{List of Tables}
\$else\$
\\addcontentsline{toc}{chapter}{List of Tables}
\$endif\$
\\listoftables
\$endif\$

% Print index if requested
\$if(index)\$
\\clearpage
\\phantomsection
\$if(has_parts)\$
\\addcontentsline{toc}{part}{Index}
\$else\$
\\addcontentsline{toc}{chapter}{Index}
\$endif\$
\\printindex
\$endif\$

% ============== ACKNOWLEDGMENTS ==============
\$if(acknowledgments)\$
\\clearpage
\\thispagestyle{plain}
\\phantomsection
\$if(has_parts)\$
\\addcontentsline{toc}{part}{Acknowledgments}
\$else\$
\\addcontentsline{toc}{chapter}{Acknowledgments}
\$endif\$
\\begin{center}
{\\LARGE\\bfseries Acknowledgments}
\\end{center}
\\vspace{1em}
\\noindent \$acknowledgments\$
\$endif\$

% ============== ABOUT THE AUTHOR ==============
\$if(about-author)\$
\\clearpage
\\thispagestyle{plain}
\\phantomsection
\$if(has_parts)\$
\\addcontentsline{toc}{part}{About the Author}
\$else\$
\\addcontentsline{toc}{chapter}{About the Author}
\$endif\$
\\begin{center}
{\\LARGE\\bfseries About the Author}
\\end{center}
\\vspace{1em}
\\noindent \$about-author\$
\$endif\$

% ============== BACK COVER (Quatrième de Couverture) ==============
% Suppressed in Lulu mode (covers are uploaded separately to lulu.com)
\$if(lulu_mode)\$
\$else\$
\$if(back_cover_image)\$
\\clearpage
\\newgeometry{margin=0pt}
\\thispagestyle{empty}
\\begin{tikzpicture}[remember picture,overlay]
  % Background fill (in case image doesn't fully cover)
  \\fill[black] (current page.south west) rectangle (current page.north east);
  % Background image
  \$if(cover_fit_cover)\$
  % Cover mode: scale uniformly to fill page, crop overflow (like CSS background-size: cover)
  \\begin{scope}
    \\clip (current page.south west) rectangle (current page.north east);
    \\node[inner sep=0pt,outer sep=0pt] at (current page.center) {
      \\includegraphics[width=\\paperwidth]{\$back_cover_image\$}
    };
  \\end{scope}
  \$else\$
  % Contain mode (default): maintain aspect ratio (may have black strips)
  \\node[inner sep=0pt,outer sep=0pt] at (current page.center) {
    \\includegraphics[width=\\paperwidth,height=\\paperheight,keepaspectratio]{\$back_cover_image\$}
  };
  \$endif\$
  % Optional dark overlay for text readability
  \$if(cover_overlay_opacity)\$
  \\fill[black,opacity=\$cover_overlay_opacity\$] (current page.south west) rectangle (current page.north east);
  \$endif\$
  % --- Back cover text color resolution ---
  % Priority: back_cover_text_color > cover_title_color > white
  % Rectangle fill is auto-inversed: white text → black fill, black text → white fill
  %
  % Content box - quote, summary, or custom text
  % Positioned in upper portion of back cover (0.08\\paperheight from top)
  \\node[\$if(back_cover_text_background)\$fill=\$if(back_cover_text_color)\$\$if(back_cover_text_color_is_white)\$black\$else\$white\$endif\$\$elseif(cover_title_color_is_white)\$black\$else\$white\$endif\$, fill opacity=\$if(back_cover_text_background_opacity)\$\$back_cover_text_background_opacity\$\$else\$0.18\$endif\$, text opacity=1, rounded corners=6pt, inner sep=0.25in,\$endif\$ text=\$if(back_cover_text_color)\$\$back_cover_text_color\$\$elseif(cover_title_color)\$\$cover_title_color\$\$else\$white\$endif\$,font=\\large,align=center,text width=0.7\\paperwidth,anchor=north] at ([yshift=-0.08\\paperheight]current page.north) {
    \$if(back_cover_quote)\$
    {\\itshape ``\$back_cover_quote\$''}
    \$if(back_cover_quote_source)\$\\\\[0.5cm]--- \$back_cover_quote_source\$\$endif\$
    \$elseif(back_cover_summary)\$
    \$back_cover_summary\$
    \$elseif(back_cover_text)\$
    \$back_cover_text\$
    \$endif\$
  };
  % Author bio section (if enabled)
  % Positioned in lower portion of back cover (0.12\\paperheight from bottom)
  \$if(back_cover_author_bio)\$
  \\node[\$if(back_cover_text_background)\$fill=\$if(back_cover_text_color)\$\$if(back_cover_text_color_is_white)\$black\$else\$white\$endif\$\$elseif(cover_title_color_is_white)\$black\$else\$white\$endif\$, fill opacity=\$if(back_cover_text_background_opacity)\$\$back_cover_text_background_opacity\$\$else\$0.18\$endif\$, text opacity=1, rounded corners=6pt, inner sep=0.25in,\$endif\$ text=\$if(back_cover_text_color)\$\$back_cover_text_color\$\$elseif(cover_title_color)\$\$cover_title_color\$\$else\$white\$endif\$,font=\\normalsize,align=left,text width=0.7\\paperwidth,anchor=south] at ([yshift=0.12\\paperheight]current page.south) {
    {\\bfseries About the Author}\\\\[0.3cm]
    \$if(back_cover_author_bio_text)\$\$back_cover_author_bio_text\$\$endif\$
  };
  \$endif\$
\\end{tikzpicture}
\\restoregeometry
\$endif\$
\$endif\$

\\end{document}
EOF

    return $?
}

# Export functions for use in main script
export -f create_template_file 2>/dev/null || true
