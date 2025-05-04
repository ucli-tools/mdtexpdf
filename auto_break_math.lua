-- auto_break_math.lua
-- A Pandoc Lua filter to automatically wrap long display math in breqn's dmath environment

function Math(elem)
  -- Only process display math (elem.mathtype == "DisplayMath")
  if elem.mathtype == "DisplayMath" then
    -- Return a raw LaTeX block using our custom command
    return pandoc.RawInline("latex", "\\begin{dmath}" .. elem.text .. "\\end{dmath}")
  end
  return elem
end