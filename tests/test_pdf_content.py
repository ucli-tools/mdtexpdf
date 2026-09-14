#!/usr/bin/env python3
"""Verify semantic content in PDFs produced by the public CLI."""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "mdtexpdf.sh"


class PdfContentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mdtexpdf pdf content ")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)

    def convert(self, source, *, success=True, environment=None):
        manuscript = self.directory / "document with spaces.md"
        output = self.directory / "document with spaces.pdf"
        manuscript.write_text(source)
        result = subprocess.run(
            [str(CLI), "convert", str(manuscript), str(output),
             "--read-metadata", "--no-footer", "--no-date"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            env=os.environ | (environment or {}),
        )
        self.assertEqual(manuscript.read_text(), source, "conversion changed the source")
        self.assertFalse(manuscript.with_suffix(".md.bak").exists())
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue(output.exists(), "successful conversion did not create a PDF")
            self.assertGreater(output.stat().st_size, 1000)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse(output.exists(), "failed conversion left a misleading PDF")
        return result, output

    def pdf_text(self, pdf):
        self.assertIsNotNone(shutil.which("pdftotext"), "pdftotext is required")
        result = subprocess.run(
            ["pdftotext", "-layout", str(pdf), "-"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout

    def word_y_positions(self, pdf):
        result = subprocess.run(
            ["pdftotext", "-bbox-layout", str(pdf), "-"],
            capture_output=True,
            text=True,
            check=True,
        )
        root = ET.fromstring(result.stdout)
        return {
            (word.text or ""): float(word.attrib["yMin"])
            for word in root.iter()
            if word.tag.endswith("word")
        }

    def word_records(self, pdf):
        result = subprocess.run(
            ["pdftotext", "-bbox-layout", str(pdf), "-"],
            capture_output=True,
            text=True,
            check=True,
        )
        root = ET.fromstring(result.stdout)
        return [
            {
                "text": word.text or "",
                "x": float(word.attrib["xMin"]),
                "y": float(word.attrib["yMin"]),
            }
            for word in root.iter()
            if word.tag.endswith("word")
        ]

    def test_literal_code_characters_survive_conversion(self):
        source = r'''---
title: Literal code characters
---

# Literal code characters

Inline code keeps `$HOME`, `${USER}`, `$event_id`, and `$param` exactly as written.

```bash
echo "$HOME/${USER}"
event_id="$event_id"
# $comment remains a comment
```

```sql
SELECT * FROM events WHERE event_id = '$event_id';
```

```python
value = "$param"
```
'''
        result, output = self.convert(source)
        self.assertNotIn("PDF conversion failed", result.stdout + result.stderr)
        text = self.pdf_text(output)
        for literal in ["$HOME", "${USER}", "$event_id", "$param",
                        "# $comment remains a comment"]:
            self.assertIn(literal, text)

    def test_tight_lists_render_more_compactly_than_loose_lists(self):
        source = '''---
title: List spacing
---

# List spacing

- TightAlpha
- TightBeta

Between the lists.

- LooseAlpha

- LooseBeta

After the lists.
'''
        _, output = self.convert(source)
        positions = self.word_y_positions(output)
        tight_gap = positions["TightBeta"] - positions["TightAlpha"]
        loose_gap = positions["LooseBeta"] - positions["LooseAlpha"]
        self.assertGreater(loose_gap, tight_gap + 3.0, (tight_gap, loose_gap))

    def test_deep_headings_preserve_inline_markup_and_special_characters(self):
        source = r'''---
title: Deep headings
---

# Deep headings

#### Account_name costs $5 at 100%: [docs](https://example.com) with *emphasis*, `code_value`, and $x_1$

Level four body.

##### Child_name keeps $9 and 50% with **strength**, `child_code`, and $y_2$

Level five body.
'''
        _, output = self.convert(source)
        text = self.pdf_text(output)
        for phrase in ["Account_name costs $5 at 100%", "docs", "emphasis",
                       "code_value", "Child_name keeps $9 and 50%",
                       "strength", "child_code"]:
            self.assertIn(phrase, text)

    def test_unicode_math_symbols_render_in_prose_styles_and_code(self):
        source = r'''---
title: Unicode mathematical symbols
---

# Unicode mathematical symbols

Normal: ∀ x ∈ ℝ, x² ≥ 0; ∃ y ∈ ℤ; H₂O; α → β; ∞; 𝕆¹; 𝕊¹.

**Bold: ∀ x ∈ ℝ, x² ≥ 0 and H₂O.**

*Italic: ∃ y ∈ ℤ, y ≠ 0 and α → β.*

Inline code: `forall = "∀"; member = "∈"; limit = "∞"; water = "H₂O"`.

```python
first_symbol = "∀"
second_symbol = "∈"
if second_symbol:
    indented_value = "∞"
```

Operators: ∉ ∋ ⊂ ⊃ ⊆ ⊇ ∪ ∩ ∧ ∨ ⊗ ◁ ⇌ ≈ ≡ ∼ ∝ ∂ ∇ ∫ ∑ ∏ √.

Math: $\forall x \in \mathbb{R}, x^2 \ge 0$.
'''
        result, output = self.convert(
            source,
            environment={"LANG": "C", "LC_ALL": "C"},
        )
        diagnostics = result.stdout + result.stderr
        self.assertIn("xelatex", diagnostics)
        self.assertNotIn("Missing character", diagnostics)
        self.assertNotIn("CJK characters", diagnostics)

        text = self.pdf_text(output)
        for phrase in ["Unicode mathematical symbols", "Normal:", "Bold:",
                       "Italic:", "Inline code:", "Operators:", "Math:"]:
            self.assertIn(phrase, text)
        for symbol in ["∀", "∈", "∞", "α", "→"]:
            self.assertIn(symbol, text)
        self.assertNotIn("[]", text)
        self.assertNotIn("”", text)
        self.assertNotIn("“", text)
        for line in ['first_symbol = "∀"', 'second_symbol = "∈"',
                     'if second_symbol:', 'indented_value = "∞"']:
            self.assertTrue(
                any(candidate.strip() == line for candidate in text.splitlines()),
                (line, text),
            )

        records = self.word_records(output)
        code_words = {}
        for expected in ["first_symbol", "second_symbol", "if", "indented_value"]:
            matches = [record for record in records if record["text"] == expected]
            self.assertEqual(len(matches), 1, (expected, matches))
            code_words[expected] = matches[0]
        self.assertLess(code_words["first_symbol"]["y"], code_words["second_symbol"]["y"])
        self.assertLess(code_words["second_symbol"]["y"], code_words["if"]["y"])
        self.assertLess(code_words["if"]["y"], code_words["indented_value"]["y"])
        self.assertGreater(code_words["indented_value"]["x"], code_words["if"]["x"])

    def test_latex_failures_report_a_concise_diagnostic(self):
        source = r'''---
title: Broken LaTeX
---

\notarealcommand
'''
        result, _ = self.convert(source, success=False)
        diagnostics = result.stdout + result.stderr
        self.assertIn(
            "Error: PDF conversion failed: Undefined control sequence.",
            diagnostics,
        )
        self.assertEqual(diagnostics.count("Undefined control sequence"), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
