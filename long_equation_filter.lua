-- long_equation_filter.lua
-- Purpose: Improve line breaking for long display equations in LaTeX output
-- Requires: breqn package (dmath environment) loaded in the LaTeX template

local is_latex = FORMAT:match('latex') ~= nil

-- Function to detect equations that need line breaking after commas
local function needs_comma_breaking(math_text)
  if not math_text then return false end
  
  -- Look for equations with commas that define multiple variables/expressions
  -- Pattern: variable = expression, variable = expression
  if math_text:find('%w+%s*=%s*.-,%s*%w+%s*=') then return true end
  
  -- Pattern: expressions separated by commas (like v1 = ..., v2 = ...)
  if math_text:find('=%s*.-,%s*%w+.*=') then return true end
  
  return false
end

-- Function to detect extremely long equations that overflow
local function is_overflowing_equation(math_text)
  if not math_text then return false end
  
  local length = string.len(math_text)
  
  -- Very long equations that likely overflow
  if length > 150 then return true end
  
  -- Multiple matrices with operators (the specific problematic case)
  if math_text:find('\\begin{pmatrix}.*\\circ.*\\begin{pmatrix}') then return true end
  
  return false
end

-- Function to break equations at commas
local function break_at_commas(math_text)
  -- Convert comma-separated variable definitions to align environment
  -- Example: v_1 = (...), v_2 = (...) becomes:
  -- \begin{align*}
  -- v_1 &= (...),\\
  -- v_2 &= (...)
  -- \end{align*}
  
  -- Split on commas but preserve the math structure
  local parts = {}
  local current_part = ""
  local in_parens = 0
  local in_braces = 0
  
  local i = 1
  while i <= #math_text do
    local char = math_text:sub(i, i)

    if char == '(' then
      in_parens = in_parens + 1
      current_part = current_part .. char
    elseif char == ')' then
      in_parens = in_parens - 1
      current_part = current_part .. char
    elseif char == '{' then
      in_braces = in_braces + 1
      current_part = current_part .. char
    elseif char == '}' then
      in_braces = in_braces - 1
      current_part = current_part .. char
    elseif char == ',' and in_parens == 0 and in_braces == 0 then
      -- Found a comma at top level - this is where we can break
      table.insert(parts, current_part .. ',')
      current_part = ""
      -- Skip whitespace after comma
      i = i + 1
      while i <= #math_text and math_text:sub(i, i):match('%s') do
        i = i + 1
      end
      -- Don't increment i again since we already did
      goto continue
    else
      current_part = current_part .. char
    end
    i = i + 1
    ::continue::
  end
  
  -- Add the last part
  if current_part ~= "" then
    table.insert(parts, current_part)
  end
  
  -- If we successfully split, create align environment
  if #parts > 1 then
    local result = "\\begin{align*}\n"
    for i, part in ipairs(parts) do
      -- Add alignment marker before equals sign
      local aligned_part = part:gsub('(%w+)%s*=', '%1 &=')
      result = result .. aligned_part
      if i < #parts then
        result = result .. "\\\\\n"
      else
        result = result .. "\n"
      end
    end
    result = result .. "\\end{align*}"
    return result
  end
  
  -- If splitting failed, return original
  return math_text
end

-- Function to handle overflowing equations
local function handle_overflow(math_text)
  -- Use dmath* for automatic breaking of very long equations
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
      
      -- First priority: Fix comma-separated variable definitions
      if needs_comma_breaking(math_text) then
        local tex = break_at_commas(math_text)
        return pandoc.RawBlock('latex', tex)
      end
      
      -- Second priority: Handle equations that overflow the page
      if is_overflowing_equation(math_text) then
        local tex = handle_overflow(math_text)
        return pandoc.RawBlock('latex', tex)
      end
    end
  end
  return nil
end
