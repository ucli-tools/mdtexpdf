#!/usr/bin/env python3
"""Verify an EPUB: is it sound, and is everything from its source in it?

    epub_verify.py BOOK.epub [--source BOOK.md] [--pdf BOOK.pdf] [--quick]
                   [--no-pdf] [--no-layout] [--shots DIR] [--json FILE]

Checks, each reported as passed, failed, warned or not verified:

  package      mimetype, container, manifest, spine, metadata, accessibility, cover
  epubcheck    the reference validator (full mode)
  documents    well-formed XHTML, unique ids, no empty headings
  text         nothing leaks into the visible text: [index:] markers, TeX, $...$,
               comment debris, Markdown or pandoc syntax; no formula left as TeX
               (span.math without MathML), no MathML error; alt text clean
  images       every image has alt text, resolves to a packaged file and decodes
  links        every internal link reaches its file and its anchor
  navigation   the contents resolve and follow reading order; NCX too
  source       against the Markdown source, counted here and not by the converter:
               headings, display equations, tables, drawings and images, \\tag
               labels, index markers, and 5-word text coverage of every block
  numbering    against the PDF of the same source: equation numbers and figure and
               table labels in the same order
  reader       calibre's own conversion opens the book and its text is clean
  layout       every chapter paginated as readers do (CSS columns) at phone and
               tablet size, with native MathML and with MathJax: nothing paints over
               text, crosses into the next page or is clipped

Exit status: 0 passed, 1 failed, 2 not verified (a required check could not run),
3 usage error.
"""
import argparse
import collections
import json
import os
import posixpath
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import unicodedata
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

XHTML = 'http://www.w3.org/1999/xhtml'
OPF = 'http://www.idpf.org/2007/opf'
DC = 'http://purl.org/dc/elements/1.1/'
MATHML = 'http://www.w3.org/1998/Math/MathML'
OPS = 'http://www.idpf.org/2007/ops'
CONTAINER = 'urn:oasis:names:tc:opendocument:xmlns:container'
NCX = 'http://www.daisy.org/z3986/2005/ncx/'


def tag(el):
    return el.tag.rsplit('}', 1)[-1] if isinstance(el.tag, str) else ''


def ns(el):
    return el.tag[1:].split('}', 1)[0] if isinstance(el.tag, str) and el.tag.startswith('{') else ''


# --------------------------------------------------------------------------- report

class Report:
    ORDER = ['package', 'epubcheck', 'documents', 'text', 'images', 'links', 'navigation',
             'source', 'numbering', 'reader', 'layout']

    def __init__(self, limit):
        self.limit = limit
        self.findings = collections.defaultdict(list)   # check -> [(level, message)]
        self.state = {}                                  # check -> ran | skipped | not verified
        self.notes = collections.defaultdict(list)

    def error(self, check, message):
        self.findings[check].append(('error', message))

    def warn(self, check, message):
        self.findings[check].append(('warning', message))

    def note(self, check, message):
        self.notes[check].append(message)

    def ran(self, check):
        self.state.setdefault(check, 'ran')

    def skip(self, check, why, required=False):
        self.state[check] = 'not verified' if required else 'skipped'
        self.notes[check].append(why)

    def status(self):
        if any(level == 'error' for items in self.findings.values() for level, _ in items):
            return 1
        return 2 if 'not verified' in self.state.values() else 0

    def as_json(self):
        return {'status': ['passed', 'failed', 'not verified'][self.status()],
                'checks': {c: {'state': self.state.get(c, 'not run'),
                               'errors': [m for l, m in self.findings[c] if l == 'error'],
                               'warnings': [m for l, m in self.findings[c] if l == 'warning'],
                               'notes': self.notes[c]} for c in self.ORDER}}

    def print(self, out=sys.stdout):
        for check in self.ORDER:
            state = self.state.get(check)
            if state is None:
                continue
            errors = [m for l, m in self.findings[check] if l == 'error']
            warnings = [m for l, m in self.findings[check] if l == 'warning']
            if state != 'ran':
                verdict = 'NOT VERIFIED' if state == 'not verified' else 'skipped'
            elif errors:
                verdict = f'FAILED ({len(errors)} error{"s" * (len(errors) != 1)})'
            elif warnings:
                verdict = f'passed, {len(warnings)} warning{"s" * (len(warnings) != 1)}'
            else:
                verdict = 'passed'
            print(f'{check:<11} {verdict}', file=out)
            for message in self.notes[check]:
                print(f'            {message}', file=out)
            for label, items in (('error', errors), ('warning', warnings)):
                for message in items[:self.limit]:
                    print(f'  {label}: {message}', file=out)
                if len(items) > self.limit:
                    print(f'  ... {len(items) - self.limit} more {label}s', file=out)
        print(f"EPUB verification: {['PASSED', 'FAILED', 'NOT VERIFIED'][self.status()]}", file=out)


# --------------------------------------------------------------------------- text helpers

def words(text):
    """Comparable words: compatibility-normalised (ligatures, math italic letters),
    lowercased, soft hyphens removed, letters and digits only."""
    text = unicodedata.normalize('NFKC', text).replace('\u00ad', '').lower()
    return re.findall(r'[^\W_]+', text)


def shingles(ws, n=5):
    return {' '.join(ws[i:i + n]) for i in range(len(ws) - n + 1)}


def excerpt(text, n=90):
    text = ' '.join(text.split())
    return text if len(text) <= n else text[:n - 1] + '…'


