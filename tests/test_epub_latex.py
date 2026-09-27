#!/usr/bin/env python3
"""Check actual EPUB contents, including failure paths and source preservation."""
import os
from pathlib import Path
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
            documents = [ET.fromstring(archive.read(n)) for n in archive.namelist()
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


if __name__ == '__main__':
    unittest.main()
