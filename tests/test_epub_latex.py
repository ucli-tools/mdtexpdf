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
