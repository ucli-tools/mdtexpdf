-- Preserve print-layout Markdown and render TikZ artwork for EPUB.
-- This filter is deliberately inactive for PDF/LaTeX output.
local preamble = ''
local render_count = 0
local convert_raw, convert_raw_inline

-- A figure's description is an HTML comment right after it (the form mdaudiobook reads
-- aloud after the caption):
--   <!-- audio-description
--   Here in Figure 2.1 we see ...
--   -->
-- It becomes the image's alt text, so a screen reader describes the picture; the comment
-- itself never shows.
local DESCRIPTION = '^%s*<!%-%-%s*audio%-description%s+(.-)%s*%-%->%s*$'
local pending_description

local function description_of(block)
  if block and block.t == 'RawBlock' and block.format == 'html' then
    return block.text:match(DESCRIPTION)
  end
end

-- TeX maths as text a screen reader can say. Pandoc's plain writer turns most of it
-- into Unicode (θ, x², ∫₀¹); fractions and roots it cannot, so they are rewritten first,
-- and whatever it still leaves as TeX loses its markup.
local function simplify_tex(tex)
  local function group(value)
    value = value:sub(2, -2)
    return value:match('^[%w.]+$') and value or '(' .. value .. ')'
  end
  local previous
  repeat
    previous = tex
    tex = tex:gsub('\\[dt]?frac%s*(%b{})%s*(%b{})', function(a, b) return group(a) .. '/' .. group(b) end)
      :gsub('\\sqrt%s*(%b{})', function(a) return '√' .. group(a) end)
  until tex == previous
  return tex
end

local function plain_text(blocks)
  local doc = pandoc.Pandoc(blocks):walk({Math = function(math)
    math.text = simplify_tex(math.text)
    return math
  end})
  local text = pandoc.write(doc, 'plain')
  text = text:gsub('%$([^$]*)%$', '%1'):gsub('\\[,;:! ]', ' '):gsub('\\(%a+)', '%1'):gsub('[{}]', '')
  return (text:gsub('%s+', ' '):gsub('^ ', ''):gsub(' $', ''))
end

