# Multilingual Document Example

This example demonstrates mdtexpdf's ability to handle multiple languages and writing systems in a single document.

## Languages Demonstrated

### Latin Script
- English
- French (with accents: é, è, ê, ç)
- German (with umlauts: ä, ö, ü, ß)
- Spanish (ñ, ¿, ¡)
- Portuguese
- Italian

### Cyrillic Script
- Russian (Русский)
- Ukrainian (Українська)

### East Asian (CJK)
- Chinese Simplified (简体中文)
- Chinese Traditional (繁體中文)
- Japanese (日本語 - Kanji, Hiragana, Katakana)
- Korean (한국어 - Hangul)

### Other Scripts
- Hindi (हिन्दी - Devanagari)
- Arabic (العربية)
- Hebrew (עברית)
- Greek (Ελληνικά)

## Build

```bash
# PDF (requires XeLaTeX and CJK fonts)
mdtexpdf convert multilingual.md --read-metadata

# EPUB (often easier for multilingual content!)
mdtexpdf convert multilingual.md --read-metadata --epub
```

## PDF vs EPUB for Multilingual Content

| Feature | PDF | EPUB |
|---------|-----|------|
| CJK support | Requires XeLaTeX + fonts | Native Unicode |
| Font embedding | Complex setup | Automatic |
| RTL languages | Manual config needed | Better native support |
| File size | Larger (embedded fonts) | Smaller |
| Setup difficulty | Higher | Lower |

**Recommendation**: EPUB is often easier for multilingual documents since modern e-readers handle Unicode natively without special font configuration.

## Requirements

For CJK content, you need:

1. **XeLaTeX** (automatically selected by mdtexpdf)
2. **CJK fonts**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install fonts-noto-cjk
   ```
3. **xeCJK package**:
   ```bash
   sudo apt-get install texlive-lang-chinese texlive-lang-japanese texlive-lang-korean
   ```

For Arabic/Hebrew:
```bash
sudo apt-get install texlive-lang-arabic
```

## How It Works

1. mdtexpdf scans the document for Unicode characters
2. If CJK characters are detected, it switches to XeLaTeX
3. The template loads xeCJK with Noto Sans CJK fonts
4. Western punctuation is preserved even with CJK content

## Limitations

- Right-to-left (RTL) languages like Arabic and Hebrew may require additional configuration for proper text direction
- Some fonts may not have all Unicode characters
- Very obscure scripts may need custom font configuration

## Tips

1. **Use UTF-8**: Ensure your markdown file is saved as UTF-8
2. **Install fonts**: CJK fonts are large; install only what you need
3. **Test incrementally**: Add one language at a time to debug issues
4. **EPUB alternative**: For maximum compatibility, EPUB handles Unicode better than PDF
