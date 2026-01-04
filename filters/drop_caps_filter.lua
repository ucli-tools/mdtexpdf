-- drop_caps_filter.lua
-- Pandoc Lua filter to add drop caps (lettrine) to the first paragraph after chapters
-- Usage: pandoc --lua-filter=drop_caps_filter.lua -V drop_caps=true

local drop_caps_enabled = false

-- Check if drop caps is enabled via metadata
function Meta(meta)
    if meta.drop_caps then
        drop_caps_enabled = pandoc.utils.stringify(meta.drop_caps) == "true"
    end
    return meta
end

-- Helper function to apply drop cap to a paragraph
local function apply_drop_cap(para)
    local content = para.content
    if #content == 0 then
        return para
    end
    
    -- Get the first inline element
    local first = content[1]
    
    if first.t == "Str" then
        local text = first.text
        if #text > 0 then
            -- Extract first letter
            local first_letter = text:sub(1, 1)
            local rest_of_word = text:sub(2)
            
            -- Check for uppercase letters - only apply drop caps to capital letters
            if first_letter:match("[A-Z]") then
                -- Find the rest of the first word
                local word_end = rest_of_word:find("[%s%p]") or (#rest_of_word + 1)
                local first_word_rest = rest_of_word:sub(1, word_end - 1)
                local after_word = rest_of_word:sub(word_end)
                
                -- Build the lettrine command
                local lettrine_raw = string.format("\\lettrine{%s}{%s}", first_letter, first_word_rest)
                
                -- Create new content with lettrine
                local new_content = {pandoc.RawInline("latex", lettrine_raw)}
                
                -- Add rest of first string if any
                if #after_word > 0 then
                    table.insert(new_content, pandoc.Str(after_word))
                end
                
                -- Add remaining inline elements
                for i = 2, #content do
                    table.insert(new_content, content[i])
                end
                
                return pandoc.Para(new_content)
            end
        end
    end
    
    return para
end

-- Process all blocks in order to track chapters and apply drop caps
function Blocks(blocks)
    if not drop_caps_enabled then
        return blocks
    end
    
    local after_chapter = false
    local result = {}
    
    for i, block in ipairs(blocks) do
        -- Check for chapter commands in RawBlocks (after book_structure.lua processing)
        if block.t == "RawBlock" and block.format == "latex" then
            -- Check if this is a chapter command
            if block.text:find("\\chapter") then
                after_chapter = true
            end
            table.insert(result, block)
        -- Check for chapter headings (level 2) - before book_structure.lua processing
        elseif block.t == "Header" and block.level == 2 then
            after_chapter = true
            table.insert(result, block)
        -- Apply drop cap to first paragraph after chapter
        elseif block.t == "Para" then
            if after_chapter then
                table.insert(result, apply_drop_cap(block))
                after_chapter = false
            else
                table.insert(result, block)
            end
        else
            table.insert(result, block)
        end
    end
    
    return result
end

-- Return the filter - Meta first, then Blocks
return {
    {Meta = Meta},
    {Blocks = Blocks}
}
