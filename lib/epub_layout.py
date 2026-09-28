"""Paginate EPUB documents the way reading systems do and measure what goes wrong.

Headless Chrome is driven over --remote-debugging-pipe (standard library only). Each
document is laid out in CSS columns one screen wide and one screen high, as paginated
readers do, at a phone and a tablet size, with native MathML and, when a MathJax copy is
available, with MathJax (calibre's viewer typesets that way). For every formula, image
and table the painted extent is measured and compared with the page and with the lines
of text around it.
"""
import base64
import fcntl
import json
import os
import select
import shutil
import subprocess
import tempfile

VIEWPORTS = {'phone': (390, 844), 'tablet': (820, 1180)}


class Chrome:
    def __init__(self, binary):
        to_chrome_r, to_chrome_w = os.pipe()
        from_chrome_r, from_chrome_w = os.pipe()
        # Chrome reads commands on fd 3 and writes replies on fd 4
        a = fcntl.fcntl(to_chrome_r, fcntl.F_DUPFD, 20)
        b = fcntl.fcntl(from_chrome_w, fcntl.F_DUPFD, 20)
        os.close(to_chrome_r)
        os.close(from_chrome_w)
        self.profile = tempfile.mkdtemp(prefix='epub-layout-chrome-')

        def child():
            os.dup2(a, 3)
            os.dup2(b, 4)
        self.proc = subprocess.Popen(
            [binary, '--headless=new', '--remote-debugging-pipe', '--disable-gpu', '--no-first-run',
             '--no-default-browser-check', '--allow-file-access-from-files', '--hide-scrollbars',
             '--mute-audio', f'--user-data-dir={self.profile}', 'about:blank'],
            pass_fds=(3, 4), preexec_fn=child, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        os.close(a)
        os.close(b)
        self.w = os.fdopen(to_chrome_w, 'wb', buffering=0)
        self.r = os.fdopen(from_chrome_r, 'rb', buffering=0)
        self.buf = b''
        self.next_id = 0
        self.events = []

    def _read(self, timeout):
        while b'\0' not in self.buf:
            ready, _, _ = select.select([self.r], [], [], timeout)
            if not ready:
                raise TimeoutError('the browser did not answer in time')
            chunk = self.r.read(1 << 20)
            if not chunk:
                raise RuntimeError('the browser closed the pipe')
            self.buf += chunk
        message, self.buf = self.buf.split(b'\0', 1)
        return json.loads(message)

    def send(self, method, params=None, session=None, timeout=300):
        self.next_id += 1
        message = {'id': self.next_id, 'method': method, 'params': params or {}}
        if session:
            message['sessionId'] = session
        self.w.write(json.dumps(message).encode() + b'\0')
        while True:
            reply = self._read(timeout)
            if reply.get('id') == self.next_id:
                if 'error' in reply:
                    raise RuntimeError(f'{method}: {reply["error"].get("message")}')
                return reply.get('result', {})
            self.events.append(reply)

    def wait_event(self, name, session, timeout=300):
        while True:
            for i, event in enumerate(self.events):
                if event.get('method') == name and event.get('sessionId') == session:
                    return self.events.pop(i)
            self.events.append(self._read(timeout))

    def close(self):
        try:
            self.send('Browser.close', timeout=10)
        except Exception:
            pass
        try:
            self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.proc.kill()
        shutil.rmtree(self.profile, ignore_errors=True)


# Record each formula's TeX before MathJax replaces the MathML
PREPARE = r'''
(() => {
  window.__mdtexpdfTex = [...document.querySelectorAll('math')].map(m => {
    const a = m.querySelector('annotation');
    return (a ? a.textContent : m.textContent).trim().replace(/\s+/g, ' ');
  });
  return window.__mdtexpdfTex.length;
})()
'''

TYPESET = r'''
(async () => {
  window.MathJax = {options: {renderActions: {addMenu: [0, '', '']}},
                    loader: {load: ['input/mml', 'output/chtml'], paths: {mathjax: '%(url)s'}},
                    startup: {typeset: true}};
  await new Promise((ok, bad) => {
    const s = document.createElementNS('http://www.w3.org/1999/xhtml', 'script');
    s.src = '%(url)s/startup.js'; s.onload = ok; s.onerror = () => bad('MathJax did not load');
    (document.head || document.documentElement).appendChild(s);
  });
  while (!(window.MathJax.startup && window.MathJax.startup.promise)) await new Promise(r => setTimeout(r, 50));
  await MathJax.startup.promise;
  return document.querySelectorAll('mjx-container').length;
})()
'''

# One screen per page, as paginated readers lay a chapter out
PAGINATE = r'''
(() => {
  const W = innerWidth, H = innerHeight;
  const style = document.createElementNS('http://www.w3.org/1999/xhtml', 'style');
  style.textContent = `html { height: ${H}px !important; column-width: ${W}px !important; column-gap: 0 !important;
                                column-fill: auto !important; overflow: hidden !important; margin: 0 !important; }
                       body { margin: 0 ${Math.round(W * 0.05)}px !important; }`;
  (document.head || document.documentElement).appendChild(style);
  return Math.round(document.documentElement.scrollWidth / W);
})()
'''

MEASURE = r'''
(async () => {
  await document.fonts.ready;
  const engine = '%(engine)s';
  const W = innerWidth, H = innerHeight;
  const pages = Math.round(document.documentElement.scrollWidth / W);
  const out = {pages, problems: []};
  const X = scrollX, Y = scrollY;
  const pageOf = x => Math.floor((x + 0.5) / W);
  const R = r => ({l: r.left + X, t: r.top + Y, r: r.right + X, b: r.bottom + Y});
  const union = (a, b) => a ? {l: Math.min(a.l, b.l), t: Math.min(a.t, b.t), r: Math.max(a.r, b.r), b: Math.max(a.b, b.b)} : b;
  const meet = (a, b) => ({l: Math.max(a.l, b.l), t: Math.max(a.t, b.t), r: Math.min(a.r, b.r), b: Math.min(a.b, b.b)});
  const graphic = 'math, mjx-container, img, svg';

  // lines of text, bucketed by page
  const lines = new Map();
  const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const t = walker.currentNode;
    if (!t.textContent.trim() || !t.parentElement || t.parentElement.closest(graphic)) continue;
    const range = document.createRange(); range.selectNodeContents(t);
    for (const rect of range.getClientRects()) {
      if (rect.width < 1 || rect.height < 1) continue;
      const box = R(rect), p = pageOf(box.l);
      if (!lines.has(p)) lines.set(p, []);
      lines.get(p).push({box, el: t.parentElement, text: t.textContent.trim().slice(0, 60)});
    }
  }

  const clipOf = el => {
    for (let a = el.parentElement; a && a !== document.body && a !== document.documentElement; a = a.parentElement) {
      const s = getComputedStyle(a);
      if (s.overflowX !== 'visible' || s.overflowY !== 'visible') return a;
    }
    return null;
  };
  const inkOf = el => {
    let ink = null;
    for (const node of [el, ...el.querySelectorAll('*')]) {
      if (node.closest('annotation, annotation-xml, mjx-assistive-mml')) continue;
      for (const rect of node.getClientRects()) if (rect.width > 0 && rect.height > 0) ink = union(ink, R(rect));
    }
    return ink;
  };

  const texts = window.__mdtexpdfTex || [];
  let targets = [];
  if (engine === 'mathjax') {
    [...document.querySelectorAll('mjx-container')].forEach((el, i) =>
      targets.push({el, kind: 'formula', display: el.getAttribute('display') === 'true', what: texts[i] || 'formula'}));
  } else {
    [...document.querySelectorAll('math')].forEach((el, i) =>
      targets.push({el, kind: 'formula', display: el.getAttribute('display') === 'block', what: texts[i] || 'formula'}));
  }
  for (const el of document.querySelectorAll('img'))
    targets.push({el, kind: 'image', display: true, what: el.getAttribute('src') || 'image'});

  let current = null;
  const report = (level, kind, what, page, text) => out.problems.push({level, kind, what, page: page + 1, text: text || '',
    box: current ? [current.l, current.t, current.r, current.b].map(Math.round) : null});
  for (const target of targets) {
    const {el, display, what} = target;
    const ink = inkOf(el);
    if (!ink) continue;
    current = ink;
    let seen = ink;
    const clip = clipOf(el);
    if (clip) {
      const c = R(clip.getBoundingClientRect()), s = getComputedStyle(clip);
      if (ink.t < c.t - 1.5 || ink.b > c.b + 1.5) report('error', 'clipped at top or bottom', what, pageOf(c.l));
      if (ink.l < c.l - 1.5 || ink.r > c.r + 1.5) {
        const scrolls = ['auto', 'scroll'].includes(s.overflowX) && clip.scrollWidth > clip.clientWidth + 1;
        if (scrolls) report('warning', 'scrolls sideways', what, pageOf(c.l));
        else report('error', 'clipped at the side', what, pageOf(c.l));
      }
      seen = meet(ink, c);
    }
    const p = pageOf(seen.l);
    if (seen.r > (p + 1) * W + 1) report('error', 'spills into the next page', what, p);
    if (seen.b - seen.t > H) report('warning', 'taller than a page', what, p);
    else if (seen.b > H + 1) report('error', 'cut at the foot of the page', what, p);
    else if (seen.t < -1) report('error', 'cut at the top of the page', what, p);
    for (const q of [p, p + 1]) {
      for (const line of lines.get(q) || []) {
        if (el.contains(line.el)) continue;
        const ix = Math.min(seen.r, line.box.r) - Math.max(seen.l, line.box.l);
        const iy = Math.min(seen.b, line.box.b) - Math.max(seen.t, line.box.t);
        if (ix > 2 && iy > 3) {
          // an inline formula touching the line above or below in its own paragraph
          // is a tall formula; over another element's text (a neighbouring table
          // cell, a caption) it hides that text
          const own = line.el.contains(el);
          report(display || !own ? 'error' : 'warning', 'paints over text', what, q, line.text);
          break;
        }
      }
    }
  }
  current = null;
  for (const table of document.querySelectorAll('table')) {
    const caption = table.querySelector('caption');
    const what = caption ? caption.textContent.trim() : table.textContent.trim();
    // a table that scrolls sideways (in its own scroll box) shows everything; one
    // that runs past the page does not, nor does one a page cuts at its foot
    const scroller = getComputedStyle(table).overflowX !== 'visible' ? table : clipOf(table);
    for (const row of table.querySelectorAll('tr')) {
      for (const rect of row.getClientRects()) {
        const box = R(rect), p = pageOf(box.l);
        if (box.r > (p + 1) * W + 1) {
          if (scroller) report('warning', 'table scrolls sideways', what, p);
          else report('error', 'table spills into the next page', what, p);
          break;
        }
        if (box.b > H + 1 && box.b - box.t <= H) report('error', 'table cut at the foot of the page', what, p);
      }
    }
  }
  return JSON.stringify(out);
})()
'''


def measure(binary, directory, documents, engines, mathjax, shots=None):
    """[(document, viewport, engine, result)] for every document, viewport and engine."""
    results = []
    chrome = Chrome(binary)
    try:
        for viewport, (width, height) in VIEWPORTS.items():
            for engine in engines:
                for doc in documents:
                    results.append((doc, viewport, engine,
                                    _one(chrome, directory, doc, width, height, engine, mathjax, shots, viewport)))
    finally:
        chrome.close()
    return results


def _one(chrome, directory, doc, width, height, engine, mathjax, shots, viewport):
    target = chrome.send('Target.createTarget', {'url': 'about:blank'})['targetId']
    try:
        session = chrome.send('Target.attachToTarget', {'targetId': target, 'flatten': True})['sessionId']
        chrome.send('Page.enable', session=session)
        chrome.send('Emulation.setDeviceMetricsOverride', {'width': width, 'height': height,
                                                           'deviceScaleFactor': 1, 'mobile': False}, session=session)
        chrome.send('Page.navigate', {'url': 'file://' + os.path.join(os.path.abspath(directory), doc)}, session=session)
        chrome.wait_event('Page.loadEventFired', session, timeout=120)

        def run(script, timeout=600):
            reply = chrome.send('Runtime.evaluate', {'expression': script, 'awaitPromise': True,
                                                     'returnByValue': True}, session=session, timeout=timeout)
            if 'exceptionDetails' in reply:
                raise RuntimeError(reply['exceptionDetails'].get('exception', {}).get('description')
                                   or reply['exceptionDetails'].get('text'))
            return reply['result'].get('value')

        run(PREPARE)
        if engine == 'mathjax':
            run(TYPESET % {'url': 'file://' + mathjax})
        run(PAGINATE)
        result = json.loads(run(MEASURE % {'engine': engine}))
        if shots:
            _shoot(chrome, session, run, result, shots, doc, viewport, engine, width)
        return result
    except (RuntimeError, TimeoutError) as error:
        return {'fatal': str(error), 'problems': []}
    finally:
        try:
            chrome.send('Target.closeTarget', {'targetId': target}, timeout=30)
        except Exception:
            pass


def _shoot(chrome, session, run, result, shots, doc, viewport, engine, width):
    """A screenshot of each page (at most eight) on which an error was found."""
    pages = sorted({p['page'] for p in result['problems'] if p['level'] == 'error'})[:8]
    os.makedirs(shots, exist_ok=True)
    for page in pages:
        run(f'document.documentElement.scrollLeft = {(page - 1) * width}; 0')
        data = chrome.send('Page.captureScreenshot', {'format': 'png'}, session=session)['data']
        name = f'{doc.replace("/", "_")}.{viewport}.{engine}.p{page}.png'
        with open(os.path.join(shots, name), 'wb') as out:
            out.write(base64.b64decode(data))
