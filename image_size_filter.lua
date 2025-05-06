-- image_size_filter.lua
-- A Pandoc Lua filter to automatically size images to fit the page width

function Image(elem)
  -- Get the image attributes
  local width = elem.attributes.width
  local height = elem.attributes.height
  
  -- If width is not specified, set it to fit the page width (0.9\textwidth)
  if not width then
    -- Simply modify the image attributes to set width
    elem.attributes.width = "90%"
    return elem
  end
  
  -- If width is specified, use it as is
  return elem
end