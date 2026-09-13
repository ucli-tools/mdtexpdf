#!/bin/bash
# Exercise the installed converter during each platform's Docker image build.
set -euo pipefail

smoke_dir=$(mktemp -d)
trap 'rm -rf "$smoke_dir"' EXIT
cd "$smoke_dir"

cat > book.md <<'EOF'
---
title: Docker EPUB smoke test
author: Example Author
dedication: For attentive readers.
---

# A quiet page

\begin{figure}[H]
\begin{tikzpicture}
\draw (0,0) circle (1);
\end{tikzpicture}
\end{figure}

\begin{minipage}{\linewidth}
\setlength{\parskip}{\baselineskip}

Inside the layout wrapper.

The final retained paragraph.

\end{minipage}
EOF
source_hash=$(sha256sum book.md)
if ! mdtexpdf convert book.md --read-metadata --epub > epub.log 2>&1; then
    cat epub.log >&2
    exit 1
fi
test "$source_hash" = "$(sha256sum book.md)"
unzip -tq book.epub
unzip -p book.epub 'EPUB/text/*.xhtml' > content.html
grep -Fq 'For attentive readers.' content.html
grep -Fq 'Inside the layout wrapper.' content.html
grep -Fq 'The final retained paragraph.' content.html
test "$(unzip -Z1 book.epub | grep -c '^EPUB/media/.*\.png$')" = 1

cat > article.md <<'EOF'
---
title: Docker PDF smoke test
author: Example Author
---

# A section without numbering

This PDF must compile with the installed template and fonts.
EOF
source_hash=$(sha256sum article.md)
if ! mdtexpdf convert article.md --read-metadata --no-numbers > pdf.log 2>&1; then
    cat pdf.log >&2
    exit 1
fi
test -s article.pdf
test "$source_hash" = "$(sha256sum article.md)"

cat > broken.md <<'EOF'
---
title: Invalid artwork
---

\begin{tikzpicture}
\notarealcommand
\end{tikzpicture}
EOF
source_hash=$(sha256sum broken.md)
if mdtexpdf convert broken.md --read-metadata --epub > broken.log 2>&1; then
    echo 'Invalid artwork incorrectly reported a successful conversion' >&2
    exit 1
fi
test "$source_hash" = "$(sha256sum broken.md)"
test ! -e broken.epub
echo 'Docker smoke: metadata, EPUB content, PDF and source restoration passed.'
