# PR: Harden XeLaTeX pipeline + Arch Linux dependency docs

## Summary
This PR improves resilience for real-world Markdown/LaTeX input (especially Google Docs/Gemini-exported docs), fixes several runtime failures in minimal LaTeX environments, and adds explicit Arch Linux dependency guidance.

## Why
Users hit multiple conversion failures despite having core tooling installed:
- Missing fonts (`Latin Modern Roman`, `CMU Serif` files)
- Missing optional LaTeX packages (`xeCJK.sty`, `dutchcal.sty`)
- Over-escaped math emitted by Google Docs exports (examples: `\\epsilon`, `\\ll`, `\\=`, `\\+`, `\\<`)

The combined result was repeated `fontspec`, `Undefined control sequence`, and `Missing $ inserted` failures during PDF conversion.

## What changed
### 1) Template hardening (`lib/template.sh`)
- Added font fallback chains for XeLaTeX/LuaLaTeX:
  - Main: Latin Modern Roman → TeX Gyre Termes
  - Sans: Latin Modern Sans → TeX Gyre Heros
  - Mono: Latin Modern Mono → TeX Gyre Cursor
- Made `xeCJK` optional via `\IfFileExists{xeCJK.sty}` with warning instead of hard failure.
- Made CJK font selection conditional via `\IfFontExistsTF`.
- Replaced hardcoded CMU file-path font setup (`cmunrm` family) with fallback-safe `\newfontfamily` logic.
- Made `dutchcal` optional via `\IfFileExists{dutchcal.sty}`.
- Added compatibility shims for escaped angle brackets (`\<`, `\>`).

### 2) Markdown preprocessing normalization (`lib/preprocess.sh`)
Added sanitation pass for common over-escaping patterns from Google Docs / converted research exports:
- `\<`, `\>` → `<`, `>`
- `\\command` → `\command` for math commands
- `\=`, `\+`, `\_x`, `\^x` → `=`, `+`, `_x`, `^x`

This eliminates common LaTeX parse failures in equations/tables without requiring manual source cleanup.

### 3) Docker base image deps (`Dockerfile.base`)
Added packages required by hardened template defaults:
- `fonts-lmodern`
- `texlive-lang-chinese`

### 4) Documentation updates (Arch Linux)
Updated install guidance in:
- `README.md`
- `examples/multilingual/README.md`
- `examples/multilingual/multilingual.md`

Included:
- Arch equivalents for core packages (`pandoc-cli`, `texlive-*`, `noto-fonts-cjk`, `imagemagick`)
- Optional Arch package for extended LaTeX coverage: `texlive-fontsextra`
- Troubleshooting entries for missing font/package errors

## Validation
- Ran shell syntax checks:
  - `bash -n lib/template.sh`
  - `bash -n lib/preprocess.sh`
- Verified successful end-to-end conversion on a previously failing Google Docs/Gemini-generated manuscript (`book.pdf` produced).

## Scope note
Please exclude local user test content from this PR:
- `book.md` (local reproduction document)

## Suggested PR title
Harden XeLaTeX conversion for over-escaped Markdown and add Arch dependency support

## Suggested commit message
fix: harden LaTeX template/preprocess for minimal TeX envs and Google Docs exports

docs: add Arch Linux dependency mappings and optional texlive extras

## Checklist
- [x] Backward-compatible behavior in normal documents
- [x] No hard failure when optional fonts/packages are absent
- [x] Arch dependency docs updated
- [x] Docker base updated for required runtime dependencies
