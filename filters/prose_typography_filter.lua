-- Preserve font-native prose punctuation that Pandoc otherwise expands into
-- constructed LaTeX sequences. In particular, Pandoc writes U+2026 HORIZONTAL
-- ELLIPSIS as \ldots{}, whose three separately spaced periods can look too loose
-- in book typography. The literal glyph is safe here because Unicode punctuation
-- selects XeLaTeX or LuaLaTeX during mdtexpdf engine detection.

local function preserve_unicode_ellipsis(element)
    if not FORMAT:match("latex") or not element.text:find("…", 1, true) then
        return nil
    end

    local output = {}
    local cursor = 1

    while true do
        local first, last = element.text:find("…", cursor, true)
        if not first then
            local suffix = element.text:sub(cursor)
            if suffix ~= "" then
                table.insert(output, pandoc.Str(suffix))
            end
            break
        end

        local prefix = element.text:sub(cursor, first - 1)
        if prefix ~= "" then
            table.insert(output, pandoc.Str(prefix))
        end
        table.insert(output, pandoc.RawInline("latex", "…"))
        cursor = last + 1
    end

    return output
end

return {
    { Str = preserve_unicode_ellipsis },
}
