-- fit_wide_equations_filter.lua
-- Purpose: Shrink a display equation to the text width when, and only when,
-- it is wider than the text block, and let a long inline formula break
-- after a top-level comma. TeX measures each display in a box; one
-- that fits is set at its natural size.
-- Enabled by the metadata field fit_wide_equations: true (see docs/METADATA.md).

if not FORMAT:match('latex') then
  return {}
end

-- Environments that cannot sit inside a box of inline math
local UNBOXABLE = {
  'align', 'equation', 'gather', 'multline', 'flalign', 'alignat', 'eqnarray',
}

-- True when the display breaks lines with \\ outside any environment
local function has_top_level_break(text)
  local depth, i, n = 0, 1, #text
  while i <= n do
    if text:sub(i, i + 6) == '\\begin{' then
      depth = depth + 1
      i = i + 7
    elseif text:sub(i, i + 4) == '\\end{' then
      depth = depth - 1
      i = i + 5
    elseif text:sub(i, i + 1) == '\\\\' then
      if depth == 0 then
        return true
      end
      i = i + 2
    elseif text:sub(i, i) == '\\' then
      i = i + 2
    else
      i = i + 1
    end
  end
  return false
end

local function boxable(text)
  if text:find('\\label', 1, true) or text:find('\\intertext', 1, true) then
    return false
  end
  for _, env in ipairs(UNBOXABLE) do
    if text:find('\\begin{' .. env, 1, true) then
      return false
    end
  end
  return not has_top_level_break(text)
end

-- A long inline formula may break after a top-level comma, as a list of
-- items is broken by hand; TeX breaks math only after relations and binary
-- operators, so a formula such as A{...}, C{...} would otherwise run into
-- the margin
local INLINE_BREAK_MIN = 60

local function allow_comma_breaks(text)
  local out, depth, lr, i, n = {}, 0, 0, 1, #text
  while i <= n do
    local c = text:sub(i, i)
    if c == '\\' then
      local cmd = text:match('^\\%a+', i)
      if cmd then
        if cmd == '\\left' then lr = lr + 1 elseif cmd == '\\right' then lr = lr - 1 end
        table.insert(out, cmd)
        i = i + #cmd
      else
        table.insert(out, text:sub(i, i + 1))
        i = i + 2
      end
    else
      if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
      table.insert(out, c)
      if c == ',' and depth == 0 and lr == 0 then
        table.insert(out, '\\allowbreak ')
      end
      i = i + 1
    end
  end
  return table.concat(out)
end

function Math(el)
  if el.mathtype == 'InlineMath' then
    if #el.text >= INLINE_BREAK_MIN then
      el.text = allow_comma_breaks(el.text)
      return el
    end
    return nil
  end
  local body = el.text
  if not boxable(body) then
    return nil
  end

  -- A \tag cannot live inside the box: set it after, at display level
  local tag = ''
  local _, tag_count = body:gsub('\\tag%*?{', '')
  if tag_count > 1 then
    return nil
  elseif tag_count == 1 then
    local s, e, star, number = body:find('\\tag(%*?){([^{}]*)}')
    if not s then
      return nil
    end
    tag = '\\tag' .. star .. '{' .. number .. '}'
    body = body:sub(1, s - 1) .. body:sub(e + 1)
  end

  -- Leave room for the equation number, and amsmath's gap before it, so
  -- the number stays on the equation's line
  local width = tag == '' and '\\linewidth' or '\\dimexpr\\linewidth-6em\\relax'

  return pandoc.RawInline('latex',
    '\\[\\sbox0{$\\displaystyle ' .. body .. '$}' ..
    '\\ifdim\\wd0>' .. width ..
    '\\resizebox{' .. width .. '}{!}{\\usebox0}\\else\\usebox0\\fi' ..
    (tag ~= '' and ' ' .. tag or '') .. '\\]')
end
