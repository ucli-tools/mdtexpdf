# Markdown to PDF with LaTeX AI Prompt

## Prompt

When you use `mdtexpdf`, you can use the following AI prompt to ensure the markdown file will be compatible with `mdtexpdf`. This can be used to create new content, or to adjust existing content into mdtexpdf-able markdown file format, thus creating a PDF with LaTeX math support in one line.

```
Explain the topic below and include relevant mathematical formulas, symbols, etc. It must be a professional, industry-standard best practice guide explaining the topic. Format the output for a VS Code Markdown file (.md), ensuring that:

- All **block-level math** (display equations, derivations, or important formulas) is enclosed in `$$ ... $$` delimiters, with the math on its own line and a blank line before and after.
- All **inline math** (symbols or short expressions within a sentence) is enclosed in single dollar signs `$...$`.
- Do NOT place raw LaTeX outside of `$` or `$$` delimiters.
- Leave an empty line between paragraphs, between a paragraph and a bullet list, and between a heading and the first line of the section.
- Use `-` for bullet points, not `*`.
- Do no use `---` to separate sections. 
- Use proper LaTeX syntax for all mathematical symbols, formulas, and expressions.
- For any mathematics, e.g. any equation/function shown, we explain each variable/symbol used, we even name it, e.g. if it's phi we should state how to pronounce it. Thus, it's very didactic and newcomers don't feel overwhelmed by the mathematics.
- For **chemical formulas**, use the mhchem package syntax with `\ce{}`:
  - Inline: `$\ce{H2O}$`, `$\ce{CH3COOH}$`, `$\ce{Fe^2+}$`
  - Block equations: `$$\ce{2H2 + O2 -> 2H2O}$$`
  - Equilibrium: `$$\ce{CH3COOH <=> CH3COO- + H+}$$`
  - Do NOT use Unicode subscripts/superscripts like H₂O or CO₂; use `$\ce{H2O}$` and `$\ce{CO2}$` instead.
- For **Greek letters** in text, you may use Unicode directly (α, β, γ) or in math mode use LaTeX (`$\alpha$`, `$\beta$`).

This will allow me to transfer the markdown `.md` into VS Code preview with correct LaTeX rendering.

Topic:
```

## How to Use

- Copy the above
- Paste to an AI tool
- Write below your "topic"
- Copy the markdown output and paste in a .md file
- Use `mdtexpdf` to convert the markdown to PDF