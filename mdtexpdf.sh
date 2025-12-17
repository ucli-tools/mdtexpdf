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
        numbering_commands="\\setcounter{secnumdepth}{0}"
    fi

    # Simplified title page logic - always use \maketitle
    local title_page_logic="\$if(title)\$\\maketitle\$endif\$"
    
    # Set document class and book-specific commands based on format
    local docclass_opts="12pt"
    local docclass="article"
    local book_specific_commands=""
    if [ "$format" = "book" ]; then
        docclass="book"
        docclass_opts="12pt, openany"
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
    \documentclass[$docclass_opts]{$docclass}
    
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
    \\usepackage{lastpage} % For page X of Y numbering
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
    $book_specific_commands
    
    % Define \real command if it doesn't exist (alternative to realnum package)
    \\providecommand{\\real}[1]{#1}
    
    % Define \arraybackslash if it doesn't exist
    \\providecommand{\\arraybackslash}{\\let\\\\\\tabularnewline}
    
    % Define \pandocbounded command used by Pandoc for complex math expressions
    \\providecommand{\\pandocbounded}[1]{\\ensuremath{#1}}
    
    % Define \passthrough command, sometimes used by Pandoc with --listings
    \providecommand{\passthrough}[1]{#1}
    
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

        % Define Unicode box-drawing characters for pdfLaTeX
        \newunicodechar{├}{\texttt{|--}}
        \newunicodechar{│}{\texttt{|}}
        \newunicodechar{└}{\texttt{$(printf %s '\`')--}}
        \newunicodechar{─}{\texttt{-}}
        % Mathematical symbols (text mode compatible)
        \newunicodechar{ℝ}{\ensuremath{\mathbb{R}}}
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

% Header and Footer Setup
    \pagestyle{fancy}
    \fancyhf{} % Clear all header and footer fields first

    % Setup Header
    \fancyhead[L]{\small\textit{$doc_author}}
    \fancyhead[R]{\small\textit{$doc_title}}
    \renewcommand{\headrulewidth}{0.4pt}

    % Setup Footer (conditionally)
    \$if(no_footer)\$
        % All footers (L, C, R) remain empty
        \renewcommand{\footrulewidth}{0pt} % No footrule if no_footer is true
    \$else\$
        % Left Footer (Date)
        \$if(date_footer_content)\$
            \fancyfoot[L]{\$date_footer_content\$}
        \$endif\$

        % Center Footer (Custom text / Copyright)
        \$if(center_footer_content)\$
            \fancyfoot[C]{\$center_footer_content\$}
        \$else\$
            % Default center footer if -f is not used and not --no-footer
            \fancyfoot[C]{\copyright All rights reserved \the\year} % Default copyright
        \$endif\$

        % Right Footer (Page number)
        \$if(page_of_format)\$
            \fancyfoot[R]{\thepage/\pageref{LastPage}}
        \$else\$
            \fancyfoot[R]{\thepage}
        \$endif\$
        \renewcommand{\footrulewidth}{0.4pt} % Footrule active if footers are shown
    \$endif\$

% First page style (plain) - should mirror the above logic
\fancypagestyle{plain}{
    \fancyhf{} % Clear header/footer for plain style
    
    % Conditionally add headers based on header_footer_policy
    \$if(header_footer_policy_all)\$
        % Include headers on all plain pages (title, part, chapter pages) when policy is all
        \fancyhead[L]{\small\textit{$doc_author}}
        \fancyhead[R]{\small\textit{$doc_title}}
        \renewcommand{\headrulewidth}{0.4pt}
    \$elseif(header_footer_policy_partial)\$
        % Include headers on part and chapter pages, but not title page when policy is partial
        \fancyhead[L]{\small\textit{$doc_author}}
        \fancyhead[R]{\small\textit{$doc_title}}
        \renewcommand{\headrulewidth}{0.4pt}
    \$else\$
        % No headers on plain pages (default behavior)
        \renewcommand{\headrulewidth}{0pt}
    \$endif\$

    % Footer logic based on header_footer_policy
    \$if(header_footer_policy_all)\$
        % Include footers on all plain pages when policy is all
        \$if(no_footer)\$
            % All footers remain empty
            \renewcommand{\footrulewidth}{0pt}
        \$else\$
            % Left Footer (Date)
            \$if(date_footer_content)\$
                \fancyfoot[L]{\$date_footer_content\$}
            \$endif\$

            % Center Footer (Custom text / Copyright)
            \$if(center_footer_content)\$
                \fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \fancyfoot[C]{\copyright All rights reserved \the\year} % Default copyright
            \$endif\$

            % Right Footer (Page number)
            \$if(page_of_format)\$
                \fancyfoot[R]{\thepage/\pageref{LastPage}}
            \$else\$
                \fancyfoot[R]{\thepage}
            \$endif\$
            \renewcommand{\footrulewidth}{0.4pt}
        \$endif\$
    \$elseif(header_footer_policy_partial)\$
        % Include footers on part and chapter pages, but not title page when policy is partial
        \$if(no_footer)\$
            % All footers remain empty
            \renewcommand{\footrulewidth}{0pt}
        \$else\$
            % Left Footer (Date)
            \$if(date_footer_content)\$
                \fancyfoot[L]{\$date_footer_content\$}
            \$endif\$

            % Center Footer (Custom text / Copyright)
            \$if(center_footer_content)\$
                \fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \fancyfoot[C]{\copyright All rights reserved \the\year} % Default copyright
            \$endif\$

            % Right Footer (Page number)
            \$if(page_of_format)\$
                \fancyfoot[R]{\thepage/\pageref{LastPage}}
            \$else\$
                \fancyfoot[R]{\thepage}
            \$endif\$
            \renewcommand{\footrulewidth}{0.4pt}
        \$endif\$
    \$else\$
        % No footers on plain pages (default behavior)
        \renewcommand{\footrulewidth}{0pt}
    \$endif\$
}

% Title page style - specific handling for title page
\fancypagestyle{titlepage}{
    \fancyhf{} % Clear header/footer for title page
    
    % Only add headers/footers on title page if policy is 'all'
    \$if(header_footer_policy_all)\$
        \fancyhead[L]{\small\textit{$doc_author}}
        \fancyhead[R]{\small\textit{$doc_title}}
        \renewcommand{\headrulewidth}{0.4pt}
        
        \$if(no_footer)\$
            % All footers remain empty
        \$else\$
            % Left Footer (Date)
            \$if(date_footer_content)\$
                \fancyfoot[L]{\$date_footer_content\$}
            \$endif\$

            % Center Footer (Custom text / Copyright)
            \$if(center_footer_content)\$
                \fancyfoot[C]{\$center_footer_content\$}
            \$else\$
                \fancyfoot[C]{\copyright All rights reserved \the\year} % Default copyright
            \$endif\$

            % Right Footer (Page number)
            \$if(page_of_format)\$
                \fancyfoot[R]{\thepage/\pageref{LastPage}}
            \$else\$
                \fancyfoot[R]{\thepage}
            \$endif\$
            \renewcommand{\footrulewidth}{0.4pt}
        \$endif\$
    \$else\$
        % No headers/footers on title page for default and partial policies
        \renewcommand{\headrulewidth}{0pt}
        \renewcommand{\footrulewidth}{0pt}
    \$endif\$
}

% Adjust paragraph spacing: add a full line skip between paragraphs
\\setlength{\\parskip}{\\baselineskip}
% Remove paragraph indentation
\\setlength{\\parindent}{0pt}
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
% Only set \title for article format or when not using custom title page
\$if(title)\$
\$if(format_book)\$
\$if(header_footer_policy_all)\$
% For book format with 'all' policy, custom title page is used, don't set \title
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
  pdfborder={0 0 0}
}

\\begin{document}

\$if(title)\$
\$if(header_footer_policy_all)\$
\$if(format_book)\$
% For book format with 'all' policy, create custom title page that respects headers/footers
\\thispagestyle{titlepage}
\\begin{center}
\\vspace*{\\fill}
{\\Huge \\textbf{\$title\$}}\\\\[0.5cm]
\$if(subtitle)\$
{\\LARGE \\itshape \$subtitle\$}\\\\[1.5cm]
\$endif\$
\$if(author)\$
{\\large \$author\$ \$if(email)\$ --- \$email\$ \$endif\$}\\\\[1cm]
\$endif\$
\$if(date)\$
{\\large \$date\$}
\$endif\$
\\vspace*{\\fill}
\\end{center}
\\newpage
\$else\$
% For article format with 'all' policy, use standard maketitle but ensure headers/footers work
\\maketitle
\$endif\$
\$else\$
% For default and partial policies, use standard maketitle
\\maketitle
\$endif\$
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
    
    # Remove duplicate title H1 heading if it matches YAML frontmatter title
    if [ -n "$META_TITLE" ]; then
        # Get the first H1 heading from the content (after YAML frontmatter)
        local first_h1=$(awk '/^---$/{if(!yaml) yaml=1; else {yaml=0; next}} yaml{next} /^# /{print substr($0,3); exit}' "$temp_file")

        # Compare with metadata title (remove quotes for comparison)
        local meta_title_clean=$(echo "$META_TITLE" | sed 's/^["\x27]*//; s/["\x27]*$//')

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
        # This is tricky because it's a combining character, so we need to capture the character it combines with
        sed -i 's/\\overset{⃑}/\\vec/g' "$temp_file"

        # All other Unicode characters are handled by \newunicodechar in the template
        # No additional preprocessing needed
    fi
    
    # Move the temp file back to the original
    mv "$temp_file" "$input_file"
    
    echo -e "${GREEN}Preprocessing complete${NC}"
}

# Function to parse HTML metadata from markdown file
parse_html_metadata() {
    local input_file="$1"
    
    # Initialize metadata variables
    META_TITLE=""
    META_AUTHOR=""
    META_DATE=""
    META_DESCRIPTION=""
    META_SECTION=""
    META_SLUG=""
    META_FOOTER=""
    META_TOC=""
    META_TOC_DEPTH=""
    META_NO_NUMBERS=""
    META_NO_FOOTER=""
    META_PAGEOF=""
    META_DATE_FOOTER=""
    META_NO_DATE=""
    META_FORMAT="article" # Default format
    META_HEADER_FOOTER_POLICY="" # New metadata for header/footer policy
    
    echo -e "${BLUE}Parsing metadata from HTML comments...${NC}"
    
    # Extract metadata from multi-line HTML comment block
    local in_comment=false
    while IFS= read -r line; do
        # Check if we're entering a comment block
        if echo "$line" | grep -q "^[[:space:]]*<!--[[:space:]]*$"; then
            in_comment=true
            continue
        fi
        
        # Check if we're exiting a comment block
        if echo "$line" | grep -q "^[[:space:]]*-->[[:space:]]*$"; then
            in_comment=false
            continue
        fi
        
        # If we're inside a comment block, parse key: value pairs
        if [ "$in_comment" = true ]; then
            # Check if line contains key: value format
            if echo "$line" | grep -q ":"; then
                local key=$(echo "$line" | sed -n 's/^[[:space:]]*\([^:]*\):[[:space:]]*.*$/\1/p')
                local value=$(echo "$line" | sed -n 's/^[[:space:]]*[^:]*:[[:space:]]*"\?\([^"]*\)"\?[[:space:]]*$/\1/p')
                
                # If value extraction with quotes failed, try without quotes
                if [ -z "$value" ]; then
                    value=$(echo "$line" | sed -n 's/^[[:space:]]*[^:]*:[[:space:]]*\(.*\)[[:space:]]*$/\1/p')
                fi
                
                # Trim whitespace from key and value
                key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            else
                continue
            fi
        else
            continue
        fi
        
        case "$key" in
            "description")
                META_DESCRIPTION="$value"
                echo -e "${GREEN}Found metadata - description: $value${NC}"
                ;;
            "section")
                META_SECTION="$value"
                echo -e "${GREEN}Found metadata - section: $value${NC}"
                ;;
            "date")
                META_DATE="$value"
                echo -e "${GREEN}Found metadata - date: $value${NC}"
                ;;
            "slug")
                META_SLUG="$value"
                echo -e "${GREEN}Found metadata - slug: $value${NC}"
                ;;
            "author")
                META_AUTHOR="$value"
                echo -e "${GREEN}Found metadata - author: $value${NC}"
                ;;
            "footer")
                META_FOOTER="$value"
                echo -e "${GREEN}Found metadata - footer: $value${NC}"
                ;;
            "toc")
                META_TOC="$value"
                echo -e "${GREEN}Found metadata - toc: $value${NC}"
                ;;
            "toc_depth")
                META_TOC_DEPTH="$value"
                echo -e "${GREEN}Found metadata - toc_depth: $value${NC}"
                ;;
            "no_numbers")
                META_NO_NUMBERS="$value"
                echo -e "${GREEN}Found metadata - no_numbers: $value${NC}"
                ;;
            "no_footer")
                META_NO_FOOTER="$value"
                echo -e "${GREEN}Found metadata - no_footer: $value${NC}"
                ;;
            "pageof")
                META_PAGEOF="$value"
                echo -e "${GREEN}Found metadata - pageof: $value${NC}"
                ;;
            "date_footer")
                META_DATE_FOOTER="$value"
                echo -e "${GREEN}Found metadata - date_footer: $value${NC}"
                ;;
            "no_date")
                META_NO_DATE="$value"
                echo -e "${GREEN}Found metadata - no_date: $value${NC}"
                ;;
            "format")
                META_FORMAT="$value"
                echo -e "${GREEN}Found metadata - format: $value${NC}"
                ;;
            "header_footer_policy")
                case "$value" in
                    "default"|"partial"|"all")
                        META_HEADER_FOOTER_POLICY="$value"
                        echo -e "${GREEN}Found metadata - header_footer_policy: $value${NC}"
                        ;;
                    *)
                        echo -e "${YELLOW}Warning: Invalid header_footer_policy '$value' in metadata. Valid options: default, partial, all${NC}"
                        ;;
                esac
                ;;
        esac
    done < "$input_file"
    
    # Extract title from first H1 heading if not provided in metadata
    if [ -z "$META_TITLE" ]; then
        META_TITLE=$(grep -m 1 "^# " "$input_file" | sed 's/^# //')
        if [ -n "$META_TITLE" ]; then
            echo -e "${GREEN}Found title from H1 heading: $META_TITLE${NC}"
        fi
    fi
}

