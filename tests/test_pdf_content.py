#!/usr/bin/env python3
"""Verify semantic content in PDFs produced by the public CLI."""

from pathlib import Path
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

    def convert(self, source, *, success=True):
        manuscript = self.directory / "document with spaces.md"
        output = self.directory / "document with spaces.pdf"
        manuscript.write_text(source)
        result = subprocess.run(
            [str(CLI), "convert", str(manuscript), str(output),
             "--read-metadata", "--no-footer", "--no-date"],
            cwd=ROOT,
            capture_output=True,
            text=True,
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
        _, output = self.convert(source)
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


if __name__ == "__main__":
    unittest.main(verbosity=2)
