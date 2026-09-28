#!/usr/bin/env python3
"""Check actual EPUB contents, including failure paths and source preservation."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FILTER = ROOT / 'filters/epub_latex_filter.lua'


class EpubLatexTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='epub latex ')
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)

    def convert(self, source, *, cli=False, env=None, success=True):
        manuscript = self.directory / 'book with spaces.md'
        output = self.directory / 'book with spaces.epub'
        manuscript.write_text(source)
        if cli:
            command = [str(ROOT / 'mdtexpdf.sh'), 'convert', str(manuscript),
                       '--epub', '--read-metadata']
        else:
            command = ['pandoc', str(manuscript), '-t', 'epub3',
                       '--lua-filter', str(FILTER), '-o', str(output)]
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True)
        self.assertEqual(manuscript.read_text(), source, 'conversion changed the source')
        self.assertFalse(manuscript.with_suffix('.md.bak').exists())
        if not success:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse(output.exists(), 'failed export left a misleading EPUB')
            return result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        with zipfile.ZipFile(output) as archive:
            self.assertIsNone(archive.testzip())
            documents = [ET.fromstring(archive.read(n)) for n in sorted(archive.namelist())
                         if n.endswith('.xhtml')]
            images = [archive.read(n) for n in archive.namelist()
                      if n.endswith('.png')]
        return documents, images

    def test_nested_layout_retains_markdown_and_literal_examples(self):
        documents, images = self.convert(r'''---
title: Layout test
---

# Chapter

Before the layout.

\begin{samepage}
\begin{minipage}[t][3cm][c]{\linewidth}
\setlength{\parskip}{\baselineskip}

First retained paragraph with *emphasis* and $x^2$.

\begin{minipage}{.9\linewidth}

Second retained paragraph.

\end{minipage}

Last retained paragraph.

```latex
\begin{minipage}{2cm}
Literal inside layout.
\end{minipage}
```

Inline example: `\begin{minipage}{1cm}`.

\end{minipage}
\end{samepage}

```latex
\begin{minipage}{\linewidth}
Literal example.
\end{minipage}
```

After the layout.
''', cli=True)
        text = ' '.join(''.join(doc.itertext()) for doc in documents)
        for phrase in ['Before the layout.', 'First retained paragraph',
                       'Second retained paragraph.', 'Last retained paragraph.',
                       'After the layout.', r'\begin{minipage}{\linewidth}',
                       r'\begin{minipage}{2cm}', r'\begin{minipage}{1cm}',
                       'Literal inside layout.']:
            self.assertIn(phrase, text)
        self.assertTrue(any(el.tag.endswith('}em') for doc in documents for el in doc.iter()))
        self.assertEqual(images, [])

    def test_artwork_headers_captions_and_spacing(self):
        documents, images = self.convert(r'''---
title: Artwork test
header-includes:
  - \usetikzlibrary{arrows.meta}
  - \newcommand{\drawingradius}{1}
---

# Chapter

Before the drawings.

\begin{figure}[H]
\centering
\vspace*{36pt}
\begin{adjustbox}{max width=.85\linewidth,max height=2.5in}
\begin{tikzpicture}
\draw (0,0) circle (\drawingradius);
\end{tikzpicture}
\end{adjustbox}
\par\vspace*{36pt}
\end{figure}

\begin{figure}[H]
\begin{tikzpicture}
\draw[-{Latex}] (0,0) -- (2,1);
\end{tikzpicture}
\caption[Short]{An \emph{ascending} line.}
\label{fig:line}
\end{figure}

After the drawings.
''', cli=True)
        self.assertEqual(len(images), 2)
        for image in images:
            self.assertTrue(image.startswith(b'\x89PNG\r\n\x1a\n'))
            self.assertGreater(len(image), 500)
        elements = [el for doc in documents for el in doc.iter()]
        artwork = [el for el in elements if el.get('class') == 'mdtexpdf-artwork']
        self.assertEqual(len(artwork), 2)
        for drawing in artwork:
            self.assertIn('padding-top:36pt', drawing.get('style'))
            self.assertIn('padding-bottom:36pt', drawing.get('style'))
        self.assertEqual(''.join(artwork[0].itertext()).strip(), '')
        self.assertIn('An ascending line.', ''.join(artwork[1].itertext()))
        self.assertEqual(artwork[1].get('id'), 'fig:line')

    def test_invalid_tikz_fails_and_restores_source(self):
        output = self.convert(r'''---
title: Broken drawing
---

\begin{tikzpicture}
\notarealcommand
\end{tikzpicture}
''', cli=True, success=False)
        self.assertIn('failed to compile', output)

    def test_renderer_failure_is_not_silent_content_loss(self):
        renderer = self.directory / 'pdftoppm'
        renderer.write_text('#!/bin/sh\nexit 42\n')
        renderer.chmod(0o755)
        env = dict(os.environ, PATH=str(self.directory) + os.pathsep + os.environ['PATH'])
        output = self.convert(r'''---
title: Renderer failure
---

\begin{tikzpicture}
\draw (0,0) -- (1,1);
\end{tikzpicture}
''', cli=True, env=env, success=False)
        self.assertIn('pdftoppm', output)

    def test_pdf_writer_keeps_latex(self):
        source = r'\begin{tikzpicture}\draw (0,0) -- (1,1);\end{tikzpicture}'
        result = subprocess.run(['pandoc', '-f', 'markdown', '-t', 'latex',
                                 '--lua-filter', str(FILTER)], input=source,
                                capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout.strip(), source)

    def test_book_artwork_conventions(self):
        # Artwork written the way a long book writes it: fenced and unfenced raw blocks,
        # TikZ arrows, the template's TikZ libraries, amsmath in nodes, a colour defined
        # in an earlier block, \centering inside a node, and a \noindent minipage.
        documents, images = self.convert(r'''---
title: Book conventions
---

# Chapter

Prose arrows convert: a -> b and c <=> d. Half is $\tfrac12$ and $\dfrac{1}{2}$.

```{=latex}
\definecolor{sharedblue}{RGB}{35,93,160}
\begin{figure}[H]
\centering
\begin{tikzpicture}
\draw[->, sharedblue] (0,0) -- (1,0);
\end{tikzpicture}
\end{figure}
```

\begin{figure}[H]
\centering
\begin{tikzpicture}
\node (a) {A};
\node[below left=1pt and 0pt of a] {$\tfrac{1}{2}$};
\draw[<->, sharedblue] (0,0) -- (1,1);
\node at (2,0) {\parbox{2cm}{\scriptsize\centering Kept word}};
\end{tikzpicture}
\end{figure}

```{=latex}
\par\medskip\noindent\begin{minipage}{\textwidth}
```

Inside the unwrapped minipage.

```{=latex}
\end{minipage}
```
''', cli=True)
        self.assertEqual(len(images), 2)
        text = ' '.join(''.join(doc.itertext()) for doc in documents)
        self.assertIn('a → b', text)
        self.assertIn('c ⇌ d', text)
        self.assertIn('Inside the unwrapped minipage.', text)
        fractions = [el for doc in documents for el in doc.iter() if el.tag.endswith('}mfrac')]
        self.assertEqual(len(fractions), 2)
        # MathML 3, which epubcheck applies, does not allow displaystyle on mfrac.
        self.assertTrue(all(el.get('displaystyle') is None for el in fractions))

    def test_descriptions_become_alt_text_and_never_show(self):
        # A description comment after a figure is the image's alt text; a caption without
        # one gives plain text, never TeX; comments stay hidden even with arrows in them.
        documents, images = self.convert(r'''---
title: Descriptions
---

# Chapter

Prose arrow: a -> b.

\begin{figure}[H]
\centering
\begin{tikzpicture}
\draw[->] (0,0) -- (1,0);
\end{tikzpicture}
\caption{A line marked at $\frac{1}{2}$.}
\end{figure}

<!-- audio-description
Here in Figure 1 we see an arrow running right, from $a$ to $b$ -> the end.
-->

```{=latex}
\begin{figure}[H]
\centering
\begin{tikzpicture}
\draw (0,0) circle (1);
\end{tikzpicture}
\caption{A circle of radius $\frac{1}{2}$ at angle $\theta$, and $\sqrt{2}$.}
\end{figure}
```

<!-- a note for the author -> never shown -->

After the figures.
''', cli=True)
        self.assertEqual(len(images), 2)
        text = ' '.join(''.join(doc.itertext()) for doc in documents)
        self.assertIn('a → b', text)
        for hidden in ('audio-description', 'Here in Figure', 'never shown', '<!'):
            self.assertNotIn(hidden, text)
        alts = [el.get('alt') for doc in documents for el in doc.iter() if el.tag.endswith('}img')]
        self.assertEqual(alts[0], 'Here in Figure 1 we see an arrow running right, from a to b -> the end.')
        self.assertEqual(alts[1], 'A circle of radius 1/2 at angle θ, and √2.')
        self.assertIn('A line marked at', text)          # the caption itself still shows

    def test_accessibility_is_declared(self):
        self.convert(r'''---
title: Accessible
---

# Chapter

Mathematics: $x^2$.

\begin{figure}[H]
\begin{tikzpicture}
\draw (0,0) -- (1,1);
\end{tikzpicture}
\caption{A diagonal.}
\end{figure}
''', cli=True)
        with zipfile.ZipFile(self.directory / 'book with spaces.epub') as archive:
            opf = archive.read('EPUB/content.opf').decode()
        for value in ('accessMode">textual', 'accessMode">visual', 'accessModeSufficient">textual<',
                      'accessibilityFeature">alternativeText', 'accessibilityFeature">MathML',
                      'accessibilityFeature">tableOfContents', 'accessibilityHazard">none',
                      'accessibilitySummary">'):
            self.assertIn(value, opf)
        self.assertIn('Every image has a text alternative.', opf)

    def test_tex_control_words_are_not_shortened(self):
        # In capture mode the renderer fails if a longer command lost its prefix.
        renderer = self.directory / 'xelatex'
        renderer.write_text('''#!/usr/bin/env python3
from pathlib import Path
import os, sys
source = Path('drawing.tex').read_text()
if r'\\parbox' not in source or r'\\partial' not in source:
    sys.exit(19)
os.execv('/usr/bin/xelatex', ['/usr/bin/xelatex'] + sys.argv[1:])
''')
        # Locate the real engine without assuming a system installation path.
        import shutil
        renderer.write_text(renderer.read_text().replace('/usr/bin/xelatex', shutil.which('xelatex')))
        renderer.chmod(0o755)
        env = dict(os.environ, PATH=str(self.directory) + os.pathsep + os.environ['PATH'])
        self.convert(r'''---
title: TeX commands
---

\begin{tikzpicture}
\node {\parbox{2cm}{$\partial x$}};
\end{tikzpicture}
''', env=env)


    # --- what the PDF shows reaches the EPUB -------------------------------------------

    @staticmethod
    def text_of(documents):
        return ' '.join(''.join(doc.itertext()) for doc in documents)

    @staticmethod
    def spans(documents, name):
        return [''.join(el.itertext()) for doc in documents for el in doc.iter()
                if el.tag.endswith('}span') and name in (el.get('class') or '').split()]

    def test_raw_tex_tables_captions_and_fitted_equations_reach_the_epub(self):
        documents, _ = self.convert(r'''---
title: Raw TeX
---

# Chapter

```{=latex}
\begin{table}[H]
\centering
\small
\newcolumntype{R}[1]{>{\raggedright\arraybackslash\hspace{0pt}}p{#1}}
\renewcommand{\arraystretch}{1.08}
\begin{tabular}{R{3cm} R{4cm}}
\hline
\textbf{Kind} & \textbf{Meaning} \\[4pt]
\hline
\noalign{\vskip 3pt}
\textbf{Round.} A wheel & Turns \(x^2\) times \\[11pt]
\hline
\end{tabular}
\caption[Short]{Wheels and their turns.}
\end{table}
```

```{=latex}
\begin{center}\textit{\(a\) plus \(b\) equals the sum.}\end{center}
```

```{=latex}
\begingroup\postdisplaypenalty=10000 \csname @beginparpenalty\endcsname=10000
```

$$a + b = c$$

```{=latex}
\begin{center}\parbox{\linewidth}{\centering\itshape A caption kept in a box.}\end{center}
\endgroup
```

```{=latex}
\newpage
```

```{=latex}
\[\sbox0{$\displaystyle
p = q + r
$}%
\ifdim\wd0>\linewidth\resizebox{\linewidth}{!}{\usebox0}\else\usebox0\fi
\tag{7.7.7}
\]
```

```{=latex}
\begin{figure}[H]
\centering
\begin{tabular}{p{3cm} p{3cm}}
\hline
Question & Answer \\
\hline
\end{tabular}
\captionof{table}{Questions beside answers.}
\end{figure}
```

Closing prose.
''', cli=True)
        text = self.text_of(documents)
        tables = [el for doc in documents for el in doc.iter() if el.tag.endswith('}table')]
        self.assertEqual(len(tables), 2)
        for phrase in ('Wheels and their turns.', 'A wheel', 'plus', 'equals the sum.',
                       'A caption kept in a box.', 'Questions beside answers.', '(7.7.7)'):
            self.assertIn(phrase, text)
        for leak in ('\\', 'begingroup', 'newcolumntype', 'sbox', '$'):
            self.assertNotIn(leak, text)
        displays = [el for doc in documents for el in doc.iter()
                    if el.tag.endswith('}math') and el.get('display') == 'block']
        self.assertEqual(len(displays), 2)

    def test_numbers_follow_the_pdf(self):
        documents, _ = self.convert(r'''---
title: Numbers
format: book
equation_numbers: true
---

# Part 1: Opening

## Chapter 1: First

$$a = b$$

$$c = d \tag{9.9.9}$$

$$e = f \notag$$

$$g = h$$

```{=latex}
\begin{table}[H]
\begin{tabular}{ll}
x & y \\
\end{tabular}
\caption{A small table.}
\end{table}
```

```{=latex}
\begin{minipage}{\linewidth}

$$m = n$$

\end{minipage}
```

## Chapter 2: Second

```{=latex}
\begin{figure}[H]
\centering
\begin{tikzpicture}
\draw (0,0) -- (1,0);
\end{tikzpicture}
\caption{A line.}
\end{figure}
```

$$k = l$$

# Appendices

## Appendix A: Extra

$$u = v$$

The end.
''', cli=True)
        self.assertEqual(self.spans(documents, 'eqno'), ['(1.1)', '(9.9.9)', '(1.2)', '(2.1)', '(A.1)'])
        self.assertEqual(self.spans(documents, 'caption-label'), ['Table 1.1:', 'Figure 2.1:'])

    def test_formulas_are_repaired_only_when_they_fail(self):
        manuscript = r'''---
title: Formulas
---

# Chapter

Primes stay primes: $f''(x)$ and $G^{''}$. A set symbol $\mathbbm{1}$ and a word $"x"$.
'''
        documents, _ = self.convert(manuscript, cli=True)
        maths = ' '.join(''.join(el.itertext()) for doc in documents for el in doc.iter()
                         if el.tag.endswith('}math'))
        self.assertIn('″', maths)                       # both double primes kept
        self.assertEqual(maths.count('″'), 2)
        self.assertIn('𝟙', maths)                       # \mathbbm{1} as \mathbb{1}
        self.assertFalse(self.spans(documents, 'math'))  # no formula left as TeX
        (self.directory / 'book with spaces.epub').unlink()
        output = self.convert(r'''---
title: Broken
---

# Chapter

No rule can repair $\notacommandanywhere{1}$.
''', cli=True, success=False)
        self.assertIn('cannot be converted to MathML', output)
        self.assertIn('notacommandanywhere', output)

    def test_display_maths_is_contained_and_numbered_beside_it(self):
        documents, _ = self.convert(r'''---
title: Contained
equation_numbers: true
---

# Chapter

$$x = \sum_{n=1}^{100} n$$
''', cli=True)
        wrappers = [el for doc in documents for el in doc.iter()
                    if el.tag.endswith('}span') and (el.get('class') or '').split() == ['math', 'display']]
        self.assertEqual(len(wrappers), 1)
        scroller = wrappers[0][0]
        self.assertIn('overflow-x:auto', scroller.get('style'))
        self.assertTrue(scroller[0].tag.endswith('}math'))
        self.assertEqual(self.spans(documents, 'eqno'), ['(1)'])

    def test_index_markers_become_a_linked_index(self):
        documents, _ = self.convert(r'''---
title: Index
---

# Chapter 1: Apples

An [index:apple]apple here and an [index:apple]apple there.

# Chapter 2: Pears

A [index:fruit|pear]pear and the [index:zeta@$\zeta$ function]zeta function.

# Chapter 3: Roots of $x^2$

A [index:root]root.
''', cli=True)
        text = self.text_of(documents)
        self.assertNotIn('[index:', text)
        anchors = {el.get('id') for doc in documents for el in doc.iter() if (el.get('id') or '').startswith('idx-')}
        self.assertEqual(len(anchors), 5)
        links = [(''.join(el.itertext()), el.get('href')) for doc in documents for el in doc.iter()
                 if el.tag.endswith('}a') and '#idx-' in (el.get('href') or '')]
        # terms sort apple, fruit (pear), root, zeta
        self.assertEqual([t for t, _ in links][:3], ['Chapter 1: Apples', '2', 'Chapter 2: Pears'])
        self.assertEqual(links[4][0], 'Chapter 2: Pears')
        # a heading with maths links with its maths typeset (MathML), never as TeX
        self.assertTrue(links[3][0].startswith('Chapter 3: Roots of'))
        root = [el for doc in documents for el in doc.iter()
                if el.tag.endswith('}a') and el.get('href', '').endswith(links[3][1].split('#')[1])]
        self.assertTrue(any(m.tag.endswith('}math') for m in root[0].iter()))
        self.assertNotIn('$', text)
        self.assertEqual({h.split('#')[1] for _, h in links}, anchors)
        self.assertIn('Index', text)

    def test_image_alt_text_with_maths_is_plain_text(self):
        picture = self.directory / 'dot.png'
        import struct, zlib
        chunk = lambda kind, body: (struct.pack('>I', len(body)) + kind + body
                                    + struct.pack('>I', zlib.crc32(kind + body)))
        picture.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0))
                            + chunk(b'IDAT', zlib.compress(b'\x00\xff\xff\xff')) + chunk(b'IEND', b''))
        documents, _ = self.convert(r'''---
title: Alt text
---

# Chapter

![A turn by $\theta$ of $\frac{1}{2}$ [index:turn]turn.](dot.png)
''', cli=True)
        alts = [el.get('alt') for doc in documents for el in doc.iter() if el.tag.endswith('}img')]
        self.assertEqual(alts, ['A turn by θ of 1/2 turn.'])
        captions = [el for doc in documents for el in doc.iter() if el.tag.endswith('}figcaption')]
        self.assertTrue(any(m.tag.endswith('}math') for m in captions[0].iter()))

    # --- the verifier ------------------------------------------------------------------

    def verify(self, *arguments):
        return subprocess.run(['python3', str(ROOT / 'lib/epub_verify.py'), *arguments],
                              capture_output=True, text=True)

    def test_verifier_finds_what_a_plain_conversion_loses(self):
        manuscript = self.directory / 'plain.md'
        epub = self.directory / 'plain.epub'
        manuscript.write_text(r'''---
title: Plain
---

# Chapter

A [index:marker]marker in the text.

```{=latex}
\begin{table}[H]
\begin{tabular}{ll}
Left cell & Right cell \\
\end{tabular}
\caption{A table the writer drops.}
\end{table}
```

$$a = b \tag{4.2}$$
''')
        subprocess.run(['pandoc', str(manuscript), '-t', 'epub3', '--mathml', '-o', str(epub)], check=True)
        result = self.verify(str(epub), '--source', str(manuscript), '--quick')
        self.assertEqual(result.returncode, 1, result.stdout)
        for finding in ('index marker in text', 'tables: the EPUB has 0, the source 1',
                        'equation label (4.2) is not shown', 'A table the writer drops'):
            self.assertIn(finding, result.stdout)

    def test_verifier_reports_what_it_could_not_check(self):
        manuscript = self.directory / 'numbered.md'
        epub = self.directory / 'numbered.epub'
        manuscript.write_text('---\ntitle: Numbered\nequation_numbers: true\n---\n\n# Chapter\n\n$$a = b$$\n')
        subprocess.run(['pandoc', str(manuscript), '-t', 'epub3', '--mathml', '-o', str(epub)], check=True)
        result = self.verify(str(epub), '--source', str(manuscript), '--no-layout')
        self.assertIn('NOT VERIFIED', result.stdout)
        self.assertIn(result.returncode, (1, 2))

    def test_numbering_oracle_matches_in_order(self):
        import sys
        sys.path.insert(0, str(ROOT / 'lib'))
        import epub_verify

        def run(pdf, epub, shown=''):
            report = epub_verify.Report(20)
            epub_verify.subsequence('numbering', report, 'equation', pdf, epub, lambda label: label in shown)
            return [level for level, _ in report.findings['numbering']]

        self.assertEqual(run(['(1.1)', '(1.2)'], ['(1.1)', '(1.2)']), [])
        # a label only in the PDF's column but written in the EPUB's text: a warning
        self.assertEqual(run(['(1.1)', '(1.9)', '(1.2)'], ['(1.1)', '(1.2)'], shown='see (1.9)'), ['warning'])
        # a label nowhere in the EPUB, or in the wrong order: errors
        self.assertEqual(run(['(1.1)', '(1.9)', '(1.2)'], ['(1.1)', '(1.2)']), ['error'])
        self.assertIn('error', run(['(1.1)', '(1.2)'], ['(1.2)', '(1.1)']))

    @unittest.skipUnless(any(shutil.which(b) for b in ('google-chrome', 'chromium', 'chromium-browser'))
                         or os.environ.get('MDTEXPDF_CHROME'), 'needs Chrome or Chromium')
    def test_layout_check_finds_a_formula_wider_than_the_page(self):
        wide = ' + '.join(f'x_{{{n}}}' for n in range(60))
        manuscript = self.directory / 'wide.md'
        manuscript.write_text(f'---\ntitle: Wide\n---\n\n# Chapter\n\nBefore.\n\n$$y = {wide}$$\n\nAfter the formula.\n')
        plain = self.directory / 'plain.epub'
        subprocess.run(['pandoc', str(manuscript), '-t', 'epub3', '--mathml', '-o', str(plain)], check=True)
        result = self.verify(str(plain), '--source', str(manuscript), '--no-pdf')
        self.assertIn('spills into the next page', result.stdout)
        self.assertEqual(result.returncode, 1)
        contained = self.directory / 'contained.epub'
        subprocess.run(['pandoc', str(manuscript), '-t', 'epub3', '--mathml', '--lua-filter', str(FILTER),
                        '-o', str(contained)], check=True)
        result = self.verify(str(contained), '--source', str(manuscript), '--no-pdf')
        self.assertNotIn('spills into the next page', result.stdout)
        self.assertIn('scrolls sideways', result.stdout)



if __name__ == '__main__':
    unittest.main()
