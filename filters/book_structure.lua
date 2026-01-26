-- book_structure.lua
-- Pandoc Lua filter to convert specific header patterns to LaTeX \part and \chapter.
-- Enhanced version with support for Preface, Appendices, Introduction, etc.
-- Automatically detects if document has Parts and adjusts back matter TOC level accordingly.

-- Global flag to track if document has Parts
local has_parts = false

-- First pass: detect if document has Parts
function detect_parts(doc)
    for _, block in ipairs(doc.blocks) do
        if block.t == "Header" then
            local header_text = pandoc.utils.stringify(block.content)
            if string.match(header_text, '^[Pp]art %d+:') then
                has_parts = true
                return  -- Found at least one Part, no need to continue
            end
        end
    end
end

-- Helper function to get TOC level based on whether document has Parts
local function get_backmatter_toc_level()
    if has_parts then
        return "part"
    else
        return "chapter"
    end
end

function Header(el)
    local header_text = pandoc.utils.stringify(el.content)
    local toc_level = get_backmatter_toc_level()

    -- Debug: print what we're processing
    -- print("Processing header: " .. header_text .. " (has_parts: " .. tostring(has_parts) .. ")")

    -- ============================================
    -- PART-STYLE PAGES (full page with large title)
    -- ============================================

    -- Check for "Part X: ..." pattern, case-insensitive
    if string.match(header_text, '^[Pp]art %d+:') then
      has_parts = true  -- Set flag for TOC formatting (Header runs before Pandoc)
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
    -- First pass: detect if document has Parts
    detect_parts(doc)

    -- Expose has_parts to the Pandoc template as a metadata variable
    -- This allows the LaTeX template to conditionally format TOC page numbers
    if has_parts then
        doc.meta.has_parts = true
    end

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
