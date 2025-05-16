#!/bin/bash

# ANSI color codes
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default TOC depth (3 = subsubsection level)
DEFAULT_TOC_DEPTH=2

# Default TOC setting (false = no TOC)
DEFAULT_TOC=false

# Default section numbering (true = numbered sections)
DEFAULT_SECTION_NUMBERS=true

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

# Function to check if a LaTeX package is available
check_latex_package() {
    if kpsewhich "$1.sty" &> /dev/null; then
        echo -e "${GREEN}✓ LaTeX package $1 is available${NC}"
        return 0
    else
        echo -e "${RED}✗ LaTeX package $1 is not available${NC}"
        return 1
    fi
}

# Function to create a template.tex file
create_template_file() {
    local template_path="$1"
    local footer_text="$2"
    local doc_title="$3"
    local doc_author="$4"
    local date_footer="$5"
    local section_numbers="${6:-true}"
    
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
        numbering_commands="\\setcounter{secnumdepth}{0}"
    fi
    
    cat > "$template_path" << EOF
    \\documentclass[12pt]{article}
    
    % Conditional packages based on LaTeX engine
    \\usepackage{iftex}
    \\ifluatex
        % LuaLaTeX-specific setup
        \\usepackage{fontspec}
        % Let fontspec use its default fonts
    \\else
        \\ifxetex
            % XeLaTeX-specific setup
            \\usepackage{fontspec}
            % Let fontspec use its default fonts
        \\else
            % pdfLaTeX-specific setup
            \\usepackage[utf8]{inputenc}
            \\usepackage[T1]{fontenc}
            \\usepackage{lmodern}  % Load Latin Modern fonts (scalable)
        \\fi
    \\fi
    \\usepackage{geometry}
    \\usepackage{fancyhdr}
    \\usepackage{graphicx}
    \\usepackage{amsmath}
    \\usepackage{amssymb}
    \\usepackage{amsthm}   % For theorem and proof environments
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
    \\usepackage[protrusion=false,expansion=false]{microtype}  % Disable font expansion
    \\usepackage{enumitem}
    \\usepackage[version=4]{mhchem}
    \\usepackage{framed}   % For snugshade environment
    
    % Define \real command if it doesn't exist (alternative to realnum package)
    \\providecommand{\\real}[1]{#1}
    
    % Define \arraybackslash if it doesn't exist
    \\providecommand{\\arraybackslash}{\\let\\\\\\tabularnewline}
    
    % Define \pandocbounded command used by Pandoc for complex math expressions
    \\providecommand{\\pandocbounded}[1]{\\ensuremath{#1}}
    
    % Define \pandocbounded command used by Pandoc for complex math expressions
    \providecommand{\pandocbounded}[1]{\ensuremath{#1}}

    % Define \passthrough command, sometimes used by Pandoc with --listings
    \providecommand{\passthrough}[1]{#1}
    
    % Define common mathematical Unicode characters
    \\ifluatex\\else\\ifxetex\\else
        % These definitions are only needed for pdfLaTeX
        % For XeLaTeX and LuaLaTeX, unicode-math handles these
        \\usepackage{accents}  % For vector arrows and other accents
        
        % U+20D1 COMBINING RIGHT HARPOON ABOVE
        \\newunicodechar{⃑}{\\vec}
        
        % Other common mathematical symbols

        % Define Unicode box-drawing characters for pdfLaTeX
        \newunicodechar{├}{\texttt{|--}}
        \newunicodechar{│}{\texttt{|}}
        \newunicodechar{└}{\texttt{$(printf %s '\`')--}}
        \newunicodechar{─}{\texttt{-}}
        % For non-listings context, rely on inputenc and font capabilities for pdflatex
        \newunicodechar{ℝ}{\mathbb{R}}
        \\newunicodechar{ℤ}{\\mathbb{Z}}
        \\newunicodechar{ℕ}{\\mathbb{N}}
        \\newunicodechar{ℚ}{\\mathbb{Q}}
        \\newunicodechar{ℂ}{\\mathbb{C}}
        \\newunicodechar{∞}{\\infty}
        \\newunicodechar{∫}{\\int}
        \\newunicodechar{∑}{\\sum}
        \\newunicodechar{∏}{\\prod}
        \\newunicodechar{√}{\\sqrt}
        \\newunicodechar{∂}{\\partial}
        \\newunicodechar{∇}{\\nabla}
        \\newunicodechar{∆}{\\Delta}
        \\newunicodechar{∈}{\\in}
        \\newunicodechar{∉}{\\notin}
        \\newunicodechar{∋}{\\ni}
        \\newunicodechar{⊂}{\\subset}
        \\newunicodechar{⊃}{\\supset}
        \\newunicodechar{⊆}{\\subseteq}
        \\newunicodechar{⊇}{\\supseteq}
        \\newunicodechar{∪}{\\cup}
        \\newunicodechar{∩}{\\cap}
        \\newunicodechar{≠}{\\neq}
        \\newunicodechar{≤}{\\leq}
        \\newunicodechar{≥}{\\geq}
        \\newunicodechar{≈}{\\approx}
        \\newunicodechar{≡}{\\equiv}
        \\newunicodechar{∼}{\\sim}
        \\newunicodechar{∝}{\\propto}
        \\newunicodechar{′}{\\prime}
        \\newunicodechar{″}{\\prime\\prime}
        \\newunicodechar{‴}{\\prime\\prime\\prime}
        \\newunicodechar{→}{\\rightarrow}
        \\newunicodechar{←}{\\leftarrow}
        \\newunicodechar{↔}{\\leftrightarrow}
        \\newunicodechar{⇒}{\\Rightarrow}
        \\newunicodechar{⇐}{\\Leftarrow}
        \\newunicodechar{⇔}{\\Leftrightarrow}
    \\fi\\fi
    
    % Configure listings for code blocks
    \lstset{
      basicstyle=\ttfamily\small,
      breaklines=true,          % Enable automatic line breaking
      breakatwhitespace=true,   % Only break at whitespace
      columns=fullflexible,     % More flexible column adjustment for better breaking
      keepspaces=true,
      showstringspaces=false,
      frame=single,
      framesep=5pt,
      framexleftmargin=5pt,
      tabsize=4,
      extendedchars=true,       % Allow extended characters (UTF-8)
      literate={ï»¿}{}{0}        % Remove UTF-8 BOM
               {é}{{\'{e}}}1
               {è}{{\`{e}}}1
               {ê}{{\^{e}}}1
               {ë}{{\"{e}}}1
               {É}{{\'{E}}}1
               {È}{{\`{E}}}1
               {Ê}{{\^{E}}}1
               {Ë}{{\"{E}}}1
               {á}{{\'{a}}}1
               {à}{{\`{a}}}1
               {â}{{\^{a}}}1
               {ä}{{\"{a}}}1
               {Á}{{\'{A}}}1
               {À}{{\`{A}}}1
               {Â}{{\^{A}}}1
               {Ä}{{\"{A}}}1
               {ó}{{\'{o}}}1
               {ò}{{\`{o}}}1
               {ô}{{\^{o}}}1
               {ö}{{\"{o}}}1
               {Ó}{{\'{O}}}1
               {Ò}{{\`{O}}}1
               {Ô}{{\^{O}}}1
               {Ö}{{\"{O}}}1
               {í}{{\'{i}}}1
               {ì}{{\`{i}}}1
               {î}{{\^{i}}}1
               {ï}{{\"{i}}}1
               {Í}{{\'{I}}}1
               {Ì}{{\`{I}}}1
               {Î}{{\^{I}}}1
               {Ï}{{\"{I}}}1
               {ú}{{\'{u}}}1
               {ù}{{\`{u}}}1
               {û}{{\^{u}}}1
               {ü}{{\"{u}}}1
               {Ú}{{\'{U}}}1
               {Ù}{{\`{U}}}1
               {Û}{{\^{U}}}1
               {Ü}{{\"{U}}}1
               {ç}{{\c{c}}}1
               {Ç}{{\c{C}}}1
               {ñ}{{\~{n}}}1
               {Ñ}{{\~{N}}}1
               {ß}{{\ss}}1
$(if [ "$PDF_ENGINE" = "pdflatex" ]; then
cat << 'INNER_LST_LITERALS_EOF'
               {├}{{\texttt{|--}}}3
               {│}{{\texttt{|}}}1
               {└}{{\texttt{`--}}}3
               {─}{{\texttt{-}}}1
INNER_LST_LITERALS_EOF
fi)
    }

% Set page geometry
\\geometry{a4paper, margin=1in}

% Setup fancy headers and footers
\\pagestyle{fancy}
\\fancyhf{} % Clear all header and footer fields

% Header with document author and title (only on pages after the first)
\\fancyhead[L]{\\small\\textit{$doc_author}}
\\fancyhead[R]{\\small\\textit{$doc_title}}
\\renewcommand{\\headrulewidth}{0.4pt}

% Footer with custom text and page number
\\fancyfoot[C]{$footer_text}
\\fancyfoot[R]{\\thepage}
$([ -n "$date_footer" ] && echo "\\fancyfoot[L]{$date_footer}")
\\renewcommand{\\footrulewidth}{0.4pt}

% First page style (no header)
\\fancypagestyle{plain}{
  \\fancyhf{}
  \\fancyfoot[C]{$footer_text}
  \\fancyfoot[R]{\\thepage}
  $([ -n "$date_footer" ] && echo "\\fancyfoot[L]{$date_footer}")
  \\renewcommand{\\footrulewidth}{0.4pt}
  \renewcommand{\headrulewidth}{0pt}
}

% Adjust paragraph spacing: add a full line skip between paragraphs
\setlength{\parskip}{\baselineskip}
% Remove paragraph indentation
\setlength{\parindent}{0pt}

% Configure list appearance using enumitem
\renewlist{itemize}{itemize}{6}  % Explicitly redefine itemize to allow 6 levels
\setlist[itemize]{label=\textbullet} % Use a standard bullet for all levels of itemize

% Optionally, do the same for enumerate for consistency if it's ever used deeply
\renewlist{enumerate}{enumerate}{6} % Explicitly redefine enumerate to allow 6 levels
% Default numbering (1., a., i., etc.) should apply, or we can customize:
% \setlist[enumerate,1]{label=\arabic*.}
% \setlist[enumerate,2]{label=\alph*.}
% etc. For now, just ensuring depth.

% Define \tightlist as an empty command.
% This prevents an "Undefined control sequence" error if pandoc emits \tightlist,
% while avoiding the original \tightlist definition that might cause issues with deep nesting.
\providecommand{\tightlist}{}

% Configure equation handling for better line breaking
% Using the amsmath package which is already loaded

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

% Define Pandoc's code highlighting environments
\\definecolor{shadecolor}{RGB}{248,248,248}
\\newenvironment{Shaded}{\\begin{snugshade}}{\end{snugshade}}
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
\$if(title)\$
\\title{\$title\$}
\$endif\$
\$if(author)\$
\\author{\$author\$}
\$endif\$
\$if(date)\$
\\date{\$date\$}
\$else\$
\\date{}
\$endif\$

% Hyperref setup
\\hypersetup{
  colorlinks=true,
  linkcolor=blue,
  filecolor=magenta,
  urlcolor=cyan,
  pdftitle={\$if(title)\$\$title\$\$endif\$},
  pdfauthor={\$if(author)\$\$author\$\$endif\$},
  pdfborder={0 0 0}
}

\\begin{document}

\$if(title)\$
\\maketitle
\$endif\$

% Set TOC depth and generate TOC if needed
\\setcounter{tocdepth}{$ARG_TOC_DEPTH}
\$if(toc)\$
\\tableofcontents
\\newpage
\$endif\$

\$body\$

\\end{document}
EOF

    return $?
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}=== LaTeX-Markdown PDF Generator Prerequisites Check ===${NC}"
    echo

    # Check for Pandoc
    echo -e "${YELLOW}Checking for Pandoc...${NC}"
    PANDOC_INSTALLED=true
    if ! check_command pandoc; then
        PANDOC_INSTALLED=false
    fi
    echo

    # Check for LaTeX engines
    echo -e "${YELLOW}Checking for LaTeX engines...${NC}"
    LATEX_INSTALLED=false
    
    # Check for LaTeX engines
    LUALATEX_AVAILABLE=false
    XELATEX_AVAILABLE=false
    PDFLATEX_AVAILABLE=false
    
    if check_command lualatex; then
        LUALATEX_AVAILABLE=true
    fi
    
    if check_command xelatex; then
        XELATEX_AVAILABLE=true
    fi
    
    if check_command pdflatex; then
        PDFLATEX_AVAILABLE=true
    fi
    
    # Prioritize pdfLaTeX for better compatibility
    if [ "$PDFLATEX_AVAILABLE" = true ]; then
        LATEX_INSTALLED=true
        PDF_ENGINE="pdflatex"
    elif [ "$XELATEX_AVAILABLE" = true ]; then
        LATEX_INSTALLED=true
        PDF_ENGINE="xelatex"
    elif [ "$LUALATEX_AVAILABLE" = true ]; then
        LATEX_INSTALLED=true
        PDF_ENGINE="lualatex"
    fi

    if [ "$LATEX_INSTALLED" = true ]; then
        echo -e "Using PDF engine: ${GREEN}$PDF_ENGINE${NC}"
    else
        echo -e "${RED}No LaTeX engine found${NC}"
    fi
    echo

    # Check for required LaTeX packages
    if [ "$LATEX_INSTALLED" = true ]; then
        echo -e "${YELLOW}Checking for required LaTeX packages...${NC}"
        PACKAGES_MISSING=false
        
        # List of required packages
        REQUIRED_PACKAGES=(
            "geometry" "fancyhdr" "graphicx" "amsmath" "amssymb" "hyperref" "xcolor"
            "booktabs" "longtable" "amsthm" "fancyvrb" "framed" "listings" "array"
            "enumitem" "etoolbox" "float" "lmodern" "textcomp" "upquote" "microtype" "mhchem"
            "breqn"  # For automatic line breaking in equations
        )
        
        for package in "${REQUIRED_PACKAGES[@]}"; do
            if ! check_latex_package "$package"; then
                PACKAGES_MISSING=true
            fi
        done
        echo
    fi

    # Print installation instructions if prerequisites are missing
    if [ "$PANDOC_INSTALLED" = false ] || [ "$LATEX_INSTALLED" = false ] || [ "$PACKAGES_MISSING" = true ]; then
        echo -e "${YELLOW}=== Installation Instructions ===${NC}"
        
        if [ "$PANDOC_INSTALLED" = false ]; then
            echo -e "${YELLOW}To install Pandoc:${NC}"
            echo "  - Ubuntu/Debian: sudo apt-get install pandoc"
            echo "  - macOS with Homebrew: brew install pandoc"
            echo "  - Windows with Chocolatey: choco install pandoc"
            echo
        fi
        
        if [ "$LATEX_INSTALLED" = false ] || [ "$PACKAGES_MISSING" = true ]; then
            echo -e "${YELLOW}To install LaTeX with required packages:${NC}"
            echo "  - Ubuntu/Debian: sudo apt-get install texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-science"
            echo "  - macOS with Homebrew: brew install --cask mactex"
            echo "  - Windows: Install MiKTeX from https://miktex.org/download"
            echo
        fi
        
        echo -e "${RED}Please install the missing prerequisites and run this script again.${NC}"
        return 1
    fi

    echo -e "${GREEN}All prerequisites are installed!${NC}"
    echo
    return 0
}

# Function to preprocess markdown file for better LaTeX compatibility
preprocess_markdown() {
    local input_file="$1"
    local temp_file="${input_file}.temp"
    
    echo -e "${BLUE}Preprocessing markdown file for better LaTeX compatibility...${NC}"
    
    # Create a copy of the file
    cp "$input_file" "$temp_file"
    
    # Replace problematic Unicode characters with LaTeX commands
    if [ "$PDF_ENGINE" = "pdflatex" ]; then
        echo -e "${YELLOW}Using pdfLaTeX engine - replacing problematic Unicode characters with LaTeX commands${NC}"
        
        # Replace combining right harpoon (U+20D1) with \vec command
        # This is tricky because it's a combining character, so we need to capture the character it combines with
        sed -i 's/\\overset{⃑}/\\vec/g' "$temp_file"
        
        # Replace other common mathematical Unicode characters
        sed -i 's/ℝ/\\mathbb{R}/g' "$temp_file"
        sed -i 's/ℤ/\\mathbb{Z}/g' "$temp_file"
        sed -i 's/ℕ/\\mathbb{N}/g' "$temp_file"
        sed -i 's/ℚ/\\mathbb{Q}/g' "$temp_file"
        sed -i 's/ℂ/\\mathbb{C}/g' "$temp_file"
        sed -i 's/∞/\\infty/g' "$temp_file"
        sed -i 's/∫/\\int/g' "$temp_file"
        sed -i 's/∑/\\sum/g' "$temp_file"
        sed -i 's/∏/\\prod/g' "$temp_file"
        sed -i 's/√/\\sqrt/g' "$temp_file"
        sed -i 's/∂/\\partial/g' "$temp_file"
        sed -i 's/∇/\\nabla/g' "$temp_file"
        sed -i 's/∆/\\Delta/g' "$temp_file"
        sed -i 's/∈/\\in/g' "$temp_file"
        sed -i 's/∉/\\notin/g' "$temp_file"
        sed -i 's/∋/\\ni/g' "$temp_file"
        sed -i 's/⊂/\\subset/g' "$temp_file"
        sed -i 's/⊃/\\supset/g' "$temp_file"
        sed -i 's/⊆/\\subseteq/g' "$temp_file"
        sed -i 's/⊇/\\supseteq/g' "$temp_file"
        sed -i 's/∪/\\cup/g' "$temp_file"
        sed -i 's/∩/\\cap/g' "$temp_file"
        sed -i 's/≠/\\neq/g' "$temp_file"
        sed -i 's/≤/\\leq/g' "$temp_file"
        sed -i 's/≥/\\geq/g' "$temp_file"
        sed -i 's/≈/\\approx/g' "$temp_file"
        sed -i 's/≡/\\equiv/g' "$temp_file"
        sed -i 's/∼/\\sim/g' "$temp_file"
        sed -i 's/∝/\\propto/g' "$temp_file"
        sed -i 's/′/\\prime/g' "$temp_file"
        sed -i 's/″/\\prime\\prime/g' "$temp_file"
        sed -i 's/‴/\\prime\\prime\\prime/g' "$temp_file"
        sed -i 's/→/\\rightarrow/g' "$temp_file"
        sed -i 's/←/\\leftarrow/g' "$temp_file"
        sed -i 's/↔/\\leftrightarrow/g' "$temp_file"
        sed -i 's/⇒/\\Rightarrow/g' "$temp_file"
        sed -i 's/⇐/\\Leftarrow/g' "$temp_file"
        sed -i 's/⇔/\\Leftrightarrow/g' "$temp_file"
    fi
    
    # Move the temp file back to the original
    mv "$temp_file" "$input_file"
    
    echo -e "${GREEN}Preprocessing complete${NC}"
}

# Function to convert markdown to PDF
convert() {
    # Initialize variables for command-line arguments
    ARG_TITLE=""
    ARG_AUTHOR=""
    ARG_DATE=""
    ARG_FOOTER=""
    ARG_NO_FOOTER=false
    ARG_DATE_FOOTER=""
    ARG_NO_DATE=false
    ARG_TOC_DEPTH=$DEFAULT_TOC_DEPTH
    ARG_TOC=$DEFAULT_TOC
    ARG_SECTION_NUMBERS=$DEFAULT_SECTION_NUMBERS
    
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)
                ARG_TITLE="$2"
                shift 2
                ;;
            --toc-depth)
                ARG_TOC_DEPTH="$2"
                shift 2
                ;;
            --toc)
                ARG_TOC=true
                shift
                ;;
            --no-numbers|--no-section-numbers)
                ARG_SECTION_NUMBERS=false
                shift
                ;;
            -a|--author)
                ARG_AUTHOR="$2"
                shift 2
                ;;
            -d|--date)
                if [[ "$2" == -* ]] || [ -z "$2" ]; then
                    # No argument provided or next argument is another option
                    ARG_DATE="$(date +"%B %d, %Y")"
                    echo -e "${GREEN}Using current date: $ARG_DATE${NC}"
                    shift
                else
                    # Argument provided
                    case "$2" in
                        "no")
                            ARG_NO_DATE=true
                            echo -e "${GREEN}Date will be disabled${NC}"
                            ;;
                        "yes")
                            ARG_DATE="$(date +"%B %d, %Y")"
                            echo -e "${GREEN}Using current date: $ARG_DATE${NC}"
                            ;;
                        "YYYY-MM-DD")
                            ARG_DATE="$(date +"%Y-%m-%d")"
                            echo -e "${GREEN}Using current date in YYYY-MM-DD format: $ARG_DATE${NC}"
                            ;;
                        "DD/MM/YY")
                            ARG_DATE="$(date +"%d/%m/%y")"
                            echo -e "${GREEN}Using current date in DD/MM/YY format: $ARG_DATE${NC}"
                            ;;
                        "Month Day, Year"|"month day, year")
                            ARG_DATE="$(date +"%B %d, %Y")"
                            echo -e "${GREEN}Using current date in Month Day, Year format: $ARG_DATE${NC}"
                            ;;
                        *)
                            # Use the provided value as the date
                            ARG_DATE="$2"
                            echo -e "${GREEN}Using custom date: $ARG_DATE${NC}"
                            ;;
                    esac
                    shift 2
                fi
                ;;
            --no-date)
                ARG_NO_DATE=true
                echo -e "${GREEN}Date will be disabled${NC}"
                shift
                ;;
            -f|--footer)
                ARG_FOOTER="$2"
                shift 2
                ;;
            --no-footer)
                ARG_NO_FOOTER=true
                shift
                ;;
            --date-footer)
                if [[ "$2" == -* ]] || [ -z "$2" ]; then
                    # No argument provided or next argument is another option
                    ARG_DATE_FOOTER="DD/MM/YY"
                    shift
                else
                    # Argument provided
                    ARG_DATE_FOOTER="$2"
                    shift 2
                fi
                ;;
            *)
                # First non-option argument is the input file
                if [ -z "$INPUT_FILE" ]; then
                    INPUT_FILE="$1"
                # Second non-option argument is the output file
                elif [ -z "$OUTPUT_FILE" ]; then
                    OUTPUT_FILE="$1"
                else
                    echo -e "${RED}Error: Unexpected argument '$1'.${NC}"
                    echo -e "Usage: mdtexpdf convert [options] <input.md> [output.pdf]"
                    echo -e "Options:"
                    echo -e "  -t, --title TITLE     Set document title"
                    echo -e "  -a, --author AUTHOR   Set document author"
                    echo -e "  --toc                 Include table of contents"
                    echo -e "  --toc-depth DEPTH     Set table of contents depth (1-5, default: $DEFAULT_TOC_DEPTH)"
                    echo -e "  --no-numbers          Disable section numbering (1.1, 1.2, etc.)"
                    echo -e "  -d, --date [VALUE]    Set document date. Special values:"
                    echo -e "                          - no argument: current date in default format"
                    echo -e "                          - \"no\": disable date"
                    echo -e "                          - \"yes\": current date in default format"
                    echo -e "                          - \"YYYY-MM-DD\": current date in YYYY-MM-DD format"
                    echo -e "                          - \"DD/MM/YY\": current date in DD/MM/YY format"
                    echo -e "                          - \"Month Day, Year\": current date in Month Day, Year format"
                    echo -e "                          - any other value: use as custom date text"
                    echo -e "  --no-date             Disable date (same as -d \"no\")"
                    echo -e "  -f, --footer TEXT     Set footer text"
                    echo -e "  --no-footer           Disable footer"
                    echo -e "  --date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\""
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if input file is specified
    if [ -z "$INPUT_FILE" ]; then
        echo -e "${RED}Error: No input file specified.${NC}"
        echo -e "Usage: mdtexpdf convert [options] <input.md> [output.pdf]"
        echo -e "Options:"
        echo -e "  -t, --title TITLE     Set document title"
        echo -e "  -a, --author AUTHOR   Set document author"
        echo -e "  --toc                 Include table of contents"
        echo -e "  --toc-depth DEPTH     Set table of contents depth (1-5, default: $DEFAULT_TOC_DEPTH)"
        echo -e "  --no-numbers          Disable section numbering (1.1, 1.2, etc.)"
        echo -e "  -d, --date [VALUE]    Set document date. Special values:"
        echo -e "                          - no argument: current date in default format"
        echo -e "                          - \"no\": disable date"
        echo -e "                          - \"yes\": current date in default format"
        echo -e "                          - \"YYYY-MM-DD\": current date in YYYY-MM-DD format"
        echo -e "                          - \"DD/MM/YY\": current date in DD/MM/YY format"
        echo -e "                          - \"Month Day, Year\": current date in Month Day, Year format"
        echo -e "                          - any other value: use as custom date text"
        echo -e "  --no-date             Disable date (same as -d \"no\")"
        echo -e "  -f, --footer TEXT     Set footer text"
        echo -e "  --no-footer           Disable footer"
        echo -e "  --date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\""
        return 1
    fi

    # Check prerequisites first
    if ! check_prerequisites; then
        return 1
    fi

    # Check if input file exists
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}Error: Input file '$INPUT_FILE' not found.${NC}"
        return 1
    fi

    # Create a backup of the original markdown file
    BACKUP_FILE="${INPUT_FILE}.bak"
    echo -e "${BLUE}Creating backup of original markdown file: $BACKUP_FILE${NC}"
    cp "$INPUT_FILE" "$BACKUP_FILE"

    # If output file is not specified, derive from input file
    if [ -z "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="${INPUT_FILE%.md}.pdf"
    fi
    
    # Preprocess the markdown file for better LaTeX compatibility
    preprocess_markdown "$INPUT_FILE"
    
    # Image captions are now handled by the image_size_filter.lua Lua filter

    # Convert markdown to PDF using pandoc with our template
    echo -e "${YELLOW}Converting $INPUT_FILE to PDF...${NC}"
    echo -e "Using PDF engine: ${GREEN}$PDF_ENGINE${NC}"

    # No additional options needed for pdflatex
    PANDOC_OPTS=""

    # Check for template.tex in the current directory first (highest priority)
    TEMPLATE_IN_CURRENT_DIR=false
    TEMPLATE_PATH="$(pwd)/template.tex"
    
    if [ -f "$TEMPLATE_PATH" ]; then
        TEMPLATE_IN_CURRENT_DIR=true
    else
        # Not found in current directory, check other locations
        TEMPLATE_PATH=""
        
        # Check in templates subdirectory
        if [ -f "$(pwd)/templates/template.tex" ]; then
            TEMPLATE_PATH="$(pwd)/templates/template.tex"
        # Check in script directory
        elif [ -f "$(dirname "$(readlink -f "$0")")/templates/template.tex" ]; then
            TEMPLATE_PATH="$(dirname "$(readlink -f "$0")")/templates/template.tex"
        elif [ -f "$(dirname "$(readlink -f "$0")")/template.tex" ]; then
            TEMPLATE_PATH="$(dirname "$(readlink -f "$0")")/template.tex"
        # Check in system directory
        elif [ -f "/usr/local/share/mdtexpdf/templates/template.tex" ]; then
            TEMPLATE_PATH="/usr/local/share/mdtexpdf/templates/template.tex"
        fi
    fi
    
    # Debug output to show which template is being used
    echo -e "${BLUE}Debug: Template path is $TEMPLATE_PATH${NC}"
    echo -e "${BLUE}Debug: Template in current dir: $TEMPLATE_IN_CURRENT_DIR${NC}"
    
    # Check if we found a template in the current directory
    if [ "$TEMPLATE_IN_CURRENT_DIR" = true ]; then
        echo -e "Using template: ${GREEN}$TEMPLATE_PATH${NC}"
    else
        # Template not found in current directory
        if [ -n "$TEMPLATE_PATH" ]; then
            # Template found in another location
            echo -e "${YELLOW}No template.tex found in current directory.${NC}"
            echo -e "${GREEN}Do you want to create a template.tex now and update your file with the proper header? (y/n) [y]:${NC}"
        else
            # No template found anywhere
            echo -e "${YELLOW}No template.tex found.${NC}"
            echo -e "${GREEN}A template.tex file is required. Create one now? (y/n) [y]:${NC}"
        fi
        
        # Skip prompt if arguments were provided
        if [ -n "$ARG_TITLE" ] || [ -n "$ARG_AUTHOR" ] || [ -n "$ARG_DATE" ] || [ -n "$ARG_FOOTER" ] || [ "$ARG_NO_FOOTER" = true ]; then
            CREATE_TEMPLATE="y"
            echo -e "${BLUE}Using command-line arguments, automatically creating template...${NC}"
        else
            read CREATE_TEMPLATE
            CREATE_TEMPLATE=${CREATE_TEMPLATE:-"y"}
        fi
        
        echo -e "${BLUE}Debug: User chose to create template: $CREATE_TEMPLATE${NC}"
        
        # Create template if user chose to
        if [[ $CREATE_TEMPLATE =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Debug: Creating template...${NC}"
            # Get document details for both template and YAML frontmatter
            echo -e "${YELLOW}Setting up document preferences...${NC}"
            
            # Check if the file has a first-level heading (# Title) before asking for title
            FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')
            
            # Set title based on command-line argument or prompt user
            if [ -n "$ARG_TITLE" ]; then
                TITLE="$ARG_TITLE"
                echo -e "${GREEN}Using title from command-line argument: '$TITLE'${NC}"
            elif [ -n "$FIRST_HEADING" ]; then
                # If a first-level heading was found, use it as the default title
                echo -e "${BLUE}Found title in document: '$FIRST_HEADING'${NC}"
                echo -e "${GREEN}Enter document title (press Enter to use the found title) [${FIRST_HEADING}]:${NC}"
                read USER_TITLE
                
                if [ -z "$USER_TITLE" ]; then
                    # User pressed Enter, use the found title
                    TITLE="$FIRST_HEADING"
                    echo -e "${GREEN}Using found title: '$FIRST_HEADING'${NC}"
                else
                    # User entered a different title, use that instead
                    TITLE="$USER_TITLE"
                    echo -e "${GREEN}Using custom title: '$USER_TITLE'${NC}"
                fi
            else
                # Otherwise use filename as default
                DEFAULT_TITLE=$(basename "$INPUT_FILE" .md | sed 's/_/ /g' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
                echo -e "${GREEN}Enter document title [${DEFAULT_TITLE}]:${NC}"
                read TITLE
                TITLE=${TITLE:-"$DEFAULT_TITLE"}
            fi
            
            # Set author based on command-line argument or prompt user
            if [ -n "$ARG_AUTHOR" ]; then
                AUTHOR="$ARG_AUTHOR"
                echo -e "${GREEN}Using author from command-line argument: '$AUTHOR'${NC}"
            else
                echo -e "${GREEN}Enter author name [$(whoami)]:${NC}"
                read AUTHOR
                AUTHOR=${AUTHOR:-"$(whoami)"}
            fi
            
            # Set date based on command-line argument or prompt user
            if [ "$ARG_NO_DATE" = true ]; then
                DOC_DATE=""
                echo -e "${GREEN}Date is disabled${NC}"
            elif [ -n "$ARG_DATE" ]; then
                DOC_DATE="$ARG_DATE"
                echo -e "${GREEN}Using date from command-line argument: '$DOC_DATE'${NC}"
            else
                echo -e "${GREEN}Enter document date [$(date +"%B %d, %Y")]:${NC}"
                read DOC_DATE
                DOC_DATE=${DOC_DATE:-"$(date +"%B %d, %Y")"}
            fi
            
            # Set footer preferences based on command-line arguments or prompt user
            if [ "$ARG_NO_FOOTER" = true ]; then
                FOOTER_TEXT=""
                echo -e "${GREEN}Footer disabled via command-line argument${NC}"
            elif [ -n "$ARG_FOOTER" ]; then
                FOOTER_TEXT="$ARG_FOOTER"
                echo -e "${GREEN}Using footer text from command-line argument: '$FOOTER_TEXT'${NC}"
            else
                echo -e "${GREEN}Do you want to add a footer to your document? (y/n) [y]:${NC}"
                read ADD_FOOTER
                ADD_FOOTER=${ADD_FOOTER:-"y"}
                
                if [[ $ADD_FOOTER =~ ^[Yy]$ ]]; then
                    echo -e "${GREEN}Enter footer text (press Enter for default '© All rights reserved $(date +"%Y")'):${NC}"
                    read FOOTER_TEXT
                    FOOTER_TEXT=${FOOTER_TEXT:-"© All rights reserved $(date +"%Y")"}
                else
                    FOOTER_TEXT=""
                fi
            fi
            
            # Format the date footer if specified
            DATE_FOOTER_TEXT=""
            if [ -n "$ARG_DATE_FOOTER" ]; then
                case "$ARG_DATE_FOOTER" in
                    "DD/MM/YY")
                        DATE_FOOTER_TEXT="$(date +"%d/%m/%y")"
                        ;;
                    "YYYY-MM-DD")
                        DATE_FOOTER_TEXT="$(date +"%Y-%m-%d")"
                        ;;
                    "Month Day, Year"|"month day, year")
                        DATE_FOOTER_TEXT="$(date +"%B %d, %Y")"
                        ;;
                    *)
                        # Use the provided format as a custom date format
                        DATE_FOOTER_TEXT="$ARG_DATE_FOOTER"
                        ;;
                esac
                echo -e "${GREEN}Adding date to footer: $DATE_FOOTER_TEXT${NC}"
            fi
            
            # Create a template file in the current directory
            TEMPLATE_PATH="$(pwd)/template.tex"
            echo -e "${YELLOW}Creating template file: $TEMPLATE_PATH${NC}"
            create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" "$DATE_FOOTER_TEXT" "$ARG_SECTION_NUMBERS"
            
            if [ ! -f "$TEMPLATE_PATH" ]; then
                echo -e "${RED}Error: Failed to create template.tex.${NC}"
                return 1
            fi
            
            echo -e "${GREEN}Created new template file: $TEMPLATE_PATH${NC}"
            
            # Check if the Markdown file has proper YAML frontmatter
            if ! grep -q "^---" "$INPUT_FILE"; then
                echo -e "${YELLOW}Updating $INPUT_FILE with proper YAML frontmatter...${NC}"
                
                # Check if the file has a first-level heading (# Title)
                FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')
                
                # Create a temporary file with the YAML frontmatter
                TMP_FILE=$(mktemp)
                
                # Add YAML frontmatter with the user-specified title
                cat > "$TMP_FILE" << EOF