# Visible text that is not text: each pattern is something a reader should never see.
LEAKS = [
    ('index marker', re.compile(r'\[index:')),
    ('TeX command', re.compile(r'\\(?:[A-Za-z]{2,}|[()\[\]])')),
    ('unconverted maths', re.compile(r'\$\$|(?<![\w$\\])\$(?=[^\s$\d])[^$\n]{1,200}?(?<=[^\s$\\])\$(?![\w$])')),
    ('comment debris', re.compile(r'<!--|-->')),
    ('Markdown link syntax', re.compile(r'\]\((?:[^)\s]+)\)')),
    ('pandoc attribute', re.compile(r'\{[#.][A-Za-z][\w-]*(?:\s[^}]*)?\}')),
    ('fenced div', re.compile(r'(?:^|\s):::(?:\s|$)')),
    ('Markdown emphasis', re.compile(r'(?<![\w*])\*\*(?=\S)[^*]+?\*\*(?![\w*])')),
    ('footnote syntax', re.compile(r'\[\^[^\]]+\]')),
]
CODE_TAGS = {'code', 'pre', 'kbd', 'samp', 'script', 'style'}
BLOCK_TAGS = {'p', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'td', 'th', 'dt', 'dd', 'caption',
              'figcaption', 'blockquote', 'div', 'section', 'nav', 'body', 'aside', 'header',
              'footer', 'pre', 'table', 'tr', 'ol', 'ul', 'dl', 'figure'}


def visible_blocks(root):
    """(block element, visible text) for every block, MathML and code excluded."""
    out = []

    def walk(el, parts, in_code):
        name = tag(el)
        if ns(el) == MATHML or name in ('script', 'style', 'head'):
            if el.tail:
                parts.append(el.tail)
            return
        code = in_code or name in CODE_TAGS
        if name in CODE_TAGS and name != 'pre':
            # inline code shows its text literally; it is not checked for leaks
            parts.append(' ')
            if el.tail:
                parts.append(el.tail)
            return
        if name in BLOCK_TAGS:
            mine = []
            if el.text:
                mine.append(el.text)
            for child in el:
                walk(child, mine, code)
            text = ''.join(mine)
            if text.strip():
                out.append((el, text, code))
            if el.tail:
                parts.append(el.tail)
            return
        if el.text:
            parts.append(el.text)
        for child in el:
            walk(child, parts, code)
        if el.tail:
            parts.append(el.tail)

    walk(root, [], False)
    return out


BREAK = '\u2029'     # a block boundary no shingle crosses (newlines inside text are spaces)


def block_text(root):
    """Visible text with a line break after every block element and table cell, so
    words of neighbouring cells or paragraphs never run together."""
    parts = []

    def walk(el, pre):
        name = tag(el)
        pre = pre or name == 'pre'
        keep = (lambda t: t.replace('\n', BREAK)) if pre else (lambda t: t)
        if name in ('script', 'style', 'head') or ns(el) == MATHML:
            parts.append(' ')      # a formula still separates the words around it
        else:
            if el.text:
                parts.append(keep(el.text))
            for child in el:
                walk(child, pre)
            if name in BLOCK_TAGS or name in ('br', 'hr'):
                parts.append(BREAK)
        if el.tail:
            parts.append(keep(el.tail))
    walk(root, False)
    return ''.join(parts)


def all_text(root, with_math=False):
    """The text inside `root` (never the text that follows it)."""
    parts = []

    def walk(el, top=False):
        if tag(el) in ('script', 'style', 'head') or (ns(el) == MATHML and not with_math):
            pass
        elif tag(el) == 'annotation' or tag(el) == 'annotation-xml':
            pass
        else:
            if el.text:
                parts.append(el.text)
            for child in el:
                walk(child)
        if el.tail and not top:
            parts.append(el.tail)
    walk(root, top=True)
    return ''.join(parts)


# --------------------------------------------------------------------------- the EPUB

