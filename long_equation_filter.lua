-- long_equation_filter.lua
-- Purpose: Improve line breaking for long display equations in LaTeX output
-- Requires: breqn package (dmath environment) loaded in the LaTeX template

local is_latex = FORMAT:match('latex') ~= nil

-- Function to detect equations that need special handling
local function needs_special_handling(math_text)
  if not math_text then return false end
  
  local length = string.len(math_text)
  
  -- Only target extremely long equations that definitely overflow
  if length > 150 then return true end
  
  -- Multiple matrices with operators (the specific problematic case)
  if math_text:find('\\begin{pmatrix}.*\\circ.*\\begin{pmatrix}') then return true end
  
  return false
end

-- Function to apply safe fixes
local function apply_safe_fixes(math_text)
  -- Use dmath* for automatic breaking - safest approach
  return "\\begin{dmath*}\n" .. math_text .. "\n\\end{dmath*}"
end

-- Replace display math paragraphs with appropriate line-breaking environments
function Para(el)
  if not is_latex then
    return nil
  end
  if #el.content == 1 then
    local m = el.content[1]
    if m.t == 'Math' and m.mathtype == 'DisplayMath' then
      local math_text = m.text or ''
      
      -- Only apply to equations that really need special handling
      if needs_special_handling(math_text) then
        local tex = apply_safe_fixes(math_text)
        return pandoc.RawBlock('latex', tex)
      end
    end
  end
  return nil
end
