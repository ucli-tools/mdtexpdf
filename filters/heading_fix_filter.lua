-- heading_fix_filter.lua
-- Pandoc Lua filter to fix level 4 and 5 headings so they render as
-- standalone block headings instead of inline \paragraph{} commands.
-- In book class with the chapter/section shift from book_structure.lua,
-- #### maps to \paragraph which runs inline with the following text.
-- This filter converts them to properly formatted block headings.

local function render_inlines(inlines)
    -- Ask Pandoc's LaTeX writer to preserve links, emphasis, code, math, and
    -- escaping. Stringifying here would discard that structure and expose
    -- characters such as _, $, and % directly to LaTeX.
    local document = pandoc.Pandoc({pandoc.Plain(inlines)})
    return pandoc.write(document, 'latex'):gsub('%s+$', '')
end

function Header(el)
    if el.level == 4 then
        -- Convert #### to a bold, standalone heading with vertical space
        local heading_latex = render_inlines(el.content)
        local latex = string.format(
            "\\vspace{0.8em}\\noindent{\\textbf{%s}}\\vspace{0.4em}\\par",
            heading_latex
        )
        return pandoc.RawBlock('latex', latex)
    elseif el.level == 5 then
        -- Convert ##### to a bold italic, standalone heading with vertical space
        local heading_latex = render_inlines(el.content)
        local latex = string.format(
            "\\vspace{0.6em}\\noindent{\\textbf{\\textit{%s}}}\\vspace{0.3em}\\par",
            heading_latex
        )
        return pandoc.RawBlock('latex', latex)
    end
    return el
end