class Epub:
    def __init__(self, path, report):
        self.path = path
        self.report = report
        self.zip = zipfile.ZipFile(path)
        self.names = set(self.zip.namelist())
        self.docs = {}          # zip name -> parsed root
        self.ids = {}           # zip name -> set of ids
        self.manifest = {}      # id -> (zip name, media type, properties)
        self.by_name = {}       # zip name -> (id, media type, properties)
        self.spine = []         # zip names in reading order
        self.opf_name = None

    def read(self, name):
        return self.zip.read(name)

    def resolve(self, base, href):
        """Zip name for an href relative to the document `base` (fragment removed)."""
        target = urllib.parse.unquote(href.split('#', 1)[0])
        if not target:
            return base
        return posixpath.normpath(posixpath.join(posixpath.dirname(base), target))

    # ---- package
    def check_package(self):
        r, c = self.report, 'package'
        r.ran(c)
        infos = self.zip.infolist()
        if not infos or infos[0].filename != 'mimetype':
            r.error(c, 'the first file in the archive is not "mimetype"')
        elif infos[0].compress_type != zipfile.ZIP_STORED:
            r.error(c, '"mimetype" is compressed')
        elif self.read('mimetype').strip() != b'application/epub+zip':
            r.error(c, '"mimetype" does not read application/epub+zip')
        if 'META-INF/container.xml' not in self.names:
            r.error(c, 'META-INF/container.xml is missing')
            return False
        container = ET.fromstring(self.read('META-INF/container.xml'))
        rootfile = container.find(f'.//{{{CONTAINER}}}rootfile')
        if rootfile is None or rootfile.get('full-path') not in self.names:
            r.error(c, 'the container names no package document that exists')
            return False
        self.opf_name = rootfile.get('full-path')
        opf = ET.fromstring(self.read(self.opf_name))
        for item in opf.iter(f'{{{OPF}}}item'):
            name = self.resolve(self.opf_name, item.get('href', ''))
            props = set((item.get('properties') or '').split())
            self.manifest[item.get('id')] = (name, item.get('media-type'), props)
            self.by_name[name] = (item.get('id'), item.get('media-type'), props)
            if name not in self.names:
                r.error(c, f'manifest item {item.get("href")} is not in the archive')
        for name in sorted(self.names):
            if name.endswith('/') or name in ('mimetype', self.opf_name) or name.startswith('META-INF/'):
                continue
            if name not in self.by_name:
                r.warn(c, f'{name} is packaged but not declared in the manifest')
        for ref in opf.iter(f'{{{OPF}}}itemref'):
            entry = self.manifest.get(ref.get('idref'))
            if entry is None:
                r.error(c, f'spine item {ref.get("idref")} is not in the manifest')
            elif ref.get('linear', 'yes') != 'no':
                self.spine.append(entry[0])
        if not self.spine:
            r.error(c, 'the spine is empty')
        meta = opf.find(f'{{{OPF}}}metadata')
        for field in ('title', 'language', 'identifier'):
            element = meta.find(f'{{{DC}}}{field}') if meta is not None else None
            if element is None or not (element.text or '').strip():
                r.error(c, f'dc:{field} is missing')
        props = {m.get('property'): (m.text or '').strip() for m in (meta.iter(f'{{{OPF}}}meta') if meta is not None else [])
                 if m.get('property')}
        if not props.get('dcterms:modified'):
            r.error(c, 'dcterms:modified is missing')
        missing = [p for p in ('schema:accessMode', 'schema:accessibilityFeature',
                               'schema:accessibilityHazard', 'schema:accessibilitySummary') if p not in props]
        if missing:
            r.warn(c, 'accessibility metadata missing: ' + ', '.join(missing))
        covers = [n for n, (_, _, p) in self.by_name.items() if 'cover-image' in p]
        self.cover = covers[0] if covers else None
        if not covers:
            r.warn(c, 'no cover image is declared')
        if not any('nav' in p for (_, _, p) in self.by_name.values()):
            r.error(c, 'no navigation document (properties="nav")')
        return True

    # ---- documents
    def load_documents(self):
        r = self.report
        r.ran('documents')
        for name, (_, media, _) in sorted(self.by_name.items()):
            if media != 'application/xhtml+xml' or name not in self.names:
                continue
            try:
                root = ET.fromstring(self.read(name))
            except ET.ParseError as error:
                r.error('documents', f'{name} is not well-formed XHTML: {error}')
                continue
            self.docs[name] = root
            seen = collections.Counter(el.get('id') for el in root.iter() if el.get('id'))
            self.ids[name] = set(seen)
            for ident, count in seen.items():
                if count > 1:
                    r.error('documents', f'{name}: id "{ident}" is used {count} times')
            for el in root.iter():
                if tag(el) in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6') and ns(el) == XHTML:
                    if not all_text(el, with_math=True).strip() and el.find(f'.//{{{XHTML}}}img') is None:
                        r.warn('documents', f'{name}: empty <{tag(el)}> heading')

    def reading_order(self):
        rest = sorted(n for n in self.docs if n not in self.spine)
        return [n for n in self.spine if n in self.docs] + rest

    # ---- visible text
    def check_text(self):
        r, c = self.report, 'text'
        r.ran(c)
        fallbacks = 0
        for name in self.reading_order():
            root = self.docs[name]
            for el in root.iter(f'{{{XHTML}}}span'):
                classes = (el.get('class') or '').split()
                if 'math' in classes and el.find(f'.//{{{MATHML}}}math') is None:
                    fallbacks += 1
                    r.error(c, f'{name}: formula shown as TeX: {excerpt(all_text(el), 80)}')
            for el in root.iter(f'{{{MATHML}}}merror'):
                r.error(c, f'{name}: MathML error: {excerpt(all_text(el, True), 80)}')
            for block, text, code in visible_blocks(root):
                if code:
                    continue
                for label, pattern in LEAKS:
                    m = pattern.search(text)
                    if m:
                        r.error(c, f'{name}: {label} in text: "{excerpt(text[max(0, m.start() - 30):m.end() + 40], 90)}"')
            for img in root.iter(f'{{{XHTML}}}img'):
                alt = img.get('alt') or ''
                for label, pattern in LEAKS[:4]:
                    if pattern.search(alt):
                        r.error(c, f'{name}: {label} in alt text: "{excerpt(alt, 80)}"')
        if fallbacks:
            r.note(c, f'{fallbacks} formula(s) shown as TeX')

    # ---- images
    def check_images(self):
        r, c = self.report, 'images'
        r.ran(c)
        count = 0
        for name in self.reading_order():
            for img in self.docs[name].iter(f'{{{XHTML}}}img'):
                count += 1
                src = img.get('src') or ''
                if img.get('alt') is None:
                    r.warn(c, f'{name}: image {src} has no text alternative (the source gives it no caption or description)')
                elif not img.get('alt').strip() and img.get('role') != 'presentation':
                    r.warn(c, f'{name}: image {src} has empty alt text')
                if re.match(r'[a-z]+:', src):
                    r.error(c, f'{name}: image {src} is not packaged')
                    continue
                target = self.resolve(name, src)
                if target not in self.names:
                    r.error(c, f'{name}: image {src} is not in the archive')
                    continue
                if target not in self.by_name:
                    r.error(c, f'{name}: image {src} is not in the manifest')
                problem = image_problem(self.read(target), target)
                if problem:
                    r.error(c, f'{target}: {problem}')
        r.note(c, f'{count} image(s)')

    # ---- links
    def check_links(self):
        r, c = self.report, 'links'
        r.ran(c)
        count = 0
        for name in self.reading_order():
            for a in self.docs[name].iter(f'{{{XHTML}}}a'):
                href = a.get('href')
                if href is None:
                    continue
                count += 1
                if re.match(r'(https?|mailto|tel):', href):
                    continue
                if re.match(r'[a-z][a-z0-9+.-]*:', href):
                    r.warn(c, f'{name}: link with scheme {href.split(":")[0]}: {excerpt(href, 60)}')
                    continue
                target = self.resolve(name, href)
                if target not in self.names:
                    r.error(c, f'{name}: link to missing file {excerpt(href, 60)}')
                    continue
                fragment = urllib.parse.unquote(href.split('#', 1)[1]) if '#' in href else ''
                if fragment and target in self.ids and fragment not in self.ids[target]:
                    r.error(c, f'{name}: link to missing anchor {excerpt(href, 60)}')
        r.note(c, f'{count} link(s)')

    # ---- navigation
    def check_navigation(self):
        r, c = self.report, 'navigation'
        r.ran(c)
        navs = [n for n, (_, _, p) in self.by_name.items() if 'nav' in p]
        order = {n: i for i, n in enumerate(self.spine)}
        for nav_name in navs:
            root = self.docs.get(nav_name)
            if root is None:
                continue
            tocs = [n for n in root.iter(f'{{{XHTML}}}nav') if n.get(f'{{{OPS}}}type') == 'toc']
            if not tocs:
                r.error(c, f'{nav_name}: no toc navigation')
                continue
            entries = [a for a in tocs[0].iter(f'{{{XHTML}}}a')]
            if not entries:
                r.error(c, 'the table of contents is empty')
            last = (-1, -1)
            for a in entries:
                href = a.get('href', '')
                target = self.resolve(nav_name, href)
                fragment = href.split('#', 1)[1] if '#' in href else ''
                if target not in self.docs:
                    r.error(c, f'contents entry "{excerpt(all_text(a), 50)}" points to a missing file')
                    continue
                position = 0
                if fragment:
                    ids = [el.get('id') for el in self.docs[target].iter() if el.get('id')]
                    if fragment not in ids:
                        r.error(c, f'contents entry "{excerpt(all_text(a), 50)}" points to a missing anchor')
                        continue
                    position = ids.index(fragment) + 1
                here = (order.get(target, 10 ** 6), position)
                if here < last:
                    r.warn(c, f'contents entry "{excerpt(all_text(a), 50)}" is out of reading order')
                last = max(last, here)
            r.note(c, f'{len(entries)} contents entries')
        for name, (_, media, _) in self.by_name.items():
            if media == 'application/x-dtbncx+xml' and name in self.names:
                ncx = ET.fromstring(self.read(name))
                for content in ncx.iter(f'{{{NCX}}}content'):
                    src = content.get('src', '')
                    target = self.resolve(name, src)
                    fragment = src.split('#', 1)[1] if '#' in src else ''
                    if target not in self.names or (fragment and target in self.ids and fragment not in self.ids[target]):
                        r.error(c, f'NCX entry points nowhere: {src}')


