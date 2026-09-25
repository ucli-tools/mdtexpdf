-- fit_wide_equations_filter.lua
-- Purpose: Shrink a display equation to the text width when, and only when,
-- it is wider than the text block. TeX measures each display in a box; one
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

function Math(el)
  if el.mathtype ~= 'DisplayMath' then
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
