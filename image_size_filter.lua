-- image_size_filter.lua
-- Purpose: Provide a reasonable default image width when none is specified
-- Behavior: For LaTeX, set width to 0.9\\linewidth if width is absent

local is_latex = FORMAT:match('latex') ~= nil
local last_was_figure = false
local last_figure_had_caption = false
local expect_followup_auto_desc = false

-- Detect MS Word auto-generated alt text paragraphs
local function is_auto_generated_desc(text)
  if not text or text == '' then return false end
  local lower = text:lower()
  if lower:find('description automatically generated', 1, true) then
    return true
  end
  if lower:find('automatically generated description', 1, true) then
    return true
  end
  return false
end

-- Detect standalone confidence-only lines
local function is_confidence_only(text)
  if not text or text == '' then return false end
  local lower = text:lower():gsub('%p', '')
  -- Drop lines that are essentially just 'medium confidence', 'high confidence', etc.
  if lower:match('^%s*[%a%s]*confidence%s*$') then
    return true
  end
  return false
end

-- Enhanced figure caption detection function
local function is_figure_caption(text)
  if not text or text == '' then return false end
  
  -- Primary patterns for figure captions
  if text:match('^%s*[Ff]igure%s+%d+') then return true end      -- "Figure 1", "figure 2"
  if text:match('^%s*[Ff]ig%.?%s+%d+') then return true end      -- "Fig. 1", "fig 2"
  if text:match('^%s*[Ff]igure%s+%d+%.') then return true end    -- "Figure 1."
  if text:match('^%s*[Ff]ig%.?%s+%d+%.') then return true end    -- "Fig. 1."
  
  -- Handle cases with special characters like "Figure 4.-"
  if text:match('^%s*[Ff]igure%s+%d+%.?%-') then return true end -- "Figure 4.-"
  if text:match('^%s*[Ff]ig%.?%s+%d+%.?%-') then return true end -- "Fig. 4.-"
  
  -- Handle cases with em-dash or other separators
  if text:match('^%s*[Ff]igure%s+%d+%.?%s*[–—%-]') then return true end -- "Figure 3. –"
  if text:match('^%s*[Ff]ig%.?%s+%d+%.?%s*[–—%-]') then return true end -- "Fig. 3. –"
  
  return false
end

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

-- Helper: get width option with fallback to 0.9\linewidth
local function get_width_option(img)
  local attr = get_attr(img) or {}
  local w = attr.width
  if not w or w == '' then
    w = '0.9\\linewidth'
  end
  return w
end

-- Helper: get image src across Pandoc versions
local function get_src(img)
  if img.src then
    return img.src
  end
  if img.target then
    if type(img.target) == 'string' then
      return img.target
    elseif type(img.target) == 'table' and #img.target >= 1 then
      return img.target[1]
    end
  end
  return nil
end

-- Helper: stringify caption/alt text if present
local function get_caption(img)
  if img.caption then
    return pandoc.utils.stringify(img.caption)
  end
  if img.title then
    return img.title
  end
  return ''
end

-- Helper: detect if a paragraph/plain contains any image (direct or link-wrapped)
local function block_has_image(el)
  if not el or not el.content then return false end
  for _, node in ipairs(el.content) do
    if node.t == 'Image' then return true end
    if node.t == 'Link' and node.content then
      for _, c in ipairs(node.content) do
        if c.t == 'Image' then return true end
      end
    end
  end
  return false
end

-- Build a LaTeX figure block with centering and optional caption
local function make_figure_block(img)
  local src = get_src(img)
  if not src then
    return nil
  end
  local width = get_width_option(img)
  local caption = get_caption(img)
  if is_auto_generated_desc(caption) or is_confidence_only(caption) then
    caption = ''
  end
  local pieces = {
    "\\begin{figure}[H]",
    "\\centering",
    string.format("\\includegraphics[width=%s]{%s}", width, src)
  }
  if caption and caption ~= '' then
    table.insert(pieces, string.format("\\caption{%s}", caption))
  end
  table.insert(pieces, "\\end{figure}")
  return pandoc.RawBlock('latex', table.concat(pieces, "\n"))
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

