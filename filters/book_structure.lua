-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.
-- Enhanced version with support for Preface, Appendices, Introduction, etc.

function Header(el)
    local header_text = pandoc.utils.stringify(el.content)

    -- Debug: print what we're processing
    -- print("Processing header: " .. header_text)

    -- ============================================
    -- PART-STYLE PAGES (full page with large title)
    -- ============================================
    
    -- Check for "Part X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Pp]art %d+:') then
      local part_title = string.gsub(header_text, '^[Pp]art %d+: *', '')
      return pandoc.RawBlock('latex', '\\clearpage\\part{' .. part_title .. '}')
    end

    -- Preface → Unnumbered chapter (content introduction, not a major division)
    if string.match(header_text, '^[Pp]reface$') then
      return pandoc.RawBlock('latex', '\\chapter*{Preface}\\addcontentsline{toc}{chapter}{Preface}')
    end

    -- Appendices/Appendix → Part-style page + switch to appendix numbering (A, B, C...)
    if string.match(header_text, '^[Aa]ppendices$') or string.match(header_text, '^[Aa]ppendix$') then
      return pandoc.RawBlock('latex', '\\clearpage\\part*{Appendices}\\appendix')
    end

    -- ============================================
    -- CHAPTER-STYLE PAGES (new page with chapter heading)
    -- ============================================
    
    -- Check for "Chapter X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Cc]hapter %d+:') then
      local chapter_title = string.gsub(header_text, '^[Cc]hapter %d+: *', '')
      return pandoc.RawBlock('latex', '\\chapter{' .. chapter_title .. '}')
    end

    -- Appendix X: Title → Chapter with appendix numbering (A, B, C...)
    -- Works because \appendix was issued above
    if string.match(header_text, '^[Aa]ppendix [A-Z]:') then
      local appendix_title = string.gsub(header_text, '^[Aa]ppendix [A-Z]: *', '')
      return pandoc.RawBlock('latex', '\\chapter{' .. appendix_title .. '}')
    end

    -- ============================================
    -- UNNUMBERED CHAPTER-STYLE PAGES
    -- For special sections that should look like chapters but without numbers
    -- ============================================
    
    -- Introduction → Unnumbered chapter
    if string.match(header_text, '^[Ii]ntroduction$') then
      return pandoc.RawBlock('latex', '\\chapter*{Introduction}\\addcontentsline{toc}{chapter}{Introduction}')
    end

    -- Conclusion → Unnumbered chapter
    if string.match(header_text, '^[Cc]onclusion$') then
      return pandoc.RawBlock('latex', '\\chapter*{Conclusion}\\addcontentsline{toc}{chapter}{Conclusion}')
    end

    -- Glossary → Unnumbered chapter
    if string.match(header_text, '^[Gg]lossary$') then
      return pandoc.RawBlock('latex', '\\chapter*{Glossary}\\addcontentsline{toc}{chapter}{Glossary}')
    end

    -- Bibliography → Unnumbered chapter
    if string.match(header_text, '^[Bb]ibliography$') then
      return pandoc.RawBlock('latex', '\\chapter*{Bibliography}\\addcontentsline{toc}{chapter}{Bibliography}')
    end

    -- References → Unnumbered chapter
    if string.match(header_text, '^[Rr]eferences$') then
      return pandoc.RawBlock('latex', '\\chapter*{References}\\addcontentsline{toc}{chapter}{References}')
    end

    -- Index → Unnumbered chapter
    if string.match(header_text, '^[Ii]ndex$') then
      return pandoc.RawBlock('latex', '\\chapter*{Index}\\addcontentsline{toc}{chapter}{Index}')
    end

    -- Acknowledgments/Acknowledgements → Unnumbered chapter
    if string.match(header_text, '^[Aa]cknowledg[e]?ments?$') then
      return pandoc.RawBlock('latex', '\\chapter*{Acknowledgments}\\addcontentsline{toc}{chapter}{Acknowledgments}')
    end

    -- About the Author → Unnumbered chapter
    if string.match(header_text, '^[Aa]bout [Tt]he [Aa]uthor$') then
      return pandoc.RawBlock('latex', '\\chapter*{About the Author}\\addcontentsline{toc}{chapter}{About the Author}')
    end

    -- Epilogue → Unnumbered chapter
    if string.match(header_text, '^[Ee]pilogue$') then
      return pandoc.RawBlock('latex', '\\chapter*{Epilogue}\\addcontentsline{toc}{chapter}{Epilogue}')
    end

    -- Prologue → Unnumbered chapter
    if string.match(header_text, '^[Pp]rologue$') then
      return pandoc.RawBlock('latex', '\\chapter*{Prologue}\\addcontentsline{toc}{chapter}{Prologue}')
    end

    -- Foreword → Unnumbered chapter
    if string.match(header_text, '^[Ff]oreword$') then
      return pandoc.RawBlock('latex', '\\chapter*{Foreword}\\addcontentsline{toc}{chapter}{Foreword}')
    end

    -- Afterword → Unnumbered chapter
    if string.match(header_text, '^[Aa]fterword$') then
      return pandoc.RawBlock('latex', '\\chapter*{Afterword}\\addcontentsline{toc}{chapter}{Afterword}')
    end

    -- Return unchanged if no pattern matches
    return el
  end
