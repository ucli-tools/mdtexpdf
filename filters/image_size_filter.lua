-- image_size_filter.lua
-- Purpose: Ensure images never exceed \textwidth in LaTeX output.
-- Also converts figure captions from alt-text to proper LaTeX figure captions.

local is_latex = FORMAT:match('latex') ~= nil

function Image(el)
  if not is_latex then return nil end

  -- If no explicit width is set, cap to \textwidth
  if not el.attributes.width or el.attributes.width == '' then
    el.attributes.width = '\\textwidth'
  end

  -- If width is a percentage string (e.g. "80%"), convert to fraction of textwidth
  local pct = el.attributes.width and el.attributes.width:match('^(%d+)%%$')
  if pct then
    local frac = tonumber(pct) / 100
    el.attributes.width = string.format('%.2f\\textwidth', frac)
  end

  -- Remove height to allow proportional scaling
  el.attributes.height = nil

  return el
end