def image_problem(data, name):
    """Why the image data cannot be displayed, or None."""
    if data.startswith(b'\x89PNG\r\n\x1a\n'):
        if len(data) < 24:
            return 'truncated PNG'
        width, height = struct.unpack('>II', data[16:24])
        return None if width and height else 'PNG of zero size'
    if data.startswith(b'\xff\xd8'):
        i = 2
        while i + 9 < len(data):
            if data[i] != 0xFF:
                return 'damaged JPEG'
            marker = data[i + 1]
            length = struct.unpack('>H', data[i + 2:i + 4])[0]
            if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
                height, width = struct.unpack('>HH', data[i + 5:i + 9])
                return None if width and height else 'JPEG of zero size'
            i += 2 + length
        return 'JPEG without a frame header'
    if data[:6] in (b'GIF87a', b'GIF89a'):
        return None
    if name.endswith('.svg'):
        try:
            ET.fromstring(data)
            return None
        except ET.ParseError as error:
            return f'SVG does not parse: {error}'
    if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
        return None
    return 'not a PNG, JPEG, GIF, SVG or WebP image'


# --------------------------------------------------------------------------- the source

TEX_DISPLAY_ENVS = r'equation\*?|align\*?|gather\*?|multline\*?|eqnarray\*?|displaymath'


def strip_environment(text, name):
    return re.sub(r'\\begin\{' + name + r'\}.*?\\end\{' + name + r'\}', ' ', text, flags=re.S)


TEX_ACCENTS = {'"': '\u0308', "'": '\u0301', '`': '\u0300', '^': '\u0302', '~': '\u0303',
               '=': '\u0304', '.': '\u0307', 'c': '\u0327', 'v': '\u030c', 'u': '\u0306',
               'H': '\u030b', 'k': '\u0328', 'r': '\u030a'}


def tex_accents(text):
    """\\"o, \\"{o}, \\c{c} ... as the accented letters they print."""
    def accent(m):
        return unicodedata.normalize('NFC', m.group(2) + TEX_ACCENTS[m.group(1)])
    text = re.sub(r'\\([\"\'`^~=.])\s*\{?([A-Za-z])\}?', accent, text)
    return re.sub(r'\\([cvuHkr])\s*\{([A-Za-z])\}', accent, text)


