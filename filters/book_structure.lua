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
      return pandoc.RawBlock('latex', '\\clearpage\\part{' .. part_title .. '}')
    end

    -- Check for "Chapter X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Cc]hapter %d+:') then
      -- Keep the full title including chapter number for proper formatting
      return pandoc.RawBlock('latex', '\\chapter{' .. header_text .. '}')
    end
  
    return el
  end
