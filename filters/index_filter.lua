-- index_filter.lua
-- Processes [index:term] markers in markdown and converts them to LaTeX \index{term} commands
-- Handles multi-word terms that pandoc splits across Str/Space elements
-- For EPUB/HTML, collects terms and generates an index appendix

local index_entries = {}
local output_format = FORMAT
local index_pattern = "%[index:([^%]]+)%]"

-- One level of a term, made safe for the .idx file and for typesetting the
-- index: makeindex's quote character " escapes its level separator ! and
-- itself (@ stays, as the sort@display separator); outside $...$ math,
-- TeX's specials _ & % # get a backslash. Unescaped, "100% tax" loses
-- everything after the % when the index is typeset.
local function latex_index_level(level)
    local out = {}
    local pos = 1
    while pos <= #level do
        local s, e = level:find("%$[^$]*%$", pos)
        local text = level:sub(pos, (s or (#level + 1)) - 1)
        text = text:gsub('(["!])', '"%1')
        text = text:gsub("(\\?)([_&%%#])", function(bs, ch)
            if bs == "\\" then return bs .. ch end
            return "\\" .. ch
        end)
        table.insert(out, text)
        if not s then break end
        table.insert(out, (level:sub(s, e):gsub('(["!])', '"%1')))
        pos = e + 1
    end
    return table.concat(out)
end

-- Convert an index term to the appropriate output format.
-- Levels are separated by | (main|sub|subsub).
local function make_index_inline(term)
    local levels = {}
    for level in (term .. "|"):gmatch("([^|]*)|") do
        if level ~= "" then
            table.insert(levels, level)
        end
    end
    if #levels == 0 then
        return nil
    end
    local main_term = levels[1]
    local sub_term = table.concat(levels, ", ", 2)

    -- Track for EPUB index generation
    if not index_entries[main_term] then
        index_entries[main_term] = {}
    end
    if sub_term ~= "" then
        table.insert(index_entries[main_term], sub_term)
    end

    -- LaTeX output
    if output_format:match("latex") or output_format:match("pdf") then
        local escaped = {}
        for _, level in ipairs(levels) do
            table.insert(escaped, latex_index_level(level))
        end
        return pandoc.RawInline("latex", "\\index{" .. table.concat(escaped, "!") .. "}")
    end

    -- For other formats, return nothing (marker is silently removed)
    return nil
end

-- Process a text string that may contain one or more [index:...] markers
-- Returns a list of pandoc inline elements
local function process_text(text)
    local result = pandoc.List()
    local pos = 1

    while pos <= #text do
        local s, e, term = text:find(index_pattern, pos)

        if s then
            -- Add any text before this marker
            if s > pos then
                local before = text:sub(pos, s - 1)
                -- Reconstruct Str/Space sequence from plain text
                local first = true
                for word in before:gmatch("%S+") do
                    if not first then
                        result:insert(pandoc.Space())
                    end
                    result:insert(pandoc.Str(word))
                    first = false
                end
                -- Preserve trailing space
                if before:match("%s$") then
                    result:insert(pandoc.Space())
                end
            end

            -- Add the index command
            local idx = make_index_inline(term)
            if idx then
                result:insert(idx)
            end

            pos = e + 1
        else
            -- No more markers; add remaining text
            local remaining = text:sub(pos)
            if remaining ~= "" then
                local first = true
                for word in remaining:gmatch("%S+") do
                    if not first then
                        result:insert(pandoc.Space())
                    end
                    result:insert(pandoc.Str(word))
                    first = false
                end
                if remaining:match("%s$") then
                    result:insert(pandoc.Space())
                end
            end
            break
        end
    end

    return result
end

-- Check if text has an unclosed [index: marker (opening bracket with no closing bracket after it)
local function has_unclosed_marker(text)
    return text:match("%[index:[^%]]*$") ~= nil
end

-- Process a list of inline elements, reassembling [index:...] markers
-- that pandoc split across multiple Str/Space nodes
function Inlines(inlines)
    -- Quick check: does any Str contain "[index:"?
    local has_marker = false
    for _, el in ipairs(inlines) do
        if el.t == "Str" and el.text:find("%[index:") then
            has_marker = true
            break
        end
    end

    if not has_marker then
        return nil -- no changes
    end

    local result = pandoc.List()
    local i = 1

    while i <= #inlines do
        local el = inlines[i]

        if el.t == "Str" and el.text:find("%[index:") then
            -- Found start of marker(s). Collect text until all markers are closed.
            local parts = {el.text}
            local j = i + 1
            local full = el.text

            while has_unclosed_marker(full) and j <= #inlines do
                local nxt = inlines[j]
                if nxt.t == "Str" then
                    table.insert(parts, nxt.text)
                    full = table.concat(parts)
                elseif nxt.t == "Space" or nxt.t == "SoftBreak" then
                    table.insert(parts, " ")
                    full = table.concat(parts)
                elseif nxt.t == "Math" and nxt.mathtype == "InlineMath" then
                    -- A term may carry math: keep it as $...$ for \index
                    table.insert(parts, "$" .. nxt.text .. "$")
                    full = table.concat(parts)
                else
                    -- Hit a non-text element (Emph, Strong, etc.); stop collecting
                    break
                end
                j = j + 1
            end

            -- Process the collected text (may contain multiple markers + trailing text)
            local processed = process_text(full)
            result:extend(processed)
            i = j
        else
            result:insert(el)
            i = i + 1
        end
    end

    return result
end

-- For EPUB/HTML: generate an index appendix at the end of the document
function Pandoc(doc)
    if output_format:match("latex") or output_format:match("pdf") then
        return doc
    end

    local has_entries = false
    for _ in pairs(index_entries) do
        has_entries = true
        break
    end

    if not has_entries then
        return doc
    end

    local index_blocks = {}
    table.insert(index_blocks, pandoc.Header(1, pandoc.Str("Index")))

    local sorted_terms = {}
    for term in pairs(index_entries) do
        table.insert(sorted_terms, term)
    end
    table.sort(sorted_terms)

    local current_letter = ""
    for _, term in ipairs(sorted_terms) do
        local first_letter = term:sub(1, 1):upper()
        if first_letter ~= current_letter then
            current_letter = first_letter
            table.insert(index_blocks, pandoc.Header(2, pandoc.Str(current_letter)))
        end

        local subterms = index_entries[term]
        if #subterms > 0 then
            local subitems = {}
            for _, sub in ipairs(subterms) do
                table.insert(subitems, pandoc.Plain({pandoc.Str(sub)}))
            end
            table.insert(index_blocks, pandoc.Para({pandoc.Strong({pandoc.Str(term)})}))
            table.insert(index_blocks, pandoc.BulletList({{pandoc.Plain(subitems)}}))
        else
            table.insert(index_blocks, pandoc.Para({pandoc.Str(term)}))
        end
    end

    for _, block in ipairs(index_blocks) do
        table.insert(doc.blocks, block)
    end

    return doc
end

return {
    {Inlines = Inlines},
    {Pandoc = Pandoc}
}