def tex_to_text(tex):
    """The words a reader should see from a raw TeX block (heuristic, independent of
    the converter): drawings, maths, layout and arguments that are not text removed."""
    t = re.sub(r'(?<!\\)%.*', '', tex)
    t = re.sub(r'\n\s*\n', '\u2063', t)
    t = tex_accents(t)
    # print-only TeX primitives ("keep these lines together" and the like)
    t = re.sub(r'\\par\\penalty-?\d+\\begingroup.*?\\endgroup', ' ', t, flags=re.S)
    t = re.sub(r'\\ifdim.*?\\fi\b', ' ', t, flags=re.S)
    t = re.sub(r'\\(advance|multiply|divide)\s*\\\w+\s*by\s*-?\s*\\?\w+', ' ', t)
    t = re.sub(r'\\(dimen|skip|count)\d+\s*=?\s*-?[\d.]*\s*\\?\w*', ' ', t)
    t = re.sub(r'\\penalty\s*-?\d+', ' ', t)
    t = strip_environment(t, 'tikzpicture')
    t = re.sub(r'\\csname.*?\\endcsname', ' ', t, flags=re.S)
    t = re.sub(r'=\s*-?\d+(\.\d+)?\s*(pt|em|ex|cm|mm|in)?', ' ', t)
    t = re.sub(r'\\captionof\*?\s*\{(?:figure|table)\}', r'\\caption', t)
    t = re.sub(r'\\caption\*?\s*(\[(?:[^\]]|\[[^\]]*\])*\])?\s*\{', '\u2063{', t)
    t = re.sub(r'\\\((.*?)\\\)', ' ', t, flags=re.S)
    t = re.sub(r'\\\[(.*?)\\\]', ' ', t, flags=re.S)
    t = re.sub(r'\$\$(.*?)\$\$', ' ', t, flags=re.S)
    t = re.sub(r'\$[^$]*\$', ' ', t)
    t = re.sub(r'\\newcolumntype\{[^}]*\}(\[[^\]]*\])?\{(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*\}', ' ', t)
    t = re.sub(r'\\(definecolor|colorlet)\s*(\{[^}]*\}\s*){2,3}', ' ', t)
    t = re.sub(r'\\(renewcommand|newcommand|setlength|addtolength|setcounter)\s*\{[^}]*\}\s*(\[[^\]]*\])?\s*\{(?:[^{}]|\{[^{}]*\})*\}', ' ', t)
    t = re.sub(r'\\(vspace|hspace|vskip|hskip|color|pagecolor|rule|arraystretch|noalign|enlargethispage)\*?\s*(\{(?:[^{}]|\{[^{}]*\})*\}\s*)*', ' ', t)
    t = re.sub(r'\\begin\{(tabular\*?|tabularx|longtable|array)\}\s*(\{[^{}]*\}\s*|\[[^\]]*\]\s*)?\{(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*\}', ' ', t)
    t = re.sub(r'\\begin\{(minipage|adjustbox)\}\s*(\[[^\]]*\]\s*)*\{(?:[^{}]|\{[^{}]*\})*\}', ' ', t)
    t = re.sub(r'\\(resizebox|scalebox|rotatebox)\s*\{(?:[^{}]|\{[^{}]*\})*\}(\s*\{(?:[^{}]|\{[^{}]*\})*\})?', ' ', t)
    t = re.sub(r'\\parbox\s*(\[[^\]]*\]\s*)*\{[^{}]*\}', ' ', t)
    t = re.sub(r'\\(caption|captionof)\*?\s*(\{(?:figure|table)\}\s*)?\[(?:[^\]]|\[[^\]]*\])*\]', r'\\\1', t)
    t = re.sub(r'\\(begin|end)\s*\{[^}]*\}\s*(\[[^\]]*\])?', ' ', t)
    t = re.sub(r'\\\\(\[[^\]]*\])?', '\u2063', t)
    t = t.replace('&', '\u2063')
    t = re.sub(r'\\(label|ref|index|includegraphics|cite)\s*(\[[^\]]*\])?\{[^}]*\}', ' ', t)
    t = re.sub(r'\\[A-Za-z@]+\*?', ' ', t)
    t = re.sub(r'\\.', ' ', t)
    return re.sub(r'[{}&~]', ' ', t)


