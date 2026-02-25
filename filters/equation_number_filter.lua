-- equation_number_filter.lua
-- Converts display math ($$ ... $$) to numbered LaTeX equations
-- when equation_numbers: true is set in document metadata.
-- Uses \begin{equation}...\end{equation} for automatic numbering.
-- Equations already in raw LaTeX blocks (e.g. \begin{equation}) are not affected.

local equation_numbers_enabled = false

function Meta(meta)
    if meta.equation_numbers then
        equation_numbers_enabled = pandoc.utils.stringify(meta.equation_numbers) == "true"
    end
    return meta
end

function Math(el)
    if not equation_numbers_enabled then
        return el
    end

    -- Only convert DisplayMath (not InlineMath)
    if el.mathtype == pandoc.DisplayMath then
        -- Strip leading/trailing whitespace from el.text to prevent blank lines
        -- inside the equation environment (multiline $$ blocks include newlines)
        local trimmed = el.text:match("^%s*(.-)%s*$")
        local tex = "\\begin{equation}\n" .. trimmed .. "\n\\end{equation}"
        return pandoc.RawInline('latex', tex)
    end

    return el
end

return {
    {Meta = Meta},
    {Math = Math}
}
