#!/bin/bash

# ANSI color codes
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
    
    # Use default values if not provided
    doc_title=${doc_title:-"Title"}
    doc_author=${doc_author:-"Author"}
    
    cat > "$template_path" << EOF
    \\documentclass[12pt]{article}
    \\usepackage[utf8]{inputenc}
    \\usepackage[T1]{fontenc}
    \\usepackage{lmodern}  % Load Latin Modern fonts (scalable)
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
    
    % Define Unicode box-drawing characters
    \\newunicodechar{├}{\\texttt{|--}}
    \\newunicodechar{│}{\\texttt{|}}
    \\newunicodechar{└}{\\texttt{\`--}}
    \\newunicodechar{─}{\\texttt{-}}
    
    % Configure listings for code blocks
    \\lstset{
      basicstyle=\\ttfamily\\small,
      breaklines=true,
      columns=flexible,
      keepspaces=true,
      showstringspaces=false,
      frame=single,
      framesep=5pt,
      framexleftmargin=5pt,
      tabsize=4
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
\\renewcommand{\\footrulewidth}{0.4pt}

% First page style (no header)
\\fancypagestyle{plain}{
  \\fancyhf{}
  \\fancyfoot[C]{$footer_text}
  \\fancyfoot[R]{\\thepage}
  \\renewcommand{\\footrulewidth}{0.4pt}
  \\renewcommand{\\headrulewidth}{0pt}
}

% Define \\tightlist command used by pandoc
\\providecommand{\\tightlist}{%
  \\setlength{\\itemsep}{0pt}\\setlength{\\parskip}{0pt}}

% Define theorem environments
\\newtheorem{theorem}{Theorem}
\\newtheorem{lemma}{Lemma}
\\newtheorem{corollary}{Corollary}
\\newtheorem{definition}{Definition}

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
\\date{\\today}
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
    if check_command pdflatex; then
        LATEX_INSTALLED=true
        PDF_ENGINE="pdflatex"
    elif check_command xelatex; then
        LATEX_INSTALLED=true
        PDF_ENGINE="xelatex"
    elif check_command lualatex; then
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

# Function to convert markdown to PDF
convert() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: No input file specified.${NC}"
        echo -e "Usage: mdtexpdf convert <input.md> [output.pdf]"
        return 1
    fi

    # Check prerequisites first
    if ! check_prerequisites; then
        return 1
    fi

    # Get input and output file names
    INPUT_FILE="$1"
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}Error: Input file '$INPUT_FILE' not found.${NC}"
        return 1
    fi

    # Create a backup of the original markdown file
    BACKUP_FILE="${INPUT_FILE}.bak"
    echo -e "${BLUE}Creating backup of original markdown file: $BACKUP_FILE${NC}"
    cp "$INPUT_FILE" "$BACKUP_FILE"

    # If output file is specified, use it; otherwise derive from input file
    if [ -n "$2" ]; then
        OUTPUT_FILE="$2"
    else
        OUTPUT_FILE="${INPUT_FILE%.md}.pdf"
    fi

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
        
        read CREATE_TEMPLATE
        CREATE_TEMPLATE=${CREATE_TEMPLATE:-"y"}
        
        echo -e "${BLUE}Debug: User chose to create template: $CREATE_TEMPLATE${NC}"
        
        # Create template if user chose to
        if [[ $CREATE_TEMPLATE =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Debug: Creating template...${NC}"
            # Get document details for both template and YAML frontmatter
            echo -e "${YELLOW}Setting up document preferences...${NC}"
            
            # Check if the file has a first-level heading (# Title) before asking for title
            FIRST_HEADING=$(grep -m 1 "^# " "$INPUT_FILE" | sed 's/^# //')
            
            if [ -n "$FIRST_HEADING" ]; then
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
            
            # Get author name
            echo -e "${GREEN}Enter author name [$(whoami)]:${NC}"
            read AUTHOR
            AUTHOR=${AUTHOR:-"$(whoami)"}
            
            # Get document date
            echo -e "${GREEN}Enter document date [$(date +"%B %d, %Y")]:${NC}"
            read DOC_DATE
            DOC_DATE=${DOC_DATE:-"$(date +"%B %d, %Y")"}
            
            # Ask about footer preferences
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
            
            # Create a template file in the current directory
            TEMPLATE_PATH="$(pwd)/template.tex"
            echo -e "${YELLOW}Creating template file: $TEMPLATE_PATH${NC}"
            create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR"
            
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
date: "$DOC_DATE"
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

    # Run pandoc with the selected PDF engine
    pandoc "$INPUT_FILE" \
        --from markdown \
        --to pdf \
        --output "$OUTPUT_FILE" \
        --template="$TEMPLATE_PATH" \
        --pdf-engine=$PDF_ENGINE \
        $PANDOC_OPTS \
        --variable=geometry:margin=1in \
        --highlight-style=tango \
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
    create_template_file "$TEMPLATE_PATH" "$FOOTER_TEXT" "$TITLE" "$AUTHOR"
    
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
date: "$DOC_DATE"
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
        
        # Copy templates to the shared directory
        SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
        
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
    echo -e "  ${GREEN}convert <input.md> [output.pdf]${NC}"
    echo -e "                  ${BLUE}Convert a Markdown file to PDF using LaTeX${NC}"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf convert document.md"
    echo -e "                  ${BLUE}Example:${NC} mdtexpdf convert document.md output.pdf\n"
    
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