"""The table filter: wide tables in a smaller type, and room around tall maths in cells.

Pandoc runs with the filter on a document held in memory and writes LaTeX to
stdout; nothing is written to disk.
"""

from pathlib import Path
import subprocess
import unittest

FILTER = Path(__file__).resolve().parent.parent / 'filters' / 'table_size_filter.lua'

TALL = (
    'Before $\\frac{a}{b}$ the table.\n\n'
    '| **$\\displaystyle n$** | **$\\displaystyle V_{1}$** |\n'
    '|---|---|\n'
    '| $\\displaystyle 5$ | $\\displaystyle \\frac{2i\\pi}{5}$ |\n'
    '| $\\displaystyle 6$ | word |\n\n'
    'After $x^2$ it.\n'
)
WIDE = '| a | b | c | d | e |\n|---|---|---|---|---|\n| 1 | 2 | 3 | 4 | $5$ |\n'


def latex(markdown: str) -> str:
    return subprocess.run(
        ['pandoc', '-f', 'markdown', '-t', 'latex', f'--lua-filter={FILTER}'],
        input=markdown, capture_output=True, text=True, check=True,
    ).stdout


class TableFilterTest(unittest.TestCase):
    def test_every_formula_in_a_cell_gets_room_and_no_other(self):
        out = latex(TALL)
        self.assertIn('\\mdtexpdfcellmath{\\(\\displaystyle \\frac{2i\\pi}{5}\\)}', out)
        self.assertIn('\\textbf{\\mdtexpdfcellmath{\\(\\displaystyle n\\)}}', out)
        self.assertEqual(out.count('\\mdtexpdfcellmath{\\('), 5, 'the five formulas in cells')
        self.assertIn('Before \\(\\frac{a}{b}\\) the table.', out, 'maths outside a table untouched')
        self.assertIn('After \\(x^2\\) it.', out)
        self.assertIn('word', out)

    def test_the_command_is_given_before_the_table(self):
        out = latex(TALL)
        defined = out.index('\\providecommand{\\mdtexpdfcellmath}')
        self.assertLess(defined, out.index('\\begin{longtable}'))
        self.assertIn('\\rule[-\\dimexpr\\dp0+3pt\\relax]{0pt}{\\dimexpr\\ht0+\\dp0+6pt\\relax}', out)

    def test_wide_tables_still_in_smaller_type(self):
        out = latex(WIDE)
        self.assertLess(out.index('\\begingroup\\small'), out.index('\\begin{longtable}'))
        self.assertGreater(out.index('\\endgroup'), out.index('\\end{longtable}'))
        self.assertNotIn('\\begingroup\\small', latex(TALL), 'two columns: normal type')

    def test_other_formats_untouched(self):
        out = subprocess.run(['pandoc', '-f', 'markdown', '-t', 'html', f'--lua-filter={FILTER}'],
                             input=TALL, capture_output=True, text=True, check=True).stdout
        self.assertNotIn('mdtexpdfcellmath', out)


if __name__ == '__main__':
    unittest.main()
