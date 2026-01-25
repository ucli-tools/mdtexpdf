-- index_filter.lua
-- Processes [index:term] markers in markdown and converts them to LaTeX \index{term} commands
-- For EPUB, it collects index terms and can generate an index appendix

-- Store index entries for EPUB index generation
local index_entries = {}
local format = FORMAT

-- Pattern to match index markers: [index:term] or [index:term|subterm]
local index_pattern = "%[index:([^%]]+)%]"

-- Process inline strings to find and replace index markers
function Str(el)
    local text = el.text

    -- Check if this string contains an index marker
    if text:match(index_pattern) then
        local result = {}
        local last_end = 1

        for term in text:gmatch(index_pattern) do
            local start_pos, end_pos = text:find("%[index:" .. term:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%]", last_end)

            -- Add text before the marker
            if start_pos > last_end then
                table.insert(result, pandoc.Str(text:sub(last_end, start_pos - 1)))
            end

            -- Process the term (handle subterms with |)
            local main_term, sub_term = term:match("([^|]+)|?(.*)")
            if sub_term and sub_term ~= "" then
                -- Store for index
                if not index_entries[main_term] then
                    index_entries[main_term] = {}
                end
                table.insert(index_entries[main_term], sub_term)
            else
                -- Simple term
                if not index_entries[main_term] then
                    index_entries[main_term] = {}
                end
            end

            -- Output format-specific index marker
            if format:match("latex") or format:match("pdf") then
                -- LaTeX: use \index{term} or \index{term!subterm}
                local latex_term = main_term
                if sub_term and sub_term ~= "" then
                    latex_term = main_term .. "!" .. sub_term
                end
                table.insert(result, pandoc.RawInline("latex", "\\index{" .. latex_term .. "}"))
            else
                -- For other formats (EPUB, HTML), we just remove the marker
                -- The index will be generated separately
            end

            last_end = end_pos + 1
        end

        -- Add any remaining text
        if last_end <= #text then
            table.insert(result, pandoc.Str(text:sub(last_end)))
        end

        if #result > 0 then
            return result
        end
    end

    return el
end

-- Also check for index markers in plain text within paragraphs
function Para(el)
    return pandoc.walk_block(el, {Str = Str})
end

-- For EPUB: Generate an index section at the end
function Pandoc(doc)
    -- Only generate index appendix for non-LaTeX formats
    if format:match("latex") or format:match("pdf") then
        return doc
    end

    -- Check if we have any index entries
    local has_entries = false
    for _ in pairs(index_entries) do
        has_entries = true
        break
    end

    if not has_entries then
        return doc
    end

    -- Generate index section for EPUB/HTML
    local index_blocks = {}
    table.insert(index_blocks, pandoc.Header(1, pandoc.Str("Index")))

    -- Sort entries alphabetically
    local sorted_terms = {}
    for term in pairs(index_entries) do
        table.insert(sorted_terms, term)
    end
    table.sort(sorted_terms)

    -- Create definition list for index
    local items = {}
    local current_letter = ""

    for _, term in ipairs(sorted_terms) do
        local first_letter = term:sub(1, 1):upper()

        -- Add letter header if new letter
        if first_letter ~= current_letter then
            current_letter = first_letter
            table.insert(index_blocks, pandoc.Header(2, pandoc.Str(current_letter)))
        end

        -- Add term
        local subterms = index_entries[term]
        if #subterms > 0 then
            -- Term with subterms
            local subitems = {}
            for _, sub in ipairs(subterms) do
                table.insert(subitems, pandoc.Plain({pandoc.Str(sub)}))
            end
            table.insert(index_blocks, pandoc.Para({pandoc.Strong({pandoc.Str(term)})}))
            table.insert(index_blocks, pandoc.BulletList({{pandoc.Plain(subitems)}}))
        else
            -- Simple term
            table.insert(index_blocks, pandoc.Para({pandoc.Str(term)}))
        end
    end

    -- Append index to document
    for _, block in ipairs(index_blocks) do
        table.insert(doc.blocks, block)
    end

    return doc
end

return {
    {Str = Str},
    {Para = Para},
    {Pandoc = Pandoc}
}
