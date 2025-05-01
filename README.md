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
  - [Creating New Markdown Documents](#creating-new-markdown-documents)
  - [LaTeX Math Support](#latex-math-support)
  - [Customizing Templates](#customizing-templates)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Using Makefile](#using-makefile)
- [License](#license)

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
- **Code Highlighting**: Syntax highlighting for code blocks
- **Tables and Figures**: Support for tables, images, and other Markdown elements
- **Theorem Environments**: Use LaTeX theorem environments in your Markdown
- **Chemical Equations**: Support for chemical formulas and equations
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
git clone https://github.com/yourusername/mdtexpdf.git
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

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.