-- image_size_filter.lua
-- Purpose: Keep an image's proportions when a width is given.
--
-- Images are kept within the text block by the template: graphicx defaults
-- \maxwidth and \maxheight (pandoc before 3.2) and \pandocbounded (pandoc
-- 3.2 and later). Pandoc's LaTeX writer reads only real dimensions and
-- percentages ("80%", "5cm"); a TeX length name such as \textwidth is
-- dropped, so none is set here.

local is_latex = FORMAT:match('latex') ~= nil

function Image(el)
  if not is_latex then return nil end

  -- A width alone scales the height in proportion
  if el.attributes.width and el.attributes.width ~= '' then
    el.attributes.height = nil
  end

  return el
end