---
title: "$TITLE"
author: "$AUTHOR"
$([ -n "$DOC_DATE" ] && echo "date: \"$DOC_DATE\"")
output:
  pdf_document:
    template: template.tex
---

EOF
                
                # If a first-level heading was found and it matches the title we're using,
                # comment it out to avoid duplication
                if [ -n "$FIRST_HEADING" ]; then
                    if [ "$FIRST_HEADING" = "$TITLE" ]; then
                        # Title is the same as the first heading, comment it out
                        echo -e "${GREEN}Commenting out the first heading to avoid duplication.${NC}"
                        sed "0,/^# $FIRST_HEADING/s/^# $FIRST_HEADING/<!-- # $FIRST_HEADING -->/" "$INPUT_FILE" >> "$TMP_FILE"
                    else
                        # Title is different from the first heading, keep both
                        echo -e "${GREEN}Keeping the first heading as it differs from the title.${NC}"
                        cat "$INPUT_FILE" >> "$TMP_FILE"
                    fi
                else
                    # No first heading, just append the content
                    cat "$INPUT_FILE" >> "$TMP_FILE"
                fi
                
                # Replace the original file
                mv "$TMP_FILE" "$INPUT_FILE"
                
                echo -e "${GREEN}Updated $INPUT_FILE with proper YAML frontmatter.${NC}"
            fi
        else
            # User chose not to create a template
            if [ -n "$TEMPLATE_PATH" ]; then
                # Use the template from another location
                echo -e "Using template: ${GREEN}$TEMPLATE_PATH${NC}"
            else
                echo -e "${RED}Cannot proceed without a template.${NC}"
                return 1
            fi
        fi
    fi

    # Find the path to the Lua filters
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    LUA_FILTERS=()
    
    # Check for long equation filter
    if [ -f "$(pwd)/long_equation_filter.lua" ]; then
        LUA_FILTERS+=("$(pwd)/long_equation_filter.lua")
        echo -e "${BLUE}Using Lua filter for long equation handling: $(pwd)/long_equation_filter.lua${NC}"
    elif [ -f "$SCRIPT_DIR/long_equation_filter.lua" ]; then
        LUA_FILTERS+=("$SCRIPT_DIR/long_equation_filter.lua")
        echo -e "${BLUE}Using Lua filter for long equation handling: $SCRIPT_DIR/long_equation_filter.lua${NC}"
    elif [ -f "/usr/local/share/mdtexpdf/long_equation_filter.lua" ]; then
        LUA_FILTERS+=("/usr/local/share/mdtexpdf/long_equation_filter.lua")
        echo -e "${BLUE}Using Lua filter for long equation handling: /usr/local/share/mdtexpdf/long_equation_filter.lua${NC}"
    else
        echo -e "${YELLOW}Warning: long_equation_filter.lua not found. Long equations may not wrap properly.${NC}"
    fi
    
    # Check for image size filter
    if [ -f "$(pwd)/image_size_filter.lua" ]; then
        LUA_FILTERS+=("$(pwd)/image_size_filter.lua")
        echo -e "${BLUE}Using Lua filter for automatic image sizing: $(pwd)/image_size_filter.lua${NC}"
    elif [ -f "$SCRIPT_DIR/image_size_filter.lua" ]; then
        LUA_FILTERS+=("$SCRIPT_DIR/image_size_filter.lua")
        echo -e "${BLUE}Using Lua filter for automatic image sizing: $SCRIPT_DIR/image_size_filter.lua${NC}"
    elif [ -f "/usr/local/share/mdtexpdf/image_size_filter.lua" ]; then
        LUA_FILTERS+=("/usr/local/share/mdtexpdf/image_size_filter.lua")
        echo -e "${BLUE}Using Lua filter for automatic image sizing: /usr/local/share/mdtexpdf/image_size_filter.lua${NC}"
    else
        echo -e "${YELLOW}Warning: image_size_filter.lua not found. Images may not be properly sized.${NC}"
    fi
    
    # Build filter options
    FILTER_OPTION=""
    for filter in "${LUA_FILTERS[@]}"; do
        FILTER_OPTION="$FILTER_OPTION --lua-filter=$filter"
    done

    # Run pandoc with the selected PDF engine
    echo -e "${BLUE}Using enhanced equation line breaking for text-heavy equations${NC}"
    
    # Add TOC option if requested
    TOC_OPTION=""
    if [ "$ARG_TOC" = true ]; then
        TOC_OPTION="--toc"
    fi
    
    # Generate section numbering variable for pandoc if needed
    SECTION_NUMBERING_OPTION=""
    if [ "$ARG_SECTION_NUMBERS" = false ]; then
        SECTION_NUMBERING_OPTION="--variable=numbersections=false"
    fi

    pandoc "$INPUT_FILE" \
        --from markdown \
        --to pdf \
        --output "$OUTPUT_FILE" \
        --template="$TEMPLATE_PATH" \
        --pdf-engine=$PDF_ENGINE \
        $PANDOC_OPTS \
        $FILTER_OPTION \
        --variable=geometry:margin=1in \
        --highlight-style=tango \
        --listings \
        $TOC_OPTION \
        $SECTION_NUMBERING_OPTION \
        --standalone

    # Check if conversion was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success! PDF created as $OUTPUT_FILE${NC}"
        
        # Clean up: Remove template.tex file if it was created in the current directory
        if [ -f "$(pwd)/template.tex" ]; then
            echo -e "${BLUE}Cleaning up: Removing template.tex${NC}"
            rm -f "$(pwd)/template.tex"
        fi
        
        # Restore the original markdown file from backup
        if [ -f "$BACKUP_FILE" ]; then
            echo -e "${BLUE}Restoring original markdown file from backup${NC}"
            mv "$BACKUP_FILE" "$INPUT_FILE"
        fi
        
        echo -e "${GREEN}Cleanup complete. Only the PDF and original markdown file remain.${NC}"
        return 0
    else
        echo -e "${RED}Error: PDF conversion failed.${NC}"
        
        # Restore the original markdown file from backup even if conversion failed
        if [ -f "$BACKUP_FILE" ]; then
            echo -e "${BLUE}Restoring original markdown file from backup${NC}"
            mv "$BACKUP_FILE" "$INPUT_FILE"
        fi
        
        return 1
    fi
}