class Source:
    """What the Markdown source holds, read with pandoc and counted here."""

    def __init__(self, path, report):
        self.path = path
        self.report = report
        self.blocks = []            # (kind, excerpt, words)
        self.headings = []          # heading texts
        self.display = 0
        self.tables = 0
        self.drawing_blocks = 0
        self.images = 0
        self.tags = []              # (label, starred)
        self.index_markers = 0
        self.captions = 0           # captioned figures and tables, which LaTeX numbers
        self.meta = {}
        document = json.loads(subprocess.run(
            ['pandoc', path, '-f', 'markdown', '-t', 'json'],
            capture_output=True, text=True, check=True).stdout)
        self.meta = {k: stringify_meta(v) for k, v in document.get('meta', {}).items()}
        side = os.path.join(os.path.dirname(os.path.abspath(path)), 'metadata.yaml')
        if os.path.exists(side):
            for line in open(side, encoding='utf-8'):
                m = re.match(r'^([A-Za-z_]+):\s*"?([^"#\n]*?)"?\s*(#.*)?$', line)
                if m:
                    self.meta.setdefault(m.group(1), m.group(2))
        self.walk_blocks(document['blocks'])

    # ---- counting
    def count_raw(self, text):
        without_drawings = strip_environment(re.sub(r'(?<!\\)%.*', '', text), 'tikzpicture')
        if '\\begin{tikzpicture}' in text:
            self.drawing_blocks += 1
        self.display += len(re.findall(r'(?<!\\)\\\[', without_drawings))
        self.display += len(re.findall(r'\$\$', without_drawings)) // 2
        self.display += len(re.findall(r'\\begin\{(?:' + TEX_DISPLAY_ENVS + r')\}', without_drawings))
        self.tables += len(re.findall(r'\\begin\{(?:tabular\*?|tabularx|longtable)\}', without_drawings))
        self.tags += [(m.group(2), m.group(1) == '*') for m in re.finditer(r'\\tag(\*?)\s*\{([^}]*)\}', without_drawings)]
        self.index_markers += len(re.findall(r'\[index:', text))
        self.captions += len(re.findall(r'\\caption(?:of)?(?![*\w])', without_drawings.replace('\\caption*', '')))

    def inline_text(self, inlines, out):
        for el in inlines:
            t, c = el['t'], el.get('c')
            if t == 'Str':
                out.append(c)
                self.index_markers += c.count('[index:')
            elif t in ('Space', 'SoftBreak', 'LineBreak'):
                out.append(' ')
            elif t == 'Math':
                out.append(' ')
                if c[0]['t'] == 'DisplayMath':
                    self.display += 1
                    self.tags += [(m.group(2), m.group(1) == '*') for m in re.finditer(r'\\tag(\*?)\s*\{([^}]*)\}', c[1])]
            elif t == 'Code':
                out.append(c[1])
            elif t == 'RawInline':
                if c[0] in ('tex', 'latex'):
                    self.count_raw(c[1])
                    out.append(' ' + tex_to_text(c[1]) + ' ')
            elif t in ('Emph', 'Strong', 'Strikeout', 'Superscript', 'Subscript', 'SmallCaps', 'Underline'):
                self.inline_text(c, out)
            elif t == 'Quoted':
                self.inline_text(c[1], out)
            elif t == 'Cite':
                # a citation is rendered by citeproc, not copied; but pandoc also
                # reads [index:sort@display] as one, so its markers still count
                self.inline_text(c[1], [])
                out.append('\u2063')
            elif t in ('Link', 'Span'):
                self.inline_text(c[1], out)
            elif t == 'Image':
                self.images += 1
                out.append(' ')
            elif t == 'Note':
                out.append('\u2063')          # a break no shingle crosses
                self.walk_blocks(c)

    def add(self, kind, text):
        text = re.sub(r'\[index:[^\]]*\]', ' ', text)
        parts = [words(p) for p in text.split('\u2063')]
        if sum(len(p) for p in parts):
            self.blocks.append((kind, excerpt(text), parts))

    def walk_blocks(self, blocks):
        for block in blocks:
            t, c = block['t'], block.get('c')
            if t in ('Para', 'Plain'):
                out = []
                self.inline_text(c, out)
                self.add('paragraph', ''.join(out))
            elif t == 'Header':
                out = []
                self.inline_text(c[2], out)
                text = ''.join(out)
                self.headings.append(re.sub(r'\[index:[^\]]*\]', ' ', text))
                self.add('heading', text)
            elif t == 'CodeBlock':
                self.add('code', c[1].replace('\n', '\u2063'))
            elif t == 'RawBlock':
                if c[0] in ('tex', 'latex'):
                    self.count_raw(c[1])
                    self.add('raw TeX', tex_to_text(c[1]))
                elif c[0] == 'html' and not re.match(r'\s*<!--', c[1]):
                    self.add('raw HTML', re.sub(r'<[^>]*>', ' ', c[1]))
            elif t == 'LineBlock':
                for line in c:
                    out = []
                    self.inline_text(line, out)
                    self.add('line', ''.join(out))
            elif t in ('BlockQuote', 'Div'):
                self.walk_blocks(c if t == 'BlockQuote' else c[1])
            elif t in ('BulletList',):
                for item in c:
                    self.walk_blocks(item)
            elif t == 'OrderedList':
                for item in c[1]:
                    self.walk_blocks(item)
            elif t == 'DefinitionList':
                for term, definitions in c:
                    out = []
                    self.inline_text(term, out)
                    self.add('term', ''.join(out))
                    for definition in definitions:
                        self.walk_blocks(definition)
            elif t == 'Figure':
                self.captions += bool(c[1][1])
                self.walk_blocks(c[1][1])            # caption
                self.walk_blocks(c[2])
            elif t == 'Table':
                self.tables += 1
                self.captions += bool(c[1][1])
                self.walk_blocks(c[1][1])            # caption
                head, bodies, foot = c[3], c[4], c[5]
                rows = list(head[1]) + [row for body in bodies for row in body[2] + body[3]] + list(foot[1])
                for row in rows:
                    for cell in row[1]:
                        self.walk_blocks(cell[4])

    def numbers_equations(self):
        return str(self.meta.get('equation_numbers', '')).lower() == 'true' or bool(self.tags)

    def prints_numbers(self):
        """Does a PDF of this source print numbers the EPUB must match?"""
        return self.numbers_equations() or self.captions > 0


def stringify_meta(value):
    t, c = value.get('t'), value.get('c')
    if t == 'MetaBool':
        return 'true' if c else 'false'
    if t == 'MetaString':
        return c
    if t in ('MetaInlines', 'MetaBlocks'):
        out = []

        def walk(x):
            if isinstance(x, dict):
                if x.get('t') == 'Str':
                    out.append(x['c'])
                elif x.get('t') == 'Space':
                    out.append(' ')
                else:
                    walk(x.get('c'))
            elif isinstance(x, list):
                for y in x:
                    walk(y)
        walk(c)
        return ''.join(out)
    return ''


def check_source(epub, source, report):
    c = 'source'
    report.ran(c)
    order = epub.reading_order()
    visible = []
    headings = []
    displays = tables = images = anchors = 0
    for name in order:
        root = epub.docs[name]
        visible.append(block_text(root.find(f'{{{XHTML}}}body') if root.find(f'{{{XHTML}}}body') is not None else root))
        for el in root.iter():
            name_ = tag(el)
            if ns(el) == XHTML and name_ in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
                headings.append(' '.join(words(all_text(el))))
            elif ns(el) == MATHML and name_ == 'math' and el.get('display') == 'block':
                displays += 1
            elif ns(el) == XHTML and name_ == 'table':
                tables += 1
            elif ns(el) == XHTML and name_ == 'img' and epub.resolve(name, el.get('src', '')) != epub.cover:
                images += 1
            elif ns(el) == XHTML and name_ == 'span' and (el.get('id') or '').startswith('idx-'):
                anchors += 1
    text = BREAK.join(visible)
    epub_words = words(text)
    epub_shingles = set().union(*(shingles(words(part)) for part in text.split(BREAK)))
    vocabulary = set(epub_words)

    # headings: every source heading's words appear as a heading
    heading_set = set(headings)
    missing = [h for h in source.headings if words(h) and ' '.join(words(h)) not in heading_set]
    for h in missing:
        report.error(c, f'heading missing: "{excerpt(h, 70)}"')
    report.note(c, f'headings {len(source.headings) - len(missing)}/{len(source.headings)}')

    def compare(label, have, want, exact_hint=''):
        report.note(c, f'{label}: EPUB {have}, source {want}{exact_hint}')
        if have < want:
            report.error(c, f'{label}: the EPUB has {have}, the source {want}')
        elif have > want:
            report.warn(c, f'{label}: the EPUB has {have}, more than the source\'s {want}')
    compare('display equations', displays, source.display)
    compare('tables', tables, source.tables)
    report.note(c, f'images: EPUB {images}, source {source.images} images + {source.drawing_blocks} drawing blocks (at least one image each)')
    if images < source.images + source.drawing_blocks:
        report.error(c, f'images: the EPUB has {images}, the source at least {source.images + source.drawing_blocks}')

    # equation labels written in the source
    lost = []
    for label, starred in source.tags:
        shown = label if starred else f'({label})'
        if shown not in text:
            lost.append(shown)
    report.note(c, f'\\tag labels shown: {len(source.tags) - len(lost)}/{len(source.tags)}')
    for shown in lost:
        report.error(c, f'equation label {shown} is not shown')

    # index markers become anchors the index links to
    if source.index_markers:
        report.note(c, f'index markers: {source.index_markers}, anchors in the EPUB: {anchors}')
        if anchors != source.index_markers:
            report.error(c, f'{source.index_markers} index markers in the source, {anchors} index anchors in the EPUB')

    # text coverage, block by block
    thin = 0
    for kind, text_excerpt, parts in source.blocks:
        grams = set().union(*(shingles(p) for p in parts))
        if len(grams) >= 3:
            found = len(grams & epub_shingles) / len(grams)
        else:
            ws = [w for p in parts for w in p]
            if len(ws) < 3:
                continue
            found = sum(w in vocabulary for w in ws) / len(ws)
        if found < 0.8:
            thin += 1
            report.error(c, f'{kind} not in the EPUB ({found:.0%} found): "{text_excerpt}"')
    report.note(c, f'text blocks: {len(source.blocks) - thin}/{len(source.blocks)} found')


