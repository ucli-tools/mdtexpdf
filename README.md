<h1> Markdown to PDF with LaTeX (mdtexpdf) </h1>

<h2> Table of Contents</h2>

- [Introduction](#introduction)
- [Repository Structure](#repository-structure)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Using the Makefile](#using-the-makefile)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
  - [Converting Markdown to PDF](#converting-markdown-to-pdf)
    - [Non-Interactive Mode with Command-Line Arguments](#non-interactive-mode-with-command-line-arguments)
    - [Header/Footer Policy Control](#headerfooter-policy-control)
      - [Format Compatibility](#format-compatibility)
    - [Complete Metadata Reference](#complete-metadata-reference)
      - [Document Information](#document-information)
      - [Document Structure](#document-structure)
      - [Table of Contents](#table-of-contents)
      - [Section Numbering](#section-numbering)
      - [Headers and Footers](#headers-and-footers)
      - [HTML Comment Format](#html-comment-format)
      - [Complete Example](#complete-example)
  - [Creating New Markdown Documents](#creating-new-markdown-documents)
  - [LaTeX Math Support](#latex-math-support)
  - [Customizing Templates](#customizing-templates)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Using Makefile](#using-makefile)
- [License](#license)
  - [🌐 Free and Open Source Software (FOSS)](#-free-and-open-source-software-foss)

## Introduction

mdtexpdf is a command-line tool designed to simplify the process of creating professional PDF documents from Markdown files using LaTeX. It combines the simplicity of Markdown with the power of LaTeX, allowing you to include complex mathematical equations, custom formatting, and professional typesetting in your documents.

## Repository Structure

- `mdtexpdf.sh`: Main script for converting Markdown to PDF
- `templates/`: Directory containing LaTeX templates
  - `template.tex`: Default LaTeX template with template footer
- `examples/`: Directory containing example Markdown files
  - `document.md`: Basic Markdown document example
  - `example.md`: Comprehensive example with various LaTeX math equations
- `Makefile`: For easy installation and management
- `.gitignore`: Configured to exclude generated PDFs and LaTeX temporary files
- `LICENSE`: Apache 2.0 license
- `CONTRIBUTING.md`: Guidelines for contributing to the project

## Features

- **Markdown to PDF Conversion**: Convert Markdown files to beautifully formatted PDFs
- **LaTeX Math Support**: Include inline and display math equations using LaTeX syntax
- **Custom Templates**: Use and customize LaTeX templates for consistent document styling
- **YAML Frontmatter**: Set document metadata like title, author, and date
- **Automatic Prerequisites Check**: Verify all required software and packages are installed
- **Custom Footer**: Include copyright or other information in the document footer
- **Header/Footer Policy Control**: Three-tier policy system for controlling headers and footers on different page types
- **Code Highlighting**: Syntax highlighting for code blocks
- **Tables and Figures**: Support for tables, images, and other Markdown elements
- **Theorem Environments**: Use LaTeX theorem environments in your Markdown
- **Chemical Equations**: Support for chemical formulas and equations
- **Automatic Equation Line Breaking**: Long mathematical equations automatically wrap to fit the page width
- **Section Numbering Control**: Option to disable section numbering for cleaner documents
- **Easy Installation**: Simple install and uninstall process
- **User-Friendly**: Colorized output and helpful error messages

## Prerequisites

To use mdtexpdf, you need:

- [Pandoc](https://pandoc.org/installing.html) - Required for Markdown to LaTeX conversion
- A LaTeX distribution:
  - Linux: TexLive (`texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-science`)
  - macOS: MacTeX or BasicTeX
  - Windows: MiKTeX
- Required LaTeX packages (automatically checked by the tool)

## Installation

### Using the Makefile

If you have `make` installed, you can simply run:

```bash
git clone https://github.com/ucli-tools/mdtexpdf.git
cd mdtexpdf
make
```

### Manual Installation

Alternatively, you can install manually:

```bash
git clone https://github.com/ucli-tools/mdtexpdf.git
cd mdtexpdf
chmod +x mdtexpdf.sh
./mdtexpdf.sh install
```

This will copy the script to `/usr/local/bin/mdtexpdf` and the template to `/usr/local/share/mdtexpdf/`, making it accessible system-wide. You'll need to enter your sudo password.

## Usage

After installation, you can use mdtexpdf with the following commands:

### Converting Markdown to PDF

Convert a Markdown file to PDF:

```bash
mdtexpdf convert document.md
```

The tool will automatically:
- Check for all prerequisites
- Find or create a template.tex file (prompting for customization if needed)
- Convert the Markdown to a beautifully formatted PDF

Specify an output filename:

```bash
mdtexpdf convert document.md output.pdf
```

You can run this command from any directory - the tool will intelligently search for templates in standard locations or create one if needed.

#### Non-Interactive Mode with Command-Line Arguments

For automated workflows or batch processing, you can bypass the interactive prompts by providing command-line arguments:

```bash
mdtexpdf convert -t "Document Title" -a "Author Name" -d "May 2, 2025" document.md
```

Available options:
- `-t, --title TITLE`: Set the document title
- `-a, --author AUTHOR`: Set the document author
- `-d, --date DATE`: Set the document date
- `-f, --footer TEXT`: Set custom footer text
- `--no-footer`: Disable the footer completely
- `--no-numbers`: Disable section numbering (1.1, 1.2, etc.)
- `--header-footer-policy POLICY`: Set header/footer policy (`default`, `partial`, `all`)

Example for automated testing or CI/CD pipelines:

```bash
mdtexpdf convert examples/example1.md -a "Test Author" -t "Test Document" -d "Today" --no-footer
```

To create a document without numbered sections:

```bash
mdtexpdf convert document.md -t "Clean Document" -a "Author Name" --no-numbers
```

Example with header/footer policy for a book-style document:

```bash
mdtexpdf convert book.md -t "My Book" -a "Author Name" --header-footer-policy all
```

When these arguments are provided, the tool will not prompt for any information and will use the specified values instead.

#### Header/Footer Policy Control

mdtexpdf provides a three-tier policy system for controlling when headers and footers appear on different page types:

- **`default`** (default): No headers/footers on title, part, or chapter pages (original behavior)
- **`partial`**: Headers/footers on part and chapter pages, but NOT on title page
- **`all`**: Headers/footers on ALL pages including title, part, and chapter pages

You can set the policy using the command-line option:

```bash
mdtexpdf convert --header-footer-policy all document.md
```

Or by adding it to your document's metadata:

```markdown
<!--
title: "My Document"
author: "Author Name"
header_footer_policy: "all"
-->
```

This is particularly useful for:
- **Academic papers**: Use `default` for clean title pages
- **Technical documentation**: Use `partial` for professional appearance
- **Books and reports**: Use `all` for consistent branding throughout

##### Format Compatibility

The header/footer policy system now works seamlessly with both document formats:

- **Article Format** (`format: "article"`): 
  - Uses standard LaTeX `\maketitle` for clean, academic-style title formatting
  - With `header_footer_policy: "all"`, provides professional headers/footers while maintaining article aesthetics
  - Perfect for papers, articles, and technical documentation

- **Book Format** (`format: "book"`):
  - Uses custom full-page title layout with enhanced typography
  - With `header_footer_policy: "all"`, creates book-style title pages with consistent branding
  - Ideal for books, reports, and multi-chapter documents

**Example: Professional Article with Headers/Footers**
```yaml
---
title: "Research Paper Title"
author: "Author Name"
format: "article"                    # Clean article formatting
header_footer_policy: "all"         # Professional headers/footers
pageof: true                         # Page X of Y numbering
date_footer: true                    # Date in footer
---
```

This combination provides the best of both worlds: clean academic formatting with professional document presentation.

#### Complete Metadata Reference

mdtexpdf supports extensive metadata configuration through YAML frontmatter or HTML comments. Here's a comprehensive reference:

##### Document Information
```yaml
---
# Basic document information
title: "Document Title"              # Document title (overrides H1)
author: "Author Name"                # Document author
date: "2025-01-20"                   # Document date
description: "Brief description"     # Document description (for metadata)
language: "en"                       # Document language
---
```

##### Document Structure
```yaml
---
# Document format and organization
format: "article"                   # "article" (default) or "book"
section: "category"                 # Section/category for organization
slug: "document-slug"               # URL-friendly identifier
---
```

##### Table of Contents
```yaml
---
# Table of contents control
toc: true                           # Enable/disable TOC (true/false)
toc_depth: 3                        # TOC depth (1-5, default: 2)
                                    # 1=sections, 2=subsections, 3=subsubsections
---
```

##### Section Numbering
```yaml
---
# Section numbering control (choose one)
section_numbers: false              # Disable section numbering
no_numbers: true                    # Alternative way to disable numbering
---
```

##### Headers and Footers
```yaml
---
# Header/footer policy and content
header_footer_policy: "all"         # "default", "partial", or "all"
footer: "© 2025 Company. All rights reserved."  # Custom footer text
no_footer: true                     # Disable all footers
pageof: true                        # Enable "Page X of Y" format
date_footer: true                   # Include date in footer
---
```

##### HTML Comment Format

You can also use HTML comments instead of YAML frontmatter:

```markdown
<!--
title: "My Document"
author: "Author Name"
format: "article"
header_footer_policy: "all"
toc: true
toc_depth: 2
pageof: true
date_footer: true
footer: "© 2025 Organization. All rights reserved."
-->

# Document Content Starts Here
```

##### Complete Example

```yaml
---
# Complete metadata example
title: "Advanced Research Paper"
author: "Dr. Jane Smith"
date: "2025-01-20"
description: "Comprehensive analysis of quantum computing applications"
language: "en"

# Document structure
format: "article"                   # Clean article formatting
section: "research"
slug: "quantum-computing-analysis"

# Table of contents
toc: true                           # Include TOC
toc_depth: 3                        # Show up to subsubsections

# Section numbering
section_numbers: true               # Enable numbered sections

# Headers and footers
header_footer_policy: "all"         # Professional headers/footers on all pages
footer: "© 2025 Research Institute | institute.org"
pageof: true                        # "Page 1 of 15" format
date_footer: true                   # Include date in footer
---
```

**Note**: Command-line arguments take precedence over metadata. Use `--read-metadata` to apply document metadata automatically.

### Creating New Markdown Documents

Create a new Markdown document with LaTeX template (interactive mode):

```bash
mdtexpdf create document.md
```

This will prompt you for:
- Document title
- Author name
- Document date
- Whether you want a footer (if a template doesn't exist)
- Custom footer text or use the default "© All rights reserved [YEAR]"

You can also specify title and author directly:

```bash
mdtexpdf create document.md "My Document Title" "Author Name"
```

The tool will automatically create a template.tex file if one doesn't exist, prompting you for customization options like the footer text.

### LaTeX Math Support

mdtexpdf supports LaTeX math equations in your Markdown files:

- **Inline equations**: Use `$E = mc^2$` or `\(F = ma\)`
- **Display equations**: Use `$$\int_{a}^{b} f(x) \, dx$$` or `\begin{equation}...\end{equation}`
- **Automatic line breaking**: Long display equations with text content will automatically wrap to fit the page width, preventing content from extending beyond the page margins in the PDF output. This is handled by custom LaTeX settings and a Lua filter that detects text-heavy equations.

### Customizing Templates

You can modify the LaTeX template (`template.tex`) to:

- Add, remove, or change the footer text
- Adjust page margins and layout
- Add additional LaTeX packages
- Customize the document style

When creating a new document or converting an existing one, if no template is found, the tool will:
1. Ask if you want to include a footer
2. Let you specify custom footer text or use the default "© All rights reserved [YEAR]"
3. Create a template with your preferences

## Examples

The package includes example files to help you get started:

- `document.md`: A basic Markdown document with YAML frontmatter
- `example.md`: A comprehensive example with various LaTeX math equations

## Troubleshooting

If you encounter errors:

1. Check prerequisites: `mdtexpdf check`
2. Ensure Pandoc is installed and in your PATH
3. Verify you have a working LaTeX distribution
4. Check for syntax errors in your Markdown or LaTeX equations
5. For specific LaTeX packages, ensure they are installed with your LaTeX distribution
6. If long equations still extend beyond page margins:
   - Try breaking the equation manually using `\\` in appropriate places
   - For text-heavy equations, use `\text{...}` for each text segment to help the automatic line breaking
   - Consider using explicit environments like `\begin{multline*}...\end{multline*}` for very long equations

## Using Makefile

For development purposes, we provide basic Makefile commands:

- Build (install the tool)
  ```
  make build
  ```
- Rebuild (uninstall and reinstall)
  ```
  make rebuild
  ```
- Delete (uninstall)
  ```
  make delete
  ```

## License

**This project is licensed under the Apache 2.0 License** - see the [LICENSE](LICENSE) file for details.

### 🌐 Free and Open Source Software (FOSS)

This universal PDF conversion tool is part of the Universalis ecosystem's **dual licensing model**:

- **🌐 This Tool (FOSS)**: Freely available under Apache 2.0 for anyone to use
- **🔒 Particular Implementations**: Organizations may use this tool in their own projects with any licensing

You are free to:
- ✅ Use this tool for any purpose (commercial or non-commercial)
- ✅ Modify and customize it for your needs
- ✅ Distribute your modifications
- ✅ Integrate it into proprietary workflows

*Part of the Universalis Project - Where universal tools meet particular implementations*