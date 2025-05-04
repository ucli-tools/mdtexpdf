-- long_equation_filter.lua
-- A Pandoc Lua filter to handle long text-heavy equations

function Math(elem)
  -- Only process display math (elem.mathtype == "DisplayMath")
  if elem.mathtype == "DisplayMath" then
    -- Check if this is a text-heavy equation (contains multiple \text commands)
    if elem.text:match("\\text.*\\text") then
      -- Insert line breaks after certain patterns to help with wrapping
      local modified_text = elem.text
      
      -- Add line breaks after certain patterns
      modified_text = modified_text:gsub("\\text{ and }", "\\text{ and } \\\\ ")
      modified_text = modified_text:gsub("\\text{ then }", "\\text{ then } \\\\ ")
      modified_text = modified_text:gsub("\\text{ such that }", "\\text{ such that } \\\\ ")
      modified_text = modified_text:gsub("\\text{ for all }", "\\text{ for all } \\\\ ")
      modified_text = modified_text:gsub("\\text{ for some }", "\\text{ for some } \\\\ ")
      modified_text = modified_text:gsub("\\text{%)}%,", "\\text{)}, \\\\ ")
      
      -- Use the gather* environment for centered equations
      return pandoc.RawInline("latex", "\\begin{gather*}" .. modified_text .. "\\end{gather*}")
    end
  end
  return elem
end