# --------------------------------------------------------------------------- numbering vs the PDF

EQ_LABEL = re.compile(r'\(((?:[0-9]+|[A-Z])(?:\.[0-9]+)+[a-z]?)\)\s*$')
EQ_PLAIN = re.compile(r'\(([0-9]+)\)\s*$')
CAPTION_LABEL = re.compile(r'^\s*(Figure|Table) ((?:[0-9]+|[A-Z])(?:\.[0-9]+)*):')


def epub_labels(epub):
    equations, captions = [], []
    for name in epub.reading_order():
        for el in epub.docs[name].iter(f'{{{XHTML}}}span'):
            classes = (el.get('class') or '').split()
            if 'eqno' in classes:
                equations.append(all_text(el).strip())
            elif 'caption-label' in classes:
                m = re.match(r'\s*(Figure|Table) (\S+?):?\s*$', all_text(el))
                if m:
                    captions.append((m.group(1), m.group(2)))
    return equations, captions


def subsequence(check, report, what, want, have, found_in_text):
    """Every EPUB label in `have` must match PDF labels in `want` in order; PDF labels
    left over must at least be visible somewhere in the EPUB."""
    j = 0
    for i, label in enumerate(have):
        k = j
        while k < len(want) and want[k] != label:
            k += 1
        if k == len(want):
            before = ', '.join(have[max(0, i - 3):i])
            after = ', '.join(want[j:j + 4])
            report.error(check, f'{what} {label} (EPUB #{i + 1}, after {before or "the start"}) '
                                f'does not follow in the PDF, whose next labels are {after or "none"}')
            return
        for leftover in want[j:k]:
            if found_in_text(leftover):
                report.warn(check, f'{what} {leftover} is in the PDF\'s label column; the EPUB shows it only in text')
            else:
                report.error(check, f'{what} {leftover} is in the PDF but nowhere in the EPUB')
        j = k + 1
    for leftover in want[j:]:
        if found_in_text(leftover):
            report.warn(check, f'{what} {leftover} is in the PDF\'s label column; the EPUB shows it only in text')
        else:
            report.error(check, f'{what} {leftover} is in the PDF but nowhere in the EPUB')


def check_numbering(epub, pdf, report):
    c = 'numbering'
    if shutil.which('pdftotext') is None:
        report.skip(c, 'pdftotext (Poppler) is not installed', required=True)
        return
    report.ran(c)
    lines = subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True, text=True,
                           check=True).stdout.splitlines()
    equations, captions = epub_labels(epub)
    chapterless = equations and all(re.fullmatch(r'\([0-9]+\)', e) for e in equations)
    pattern = EQ_PLAIN if chapterless else EQ_LABEL
    pdf_equations = [f'({m.group(1)})' for m in (pattern.search(l) for l in lines) if m]
    pdf_captions = [(m.group(1), m.group(2)) for m in (CAPTION_LABEL.match(l) for l in lines) if m]
    shown = '\n'.join(all_text(epub.docs[n], with_math=True) for n in epub.reading_order())
    epub_eq = [e for e in equations if pattern.fullmatch(e) or re.fullmatch(r'\([0-9A-Z.]+[a-z]?\)', e)]
    report.note(c, f'equation labels: PDF {len(pdf_equations)}, EPUB {len(epub_eq)}')
    subsequence(c, report, 'equation', pdf_equations, epub_eq, lambda l: l in shown)
    for kind in ('Figure', 'Table'):
        want = [f'{kind} {l}' for k, l in pdf_captions if k == kind]
        have = [f'{kind} {l}' for k, l in captions if k == kind]
        report.note(c, f'{kind.lower()} labels: PDF {len(want)}, EPUB {len(have)}')
        subsequence(c, report, kind.lower(), want, have, lambda l: l in shown)


# --------------------------------------------------------------------------- calibre

def check_reader(epub_path, report):
    c = 'reader'
    tool = shutil.which('ebook-convert')
    if tool is None:
        report.skip(c, 'calibre (ebook-convert) is not installed')
        return
    report.ran(c)
    with tempfile.TemporaryDirectory(prefix='epub-verify-') as directory:
        out = os.path.join(directory, 'book.txt')
        result = subprocess.run([tool, epub_path, out], capture_output=True, text=True)
        if result.returncode != 0 or not os.path.exists(out):
            report.error(c, 'calibre could not open the book: ' + excerpt(result.stderr or result.stdout, 200))
            return
        text = open(out, encoding='utf-8', errors='replace').read()
    report.note(c, f'calibre read {len(text.split())} words')
    for label, pattern in LEAKS[:3]:
        hits = [m for m in pattern.finditer(text)]
        if hits:
            m = hits[0]
            report.error(c, f'calibre shows {len(hits)} {label}(s), first: "{excerpt(text[max(0, m.start() - 30):m.end() + 40])}"')


