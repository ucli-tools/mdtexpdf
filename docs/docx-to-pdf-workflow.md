# DOCX → PDF: What we changed and how to avoid manual template edits

This note summarizes the fixes we made to reliably convert DOCX to PDF and proposes how to make it work out-of-the-box with `mdtexpdf` without manually editing `template.tex` per project.

## What we changed right now

- __Selected a Unicode-friendly engine__: Updated `docx_example/Makefile` to call:
  ```sh
  bash ../mdtexpdf/mdtexpdf.sh convert --pdf-engine xelatex example.docx -m metadata.yaml
  ```
  `xelatex` (or `lualatex`) handles Unicode and avoids many pdflatex issues.

- __Cleaned problematic DOCX containers automatically__: `mdtexpdf.sh` now unzips and re-zips `.docx` files before Pandoc runs, working around the “Did not find end of central directory signature” unpack error. Warnings from `unzip` are tolerated when a valid DOCX marker is present.

- __Made the LaTeX template safe by default for Unicode engines__: Simplified `\lstset{...}` in `docx_example/template.tex` to a minimal, Unicode-safe configuration and used `fontspec`/`unicode-math` for Xe/LuaTeX. This removed the `\lstset` parsing error and still formats code nicely.

- __Help/documentation__: `help()` now documents `--pdf-engine`.

## Why this fixes the failures

- __Pandoc error fixed__: Repacking DOCX removes extra ZIP bytes; Pandoc can unpack it.
- __LaTeX Unicode issues mitigated__: XeLaTeX/LuaLaTeX natively support Unicode; the simplified `listings` config avoids brittle "literate" mappings.

## Use mdtexpdf without editing template.tex (today)

`mdtexpdf.sh` already auto-detects templates in this order:
- `./template.tex` (project-local)
- `./templates/template.tex`
- `$(script_dir)/templates/template.tex`
- `/usr/local/share/mdtexpdf/templates/template.tex`

To avoid per-project editing:
- __Option A (recommended)__: Install a good default template once and let all runs use it automatically.
  1) Copy `docx_example/template.tex` (the simplified, Unicode-safe version) to `mdtexpdf/templates/template.tex`.
  2) Run `mdtexpdf install` (or the script’s install step) to copy it to `/usr/local/share/mdtexpdf/templates/template.tex`.
  3) Now, any run of `mdtexpdf convert` will find and use that template when no local template exists.

- __Option B__: Keep a `templates/template.tex` inside each repo. No edits per run; template is versioned with the project.

- __Always pass a Unicode engine for DOCX__:
  ```sh
  mdtexpdf convert --pdf-engine xelatex -m your-metadata.yaml your.docx
  ```

## Proposed improvements to mdtexpdf (no manual edits needed)

- __Ship a Unicode-safe default template__: Update `create_template_file()` and the packaged template to:
  - Use `fontspec + unicode-math` for Xe/LuaTeX.
  - Keep pdfLaTeX compatibility mappings (e.g., ℓ and subscript digits, plus `≔` via `mathtools`’ `\coloneqq`).
  - Keep the simplified, robust `\lstset`.

- __Add template profiles__:
  - `--template-profile unicode-safe|minimal|custom` to select generation presets.

- __Avoid surprise deletion__:
  - Add `--keep-template` to prevent auto-removal when a template is auto-created.
  - Or write auto-generated templates to `./templates/template.tex` (project-scoped) instead of `./template.tex`.

- __Better defaults for DOCX__:
  - Default to `--pdf-engine xelatex` for DOCX when available (fallback to `lualatex`, then `pdflatex` with mappings). Emit a warning if falling back.

- __Unicode mappings for pdfLaTeX__:
  - Ensure ℓ (U+2113), subscript digits (U+2080…U+2089), and `≔` map cleanly when `pdflatex` is forced.

## Known caveats

- Some symbols may still warn if the chosen fonts lack glyphs. With Xe/LuaLaTeX, consider installing and selecting `STIX Two Math` (already attempted in the example template).
- Missing optional Lua filters trigger warnings only; they don’t block PDF generation.

## TL;DR Workflow (current best practice)

- Use a global default template once:
  - Install `mdtexpdf/templates/template.tex` to `/usr/local/share/mdtexpdf/templates/template.tex`.
- Convert DOCX with Unicode engine:
  ```sh
  mdtexpdf convert --pdf-engine xelatex -m metadata.yaml your.docx
  ```
- No per-run edits to `template.tex` are needed if a global or project template exists.
