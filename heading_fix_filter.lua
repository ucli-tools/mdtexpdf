-- heading_fix_filter.lua
-- Purpose: Ensure level-4 and level-5 headings break onto a new line in LaTeX output
-- Approach: For LaTeX, remap Header levels >= 4 to level 3 (\\subsubsection)
-- This maintains structure while avoiding inline paragraph-style headings.

local is_latex = FORMAT:match('latex') ~= nil

function Header(el)
  if not is_latex then
    return nil
  end
  if el.level >= 4 then
    el.level = 3
    return el
  end
  return nil
end
