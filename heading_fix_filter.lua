-- heading_fix_filter.lua
-- A Pandoc Lua filter to fix paragraph and subparagraph headings

function Header(elem)
  -- Check if this is a level 4 or 5 heading (#### or #####)
  if elem.level == 4 or elem.level == 5 then
    -- Process the heading content to handle math properly
    local heading_parts = {}
    
    for _, inline in ipairs(elem.content) do
      if inline.t == "Math" then
        -- Keep math in math mode
        if inline.mathtype == "InlineMath" then
          table.insert(heading_parts, "$" .. inline.text .. "$")
        else
          table.insert(heading_parts, "$$" .. inline.text .. "$$")
        end
      else
        -- Convert other content to string
        table.insert(heading_parts, pandoc.utils.stringify(inline))
      end
    end
    
    local heading_text = table.concat(heading_parts)
    local latex_cmd
    
    if elem.level == 4 then
      -- Level 4 headings: italic and normal size for better hierarchy
      latex_cmd = "\\par\\vspace{1.5ex}\\noindent{\\normalsize\\textit{" .. heading_text .. "}}\\\\[0.5ex]\\noindent"
    else -- level 5
      -- Level 5 headings: smaller italic for even deeper hierarchy
      latex_cmd = "\\par\\vspace{1ex}\\noindent{\\small\\textit{" .. heading_text .. "}}\\\\[0.3ex]\\noindent"
    end
    
    return pandoc.RawBlock("latex", latex_cmd)
  end
  
  -- Return unchanged for other heading levels
  return elem
end