# Function to create a new markdown document with LaTeX template
create() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: No output file specified.${NC}"
        echo -e "Usage: mdtexpdf create <output.md> [title] [author]"
        return 1
    fi

    OUTPUT_FILE="$1"
    
    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "${RED}Error: File '$OUTPUT_FILE' already exists.${NC}"
        echo -e "Use a different filename or delete the existing file."
        return 1
    fi

    echo -e "${YELLOW}Creating new markdown document: $OUTPUT_FILE${NC}"
    
    # Interactive mode - ask for document details
    if [ -z "$2" ]; then
        echo -e "${GREEN}Enter document title:${NC}"
        read TITLE
        TITLE=${TITLE:-"My Document"}
    else
        TITLE="$2"
    fi
    
    if [ -z "$3" ]; then
        echo -e "${GREEN}Enter author name:${NC}"
        read AUTHOR
        AUTHOR=${AUTHOR:-"$(whoami)"}
    else
        AUTHOR="$3"
    fi
    
    echo -e "${GREEN}Enter document date [$(date +"%B %d, %Y")]:${NC}"
    read DOC_DATE
    DOC_DATE=${DOC_DATE:-"$(date +"%B %d, %Y")"}
    
    # Always ask about footer preferences
    echo -e "${GREEN}Do you want to add a footer to your document? (y/n) [y]:${NC}"
    read ADD_FOOTER
    ADD_FOOTER=${ADD_FOOTER:-"y"}
    
    if [[ $ADD_FOOTER =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Enter footer text (press Enter for default '© All rights reserved $(date +"%Y")'):${NC}"
        read FOOTER_TEXT
        FOOTER_TEXT=${FOOTER_TEXT:-"© All rights reserved $(date +"%Y")"}
    else
        FOOTER_TEXT=""
    fi
    
    # Always create a new template.tex in the current directory
    TEMPLATE_PATH="$(pwd)/template.tex"
    echo -e "${YELLOW}Creating template file: $TEMPLATE_PATH${NC}"
    
    # Create the template file
    create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" ""
    
    if [ ! -f "$TEMPLATE_PATH" ]; then
        echo -e "${RED}Error: Failed to create template.tex.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Created new template file: $TEMPLATE_PATH${NC}"
    
    # Debug output to show which template is being used
    echo -e "${BLUE}Debug: Template path is $TEMPLATE_PATH${NC}"
    
    # Create the markdown file with YAML frontmatter and example content
    cat > "$OUTPUT_FILE" << EOF
---
title: "$TITLE"
author: "$AUTHOR"
$([ -n "$DOC_DATE" ] && echo "date: \"$DOC_DATE\"")
output:
  pdf_document:
    template: template.tex
---

# $TITLE

## Introduction

This is a sample document created with mdtexpdf. You can write regular Markdown text here.

## LaTeX Math Support

You can include inline math equations like this: \$E = mc^2\$ or \\\(F = ma\\\).

For display equations, use double dollar signs:

\$\$\\int_{a}^{b} f(x) \\, dx = F(b) - F(a)\$\$

## Formatting

You can use **bold text**, *italic text*, and \`code\`.

- Bullet points
- Work as expected

1. Numbered lists
2. Also work well

> Blockquotes are supported too.

## Tables

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

## Code Blocks

\`\`\`python
def hello_world():
    print("Hello, world!")
\`\`\`

---
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success! Markdown document created as $OUTPUT_FILE${NC}"
        echo -e "You can now edit this file and convert it to PDF using:"
        echo -e "${BLUE}mdtexpdf convert $OUTPUT_FILE${NC}"
        return 0
    else
        echo -e "${RED}Error: Failed to create markdown document.${NC}"
        return 1
    fi
}

# Function to install the script
install() {
    echo
    echo -e "${GREEN}Installing mdtexpdf...${NC}"
    if sudo -v; then
        # Create directories for templates and resources
        sudo mkdir -p /usr/local/share/mdtexpdf/templates
        sudo mkdir -p /usr/local/share/mdtexpdf/examples
        
        # Copy the script to /usr/local/bin
        sudo cp "$0" /usr/local/bin/mdtexpdf
        sudo chmod 755 /usr/local/bin/mdtexpdf
        
        # Copy the Lua filters if they exist
        SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
        
        # Copy long equation filter
        if [ -f "$SCRIPT_DIR/long_equation_filter.lua" ]; then
            sudo cp "$SCRIPT_DIR/long_equation_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/long_equation_filter.lua
            echo -e "${GREEN}✓ Installed long_equation_filter.lua for handling text-heavy equations${NC}"
        elif [ -f "$(pwd)/long_equation_filter.lua" ]; then
            sudo cp "$(pwd)/long_equation_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/long_equation_filter.lua
            echo -e "${GREEN}✓ Installed long_equation_filter.lua for handling text-heavy equations${NC}"
        else
            echo -e "${YELLOW}Warning: long_equation_filter.lua not found. Long equations may not wrap properly.${NC}"
        fi
        
        # Copy image size filter
        if [ -f "$SCRIPT_DIR/image_size_filter.lua" ]; then
            sudo cp "$SCRIPT_DIR/image_size_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/image_size_filter.lua
            echo -e "${GREEN}✓ Installed image_size_filter.lua for automatic image sizing${NC}"
        elif [ -f "$(pwd)/image_size_filter.lua" ]; then
            sudo cp "$(pwd)/image_size_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/image_size_filter.lua
            echo -e "${GREEN}✓ Installed image_size_filter.lua for automatic image sizing${NC}"
        else
            echo -e "${YELLOW}Warning: image_size_filter.lua not found. Images may not be properly sized.${NC}"
        fi
        
        # Copy templates to the shared directory
        
        # Look for templates in various locations
        if [ -d "$SCRIPT_DIR/templates" ]; then
            sudo cp -r "$SCRIPT_DIR/templates/"* /usr/local/share/mdtexpdf/templates/
            sudo chmod 644 /usr/local/share/mdtexpdf/templates/*
        elif [ -f "$SCRIPT_DIR/template.tex" ]; then
            sudo cp "$SCRIPT_DIR/template.tex" /usr/local/share/mdtexpdf/templates/
            sudo chmod 644 /usr/local/share/mdtexpdf/templates/template.tex
        fi
        
        # Copy example files
        if [ -d "$SCRIPT_DIR/examples" ]; then
            sudo cp -r "$SCRIPT_DIR/examples/"* /usr/local/share/mdtexpdf/examples/
            sudo chmod 644 /usr/local/share/mdtexpdf/examples/*
        elif [ -f "$SCRIPT_DIR/document.md" ] || [ -f "$SCRIPT_DIR/example.md" ]; then
            [ -f "$SCRIPT_DIR/document.md" ] && sudo cp "$SCRIPT_DIR/document.md" /usr/local/share/mdtexpdf/examples/
            [ -f "$SCRIPT_DIR/example.md" ] && sudo cp "$SCRIPT_DIR/example.md" /usr/local/share/mdtexpdf/examples/
            sudo chmod 644 /usr/local/share/mdtexpdf/examples/*
        else
            echo -e "${YELLOW}Warning: template.tex not found in the script directory.${NC}"
            echo -e "You'll need to provide your own template.tex file when converting documents."
        fi

        echo
        echo -e "${PURPLE}mdtexpdf has been installed successfully.${NC}"
        echo -e "You can now use ${GREEN}mdtexpdf${NC} command from anywhere."
        echo
        echo -e "Use ${BLUE}mdtexpdf help${NC} to see the commands."
        echo
    else
        echo -e "${RED}Error: Failed to obtain sudo privileges. Installation aborted.${NC}"
        exit 1
    fi
}

# Function to uninstall the script
uninstall() {
    echo
    echo -e "${GREEN}Uninstalling mdtexpdf...${NC}"
    if sudo -v; then
        echo -e "${YELLOW}Removing executable...${NC}"
        sudo rm -f /usr/local/bin/mdtexpdf
        
        echo -e "${YELLOW}Removing shared files...${NC}"
        sudo rm -rf /usr/local/share/mdtexpdf
        
        echo -e "${PURPLE}mdtexpdf has been uninstalled successfully.${NC}"
        echo
    else
        echo -e "${RED}Error: Failed to obtain sudo privileges. Uninstallation aborted.${NC}"
        exit 1
    fi
}

# Function to display help information
help() {
    echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}         mdtexpdf - Markdown to PDF         ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"
    
    echo -e "${PURPLE}Description:${NC} mdtexpdf is a tool for converting Markdown documents to PDF using LaTeX templates."
    echo -e "${PURPLE}             It supports LaTeX math equations, custom templates, and more.${NC}"
    echo -e "${PURPLE}Usage:${NC}       mdtexpdf <command> [arguments]"
    echo -e "${PURPLE}License:${NC}     Apache 2.0"
    echo -e "${PURPLE}Code:${NC}        https://github.com/mik-tf/mdtexpdf\n"
    
    echo -e "${PURPLE}Commands:${NC}"
    echo -e "  ${GREEN}convert [options] <input.md> [output.pdf]${NC}"
    echo -e "                  ${BLUE}Convert a Markdown file to PDF using LaTeX${NC}"
    echo -e "                  ${BLUE}Options:${NC}"
    echo -e "                    ${BLUE}-t, --title TITLE     Set document title${NC}"
    echo -e "                    ${BLUE}-a, --author AUTHOR   Set document author${NC}"
    echo -e "                    ${BLUE}--toc                 Include table of contents${NC}"
    echo -e "                    ${BLUE}--toc-depth DEPTH     Set table of contents depth (1-5, default: $DEFAULT_TOC_DEPTH)${NC}"
    echo -e "                    ${BLUE}--no-numbers          Disable section numbering (1.1, 1.2, etc.)${NC}"
    echo -e "                    ${BLUE}-d, --date [VALUE]    Set document date. Special values:${NC}"
    echo -e "                    ${BLUE}                        - no argument: current date in default format${NC}"
    echo -e "                    ${BLUE}                        - \"no\": disable date${NC}"
    echo -e "                    ${BLUE}                        - \"yes\": current date in default format${NC}"
    echo -e "                    ${BLUE}                        - \"YYYY-MM-DD\": current date in YYYY-MM-DD format${NC}"
    echo -e "                    ${BLUE}                        - \"DD/MM/YY\": current date in DD/MM/YY format${NC}"
    echo -e "                    ${BLUE}                        - \"Month Day, Year\": current date in Month Day, Year format${NC}"
    echo -e "                    ${BLUE}                        - any other value: use as custom date text${NC}"
    echo -e "                    ${BLUE}--no-date             Disable date (same as -d \"no\")${NC}"
    echo -e "                    ${BLUE}-f, --footer TEXT     Set footer text${NC}"
    echo -e "                    ${BLUE}--no-footer           Disable footer${NC}"
    echo -e "                    ${BLUE}--date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\"${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf convert document.md"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf convert -a \"John Doe\" -t \"My Document\" --toc --toc-depth 3 document.md output.pdf\n"
    
    echo -e "  ${GREEN}create <output.md> [title] [author]${NC}"
    echo -e "                  ${BLUE}Create a new Markdown document with LaTeX template${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf create document.md"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf create document.md \"My Title\" \"Author Name\"\n"
    
    echo -e "  ${GREEN}check${NC}"
    echo -e "                  ${BLUE}Check if all prerequisites are installed${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf check\n"
    
    echo -e "  ${GREEN}install${NC}"
    echo -e "                  ${BLUE}Install mdtexpdf system-wide${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf install\n"
    
    echo -e "  ${GREEN}uninstall${NC}"
    echo -e "                  ${BLUE}Remove mdtexpdf from the system${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf uninstall\n"
    
    echo -e "  ${GREEN}help${NC}"
    echo -e "                  ${BLUE}Display this help information${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf help\n"
    
    echo -e "${PURPLE}Prerequisites:${NC}"
    echo -e "  - Pandoc: Document conversion tool"
    echo -e "  - LaTeX: PDF generation engine (pdflatex, xelatex, or lualatex)"
    echo -e "  - LaTeX Packages: Various packages for formatting and math support\n"
    
    echo -e "${PURPLE}For more information, see the README.md file.${NC}\n"
}

# Main script execution
case "$1" in
    convert)
        shift
        convert "$@"
        ;;
    create)
        shift
        create "$@"
        ;;
    check)
        check_prerequisites
        ;;
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    help)
        help
        ;;
    *)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: No command specified.${NC}"
        else
            echo -e "${RED}Error: Unknown command '$1'.${NC}"
        fi
        echo -e "Use ${BLUE}mdtexpdf help${NC} to see available commands."
        exit 1
        ;;
esac

exit $?