"""Colour in tables: a cell's background and a value's colour, in the PDF and in the EPUB.

docx2md keeps a Word table's colours as `\\cellcolor[HTML]{...}` (raw TeX at the start of a cell)
and `\\textcolor[HTML]{...}{...}` around a cell's formula. Pandoc runs on documents held in
memory; the EPUB is read from its bytes; nothing is written to disk.
"""

import io
from pathlib import Path
import re
import subprocess
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent
EPUB_FILTER = ROOT / 'filters' / 'epub_latex_filter.lua'

TABLE = (
    '| **$n$** | **$V_1$** | **$V_2$** |\n'
    '|---|---|---|\n'
    '| `\\cellcolor[HTML]{BFBFBF}`{=latex}$3$ | `\\cellcolor[HTML]{BDD6EE}`{=latex}'
    '$\\textcolor[HTML]{FF0000}{\\displaystyle \\frac{2i\\pi}{3}}$ | $\\textcolor[HTML]{1E48FF}{\\frac{4i\\pi}{3}}$ |\n'
    '| $4$ | $a + \\textcolor{red}{b}$ | plain |\n'
)


def epub_text(markdown: str) -> str:
    out = subprocess.run(['pandoc', '-f', 'markdown', '-t', 'epub3', '--mathml',
                          f'--lua-filter={EPUB_FILTER}', '-o', '-'],
                         input=markdown.encode(), capture_output=True, check=True)
    assert b'Could not convert TeX math' not in out.stderr, out.stderr.decode()
    with zipfile.ZipFile(io.BytesIO(out.stdout)) as z:
        return ''.join(z.read(n).decode() for n in z.namelist() if n.endswith('.xhtml'))


class ColourTest(unittest.TestCase):
    def test_the_pdf_template_loads_colour_for_table_cells(self):
        template = (ROOT / 'lib' / 'template.sh').read_text(encoding='utf-8')
        self.assertIn('\\\\usepackage[table]{xcolor}', template)

    def test_the_pdf_keeps_both_as_tex(self):
        out = subprocess.run(['pandoc', '-f', 'markdown', '-t', 'latex'], input=TABLE,
                             capture_output=True, text=True, check=True).stdout
        self.assertIn('\\cellcolor[HTML]{BDD6EE}', out)
        self.assertIn('\\textcolor[HTML]{FF0000}{\\displaystyle \\frac{2i\\pi}{3}}', out)

    def test_the_epub_cell_background_becomes_the_cell_style(self):
        text = epub_text(TABLE)
        self.assertEqual(text.count('style="background-color:#BFBFBF"'), 1)
        self.assertEqual(text.count('style="background-color:#BDD6EE"'), 1)
        self.assertNotIn('cellcolor', re.sub(r'<annotation.*?</annotation>', '', text))

    def test_the_epub_value_takes_its_colour_and_stays_maths(self):
        text = epub_text(TABLE)
        self.assertRegex(text, r'<span style="color:#FF0000"><math[^>]*>.*?<mfrac>')
        self.assertRegex(text, r'<span style="color:#1E48FF"><math')
        # A colour inside a formula is dropped and the formula kept.
        self.assertRegex(text, r'<mi>a</mi><mo>\+</mo><mi>b</mi>')
        self.assertNotIn('textcolor', re.sub(r'<annotation.*?</annotation>', '', text))


    def test_the_epub_check_reads_no_colour_as_text(self):
        import sys
        sys.path.insert(0, str(ROOT / 'lib'))
        from epub_verify import tex_to_text
        words = lambda tex: tex_to_text(tex).split()
        self.assertEqual(words('\\cellcolor[HTML]{BFBFBF}'), [])
        self.assertEqual(words('\\rowcolor{gray}'), [])
        self.assertEqual(words('\\textcolor[HTML]{FF0000}{prime} vertices'), ['prime', 'vertices'])
        self.assertEqual(words('\\color[HTML]{1E48FF} blue'), ['blue'])


if __name__ == '__main__':
    unittest.main()
