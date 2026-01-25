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

    -- Preface → Unnumbered chapter with part-level TOC entry (major front matter section)
    if string.match(header_text, '^[Pp]reface$') then
      return pandoc.RawBlock('latex', '\\chapter*{Preface}\\addcontentsline{toc}{part}{Preface}')
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

    -- ============================================
    -- UNNUMBERED SECTIONS WITH PART-LEVEL TOC ENTRIES
    -- These are major divisions that appear at the same level as Parts in TOC
    -- ============================================

    -- Introduction → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Ii]ntroduction$') then
      return pandoc.RawBlock('latex', '\\chapter*{Introduction}\\addcontentsline{toc}{part}{Introduction}')
    end

    -- Conclusion → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Cc]onclusion$') then
      return pandoc.RawBlock('latex', '\\chapter*{Conclusion}\\addcontentsline{toc}{part}{Conclusion}')
    end

    -- Glossary → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Gg]lossary$') then
      return pandoc.RawBlock('latex', '\\chapter*{Glossary}\\addcontentsline{toc}{part}{Glossary}')
    end

    -- Bibliography → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Bb]ibliography$') then
      return pandoc.RawBlock('latex', '\\chapter*{Bibliography}\\addcontentsline{toc}{part}{Bibliography}')
    end

    -- References → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Rr]eferences$') then
      return pandoc.RawBlock('latex', '\\chapter*{References}\\addcontentsline{toc}{part}{References}')
    end

    -- Index → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Ii]ndex$') then
      return pandoc.RawBlock('latex', '\\chapter*{Index}\\addcontentsline{toc}{part}{Index}')
    end

    -- Acknowledgments/Acknowledgements → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Aa]cknowledg[e]?ments?$') then
      return pandoc.RawBlock('latex', '\\chapter*{Acknowledgments}\\addcontentsline{toc}{part}{Acknowledgments}')
    end

    -- About the Author → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Aa]bout [Tt]he [Aa]uthor$') then
      return pandoc.RawBlock('latex', '\\chapter*{About the Author}\\addcontentsline{toc}{part}{About the Author}')
    end

    -- Epilogue → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Ee]pilogue$') then
      return pandoc.RawBlock('latex', '\\chapter*{Epilogue}\\addcontentsline{toc}{part}{Epilogue}')
    end

    -- Prologue → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Pp]rologue$') then
      return pandoc.RawBlock('latex', '\\chapter*{Prologue}\\addcontentsline{toc}{part}{Prologue}')
    end

    -- Foreword → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Ff]oreword$') then
      return pandoc.RawBlock('latex', '\\chapter*{Foreword}\\addcontentsline{toc}{part}{Foreword}')
    end

    -- Afterword → Unnumbered chapter with part-level TOC entry
    if string.match(header_text, '^[Aa]fterword$') then
      return pandoc.RawBlock('latex', '\\chapter*{Afterword}\\addcontentsline{toc}{part}{Afterword}')
    end

    -- ============================================
    -- FRONT MATTER PAGES (special styling, no TOC entry)
    -- These are typically used before the main content
    -- ============================================

    -- Dedication → Centered page with no header, italic text follows
    -- Content after this heading will be styled by the DedicationContent environment
    if string.match(header_text, '^[Dd]edication$') then
      return pandoc.RawBlock('latex', '\\clearpage\\thispagestyle{empty}\\vspace*{\\fill}\\begin{center}\\itshape\\large')
    end

    -- Epigraph → Right-aligned quote page with source attribution
    -- Content after this heading will be styled by the EpigraphContent environment
    if string.match(header_text, '^[Ee]pigraph$') then
      return pandoc.RawBlock('latex', '\\clearpage\\thispagestyle{empty}\\vspace*{\\fill}\\begin{flushright}\\itshape\\large')
    end

    -- Return unchanged if no pattern matches
    return el
  end

-- ============================================
-- BLOCK PROCESSING
-- Handle content following special headers
-- ============================================

-- Track state for special content processing
local in_dedication = false
local in_epigraph = false

function Pandoc(doc)
    local new_blocks = {}
    local i = 1

    while i <= #doc.blocks do
        local block = doc.blocks[i]

        -- Check if this is a dedication header
        if block.t == "Header" then
            local header_text = pandoc.utils.stringify(block.content)

            if string.match(header_text, '^[Dd]edication$') then
                -- Add the opening LaTeX
                table.insert(new_blocks, pandoc.RawBlock('latex',
                    '\\clearpage\\thispagestyle{empty}\\vspace*{\\fill}\\begin{center}\\itshape\\large'))

                -- Collect content until next header
                i = i + 1
                while i <= #doc.blocks and doc.blocks[i].t ~= "Header" do
                    table.insert(new_blocks, doc.blocks[i])
                    i = i + 1
                end

                -- Close the dedication
                table.insert(new_blocks, pandoc.RawBlock('latex',
                    '\\end{center}\\vspace*{\\fill}\\clearpage'))

                -- Don't increment i again, we're at the next header
                goto continue

            elseif string.match(header_text, '^[Ee]pigraph$') then
                -- Add the opening LaTeX
                table.insert(new_blocks, pandoc.RawBlock('latex',
                    '\\clearpage\\thispagestyle{empty}\\vspace*{\\fill}\\begin{flushright}\\itshape\\large'))

                -- Collect content until next header
                i = i + 1
                while i <= #doc.blocks and doc.blocks[i].t ~= "Header" do
                    table.insert(new_blocks, doc.blocks[i])
                    i = i + 1
                end

                -- Close the epigraph
                table.insert(new_blocks, pandoc.RawBlock('latex',
                    '\\end{flushright}\\vspace*{\\fill}\\clearpage'))

                -- Don't increment i again, we're at the next header
                goto continue
            end
        end

        table.insert(new_blocks, block)
        i = i + 1

        ::continue::
    end

    doc.blocks = new_blocks
    return doc
end
