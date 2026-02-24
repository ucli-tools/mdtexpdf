-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.
-- Enhanced version with support for Preface, Appendices, Introduction, etc.
-- Automatically detects if document has Parts and adjusts back matter TOC level accordingly.
--
-- Uses a two-pass filter:
--   Pass 1: Scan document for Part headers, set has_parts flag and metadata
--   Pass 2: Process all headers and dedication/epigraph blocks
-- This ordering ensures has_parts is set BEFORE any Header is processed,
-- so Preface (which appears before Part 1) gets the correct TOC level.

-- Global flag to track if document has Parts
local has_parts = false

-- Helper function to get TOC level based on whether document has Parts
local function get_backmatter_toc_level()
    if has_parts then
        return "part"
    else
        return "chapter"
    end
end

-- ============================================
-- PASS 1: Detect Parts and set metadata
-- ============================================

local function pass1_detect_parts(doc)
    for _, block in ipairs(doc.blocks) do
        if block.t == "Header" then
            local header_text = pandoc.utils.stringify(block.content)
            if string.match(header_text, '^[Pp]art %d+:') then
                has_parts = true
                break
            end
        end
    end

    -- Expose has_parts to the Pandoc template as a metadata variable
    if has_parts then
        doc.meta.has_parts = true
    end

    return doc
end

-- ============================================
-- PASS 2: Header processing
-- ============================================

local function process_header(el)
    local header_text = pandoc.utils.stringify(el.content)
    local toc_level = get_backmatter_toc_level()

    -- ============================================
    -- PART-STYLE PAGES (full page with large title)
    -- ============================================

    -- Check for "Part X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Pp]art %d+:') then
      local part_title = string.gsub(header_text, '^[Pp]art %d+: *', '')
      return pandoc.RawBlock('latex', '\\clearpage\\part{' .. part_title .. '}')
    end

    -- Preface → Unnumbered chapter with appropriate TOC level
    if string.match(header_text, '^[Pp]reface$') then
      return pandoc.RawBlock('latex', '\\chapter*{Preface}\\addcontentsline{toc}{' .. toc_level .. '}{Preface}')
    end

    -- Appendices/Appendix → Part-style page + switch to appendix numbering (A, B, C...)
    if string.match(header_text, '^[Aa]ppendices$') or string.match(header_text, '^[Aa]ppendix$') then
      if has_parts then
        return pandoc.RawBlock('latex', '\\clearpage\\part*{Appendices}\\appendix')
      else
        -- For books without parts, just use unnumbered chapter and switch to appendix mode
        return pandoc.RawBlock('latex', '\\chapter*{Appendices}\\addcontentsline{toc}{chapter}{Appendices}\\appendix')
      end
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
    -- UNNUMBERED SECTIONS WITH DYNAMIC TOC LEVEL
    -- TOC level depends on whether document has Parts
    -- ============================================

    -- Introduction → Unnumbered chapter
    if string.match(header_text, '^[Ii]ntroduction$') then
      return pandoc.RawBlock('latex', '\\chapter*{Introduction}\\addcontentsline{toc}{' .. toc_level .. '}{Introduction}')
    end

    -- Conclusion → Unnumbered chapter
    if string.match(header_text, '^[Cc]onclusion$') then
      return pandoc.RawBlock('latex', '\\chapter*{Conclusion}\\addcontentsline{toc}{' .. toc_level .. '}{Conclusion}')
    end

    -- Glossary → Unnumbered chapter
    if string.match(header_text, '^[Gg]lossary$') then
      return pandoc.RawBlock('latex', '\\chapter*{Glossary}\\addcontentsline{toc}{' .. toc_level .. '}{Glossary}')
    end

    -- Bibliography → Unnumbered chapter
    if string.match(header_text, '^[Bb]ibliography$') then
      return pandoc.RawBlock('latex', '\\chapter*{Bibliography}\\addcontentsline{toc}{' .. toc_level .. '}{Bibliography}')
    end

    -- References → Unnumbered chapter
    if string.match(header_text, '^[Rr]eferences$') then
      return pandoc.RawBlock('latex', '\\chapter*{References}\\addcontentsline{toc}{' .. toc_level .. '}{References}')
    end

    -- Index → Unnumbered chapter
    if string.match(header_text, '^[Ii]ndex$') then
      return pandoc.RawBlock('latex', '\\chapter*{Index}\\addcontentsline{toc}{' .. toc_level .. '}{Index}')
    end

    -- Acknowledgments/Acknowledgements → Unnumbered chapter
    if string.match(header_text, '^[Aa]cknowledg[e]?ments?$') then
      return pandoc.RawBlock('latex', '\\chapter*{Acknowledgments}\\addcontentsline{toc}{' .. toc_level .. '}{Acknowledgments}')
    end

    -- About the Author → Unnumbered chapter
    if string.match(header_text, '^[Aa]bout [Tt]he [Aa]uthor$') then
      return pandoc.RawBlock('latex', '\\chapter*{About the Author}\\addcontentsline{toc}{' .. toc_level .. '}{About the Author}')
    end

    -- Epilogue → Unnumbered chapter
    if string.match(header_text, '^[Ee]pilogue$') then
      return pandoc.RawBlock('latex', '\\chapter*{Epilogue}\\addcontentsline{toc}{' .. toc_level .. '}{Epilogue}')
    end

    -- Prologue → Unnumbered chapter
    if string.match(header_text, '^[Pp]rologue$') then
      return pandoc.RawBlock('latex', '\\chapter*{Prologue}\\addcontentsline{toc}{' .. toc_level .. '}{Prologue}')
    end

    -- Foreword → Unnumbered chapter
    if string.match(header_text, '^[Ff]oreword$') then
      return pandoc.RawBlock('latex', '\\chapter*{Foreword}\\addcontentsline{toc}{' .. toc_level .. '}{Foreword}')
    end

    -- Afterword → Unnumbered chapter
    if string.match(header_text, '^[Aa]fterword$') then
      return pandoc.RawBlock('latex', '\\chapter*{Afterword}\\addcontentsline{toc}{' .. toc_level .. '}{Afterword}')
    end

    -- ============================================
    -- FRONT MATTER PAGES
    -- Dedication, Epigraph, and Copyright Page are handled in
    -- pass2_process_blocks() which uses open-collect-close block
    -- processing.  Do NOT transform them here — converting to
    -- RawBlock would prevent pass2 from finding them as Headers.
    -- ============================================

    -- Return unchanged if no pattern matches
    return el