-- Convert a paragraph that only contains an image (or a link-wrapped image)
-- into a centered figure with caption below.
function Para(el)
  if not is_latex then
    return nil
  end
  -- Unconditionally drop MS Word auto-generated description paragraphs
  do
    local txt = pandoc.utils.stringify(el)
    if (is_auto_generated_desc(txt) or is_confidence_only(txt)) and not block_has_image(el) then
      return {}
    end
  end
  if #el.content == 1 then
    local node = el.content[1]
    if node.t == 'Image' then
      local cap = get_caption(node)
      local fig = make_figure_block(node)
      if fig then
        last_was_figure = true
        last_figure_had_caption = (cap and cap ~= '')
        return fig
      end
    elseif node.t == 'Link' and #node.content == 1 and node.content[1].t == 'Image' then
      -- Link-wrapped image: ignore the link for LaTeX figure purposes
      local inner = node.content[1]
      local cap = get_caption(inner)
      local fig = make_figure_block(inner)
      if fig then
        last_was_figure = true
        last_figure_had_caption = (cap and cap ~= '')
        return fig
      end
    end
  end

  -- If the previous block was a figure, check for figure captions to center
  -- (regardless of whether the figure had an embedded caption)
  if last_was_figure then
    local text = pandoc.utils.stringify(el)
    local lower = (text or ''):lower()
    
    -- Skip auto-generated descriptions
    if is_auto_generated_desc(text) then
      -- Drop auto-generated description and keep looking for the real caption
      expect_followup_auto_desc = true
      return {}
    end
    
    -- Skip confidence-only lines following auto-generated descriptions
    if expect_followup_auto_desc and lower:find('confidence', 1, true) and not is_figure_caption(text) then
      -- Drop trailing 'medium/high confidence' line
      expect_followup_auto_desc = false
      return {}
    end
    expect_followup_auto_desc = false
    
    -- Center any figure caption regardless of embedded caption state
    if is_figure_caption(text) then
      local latex = pandoc.write(pandoc.Pandoc({el}), 'latex')
      last_was_figure = false
      last_figure_had_caption = false
      return pandoc.RawBlock('latex', '\\begin{center}\n' .. latex .. '\n\\end{center}')
    end
    
    -- Reset state if not a figure caption
    last_was_figure = false
    last_figure_had_caption = false
  end
  return nil
end

-- Handle Plain similarly (some inputs may use Plain instead of Para)
function Plain(el)
  if not is_latex then
    return nil
  end
  do
    local txt = pandoc.utils.stringify(el)
    if (is_auto_generated_desc(txt) or is_confidence_only(txt)) and not block_has_image(el) then
      return {}
    end
  end
  if #el.content == 1 then
    local node = el.content[1]
    if node.t == 'Image' then
      local cap = get_caption(node)
      local fig = make_figure_block(node)
      if fig then
        last_was_figure = true
        last_figure_had_caption = (cap and cap ~= '')
        return fig
      end
    elseif node.t == 'Link' and #node.content == 1 and node.content[1].t == 'Image' then
      local inner = node.content[1]
      local cap = get_caption(inner)
      local fig = make_figure_block(inner)
      if fig then
        last_was_figure = true
        last_figure_had_caption = (cap and cap ~= '')
        return fig
      end
    end
  end

  if last_was_figure then
    local text = pandoc.utils.stringify(el)
    local lower = (text or ''):lower()
    
    -- Skip auto-generated descriptions
    if is_auto_generated_desc(text) then
      expect_followup_auto_desc = true
      return {}
    end
    
    -- Skip confidence-only lines following auto-generated descriptions
    if expect_followup_auto_desc and lower:find('confidence', 1, true) and not is_figure_caption(text) then
      expect_followup_auto_desc = false
      return {}
    end
    expect_followup_auto_desc = false
    
    -- Center any figure caption regardless of embedded caption state
    if is_figure_caption(text) then
      local latex = pandoc.write(pandoc.Pandoc({el}), 'latex')
      last_was_figure = false
      last_figure_had_caption = false
      return pandoc.RawBlock('latex', '\\begin{center}\n' .. latex .. '\n\\end{center}')
    end
    
    -- Reset state if not a figure caption
    last_was_figure = false
    last_figure_had_caption = false
  end
  return nil
end
