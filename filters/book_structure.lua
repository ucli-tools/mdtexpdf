-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.

-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.

function Header(el)
    local header_text = pandoc.utils.stringify(el.content)

    -- Debug: print what we're processing
    -- print("Processing header: " .. header_text)

    -- Check for "Part X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Pp]art %d+:') then
      local part_title = string.gsub(header_text, '^[Pp]art %d+: *', '')
      -- Use \newpage to ensure parts start on a new page
      return pandoc.RawBlock('latex', '\\clearpage\\part{' .. part_title .. '}')
    end

    -- Check for "Chapter X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Cc]hapter %d+:') then
      local chapter_title = string.gsub(header_text, '^[Cc]hapter %d+: *', '')
      -- The \chapter command in the 'book' class already starts a new page
      return pandoc.RawBlock('latex', '\\chapter{' .. chapter_title .. '}')
    end

    return el
  end
