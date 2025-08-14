-- long_equation_filter.lua
-- Purpose: Improve line breaking for long display equations in LaTeX output
-- Requires: breqn package (dmath environment) loaded in the LaTeX template

local is_latex = FORMAT:match('latex') ~= nil

-- Replace display math paragraphs with breqn's dmath* environment
function Para(el)
  if not is_latex then
    return nil
  end
  if #el.content == 1 then
    local m = el.content[1]
    if m.t == 'Math' and m.mathtype == 'DisplayMath' then
      local tex = "\\begin{dmath*}\n" .. (m.text or '') .. "\n\\end{dmath*}"
      return pandoc.RawBlock('latex', tex)
    end
  end
  return nil
end