# Function to parse YAML frontmatter from markdown file
parse_yaml_metadata() {
    local input_file="$1"
    
    # Initialize metadata variables
    META_TITLE=""
    META_AUTHOR=""
    META_DATE=""
    META_DESCRIPTION=""
    META_SECTION=""
    META_SLUG=""
    META_FOOTER=""
    META_TOC=""
    META_TOC_DEPTH=""
    META_NO_NUMBERS=""
    META_NO_FOOTER=""
    META_PAGEOF=""
    META_DATE_FOOTER=""
    META_NO_DATE=""
    META_FORMAT="article" # Default format
    META_HEADER_FOOTER_POLICY="" # New metadata for header/footer policy
    META_LANGUAGE=""
    META_GENRE=""
    META_NARRATOR_VOICE=""
    META_READING_SPEED=""
    
    echo -e "${BLUE}Parsing metadata from YAML frontmatter...${NC}"
    
    # Check if file has YAML frontmatter (starts with ---)
    if ! head -n 1 "$input_file" | grep -q "^---\s*$"; then
        echo -e "${YELLOW}No YAML frontmatter found, trying H1 title extraction...${NC}"
        # Extract title from first H1 heading if no frontmatter
        META_TITLE=$(grep -m 1 "^# " "$input_file" | sed 's/^# //')
        if [ -n "$META_TITLE" ]; then
            echo -e "${GREEN}Found title from H1 heading: $META_TITLE${NC}"
        fi
        return
    fi
    
    # Extract YAML frontmatter block (between first --- and second ---)
    local yaml_content
    yaml_content=$(sed -n '/^---$/,/^---$/p' "$input_file" | sed '1d;$d')
    
    if [ -z "$yaml_content" ]; then
        echo -e "${YELLOW}Empty YAML frontmatter block${NC}"
        return
    fi
    
    # Create temporary YAML file for parsing
    local temp_yaml=$(mktemp)
    echo "$yaml_content" > "$temp_yaml"
    
    # Parse YAML using yq and extract metadata fields
    # Core metadata (Dublin Core standard)
    META_TITLE=$(yq eval '.title // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_AUTHOR=$(yq eval '.author // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_DATE=$(yq eval '.date // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_DESCRIPTION=$(yq eval '.description // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_LANGUAGE=$(yq eval '.language // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    
    # Document structure metadata
    META_SECTION=$(yq eval '.section // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_SLUG=$(yq eval '.slug // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_FORMAT=$(yq eval '.format // "article"' "$temp_yaml" 2>/dev/null | sed 's/^null$/article/')
    
    # PDF-specific metadata
    META_TOC=$(yq eval '.toc // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_TOC_DEPTH=$(yq eval '.toc_depth // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_FOOTER=$(yq eval '.footer // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_HEADER_FOOTER_POLICY=$(yq eval '.header_footer_policy // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    
    # Boolean flags (convert true/false to appropriate values)
    local section_numbers_val=$(yq eval '.section_numbers // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    local no_numbers_val=$(yq eval '.no_numbers // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$section_numbers_val" = "false" ] && META_NO_NUMBERS="true"
    [ "$no_numbers_val" = "true" ] && META_NO_NUMBERS="true"
    
    local no_footer_val=$(yq eval '.no_footer // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$no_footer_val" = "true" ] && META_NO_FOOTER="true"
    
    local pageof_val=$(yq eval '.pageof // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$pageof_val" = "true" ] && META_PAGEOF="true"
    
    local date_footer_val=$(yq eval '.date_footer // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$date_footer_val" = "true" ] && META_DATE_FOOTER="true"
    
    local no_date_val=$(yq eval '.no_date // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    [ "$no_date_val" = "true" ] && META_NO_DATE="true"
    
    # Audio-specific metadata (for future compatibility)
    META_GENRE=$(yq eval '.genre // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_NARRATOR_VOICE=$(yq eval '.narrator_voice // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    META_READING_SPEED=$(yq eval '.reading_speed // ""' "$temp_yaml" 2>/dev/null | sed 's/^null$//')
    
    # Clean up temporary file
    rm -f "$temp_yaml"
    
    # Display found metadata
    [ -n "$META_TITLE" ] && echo -e "${GREEN}Found metadata - title: $META_TITLE${NC}"
    [ -n "$META_AUTHOR" ] && echo -e "${GREEN}Found metadata - author: $META_AUTHOR${NC}"
    [ -n "$META_DATE" ] && echo -e "${GREEN}Found metadata - date: $META_DATE${NC}"
    [ -n "$META_DESCRIPTION" ] && echo -e "${GREEN}Found metadata - description: $META_DESCRIPTION${NC}"
    [ -n "$META_LANGUAGE" ] && echo -e "${GREEN}Found metadata - language: $META_LANGUAGE${NC}"
    [ -n "$META_SECTION" ] && echo -e "${GREEN}Found metadata - section: $META_SECTION${NC}"
    [ -n "$META_SLUG" ] && echo -e "${GREEN}Found metadata - slug: $META_SLUG${NC}"
    [ -n "$META_FORMAT" ] && echo -e "${GREEN}Found metadata - format: $META_FORMAT${NC}"
    [ -n "$META_TOC" ] && echo -e "${GREEN}Found metadata - toc: $META_TOC${NC}"
    [ -n "$META_TOC_DEPTH" ] && echo -e "${GREEN}Found metadata - toc_depth: $META_TOC_DEPTH${NC}"
    [ -n "$META_FOOTER" ] && echo -e "${GREEN}Found metadata - footer: $META_FOOTER${NC}"
    [ -n "$META_HEADER_FOOTER_POLICY" ] && echo -e "${GREEN}Found metadata - header_footer_policy: $META_HEADER_FOOTER_POLICY${NC}"
    [ -n "$META_NO_NUMBERS" ] && echo -e "${GREEN}Found metadata - section_numbers: false${NC}"
    [ -n "$META_NO_FOOTER" ] && echo -e "${GREEN}Found metadata - no_footer: true${NC}"
    [ -n "$META_PAGEOF" ] && echo -e "${GREEN}Found metadata - pageof: true${NC}"
    [ -n "$META_DATE_FOOTER" ] && echo -e "${GREEN}Found metadata - date_footer: true${NC}"
    [ -n "$META_NO_DATE" ] && echo -e "${GREEN}Found metadata - no_date: true${NC}"
    [ -n "$META_GENRE" ] && echo -e "${GREEN}Found metadata - genre: $META_GENRE${NC}"
    [ -n "$META_NARRATOR_VOICE" ] && echo -e "${GREEN}Found metadata - narrator_voice: $META_NARRATOR_VOICE${NC}"
    [ -n "$META_READING_SPEED" ] && echo -e "${GREEN}Found metadata - reading_speed: $META_READING_SPEED${NC}"
    
    # Extract title from first H1 heading if not provided in metadata
    if [ -z "$META_TITLE" ]; then
        META_TITLE=$(grep -m 1 "^# " "$input_file" | sed 's/^# //')
        if [ -n "$META_TITLE" ]; then
            echo -e "${GREEN}Found title from H1 heading: $META_TITLE${NC}"
        fi
    fi
}

# Function to apply metadata to command-line arguments
apply_metadata_args() {
    local read_metadata="$1"
    
    if [ "$read_metadata" = true ]; then
        echo -e "${BLUE}Applying metadata to arguments (CLI args take precedence)...${NC}"
        
        # Apply metadata values only if command-line arguments weren't provided
        [ -z "$ARG_TITLE" ] && [ -n "$META_TITLE" ] && ARG_TITLE="$META_TITLE"
        [ -z "$ARG_AUTHOR" ] && [ -n "$META_AUTHOR" ] && ARG_AUTHOR="$META_AUTHOR"
        [ -z "$ARG_DATE" ] && [ -n "$META_DATE" ] && ARG_DATE="$META_DATE"
        [ -z "$ARG_FOOTER" ] && [ -n "$META_FOOTER" ] && ARG_FOOTER="$META_FOOTER"
        [ -z "$ARG_DATE_FOOTER" ] && [ -n "$META_DATE_FOOTER" ] && ARG_DATE_FOOTER="$META_DATE_FOOTER"
        [ -z "$ARG_FORMAT" ] && [ -n "$META_FORMAT" ] && ARG_FORMAT="$META_FORMAT"
        
        # Apply header/footer policy only if not explicitly set via CLI and metadata is valid
        if [ "$ARG_HEADER_FOOTER_POLICY" = "default" ] && [ -n "$META_HEADER_FOOTER_POLICY" ]; then
            ARG_HEADER_FOOTER_POLICY="$META_HEADER_FOOTER_POLICY"
        fi
        
        # Handle boolean flags - only apply if not explicitly set via CLI
        if [ "$ARG_TOC" = "$DEFAULT_TOC" ] && [ -n "$META_TOC" ]; then
            case "$META_TOC" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1")
                    ARG_TOC=true
                    ;;
                "false"|"False"|"FALSE"|"no"|"No"|"NO"|"0")
                    ARG_TOC=false
                    ;;
            esac
        fi
        
        if [ "$ARG_TOC_DEPTH" = "$DEFAULT_TOC_DEPTH" ] && [ -n "$META_TOC_DEPTH" ]; then
            ARG_TOC_DEPTH="$META_TOC_DEPTH"
        fi
        
        if [ "$ARG_SECTION_NUMBERS" = "$DEFAULT_SECTION_NUMBERS" ] && [ -n "$META_NO_NUMBERS" ]; then
            case "$META_NO_NUMBERS" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1")
                    ARG_SECTION_NUMBERS=false
                    ;;
                "false"|"False"|"FALSE"|"no"|"No"|"NO"|"0")
                    ARG_SECTION_NUMBERS=true
                    ;;
            esac
        fi
        
        if [ "$ARG_NO_FOOTER" = false ] && [ -n "$META_NO_FOOTER" ]; then
            case "$META_NO_FOOTER" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1")
                    ARG_NO_FOOTER=true
                    ;;
            esac
        fi
        
        if [ "$ARG_PAGE_OF" = false ] && [ -n "$META_PAGEOF" ]; then
            case "$META_PAGEOF" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1")
                    ARG_PAGE_OF=true
                    ;;
            esac
        fi
        
        if [ "$ARG_NO_DATE" = false ] && [ -n "$META_NO_DATE" ]; then
            case "$META_NO_DATE" in
                "true"|"True"|"TRUE"|"yes"|"Yes"|"YES"|"1")
                    ARG_NO_DATE=true
                    ;;
            esac
        fi
        
        echo -e "${GREEN}Metadata applied successfully${NC}"
    fi
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
    ARG_PAGE_OF=false # New variable for page X of Y format
    ARG_READ_METADATA=false # New variable for metadata reading
    ARG_FORMAT="" # New variable for document format
    ARG_HEADER_FOOTER_POLICY="default" # New variable for header/footer policy (default, partial, all)
    
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
            --pageof)
                ARG_PAGE_OF=true
                shift
                ;;
            --read-metadata)
                ARG_READ_METADATA=true
                shift
                ;;
            --format)
                ARG_FORMAT="$2"
                shift 2
                ;;
            --header-footer-policy)
                case "$2" in
                    "default"|"partial"|"all")
                        ARG_HEADER_FOOTER_POLICY="$2"
                        ;;
                    *)
                        echo -e "${RED}Error: Invalid header-footer-policy '$2'. Valid options: default, partial, all${NC}"
                        return 1
                        ;;
                esac
                shift 2
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
                    echo -e "  --pageof              Use 'Page X of Y' format in footer"
                    echo -e "  --date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\""
                    echo -e "  --read-metadata       Read metadata from HTML comments in markdown file"
                    echo -e "  --format FORMAT       Set document format (article or book)"
                    echo -e "  --header-footer-policy POLICY Set header/footer policy (default, partial, all). Default: default"
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
        echo -e "  --pageof              Use 'Page X of Y' format in footer"
        echo -e "  --date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\""
        echo -e "  --read-metadata       Read metadata from HTML comments in markdown file"
        echo -e "  --format FORMAT       Set document format (article or book)"
        echo -e "  --header-footer-policy POLICY Set header/footer policy (default, partial, all). Default: default"
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

    # Parse metadata from YAML frontmatter if --read-metadata flag is set
    if [ "$ARG_READ_METADATA" = true ]; then
        parse_yaml_metadata "$INPUT_FILE"
        apply_metadata_args "$ARG_READ_METADATA"
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
            # Use the template from another location
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
                    echo -e "${GREEN}Enter footer text (press Enter for default ' All rights reserved $(date +"%Y")'):${NC}"
                    read FOOTER_TEXT
                    FOOTER_TEXT=${FOOTER_TEXT:-" All rights reserved $(date +"%Y")"}
                else
                    FOOTER_TEXT=""
                fi
            fi
            
            # Format the date footer if specified
            DATE_FOOTER_TEXT=""
            if [ -n "$ARG_DATE_FOOTER" ]; then # Check if --date-footer was used at all
                if [ -n "$ARG_DATE" ] && [ "$ARG_DATE" != "no" ]; then
                    # Attempt to parse ARG_DATE and format as YY/MM/DD
                    PARSED_DATE_FOOTER=$(date -d "$ARG_DATE" +"%y/%m/%d" 2>/dev/null)
                    if [ -n "$PARSED_DATE_FOOTER" ]; then
                        DATE_FOOTER_TEXT="$PARSED_DATE_FOOTER"
                        echo -e "${GREEN}Using document date for footer (YY/MM/DD): $DATE_FOOTER_TEXT${NC}"
                    else
                        # Fallback to current date if ARG_DATE is not parsable
                        DATE_FOOTER_TEXT="$(date +"%y/%m/%d")"
                        echo -e "${YELLOW}Warning: Could not parse date '$ARG_DATE'. Using current date for footer (YY/MM/DD): $DATE_FOOTER_TEXT${NC}"
                    fi
                else
                    # If -d was not used or was 'no', use current date formatted as YY/MM/DD
                    DATE_FOOTER_TEXT="$(date +"%y/%m/%d")"
                fi
            fi
            
            # Create a template file in the current directory
            TEMPLATE_PATH="$(pwd)/template.tex"
            echo -e "${YELLOW}Creating template file: $TEMPLATE_PATH${NC}"
            create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" "$DATE_FOOTER_TEXT" "$ARG_SECTION_NUMBERS" "$ARG_FORMAT" "$ARG_HEADER_FOOTER_POLICY"
            
            if [ ! -f "$TEMPLATE_PATH" ]; then
                echo -e "${RED}Error: Failed to create template.tex.${NC}"
                return 1
            fi
            
            echo -e "${GREEN}Created new template file: $TEMPLATE_PATH${NC}"
            
            # Check if the Markdown file has proper YAML frontmatter
            if ! head -n 1 "$INPUT_FILE" | grep -q "^---"; then
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
    
    # Check for heading fix filter (add this first to process headings before other filters)
    if [ -f "$(pwd)/heading_fix_filter.lua" ]; then
        LUA_FILTERS+=("$(pwd)/heading_fix_filter.lua")
        echo -e "${BLUE}Using Lua filter for heading line break fix: $(pwd)/heading_fix_filter.lua${NC}"
    elif [ -f "$SCRIPT_DIR/heading_fix_filter.lua" ]; then
        LUA_FILTERS+=("$SCRIPT_DIR/heading_fix_filter.lua")
        echo -e "${BLUE}Using Lua filter for heading line break fix: $SCRIPT_DIR/heading_fix_filter.lua${NC}"
    elif [ -f "/usr/local/share/mdtexpdf/heading_fix_filter.lua" ]; then
        LUA_FILTERS+=("/usr/local/share/mdtexpdf/heading_fix_filter.lua")
        echo -e "${BLUE}Using Lua filter for heading line break fix: /usr/local/share/mdtexpdf/heading_fix_filter.lua${NC}"
    else
        echo -e "${YELLOW}Warning: heading_fix_filter.lua not found. Level 4 and 5 headings may run inline.${NC}"
    fi
    
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

    # Add book structure filter if format is book
    if [ "$ARG_FORMAT" = "book" ]; then
        local book_filter_path=""
        if [ -f "$(pwd)/filters/book_structure.lua" ]; then
            book_filter_path="$(pwd)/filters/book_structure.lua"
        elif [ -f "$SCRIPT_DIR/filters/book_structure.lua" ]; then
            book_filter_path="$SCRIPT_DIR/filters/book_structure.lua"
        elif [ -f "/usr/local/share/mdtexpdf/book_structure.lua" ]; then
            book_filter_path="/usr/local/share/mdtexpdf/book_structure.lua"
        fi

        if [ -n "$book_filter_path" ]; then
            LUA_FILTERS+=("$book_filter_path")
            echo -e "${BLUE}Using Lua filter for book structure: $book_filter_path${NC}"
        else
            echo -e "${YELLOW}Warning: book_structure.lua not found. Book format may not work correctly.${NC}"
        fi
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

    FOOTER_VARS=()
    if [ "$ARG_NO_FOOTER" = true ]; then
        FOOTER_VARS+=("--variable=no_footer=true")
    else
        # Center footer content from -f option
        if [ -n "$ARG_FOOTER" ]; then # ARG_FOOTER is the value from -f option
             FOOTER_VARS+=("--variable=center_footer_content=$ARG_FOOTER")
        fi

        # Page X of Y format for right footer
        if [ "$ARG_PAGE_OF" = true ]; then
            FOOTER_VARS+=("--variable=page_of_format=true")
        fi

        # Left footer content (date)
        # DATE_FOOTER_TEXT is determined around lines 916-934 based on ARG_DATE_FOOTER
        if [ -n "$DATE_FOOTER_TEXT" ]; then # DATE_FOOTER_TEXT is a shell variable in convert()
            FOOTER_VARS+=("--variable=date_footer_content=$DATE_FOOTER_TEXT")
        fi
    fi

    # Add header/footer policy variables
    HEADER_FOOTER_VARS=()
    if [ "$ARG_HEADER_FOOTER_POLICY" = "all" ]; then
        HEADER_FOOTER_VARS+=("--variable=header_footer_policy_all=true")
    elif [ "$ARG_HEADER_FOOTER_POLICY" = "partial" ]; then
        HEADER_FOOTER_VARS+=("--variable=header_footer_policy_partial=true")
    else
        # default policy - no special variables needed (plain pages will have no headers/footers)
        HEADER_FOOTER_VARS+=("--variable=header_footer_policy_default=true")
    fi
    
    # Add format variable for template logic
    if [ "$ARG_FORMAT" = "book" ]; then
        HEADER_FOOTER_VARS+=("--variable=format_book=true")
    else
        HEADER_FOOTER_VARS+=("--variable=format_article=true")
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
        "${FOOTER_VARS[@]}" \
        "${HEADER_FOOTER_VARS[@]}" \
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
    create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR" "" "true" "article" "content-only"
    
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
        
        # Copy heading fix filter
        if [ -f "$SCRIPT_DIR/heading_fix_filter.lua" ]; then
            sudo cp "$SCRIPT_DIR/heading_fix_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/heading_fix_filter.lua
            echo -e "${GREEN}✓ Installed heading_fix_filter.lua for fixing heading line breaks${NC}"
        elif [ -f "$(pwd)/heading_fix_filter.lua" ]; then
            sudo cp "$(pwd)/heading_fix_filter.lua" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/heading_fix_filter.lua
            echo -e "${GREEN}✓ Installed heading_fix_filter.lua for fixing heading line breaks${NC}"
        else
            echo -e "${YELLOW}Warning: heading_fix_filter.lua not found. Level 4 and 5 headings may run inline.${NC}"
        fi
        
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

        # Install book_structure.lua filter
        local book_filter_src=""
        if [ -f "$SCRIPT_DIR/filters/book_structure.lua" ]; then
            book_filter_src="$SCRIPT_DIR/filters/book_structure.lua"
        elif [ -f "$(pwd)/filters/book_structure.lua" ]; then
            book_filter_src="$(pwd)/filters/book_structure.lua"
        fi

        if [ -n "$book_filter_src" ]; then
            sudo cp "$book_filter_src" /usr/local/share/mdtexpdf/
            sudo chmod 644 /usr/local/share/mdtexpdf/book_structure.lua
            echo -e "${GREEN}✓ Installed book_structure.lua for book format${NC}"
        else
            echo -e "${YELLOW}Warning: book_structure.lua not found. Book format may not work correctly.${NC}"
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
    echo -e "${PURPLE}Code:${NC}        https://github.com/ucli-tools/mdtexpdf\n"
    
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
    echo -e "                    ${BLUE}--pageof              Use 'Page X of Y' format in footer${NC}"
    echo -e "                    ${BLUE}--date-footer [FORMAT] Add date to footer (left side). Optional formats: DD/MM/YY (default), YYYY-MM-DD, \"Month Day, Year\"${NC}"
    echo -e "                    ${BLUE}--read-metadata       Read metadata from HTML comments in markdown file${NC}"
    echo -e "                    ${BLUE}--header-footer-policy POLICY Set header/footer policy (default, partial, all). Default: default${NC}"
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