# --------------------------------------------------------------------------- layout

def find_chrome():
    for candidate in (os.environ.get('MDTEXPDF_CHROME'), 'google-chrome', 'google-chrome-stable',
                      'chromium', 'chromium-browser'):
        if candidate and shutil.which(candidate):
            return shutil.which(candidate)
    return None


def find_mathjax():
    for candidate in (os.environ.get('MDTEXPDF_MATHJAX'), '/opt/calibre/resources/mathjax',
                      '/usr/share/calibre/mathjax', '/usr/lib/calibre/resources/mathjax'):
        if candidate and os.path.exists(os.path.join(candidate, 'startup.js')):
            return os.path.abspath(candidate)
    return None


def check_layout(epub, report, shots=None):
    c = 'layout'
    chrome = find_chrome()
    if chrome is None:
        report.skip(c, 'no Chrome or Chromium found (set MDTEXPDF_CHROME)', required=True)
        return
    try:
        import epub_layout
    except ImportError:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import epub_layout
    mathjax = find_mathjax()
    engines = ['native'] + (['mathjax'] if mathjax else [])
    if not mathjax:
        report.note(c, 'MathJax not found (set MDTEXPDF_MATHJAX): native MathML only')
    report.ran(c)
    documents = [n for n in epub.spine if n in epub.docs]
    seen = set()
    with tempfile.TemporaryDirectory(prefix='epub-layout-') as directory:
        epub.zip.extractall(directory)
        results = epub_layout.measure(chrome, directory, documents, engines, mathjax, shots)
    pages = 0
    for doc, viewport, engine, result in results:
        if 'fatal' in result:
            report.error(c, f'{doc} ({viewport}, {engine}): {result["fatal"]}')
            continue
        pages += result.get('pages', 0)
        for problem in result['problems']:
            key = (doc, problem['kind'], problem['what'])
            if key in seen:
                continue
            seen.add(key)
            message = f'{doc} ({viewport}, {engine}, page {problem["page"]}): {problem["kind"]}: {excerpt(problem["what"], 80)}'
            if problem.get('text'):
                message += f' over "{excerpt(problem["text"], 40)}"'
            (report.error if problem['level'] == 'error' else report.warn)(c, message)
    report.note(c, f'{len(documents)} document(s), {len(results)} renderings, {pages} pages, engines: {", ".join(engines)}')


# --------------------------------------------------------------------------- epubcheck

def check_epubcheck(epub_path, report):
    c = 'epubcheck'
    if shutil.which('epubcheck') is None:
        report.skip(c, 'epubcheck is not installed', required=True)
        return
    report.ran(c)
    result = subprocess.run(['epubcheck', '--quiet', epub_path], capture_output=True, text=True)
    for line in (result.stdout + result.stderr).splitlines():
        if line.startswith(('ERROR', 'FATAL')):
            report.error(c, excerpt(line, 200))
        elif line.startswith('WARNING'):
            report.warn(c, excerpt(line, 200))
    if result.returncode != 0 and not report.findings[c]:
        report.error(c, 'epubcheck failed: ' + excerpt(result.stdout + result.stderr, 200))


# --------------------------------------------------------------------------- main

def main(argv=None):
    parser = argparse.ArgumentParser(description='Verify that an EPUB is sound and complete.')
    parser.add_argument('epub')
    parser.add_argument('--source', help='the Markdown the EPUB was built from')
    parser.add_argument('--pdf', help='a PDF built from the same source, to check numbering against')
    parser.add_argument('--no-pdf', action='store_true', help='accept that numbering is not checked against a PDF')
    parser.add_argument('--no-layout', action='store_true', help='skip the paginated layout check')
    parser.add_argument('--quick', action='store_true',
                        help='package, text, links, navigation and source only (after every build)')
    parser.add_argument('--shots', help='save a screenshot of every page with a layout error here')
    parser.add_argument('--limit', type=int, default=12, help='details shown per check')
    parser.add_argument('--json', help='also write the report as JSON to this file')
    args = parser.parse_args(argv)
    if not os.path.isfile(args.epub):
        print(f'epub_verify: {args.epub} not found', file=sys.stderr)
        return 3
    report = Report(args.limit)
    try:
        epub = Epub(args.epub, report)
    except zipfile.BadZipFile:
        report.error('package', 'not a ZIP archive')
        report.ran('package')
        report.print()
        return report.status()
    if epub.check_package():
        epub.load_documents()
        epub.check_text()
        epub.check_images()
        epub.check_links()
        epub.check_navigation()
    source = None
    if args.source:
        try:
            source = Source(args.source, report)
        except (OSError, subprocess.CalledProcessError) as error:
            report.error('source', f'could not read the source with pandoc: {error}')
            report.ran('source')
        if source is not None:
            check_source(epub, source, report)
    else:
        report.skip('source', 'no --source given: completeness not checked', required=not args.quick)
    if args.quick:
        report.skip('numbering', 'quick check: numbering is verified by `mdtexpdf validate --pdf`')
    elif args.pdf:
        check_numbering(epub, args.pdf, report)
    else:
        needs = source is not None and source.prints_numbers()
        report.skip('numbering', 'no --pdf given: equation, figure and table numbers not checked against a PDF',
                    required=needs and not args.no_pdf)
    if not args.quick:
        check_epubcheck(args.epub, report)
        check_reader(args.epub, report)
        if args.no_layout:
            report.skip('layout', '--no-layout given')
        else:
            check_layout(epub, report, args.shots)
    report.print()
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as out:
            json.dump(report.as_json(), out, indent=2, ensure_ascii=False)
    return report.status()


if __name__ == '__main__':
    sys.exit(main())
