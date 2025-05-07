-- image_size_filter.lua
-- A Pandoc Lua filter to automatically size images to fit the page width
-- and ensure captions are properly formatted

-- Function to add necessary packages to the document
function Meta(meta)
  -- Create a header-includes field if it doesn't exist
  if not meta["header-includes"] then
    meta["header-includes"] = pandoc.MetaList({})
  end
  
  -- Add the float package with the H option
  local float_package = pandoc.MetaInlines({pandoc.RawInline("latex", "\\usepackage{float}")})
  table.insert(meta["header-includes"], float_package)
  
  -- Add the caption package for better caption formatting
  local caption_package = pandoc.MetaInlines({pandoc.RawInline("latex", "\\usepackage{caption}")})
  table.insert(meta["header-includes"], caption_package)
  
  -- Configure captions to be in italics and properly spaced
  local caption_setup = pandoc.MetaInlines({pandoc.RawInline("latex", "\\captionsetup{font={small,it},skip=0pt}")})
  table.insert(meta["header-includes"], caption_setup)
  
  return meta
end

-- Function to handle images - make them smaller by default
function Image(elem)
  -- Set a reasonable width for images (60% of text width)
  elem.attributes.width = "0.6\\textwidth"
  
  -- Return the modified image element
  return elem
end

-- Function to handle paragraphs that might contain an image followed by a caption
function Para(elem)
  -- Check if this paragraph contains only an image followed by text on the same line
  if #elem.content >= 2 and elem.content[1].t == "Image" then
    -- Get the image
    local image = elem.content[1]
    
    -- Set image width
    local width = image.attributes.width or "0.6\\textwidth"
    
    -- Check if there's text after the image (without a line break)
    local has_caption = false
    local caption_text = ""
    
    -- Collect all elements after the image as potential caption
    if #elem.content > 1 then
      local caption_elements = {}
      for i = 2, #elem.content do
        table.insert(caption_elements, elem.content[i])
      end
      
      -- Convert the caption elements to text
      caption_text = pandoc.utils.stringify(pandoc.Inlines(caption_elements))
      has_caption = true
    end
    
    -- If we have a caption, create a figure with caption
    if has_caption and caption_text ~= "" then
      -- Create a LaTeX figure environment
      local latex = "\\begin{figure}[H]\n"
      latex = latex .. "  \\centering\n"
      
      -- Make sure the image path is properly escaped for LaTeX
      local img_path = image.src:gsub("\\", "/")
      
      -- Add the image
      latex = latex .. "  \\includegraphics[width=" .. width .. "]{" .. img_path .. "}\n"
      
      -- Add the caption
      latex = latex .. "  \\caption*{" .. caption_text .. "}\n"
      latex = latex .. "\\end{figure}\n"
      
      -- Return a raw LaTeX block
      return pandoc.RawBlock("latex", latex)
    end
  end
  
  -- If none of the above cases match, return unchanged
  return elem
end