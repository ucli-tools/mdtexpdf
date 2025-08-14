-- image_size_filter.lua
-- Purpose: Provide a reasonable default image width when none is specified
-- Behavior: For LaTeX, set width to 0.9\\linewidth if width is absent

local is_latex = FORMAT:match('latex') ~= nil

local function get_attr(img)
  -- Pandoc pre/post 2.17 compatibility
  if img.attributes then
    return img.attributes
  elseif img.attr and img.attr.attributes then
    return img.attr.attributes
  else
    return nil
  end
end

function Image(img)
  if not is_latex then
    return nil
  end
  local attr = get_attr(img)
  if not attr then
    return nil
  end
  if not attr.width or attr.width == '' then
    -- Use a default width that respects margins
    attr.width = '0.9\\linewidth'
    -- Ensure the attribute is written back
    if img.attributes then
      img.attributes = attr
    elseif img.attr and img.attr.attributes then
      img.attr.attributes = attr
    end
    return img
  end
  return nil
end
