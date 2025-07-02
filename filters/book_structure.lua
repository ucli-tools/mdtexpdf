-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.

-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.

function Header(el)
    local header_text = pandoc.utils.stringify(el.content)
  
    -- Check for "Part X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Pp]art %d+:') then
      local part_title = string.gsub(header_text, '^[Pp]art %d+: *', '')
      -- Use \newpage to ensure parts start on a new page
      return pandoc.RawBlock('tex', '\\clearpage\\part{' .. part_title .. '}')
    end
  
    -- Check for "Chapter X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Cc]hapter %d+:') then
      local chapter_title = string.gsub(header_text, '^[Cc]hapter %d+: *', '')
      -- The \chapter command in the 'book' class already starts a new page
      -- Add \par to ensure we're not in the middle of a paragraph
      return pandoc.RawBlock('tex', '\\par\\chapter{' .. chapter_title .. '}')
    end
  
    return el
  end