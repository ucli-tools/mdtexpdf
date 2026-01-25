# Troubleshooting Guide

Common issues and solutions when using mdtexpdf.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Dependency Issues](#dependency-issues)
- [PDF Generation Issues](#pdf-generation-issues)
- [EPUB Generation Issues](#epub-generation-issues)
- [Content Rendering Issues](#content-rendering-issues)
- [Performance Issues](#performance-issues)

---

## Installation Issues

### "command not found: mdtexpdf"

**Cause**: mdtexpdf is not in your PATH.

**Solutions**:

1. If installed locally:
   ```bash
   # Add to PATH in ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/mdtexpdf"
   source ~/.bashrc
   ```

2. If installed via `make install`:
   ```bash
   # Verify installation
   ls -la /usr/local/bin/mdtexpdf
   
   # Re-install if missing
   sudo make install
   ```

3. Use Docker instead:
   ```bash
   docker run --rm -v "$(pwd):/data" uclitools/mdtexpdf convert input.md
   ```

### Permission denied during install

**Cause**: Need sudo for system-wide installation.

**Solution**:
```bash
sudo make install
```

---

## Dependency Issues

### "pandoc is not installed"

**Solution**:

```bash
# Ubuntu/Debian
sudo apt-get install pandoc

# macOS
brew install pandoc

# Or use Docker (includes all dependencies)
docker pull uclitools/mdtexpdf
```

### "pdflatex/xelatex/lualatex is not installed"

**Solution**:

```bash
# Ubuntu/Debian (full installation)
sudo apt-get install texlive-full

# Ubuntu/Debian (minimal installation)
sudo apt-get install texlive-latex-base texlive-latex-recommended texlive-latex-extra

# macOS
brew install --cask mactex
```

### "LaTeX package X is not available"

**Cause**: Required LaTeX package not installed.

**Solution**:

```bash
# Check which packages are missing
mdtexpdf check

# Ubuntu/Debian - install additional packages
sudo apt-get install texlive-science texlive-fonts-extra

# Or install specific package via tlmgr
sudo tlmgr install packagename
```

### "yq: command not found"

**Cause**: yq is required for YAML metadata parsing.

**Solution**:

```bash
# Ubuntu/Debian
sudo apt-get install yq

# macOS
brew install yq

# Or use snap
sudo snap install yq
```

---

## PDF Generation Issues

### "Error producing PDF"

**Diagnosis**:

1. Run with `--verbose` or `--debug` for more details:
   ```bash
   mdtexpdf convert --debug input.md
   ```

2. Check the LaTeX log file (if generated)

**Common causes**:

1. **Invalid LaTeX in content**: Check for unescaped special characters
2. **Missing packages**: Run `mdtexpdf check`
3. **Font issues**: Try different PDF engine

### "Undefined control sequence"

**Cause**: LaTeX command not recognized.

**Solutions**:

1. Ensure required packages are loaded
2. Check for typos in LaTeX commands
3. Use `--verbose` to see which line causes the error

### "Missing $ inserted" or "Missing } inserted"

**Cause**: Unbalanced math mode or braces.

**Solutions**:

1. Check that all `$...$` pairs are balanced
2. Check that all `{...}` pairs are balanced
3. Escape dollar signs in text: `\$`

### PDF is blank or only has title page

**Cause**: Content not being processed correctly.

**Solutions**:

1. Check YAML frontmatter syntax
2. Ensure content starts after `---` closing
3. Verify Markdown syntax is valid

### Images not appearing

**Cause**: Image paths or formats not supported.

**Solutions**:

1. Use absolute paths or paths relative to markdown file
2. Supported formats: PNG, JPG, PDF
3. Check file permissions

```yaml
# In YAML frontmatter, use relative path from markdown file
cover_image: "img/cover.jpg"
```

---

## EPUB Generation Issues

For comprehensive EPUB documentation, see the [EPUB Guide](EPUB_GUIDE.md).

### "EPUB file is empty or corrupted"

**Solutions**:

1. Validate markdown structure
2. Ensure pandoc version is 2.0+
3. Check for special characters in filenames
4. Validate with epubcheck: `epubcheck mybook.epub`

### Cover image not appearing in EPUB

**Solutions**:

1. Ensure image exists at specified path
2. Use supported format (JPG, PNG)
3. Check image dimensions (minimum 625x1000, recommended 1600x2400)
4. Verify file size is under 5MB

```yaml
cover_image: "img/cover.jpg"  # Relative to markdown file
```

### Table of contents missing in EPUB

**Solution**: Enable TOC in metadata:

```yaml
toc: true
toc_depth: 2
```

### Math equations not rendering in EPUB

**Cause**: EPUB has limited LaTeX math support.

**Solutions**:
1. Simple math converts to Unicode: `$x^2$` → x², `$H_2O$` → H₂O
2. For complex equations, use PDF format instead
3. Or convert equations to images

### Chemistry formulas not rendering in EPUB

**Cause**: EPUB doesn't support LaTeX math natively.

**Note**: mdtexpdf automatically converts common chemistry formulas to Unicode:
- `\ce{H2O}` becomes `H₂O`
- `\ce{CO2}` becomes `CO₂`

For complex formulas, consider using images.

### EPUB not opening on Kindle

**Cause**: Kindle uses a proprietary format.

**Solutions**:
1. Upload EPUB to Kindle Direct Publishing (converts automatically)
2. Or use Calibre to convert: `ebook-convert book.epub book.mobi`
3. Or send via Amazon's Send to Kindle service

### Characters displaying incorrectly in EPUB

**Solutions**:
1. Ensure markdown file is saved as UTF-8
2. Add `lang: "en"` (or appropriate code) to metadata
3. Test in Calibre viewer to isolate the issue

---

## Content Rendering Issues

### CJK characters (Chinese/Japanese/Korean) not displaying

**Cause**: Missing CJK fonts or wrong LaTeX engine.

**Solutions**:

1. Install CJK fonts:
   ```bash
   sudo apt-get install fonts-noto-cjk
   ```

2. mdtexpdf automatically uses XeLaTeX for CJK content

3. Install xeCJK package:
   ```bash
   sudo apt-get install texlive-lang-chinese
   ```

### Math equations not rendering

**Solutions**:

1. Ensure amsmath package is installed:
   ```bash
   sudo apt-get install texlive-latex-base
   ```

2. Check equation syntax:
   - Inline: `$E = mc^2$`
   - Display: `$$\int_0^1 x dx$$`

### Chemistry formulas (\ce{}) not working

**Solution**: Install mhchem package:

```bash
sudo apt-get install texlive-science
```

### Code blocks not syntax highlighted

**Solutions**:

1. Specify language in code fence:
   ````markdown
   ```python
   print("Hello")
   ```
   ````

2. Ensure pandoc highlighting is enabled (default)

### Tables look wrong

**Solutions**:

1. Use proper Markdown table syntax
2. Ensure booktabs package is installed
3. For wide tables, consider landscape mode

---

## Performance Issues

### Conversion is very slow

**Causes and solutions**:

1. **Many images**: Resize/compress images before conversion
2. **Complex math**: Normal for documents with many equations
3. **First run**: LaTeX caches fonts on first use

### Out of memory during conversion

**Solutions**:

1. Split large documents
2. Reduce image sizes
3. Use Docker with memory limits:
   ```bash
   docker run --memory=4g uclitools/mdtexpdf convert input.md
   ```

### Temporary files not cleaned up

**Cause**: Conversion was interrupted.

**Solution**:
```bash
# Clean up manually
rm -f *.aux *.log *.out *.toc template.tex
```

---

## Getting More Help

### Enable verbose/debug output

```bash
mdtexpdf convert --verbose input.md  # Informational messages
mdtexpdf convert --debug input.md    # Detailed debug output
```

### Check system status

```bash
mdtexpdf check  # Shows all dependencies and their status
```

### Report a bug

If you've tried the solutions above and still have issues:

1. Run `mdtexpdf --version`
2. Run `mdtexpdf check`
3. Create a minimal example that reproduces the issue
4. Open an issue at: https://github.com/ucli-tools/mdtexpdf/issues

Include:
- mdtexpdf version
- Operating system
- Pandoc version (`pandoc --version`)
- LaTeX distribution
- Minimal input file
- Full error message