local function strip_layout(text)
  local lines, fence_char, fence_length, changed = {}, nil, 0, false
  for line in (text .. '\n'):gmatch('(.-)\n') do
    local indent, fence = line:match('^( *)([`~]+)')
    local is_fence = fence and #indent <= 3 and #fence >= 3
      and (fence:match('^`+$') or fence:match('^~+$'))
    if fence_char then
      lines[#lines + 1] = line
      if is_fence and fence:sub(1, 1) == fence_char and #fence >= fence_length
          and line:match('^[ `~]*$') then
        fence_char = nil
      end
    elseif is_fence then
      fence_char, fence_length = fence:sub(1, 1), #fence
      lines[#lines + 1] = line
    else
      -- Only layout commands at the start of a line are wrappers. Never rewrite
      -- examples inside fenced code, inline code, or the prose of that line.
      local original = line
      -- Print-only spacing before a minipage (\par, \medskip, \noindent) goes with it.
      local head = line:gsub('^%s*\\par%f[^%a]%s*', ''):gsub('^%s*\\medskip%f[^%a]%s*', '')
        :gsub('^%s*\\noindent%f[^%a]%s*', '')
      if head:match('^%s*\\begin{minipage}') then line = head end
      line = line:gsub('^%s*\\begin{minipage}%s*(%b[])%s*(%b[])%s*(%b[])%s*(%b{})', '')
        :gsub('^%s*\\begin{minipage}%s*(%b[])%s*(%b[])%s*(%b{})', '')
        :gsub('^%s*\\begin{minipage}%s*(%b[])%s*(%b{})', '')
        :gsub('^%s*\\begin{minipage}%s*(%b{})', '')
        :gsub('^%s*\\end{minipage}', '')
        :gsub('^%s*\\begin{samepage}', ''):gsub('^%s*\\end{samepage}', '')
        :gsub('^%s*\\setlength%s*{\\parskip}%s*(%b{})', '')
        :gsub('^%s*\\setlength%s*{\\parindent}%s*(%b{})', '')
      lines[#lines + 1] = line
      changed = changed or line ~= original
    end
  end
  return table.concat(lines, '\n'), changed
end

local function render_artwork(text)
  local caption
  text = text:gsub('\\caption%s*(%b[])%s*(%b{})', function(_, value)
    caption = value:sub(2, -2)
    return ''
  end):gsub('\\caption%s*(%b{})', function(value)
    caption = value:sub(2, -2)
    return ''
  end)
  local identifier = text:match('\\label%s*{([^}]+)}') or ''
  text = text:gsub('\\label%s*(%b{})', '')
    :gsub('\\begin{figure%*?}%s*(%b[])', '')
    :gsub('\\begin{figure%*?}', ''):gsub('\\end{figure%*?}', '')
    :gsub('^[ \t]*\\centering[ \t]*\n', ''):gsub('\n[ \t]*\\centering[ \t]*\n', '\n')
    :gsub('\\vspace%*?%s*(%b{})', '')
    :gsub('\\par%f[^%a]%s*', '\n')

  render_count = render_count + 1
  local name = 'mdtexpdf-tikz-' .. render_count .. '.png'
  local png = pandoc.system.with_temporary_directory('mdtexpdf-tikz', function(dir)
    return pandoc.system.with_working_directory(dir, function()
      local file = assert(io.open('drawing.tex', 'w'))
      file:write('\\documentclass[border=2pt]{standalone}\n',
        '\\usepackage{amsmath}\n\\usepackage{amssymb}\n',
        '\\usepackage{tikz}\n\\usepackage{pgfplots}\n\\usepackage{adjustbox}\n',
        -- The same TikZ setup the PDF template loads, so artwork compiles identically.
        '\\usetikzlibrary{positioning,arrows.meta,decorations.markings,decorations.pathreplacing,calc,patterns}\n',
        '\\pgfplotsset{compat=1.17}\n\\usepgfplotslibrary{fillbetween}\n',
        preamble, '\n\\begin{document}\n', text, '\n\\end{document}\n')
      file:close()
      -- Argument vectors avoid shell interpolation; shell escape is disabled.
      local ok, result = pcall(pandoc.pipe, 'xelatex', {
        '-no-shell-escape', '-halt-on-error', '-interaction=nonstopmode', 'drawing.tex'
      }, '')
      if not ok then
        error('EPUB TikZ drawing ' .. render_count .. ' failed to compile (xelatex required):\n' .. tostring(result))
      end
      ok, result = pcall(pandoc.pipe, 'pdftoppm', {
        '-singlefile', '-png', '-r', '144', 'drawing.pdf', 'drawing'
      }, '')
      if not ok then
        error('EPUB TikZ rendering requires pdftoppm (Poppler):\n' .. tostring(result))
      end
      local image = assert(io.open('drawing.png', 'rb'))
      local data = image:read('*a')
      image:close()
      return data
    end)
  end)
  pandoc.mediabag.insert(name, 'image/png', png)
  -- PNG IHDR width at 144 dpi, expressed in physical points for reading size.
  local width = string.unpack('>I4', png, 17) / 2
  -- raw_tex keeps the caption's number marker (\mdtexpdflabel) for the label pass
  local caption_inlines = caption and pandoc.utils.blocks_to_inlines(pandoc.read(caption, 'latex+raw_tex').blocks) or {}
  -- Alt text: the figure's description when it has one (only the first drawing of a
  -- figure takes it), else the caption as plain text
  local alt = ''
  if pending_description then
    alt = plain_text(pandoc.read(pending_description, 'markdown').blocks)
    pending_description = nil
  elseif caption then
    alt = plain_text(pandoc.read(caption, 'latex').blocks)
  end
  local artwork = pandoc.Image(alt ~= '' and {pandoc.Str(alt)} or {}, name, '', pandoc.Attr('', {}, {
    style = string.format('width:%.1fpt;max-width:85%%;height:auto;', width)
  }))
  local blocks = {pandoc.Plain({artwork})}
  if caption then blocks[#blocks + 1] = pandoc.Para(caption_inlines) end
  -- Empty alt text is intentional for uncaptioned, decorative artwork.
  return pandoc.Div(blocks, pandoc.Attr(identifier, {'mdtexpdf-artwork'}, {
    style = 'text-align:center;padding-top:36pt;padding-bottom:36pt;break-inside:avoid;page-break-inside:avoid;'
  }))
end

-- Raw TeX that only shapes the printed page (breaks, penalties, spacing, grouping) has
-- nothing to show in an EPUB. It is removed wherever it stands, so a block made of it
-- alone disappears and a block that also holds content keeps only the content.
local LAYOUT_ONLY = {
  '\\par\\penalty%-?%d+\\begingroup.-\\endgroup',          -- "keep N lines together" blocks
  '\\begingroup\\postdisplaypenalty=%d+%s*\\csname @beginparpenalty\\endcsname=%d+',
  '\\begingroup', '\\endgroup',
  '\\newpage', '\\clearpage', '\\cleardoublepage', '\\pagebreak%s*%b[]', '\\pagebreak',
  '\\nopagebreak%s*%b[]', '\\nopagebreak', '\\enlargethispage%*?%s*%b{}', '\\FloatBarrier',
  '\\needspace%s*%b{}', '\\setcounter%s*%b{}%s*%b{}', '\\vspace%*?%s*%b{}', '\\medskip', '\\bigskip', '\\smallskip',
  '\\noindent', '\\par%f[^%a]', '\\penalty%-?%d+', '\\hfill', '\\vfill', '\\null',
}

local function strip_page_layout(text)
  for _, pattern in ipairs(LAYOUT_ONLY) do text = text:gsub(pattern, ' ') end
  return text
end

-- Raw TeX blocks the EPUB could not show, reported once the book is converted
local dropped = {}

-- Letters left once commands, dimensions and numbers are taken out
local function has_visible_text(text)
  local rest = text:gsub('\\begin%s*%b{}', ' '):gsub('\\end%s*%b{}', ' '):gsub('\\%a+%*?', ' ')
    :gsub('%-?%d*%.?%d+%s*[pectimbs][tmxnp]%f[^%a]', ' ')
  return rest:find('[%a\128-\255]') ~= nil
end

-- A table as pandoc's LaTeX reader understands it: column types defined for print
-- (R{w}, >{..}, @{..}), print spacing (\\[11pt], \noalign, \arraystretch) and sizes
-- removed; a negative row space after a rule is a print adjustment, not a row.
local function readable_table_tex(text)
  text = text:gsub('\\newcolumntype%s*%b{}%s*%b[]%s*%b{}', ''):gsub('\\newcolumntype%s*%b{}%s*%b{}', '')
    :gsub('\\renewcommand%s*{\\arraystretch}%s*%b{}', '')
    :gsub('\\setlength%s*{\\tabcolsep}%s*%b{}', '')
    :gsub('\\noalign%s*%b{}', '')
    :gsub('\\\\%s*%[%-[%d.]+%a%a%]', '')
    :gsub('\\\\%s*%[[%d.]+%a%a%]', '\\\\')
    :gsub('\\(%a+size)%f[^%a]', ''):gsub('\\small%f[^%a]', ''):gsub('\\large%f[^%a]', '')
    :gsub('\\Large%f[^%a]', ''):gsub('\\LARGE%f[^%a]', ''):gsub('\\huge%f[^%a]', ''):gsub('\\Huge%f[^%a]', '')
    :gsub('\\centering%f[^%a]', ''):gsub('\\raggedright%f[^%a]', '')
    :gsub('\\begin{(%a+%*?)}%s*%[[htbpH!]+%]', '\\begin{%1}')
    :gsub('\\captionof%s*%b{}', '\\caption')
  -- the column specification of every tabular
  text = text:gsub('(\\begin{tabular%*?})(%s*)(%b{})', function(open, space, spec)
    spec = spec:sub(2, -2)
      :gsub('[><@!]%s*%b{}', '')
      :gsub('[RPLCMmb]%s*(%b{})', 'p%1')
      :gsub('|', '')
    return open .. space .. '{' .. spec .. '}'
  end)
  return text
end

local function read_tex(text)
  return pandoc.read(text, 'latex+raw_tex').blocks
end

-- The inner text of a \parbox, set italic when it opens with \itshape
local function readable_center_tex(text)
  return text:gsub('\\parbox%s*%b[]%s*(%b{})%s*(%b{})', function(_, body) return body end)
    :gsub('\\parbox%s*(%b{})%s*(%b{})', function(_, body) return body end)
end

local function centered(blocks)
  return pandoc.Div(blocks, pandoc.Attr('', {'center'}, {style = 'text-align:center;'}))
end

-- A wide equation fitted to the text width for print:
--   \[\sbox0{$\displaystyle X$}% \ifdim\wd0>\linewidth\resizebox{..}{!}{\usebox0}\else\usebox0\fi \tag{L} \]
-- The EPUB takes X, and the tag written after the box, as one display equation.
local function fitted_equation(text)
  local body, rest = text:match('^%s*\\%[%s*\\sbox0%s*{%$\\displaystyle(.-)%$}%%?(.-)\\%]%s*$')
  if not body then return nil end
  local tagged = rest:match('(\\tag%*?%s*%b{})')
  if tagged then body = body .. ' ' .. tagged end
  return pandoc.Para({pandoc.Math('DisplayMath', body)})
end

-- \[ ... \] written as raw TeX
local function bracket_equation(text)
  local body = text:match('^%s*\\%[(.-)\\%]%s*$')
  if body and not body:find('\\sbox', 1, true) then
    return pandoc.Para({pandoc.Math('DisplayMath', body)})
  end
end

local function finish(blocks)
  return pandoc.Blocks(blocks):walk({RawBlock = convert_raw, RawInline = convert_raw_inline})
end

local function convert_with_reader(text)
  local ok, blocks = pcall(read_tex, text)
  if not ok then return nil end
  local shown = pandoc.write(pandoc.Pandoc(blocks), 'plain')
  if shown:match('%S') then return blocks end
end

convert_raw = function(block)
  if block.format ~= 'tex' and block.format ~= 'latex' then return nil end
  local text = block.text
  if text:find('\\begin{minipage}', 1, true) or text:find('\\begin{samepage}', 1, true) then
    local unwrapped, changed = strip_layout(text)
    if not changed then
      error('EPUB cannot unwrap this minipage; expected a width argument')
    end
    local content = pandoc.read(unwrapped, 'markdown')
    return content:walk({RawBlock = convert_raw, RawInline = convert_raw_inline}).blocks
  end
  if text:find('\\begin{tikzpicture}', 1, true) then
    return render_artwork(text)
  end
  text = strip_page_layout(text)
  if not text:match('%S') then return {} end
  local equation = fitted_equation(text) or bracket_equation(text)
  if equation then return equation end
  if text:find('\\begin{tabular', 1, true) then
    local ok, blocks = pcall(read_tex, readable_table_tex(text))
    if ok and #blocks > 0 then return finish(blocks) end
  end
  if text:match('^%s*\\begin{center}') then
    local ok, blocks = pcall(read_tex, readable_center_tex(text))
    if ok and #blocks > 0 then
      -- the reader already gives a center Div; make it centre in e-readers too
      return finish(pandoc.Blocks(blocks):walk({Div = function(div)
        if div.classes:includes('center') then return centered(div.content) end
      end}))
    end
  end
  if not has_visible_text(text) then return {} end
  local blocks = convert_with_reader(text)
  if blocks then return finish(blocks) end
  dropped[#dropped + 1] = text
  return {}
end

-- Raw TeX inside a paragraph: print layout goes, anything with text is read as LaTeX
convert_raw_inline = function(inline)
  if inline.format ~= 'tex' and inline.format ~= 'latex' then return nil end
  if inline.text:match('^\\mdtexpdflabel') then return nil end
  local text = strip_page_layout(inline.text)
  if not text:match('%S') or not has_visible_text(text) then return {} end
  local blocks = convert_with_reader(text)
  if blocks then return pandoc.utils.blocks_to_inlines(blocks) end
  dropped[#dropped + 1] = inline.text
  return {}
end

-- ---------------------------------------------------------------------------
-- Numbering, as the PDF numbers: equations when equation_numbers is set, figures
-- unless no_figure_numbers is set, tables always. In a book each counter restarts
-- at every "Chapter N:" and "Appendix X:" heading (the headings book_structure.lua
-- makes \chapter) and a number reads chapter.n; elsewhere it reads n. Only what the
-- PDF numbers is numbered: Markdown display maths (equation_number_filter.lua),
-- \caption and \captionof in raw figures and tables, captioned images and tables.
-- This runs before any raw TeX is converted, so maths recovered from print layout
-- is never numbered. Equation numbers travel as \tag{..}; caption numbers as
-- \mdtexpdflabel{..} at the head of the caption.
-- ---------------------------------------------------------------------------
local function flag(meta, name)
  return meta[name] ~= nil and pandoc.utils.stringify(meta[name]) == 'true'
end

local function number_document(doc)
  local number_equations = flag(doc.meta, 'equation_numbers')
  local number_figures = not flag(doc.meta, 'no_figure_numbers')
  local book = doc.meta['mdtexpdf-format'] and pandoc.utils.stringify(doc.meta['mdtexpdf-format']) == 'book'
  local chapter = book and '0' or nil
  local counters = {equation = 0, figure = 0, table = 0}

  local function next_label(kind)
    counters[kind] = counters[kind] + 1
    return chapter and (chapter .. '.' .. counters[kind]) or tostring(counters[kind])
  end
  local function marker(kind)
    local name = kind == 'figure' and 'Figure' or 'Table'
    return pandoc.RawInline('latex', '\\mdtexpdflabel{' .. name .. ' ' .. next_label(kind) .. '}')
  end
  local function label_caption(caption, kind)
    local first = caption.long[1]
    if first and (first.t == 'Plain' or first.t == 'Para') then
      first.content:insert(1, marker(kind))
    else
      caption.long:insert(1, pandoc.Plain({marker(kind)}))
    end
    return caption
  end

  -- \caption / \captionof in raw TeX, in order, each stepping the counter of its
  -- figure or table environment
  local function label_raw(text)
    local out, position, stack = {}, 1, {}
    while true do
      local s, e, command = text:find('\\(%a+)', position)
      if not s then break end
      out[#out + 1] = text:sub(position, e)
      position = e + 1
      if command == 'begin' or command == 'end' then
        local environment = text:match('^%s*{(%a+)%*?}', position)
        if environment == 'figure' or environment == 'table' then
          if command == 'begin' then stack[#stack + 1] = environment else stack[#stack] = nil end
        end
      elseif command == 'caption' or command == 'captionof' then
        local starred = text:sub(position, position) == '*'
        local kind = stack[#stack]
        local head = ''
        if command == 'captionof' then
          head = text:match('^%*?%s*%b{}', position) or ''
          kind = head:match('{(%a+)}')
        else
          head = text:match('^%*?', position)
        end
        local optional = text:match('^%s*%b[]', position + #head) or ''
        local brace = position + #head + #optional
        local opens = text:match('^%s*{', brace)
        if not starred and opens and (kind == 'table' or (kind == 'figure' and number_figures)) then
          local name = kind == 'figure' and 'Figure' or 'Table'
          out[#out + 1] = text:sub(position, brace + #opens - 1)
            .. '\\mdtexpdflabel{' .. name .. ' ' .. next_label(kind) .. '}'
          position = brace + #opens
        end
      end
    end
    out[#out + 1] = text:sub(position)
    return table.concat(out)
  end

  doc.blocks = doc.blocks:walk({
    traverse = 'topdown',
    Header = function(header)
      local text = pandoc.utils.stringify(header.content)
      local number = text:match('^[Cc]hapter (%d+):') or text:match('^[Aa]ppendix ([A-Z]):')
      if book and number then
        chapter = number
        counters = {equation = 0, figure = 0, table = 0}
      end
    end,
    Math = function(math)
      if not number_equations or math.mathtype ~= 'DisplayMath' then return nil end
      if math.text:find('\\tag', 1, true) or math.text:find('\\notag', 1, true)
          or math.text:find('\\nonumber', 1, true) then
        return nil
      end
      math.text = math.text .. ' \\tag{' .. next_label('equation') .. '}'
      return math
    end,
    RawBlock = function(raw)
      if raw.format ~= 'tex' and raw.format ~= 'latex' then return nil end
      if not raw.text:find('\\caption', 1, true) then return nil end
      raw.text = label_raw(raw.text)
      return raw
    end,
    Figure = function(figure)
      if number_figures and #figure.caption.long > 0 then
        figure.caption = label_caption(figure.caption, 'figure')
        return figure
      end
    end,
    Table = function(tbl)
      if #tbl.caption.long > 0 then
        tbl.caption = label_caption(tbl.caption, 'table')
        return tbl
      end
    end,
  })
  return doc
end

-- The caption number marker becomes the label a reader sees: "Figure 2.1: "
local function caption_label(raw)
  if raw.format ~= 'tex' and raw.format ~= 'latex' then return nil end
  local label = raw.text:match('^\\mdtexpdflabel{(.-)}$')
  if label then
    return {pandoc.Span({pandoc.Str(label .. ':')}, pandoc.Attr('', {'caption-label'})), pandoc.Space()}
  end
end

-- ---------------------------------------------------------------------------
-- Formulas. Each one is first converted exactly as written; only one that pandoc
-- cannot convert to MathML is repaired, one rule at a time, and every repair is
-- listed. A formula no rule repairs stops the build. Display maths is set in a
-- block of its own that scrolls sideways when it is wider than the page, with its
-- number beside it.
-- ---------------------------------------------------------------------------
local converts_cache = {}
local repairs, unrepaired = {}, {}

local function converts(text, mathtype)
  local key = mathtype .. '\0' .. text
  if converts_cache[key] == nil then
    local html = pandoc.write(pandoc.Pandoc({pandoc.Plain({pandoc.Math(mathtype, text)})}), 'html',
      {html_math_method = 'mathml'})
    converts_cache[key] = html:find('<math', 1, true) ~= nil
  end
  return converts_cache[key]
end

local REPAIRS = {
  {'\\mathbbm is not supported: \\mathbb', function(text)
    return (text:gsub('\\mathbbm%s*(%b{})', '\\mathbb%1'))
  end},
  {'quotation marks inside maths set as text', function(text)
    -- only a matched pair: `` .. '' or " .. ", never a prime (x'')
    local out = text:gsub('``(.-)\'\'', '\\text{“}%1\\text{”}')
    out = out:gsub('``(.-)"', '\\text{“}%1\\text{”}')
    out = out:gsub('"(.-)"', '\\text{“}%1\\text{”}')
    return out
  end},
}

local function repaired(text, mathtype)
  if converts(text, mathtype) then return text end
  local current = text
  for _, rule in ipairs(REPAIRS) do
    local changed = rule[2](current)
    if changed ~= current then
      current = changed
      if converts(current, mathtype) then
        repairs[#repairs + 1] = rule[1] .. ': ' .. text:gsub('%s+', ' '):sub(1, 80)
        return current
      end
    end
  end
  unrepaired[#unrepaired + 1] = text:gsub('%s+', ' '):sub(1, 80)
  return text
end

local used_labels = {}

-- A rough count of the characters a formula shows, to find inline formulas that
-- may be wider than a phone screen
local function shown_length(text)
  return #(text:gsub('\\%a+', '#'):gsub('[%s{}^_&\\]', ''):gsub('[\128-\191]', ''))
end

local function present_math(math)
  if math.mathtype ~= 'DisplayMath' then
    local text = repaired(math.text, 'InlineMath')
    local changed = text ~= math.text
    math.text = text
    -- a formula cannot wrap: a long one scrolls sideways on a narrow screen
    -- rather than running off the page
    if shown_length(text) > 16 then
      return pandoc.Span({math}, pandoc.Attr('', {'math-inline-wide'}, {
        style = 'display:inline-block;max-width:100%;overflow-x:auto;overflow-y:hidden;vertical-align:middle;padding:0 0.1em;'
      }))
    end
    return changed and math or nil
  end
  local text, label, starred = math.text, nil, false
  text = text:gsub('\\tag(%*?)%s*(%b{})', function(star, value)
    label, starred = value:sub(2, -2), star == '*'
    return ''
  end):gsub('\\notag%f[^%a]', ''):gsub('\\nonumber%f[^%a]', '')
  text = repaired(text, 'DisplayMath')
  -- centred by auto margins, which never push a formula wider than the screen
  -- off its left edge: it starts at the left and scrolls
  local centred = pandoc.Span({pandoc.Math('DisplayMath', text)}, pandoc.Attr('', {}, {
    style = 'flex:none;margin:0 auto;'
  }))
  local formula = pandoc.Span({centred}, pandoc.Attr('', {}, {
    -- side padding keeps a glyph's overhang (an integral sign, a large bracket) inside
    style = 'display:flex;flex:1 1 auto;min-width:0;overflow-x:auto;overflow-y:hidden;padding:0.4em 0.25em;'
  }))
  local parts = {formula}
  if label then
    local shown = starred and label or ('(' .. label .. ')')
    local identifier = ''
    if not used_labels[label] and label:match('^[%w.-]+$') then
      used_labels[label] = true
      identifier = 'eq-' .. label
    end
    parts[#parts + 1] = pandoc.Span({pandoc.Str(shown)}, pandoc.Attr(identifier, {'eqno'}, {
      style = 'flex:none;padding-left:0.8em;'
    }))
  end
  return pandoc.Span(parts, pandoc.Attr('', {'math', 'display'}, {
    style = 'display:flex;align-items:center;max-width:100%;margin:0.2em 0;'
  }))
end

-- An image's alt text is read aloud or shown in place of the picture, where maths
-- cannot be typeset: alt text holding maths or raw TeX becomes plain text (θ, x², 1/2)
local function plain_alt(image)
  local needs = false
  image.caption:walk({Math = function() needs = true end, RawInline = function() needs = true end})
  if not needs then return nil end
  image.caption = {pandoc.Str(plain_text({pandoc.Plain(image.caption)}))}
  return image
end

-- A reader may break the line after an inline formula (MathJax sets each one in a
-- box), which would start the next line with the comma or full stop that follows
-- it: that punctuation joins the formula in a span that does not break
local function keep_punctuation(inlines)
  local changed = false
  for i = #inlines - 1, 1, -1 do
    local here, after = inlines[i], inlines[i + 1]
    local formula = (here.t == 'Math' and here.mathtype == 'InlineMath')
      or (here.t == 'Span' and here.classes:includes('math-inline-wide'))
    if formula and after.t == 'Str' then
      local mark, rest = after.text:match('^([%.,;:!%?%)%]]+)(.*)$')
      if not mark then
        mark, rest = after.text:match('^(\226\128[\153\157]+)(.*)$')    -- ’ ”
      end
      if mark then
        inlines[i] = pandoc.Span({here, pandoc.Str(mark)}, pandoc.Attr('', {}, {style = 'white-space:nowrap;'}))
        if rest == '' then inlines:remove(i + 1) else after.text = rest end
        changed = true
      end
    end
  end
  return changed and inlines or nil
end

local function report_conversions()
  for _, text in ipairs(dropped) do
    io.stderr:write('[mdtexpdf] EPUB: raw LaTeX with text could not be converted and is left out: '
      .. text:gsub('%s+', ' '):sub(1, 120) .. '\n')
  end
  if #repairs > 0 then
    io.stderr:write(string.format('[mdtexpdf] EPUB: %d formula(s) pandoc could not convert as written were repaired:\n', #repairs))
    for _, line in ipairs(repairs) do io.stderr:write('  ' .. line .. '\n') end
  end
  if #unrepaired > 0 then
    error(string.format('EPUB: %d formula(s) cannot be converted to MathML:\n  %s', #unrepaired,
      table.concat(unrepaired, '\n  ')))
  end
end

-- A drawing or an image followed by its description: render the drawing with the
-- description as alt text (or set it on the image), and drop the comment
local function describe_figures(blocks)
  local out, i = pandoc.List(), 1
  while i <= #blocks do
    local block, text = blocks[i], description_of(blocks[i + 1])
    local drawing = text and block.t == 'RawBlock' and (block.format == 'tex' or block.format == 'latex')
      and block.text:find('\\begin{tikzpicture}', 1, true)
    local images = 0
    if text and not drawing and block.t ~= 'RawBlock' then
      block:walk({Image = function() images = images + 1 end})
    end
    if drawing then
      pending_description = text
      local result = convert_raw(block)
      pending_description = nil
      if result == nil then out:insert(block)
      elseif result.t then out:insert(result)
      else out:extend(result) end
      i = i + 2
    elseif images == 1 then
      local alt = plain_text(pandoc.read(text, 'markdown').blocks)
      out:insert(block:walk({Image = function(image)
        image.caption = {pandoc.Str(alt)}
        return image
      end}))
      i = i + 2
    else
      out:insert(block)
      i = i + 1
    end
  end
  return out
end

-- Text set in a size of its own ([text]{size="28pt"}, a title page): HTML has
-- no size attribute on a span, so the size becomes CSS, relative to the
-- 12pt body text the PDF is set in
local function sized_span(el)
  local value = el.attributes.size and el.attributes.size:match('^([%d.]+)pt$')
  if not value then return nil end
  el.attributes.size = nil
  el.attributes.style = string.format('font-size: %.2fem', tonumber(value) / 12)
  return el
end

function Pandoc(doc)
  if not FORMAT:match('epub') then return nil end
  local headers = doc.meta['header-includes']
  if headers then
    -- Pandoc retains raw TeX in metadata; writing it as LaTeX preserves macros.
    if pandoc.utils.type(headers) ~= 'List' then headers = {headers} end
    for _, header in ipairs(headers) do
      local blocks = pandoc.utils.type(header) == 'Blocks' and header or {pandoc.Plain(header)}
      preamble = preamble .. pandoc.write(pandoc.Pandoc(blocks), 'latex') .. '\n'
    end
  end
  -- Colours defined in one raw block stay defined for later ones in the PDF; each EPUB
  -- drawing compiles alone, so give every drawing all the colour definitions (first wins,
  -- and a drawing's own definitions still come after the preamble).
  local seen, colours = {}, {}
  local function collect(raw)
    if raw.format ~= 'tex' and raw.format ~= 'latex' then return nil end
    for name, model, spec in raw.text:gmatch('\\definecolor%s*(%b{})%s*(%b{})%s*(%b{})') do
      if not seen[name] then
        seen[name] = true
        colours[#colours + 1] = '\\definecolor' .. name .. model .. spec
      end
    end
    for name, spec in raw.text:gmatch('\\colorlet%s*(%b{})%s*(%b{})') do
      if not seen[name] then
        seen[name] = true
        colours[#colours + 1] = '\\colorlet' .. name .. spec
      end
    end
  end
  doc:walk({RawBlock = collect, RawInline = collect})
  if #colours > 0 then preamble = preamble .. table.concat(colours, '\n') .. '\n' end
  doc = number_document(doc)
  doc = doc:walk({Blocks = describe_figures})
  doc.blocks = doc.blocks:walk({RawBlock = convert_raw, RawInline = convert_raw_inline})
  doc = doc:walk({Span = sized_span})
  doc.blocks = doc.blocks:walk({Math = present_math})
  doc.blocks = doc.blocks:walk({Inlines = keep_punctuation})
  doc.blocks = doc.blocks:walk({RawInline = caption_label})
  doc.blocks = doc.blocks:walk({Image = plain_alt})
  report_conversions()
  return doc
end
