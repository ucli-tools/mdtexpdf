-- index_filter.lua
-- Processes [index:term] markers in markdown and converts them to LaTeX \index{term} commands
-- Handles multi-word terms that pandoc splits across Str/Space elements
-- For EPUB/HTML, collects terms and generates an index appendix

local index_entries = {}
local anchors = {}          -- anchor id -> levels of its term (non-LaTeX formats)
local anchor_count = 0
local in_alt_text = false   -- a marker in an image's alt text gets no anchor
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

    -- Other formats (EPUB, HTML): an anchor the linked index points to, except in
    -- an image's alt text, which cannot hold one (the figure caption carries it)
    if in_alt_text then
        return nil
    end
    anchor_count = anchor_count + 1
    local id = "idx-" .. anchor_count
    anchors[id] = levels
    return pandoc.Span({}, pandoc.Attr(id))
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

-- For EPUB/HTML: a linked index at the end of the document. Each entry lists where
-- its term occurs by the heading (level 1 or 2) the occurrence falls under, linked to
-- the occurrence itself; further occurrences under the same heading follow as 2, 3, ...
-- A level written sort@display sorts by its first part and shows its second.
local function split_level(level)
    local sort, display = level:match("^(.-)@(.+)$")
    if sort then return sort, display end
    return level, level
end

local function display_inlines(text)
    local blocks = pandoc.read(text, "markdown").blocks
    if #blocks == 0 then return {pandoc.Str(text)} end
    return pandoc.utils.blocks_to_inlines(blocks)
end

local function sort_key(text)
    return (text:gsub("%$", ""):gsub("^[^%w\128-\255]+", ""):lower())
end

function Pandoc(doc)
    if output_format:match("latex") or output_format:match("pdf") then
        return doc
    end
    if anchor_count == 0 then
        return doc
    end

    -- where each anchor falls, in reading order
    local occurrences = {}
    local heading = {text = "Opening pages"}
    doc.blocks:walk({
        traverse = "topdown",
        Header = function(header)
            if header.level <= 2 then
                heading = {text = pandoc.utils.stringify(header.content)}
            end
        end,
        Span = function(span)
            if anchors[span.identifier] then
                table.insert(occurrences, {id = span.identifier, heading = heading})
            end
        end,
    })

    -- the tree of terms
    local root = {children = {}}
    for _, occurrence in ipairs(occurrences) do
        local node = root
        for _, level in ipairs(anchors[occurrence.id]) do
            local sort, display = split_level(level)
            local key = sort_key(sort) .. "\0" .. display
            if not node.children[key] then
                node.children[key] = {sort = sort_key(sort), display = display, children = {}, places = {}}
            end
            node = node.children[key]
        end
        table.insert(node.places, occurrence)
    end

    local function sorted(children)
        local list = {}
        for _, child in pairs(children) do table.insert(list, child) end
        table.sort(list, function(a, b)
            if a.sort ~= b.sort then return a.sort < b.sort end
            return a.display < b.display
        end)
        return list
    end

    -- "Heading, 2, 3; Other heading" with every part a link
    local function places(node)
        local out = {}
        local previous, count = nil, 0
        for _, place in ipairs(node.places) do
            if place.heading == previous then
                count = count + 1
                table.insert(out, pandoc.Str(","))
                table.insert(out, pandoc.Space())
                table.insert(out, pandoc.Link({pandoc.Str(tostring(count))}, "#" .. place.id))
            else
                table.insert(out, pandoc.Str(#out == 0 and "" or ";"))
                if #out > 1 then table.insert(out, pandoc.Space()) end
                table.insert(out, pandoc.Link({pandoc.Str(place.heading.text)}, "#" .. place.id))
                previous, count = place.heading, 1
            end
        end
        return out
    end

    local function entry(node)
        local inlines = display_inlines(node.display)
        if #node.places > 0 then
            table.insert(inlines, pandoc.Str(":"))
            table.insert(inlines, pandoc.Space())
            for _, inline in ipairs(places(node)) do table.insert(inlines, inline) end
        end
        local blocks = {pandoc.Plain(inlines)}
        local children = sorted(node.children)
        if #children > 0 then
            local items = {}
            for _, child in ipairs(children) do table.insert(items, entry(child)) end
            table.insert(blocks, pandoc.BulletList(items))
        end
        return blocks
    end

    local index_blocks = {pandoc.Header(1, pandoc.Str("Index"), pandoc.Attr("index", {"unnumbered"}))}
    local current_letter = nil
    local items = {}
    local function flush()
        if #items > 0 then table.insert(index_blocks, pandoc.BulletList(items)) end
        items = {}
    end
    for _, node in ipairs(sorted(root.children)) do
        local first = node.sort:sub(1, 1)
        local letter = first:match("%a") and first:upper() or "Symbols and numbers"
        if letter ~= current_letter then
            flush()
            current_letter = letter
            table.insert(index_blocks, pandoc.Header(2, pandoc.Str(letter), pandoc.Attr("", {"unnumbered", "unlisted"})))
        end
        table.insert(items, entry(node))
    end
    flush()

    for _, block in ipairs(index_blocks) do
        table.insert(doc.blocks, block)
    end
    return doc
end

-- For EPUB/HTML: an image's alt text repeats its figure caption as plain text, so
-- markers there are removed without anchors; the caption's own markers get them
local function alt_text(image)
    if output_format:match("latex") or output_format:match("pdf") then
        return nil
    end
    in_alt_text = true
    local caption = Inlines(image.caption)
    in_alt_text = false
    if caption then
        image.caption = caption
        return image
    end
end

return {
    {Image = alt_text},
    {Inlines = Inlines},
    {Pandoc = Pandoc}
}
