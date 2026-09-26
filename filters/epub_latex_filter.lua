-- Preserve print-layout Markdown and render TikZ artwork for EPUB.
-- This filter is deliberately inactive for PDF/LaTeX output.
local preamble = ''
local render_count = 0
local convert_raw

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
  local caption_inlines = caption and pandoc.utils.blocks_to_inlines(pandoc.read(caption, 'latex').blocks) or {}
  local artwork = pandoc.Image(caption_inlines, name, '', pandoc.Attr('', {}, {
    style = string.format('width:%.1fpt;max-width:85%%;height:auto;', width)
  }))
  local blocks = {pandoc.Plain({artwork})}
  if caption then blocks[#blocks + 1] = pandoc.Para(caption_inlines) end
  -- Empty alt text is intentional for uncaptioned, decorative artwork.
  return pandoc.Div(blocks, pandoc.Attr(identifier, {'mdtexpdf-artwork'}, {
    style = 'text-align:center;padding-top:36pt;padding-bottom:36pt;break-inside:avoid;page-break-inside:avoid;'
  }))
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
    return content:walk({RawBlock = convert_raw}).blocks
  end
  if text:find('\\begin{tikzpicture}', 1, true) then
    return render_artwork(text)
  end
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
  return doc:walk({RawBlock = convert_raw, Span = sized_span})
end