end

-- ============================================
-- PASS 2: Block processing (dedication/epigraph content)
-- ============================================

local function pass2_process_blocks(doc)
    local new_blocks = {}
    local i = 1

    while i <= #doc.blocks do
        local block = doc.blocks[i]

        -- Check if this is a dedication or epigraph header
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

                goto continue

            elseif string.match(header_text, '^[Cc]opyright [Pp]age$') then
                -- Copyright page: left-aligned, small text, pushed to bottom of page
                table.insert(new_blocks, pandoc.RawBlock('latex',
                    '\\clearpage\\thispagestyle{empty}\\vspace*{\\fill}\\begin{flushleft}\\small'))

                -- Collect content until next header
                i = i + 1
                while i <= #doc.blocks and doc.blocks[i].t ~= "Header" do
                    table.insert(new_blocks, doc.blocks[i])
                    i = i + 1
                end

                -- Close the copyright page
                table.insert(new_blocks, pandoc.RawBlock('latex',
                    '\\end{flushleft}\\clearpage'))

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

-- ============================================
-- MULTI-PASS FILTER
-- Return a list of filters applied in order:
--   Pass 1: Detect parts (document-level scan)
--   Pass 2: Process front matter blocks (Dedication, Epigraph, Copyright Page)
--           Must run BEFORE Header processing so that these headers are still
--           intact as Header elements (not yet converted to RawBlocks).
--   Pass 3: Process remaining headers (Part, Chapter, etc. → LaTeX commands)
-- ============================================

return {
    { Pandoc = pass1_detect_parts },
    { Pandoc = pass2_process_blocks },
    { Header = process_header }
}
