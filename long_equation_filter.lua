-- long_equation_filter.lua
-- Purpose: Improve line breaking for long display equations in LaTeX output
-- Requires: breqn package (dmath environment) loaded in the LaTeX template

local is_latex = FORMAT:match('latex') ~= nil

-- Function to detect equations that need special handling
local function needs_special_handling(math_text)
  if not math_text then return false end

  local length = string.len(math_text)

  -- Only target extremely long equations that definitely overflow
  if length > 150 then return true end

  -- Multiple matrices with operators (the specific problematic case)
  if math_text:find('\\begin{pmatrix}.*\\circ.*\\begin{pmatrix}') then return true end

  -- Detect top-level comma-separated definitions like: v1 = ..., v2 = ...
  -- We split only at commas not inside {...}, (...), or [...] and not escaped as \,
  local function parts_from_top_level_commas(s)
    local parts = {}
    local brace, paren, bracket = 0, 0, 0
    local left_depth, env_depth = 0, 0
    local start = 1
    local i = 1
    local n = #s
    while i <= n do
      -- Handle control sequences that affect grouping
      if s:sub(i):find('^\\left') then
        left_depth = left_depth + 1
        i = i + 5
        goto continue
      elseif s:sub(i):find('^\\right') then
        if left_depth > 0 then left_depth = left_depth - 1 end
        i = i + 6
        goto continue
      elseif s:sub(i):find('^\\begin%s*%{') then
        -- advance to matching closing brace of \begin{...}
        local j = i + 7 -- after "\\begin"
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1
          local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1
            elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          env_depth = env_depth + 1
          i = j
          goto continue
        end
      elseif s:sub(i):find('^\\end%s*%{') then
        -- advance past \end{...}
        local j = i + 5 -- after "\\end"
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1
          local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1
            elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          if env_depth > 0 then env_depth = env_depth - 1 end
          i = j
          goto continue
        end
      end

      local ch = s:sub(i, i)
      if ch == '{' then
        brace = brace + 1
      elseif ch == '}' and brace > 0 then
        brace = brace - 1
      elseif ch == '(' then
        paren = paren + 1
      elseif ch == ')' and paren > 0 then
        paren = paren - 1
      elseif ch == '[' then
        bracket = bracket + 1
      elseif ch == ']' and bracket > 0 then
        bracket = bracket - 1
      elseif ch == ','
        and (brace == 0 and paren == 0 and bracket == 0)
        and left_depth == 0 and env_depth == 0
        and not (i > 1 and s:sub(i-1, i-1) == '\\') then
        local seg = s:sub(start, i - 1)
        seg = seg:gsub('^%s+', ''):gsub('%s+$', '')
        table.insert(parts, seg)
        i = i + 1
        while i <= n and s:sub(i, i):match('%s') do
          i = i + 1
        end
        start = i
        goto continue
      end
      i = i + 1
      ::continue::
    end
    local last = s:sub(start)
    last = last:gsub('^%s+', ''):gsub('%s+$', '')
    table.insert(parts, last)
    return parts
  end

  local parts = parts_from_top_level_commas(math_text)
  if #parts >= 2 then
    local with_eq = 0
    for _, seg in ipairs(parts) do
      if seg:find('=') then with_eq = with_eq + 1 end
    end
    -- Only trigger for multi-assignments when the expression is long or has many parts
    if with_eq >= 2 and (#parts >= 3 or length > 120) then
      return true
    end
  end

  -- Additional trigger: at least two top-level '=' in the expression
  local function count_top_level_eqs(s)
    local brace, paren, bracket = 0, 0, 0
    local left_depth, env_depth = 0, 0
    local i, n, count = 1, #s, 0
    while i <= n do
      if s:sub(i):find('^\\left') then
        left_depth = left_depth + 1; i = i + 5; goto continue
      elseif s:sub(i):find('^\\right') then
        if left_depth > 0 then left_depth = left_depth - 1 end; i = i + 6; goto continue
      elseif s:sub(i):find('^\\begin%s*%{') then
        local j = i + 7
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1; local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          env_depth = env_depth + 1; i = j; goto continue
        end
      elseif s:sub(i):find('^\\end%s*%{') then
        local j = i + 5
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1; local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          if env_depth > 0 then env_depth = env_depth - 1 end; i = j; goto continue
        end
      end
      local ch = s:sub(i, i)
      if ch == '{' then brace = brace + 1
      elseif ch == '}' and brace > 0 then brace = brace - 1
      elseif ch == '(' then paren = paren + 1
      elseif ch == ')' and paren > 0 then paren = paren - 1
      elseif ch == '[' then bracket = bracket + 1
      elseif ch == ']' and bracket > 0 then bracket = bracket - 1
      elseif ch == '=' and brace == 0 and paren == 0 and bracket == 0 and left_depth == 0 and env_depth == 0 then
        count = count + 1
      end
      i = i + 1
      ::continue::
    end
    return count
  end

  if count_top_level_eqs(math_text) >= 2 and length > 120 then
    return true
  end

  return false
end

-- Function to apply safe fixes
local function apply_safe_fixes(math_text)
  -- Trim leading/trailing whitespace to avoid blank lines inside math environments
  math_text = (math_text or ''):gsub('^%s+', ''):gsub('%s+$', '')
  -- First, try to break comma-separated definitions safely using explicit
  -- line breaks between parts inside breqn's dmath* (avoid amsmath envs).
  local function parts_from_top_level_commas(s)
    local parts = {}
    local brace, paren, bracket = 0, 0, 0
    local left_depth, env_depth = 0, 0
    local start = 1
    local i = 1
    local n = #s
    while i <= n do
      -- Handle control sequences that affect grouping
      if s:sub(i):find('^\\left') then
        left_depth = left_depth + 1
        i = i + 5
        goto continue
      elseif s:sub(i):find('^\\right') then
        if left_depth > 0 then left_depth = left_depth - 1 end
        i = i + 6
        goto continue
      elseif s:sub(i):find('^\\begin%s*%{') then
        -- advance to matching closing brace of \begin{...}
        local j = i + 7 -- after "\\begin"
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1
          local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1
            elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          env_depth = env_depth + 1
          i = j
          goto continue
        end
      elseif s:sub(i):find('^\\end%s*%{') then
        -- advance past \end{...}
        local j = i + 5 -- after "\\end"
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1
          local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1
            elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          if env_depth > 0 then env_depth = env_depth - 1 end
          i = j
          goto continue
        end
      end

      local ch = s:sub(i, i)
      if ch == '{' then
        brace = brace + 1
      elseif ch == '}' and brace > 0 then
        brace = brace - 1
      elseif ch == '(' then
        paren = paren + 1
      elseif ch == ')' and paren > 0 then
        paren = paren - 1
      elseif ch == '[' then
        bracket = bracket + 1
      elseif ch == ']' and bracket > 0 then
        bracket = bracket - 1
      elseif ch == ','
        and (brace == 0 and paren == 0 and bracket == 0)
        and left_depth == 0 and env_depth == 0
        and not (i > 1 and s:sub(i-1, i-1) == '\\') then
        local seg = s:sub(start, i - 1)
        seg = seg:gsub('^%s+', ''):gsub('%s+$', '')
        table.insert(parts, seg)
        i = i + 1
        while i <= n and s:sub(i, i):match('%s') do
          i = i + 1
        end
        start = i
        goto continue
      end
      i = i + 1
      ::continue::
    end
    local last = s:sub(start)
    last = last:gsub('^%s+', ''):gsub('%s+$', '')
    table.insert(parts, last)
    return parts
  end

  local parts = parts_from_top_level_commas(math_text)
  if #parts >= 2 then
    local with_eq = 0
    for _, seg in ipairs(parts) do
      if seg:find('=') then with_eq = with_eq + 1 end
    end
    if with_eq >= 2 then
      -- Split a segment into lhs and rhs at the first top-level '='
      local function split_top_level_eq(s)
        local brace, paren, bracket = 0, 0, 0
        local left_depth, env_depth = 0, 0
        local i, n = 1, #s
        while i <= n do
          if s:sub(i):find('^\\left') then
            left_depth = left_depth + 1
            i = i + 5
            goto continue
          elseif s:sub(i):find('^\\right') then
            if left_depth > 0 then left_depth = left_depth - 1 end
            i = i + 6
            goto continue
          elseif s:sub(i):find('^\\begin%s*%{') then
            local j = i + 7
            while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
            if j <= n and s:sub(j, j) == '{' then
              j = j + 1
              local depth = 1
              while j <= n and depth > 0 do
                local c = s:sub(j, j)
                if c == '{' then depth = depth + 1
                elseif c == '}' then depth = depth - 1 end
                j = j + 1
              end
              env_depth = env_depth + 1
              i = j
              goto continue
            end
          elseif s:sub(i):find('^\\end%s*%{') then
            local j = i + 5
            while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
            if j <= n and s:sub(j, j) == '{' then
              j = j + 1
              local depth = 1
              while j <= n and depth > 0 do
                local c = s:sub(j, j)
                if c == '{' then depth = depth + 1
                elseif c == '}' then depth = depth - 1 end
                j = j + 1
              end
              if env_depth > 0 then env_depth = env_depth - 1 end
              i = j
              goto continue
            end
          end

          local ch = s:sub(i, i)
          if ch == '{' then
            brace = brace + 1
          elseif ch == '}' and brace > 0 then
            brace = brace - 1
          elseif ch == '(' then
            paren = paren + 1
          elseif ch == ')' and paren > 0 then
            paren = paren - 1
          elseif ch == '[' then
            bracket = bracket + 1
          elseif ch == ']' and bracket > 0 then
            bracket = bracket - 1
          elseif ch == '=' and brace == 0 and paren == 0 and bracket == 0 and left_depth == 0 and env_depth == 0 then
            local lhs = s:sub(1, i - 1):gsub('^%s+', ''):gsub('%s+$', '')
            local rhs = s:sub(i + 1):gsub('^%s+', ''):gsub('%s+$', '')
            return lhs, rhs
          end
          i = i + 1
          ::continue::
        end
        return nil, nil
      end

      local lines = {}
      for i, seg in ipairs(parts) do
        seg = seg:gsub('^%s+', ''):gsub('%s+$', '')
        local lhs, rhs = split_top_level_eq(seg)
        if lhs and rhs then
          -- Sanitize LHS/RHS: remove newlines and leading spacing macros from LHS
          lhs = lhs:gsub('[\r\n]+', ' ')
          lhs = lhs:gsub('\\quad', ''):gsub('\\qquad', ''):gsub('\\,', ''):gsub('\\;', ''):gsub('\\:', '')
          lhs = lhs:gsub('^%s+', ''):gsub('%s+$', '')
          rhs = rhs:gsub('[\r\n]+', ' ')
          if i < #parts then
            rhs = rhs .. ','
          end
          table.insert(lines, '  ' .. lhs .. ' &= ' .. rhs)
        else
          -- Fallback if this segment has no '=': append to previous row to avoid spurious breaks
          local seg_line = seg:gsub('[\r\n]+', ' ')
          if i < #parts then
            seg_line = seg_line .. ','
          end
          if #lines > 0 then
            lines[#lines] = lines[#lines] .. ' ' .. seg_line
          else
            table.insert(lines, '  ' .. seg_line)
          end
        end
      end
      local rowsep = " " .. "\\\\" .. "\n"
      return "\\begin{align*}\n" .. table.concat(lines, rowsep) .. "\n\\end{align*}"
    end
  end

  -- Fallback strategy: split by top-level '=' groups and capture RHS up to next top-level comma
  local function assignments_from_top_level_equals(s)
    local brace, paren, bracket = 0, 0, 0
    local left_depth, env_depth = 0, 0
    local i, n = 1, #s
    local result = {}
    local seg_start = 1
    while i <= n do
      -- find '=' at top level
      if s:sub(i):find('^\\left') then left_depth = left_depth + 1; i = i + 5; goto step
      elseif s:sub(i):find('^\\right') then if left_depth > 0 then left_depth = left_depth - 1 end; i = i + 6; goto step
      elseif s:sub(i):find('^\\begin%s*%{') then
        local j = i + 7
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1; local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          env_depth = env_depth + 1; i = j; goto step
        end
      elseif s:sub(i):find('^\\end%s*%{') then
        local j = i + 5
        while j <= n and s:sub(j, j) ~= '{' do j = j + 1 end
        if j <= n and s:sub(j, j) == '{' then
          j = j + 1; local depth = 1
          while j <= n and depth > 0 do
            local c = s:sub(j, j)
            if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
            j = j + 1
          end
          if env_depth > 0 then env_depth = env_depth - 1 end; i = j; goto step
        end
      end

      if s:sub(i, i) == '=' and brace == 0 and paren == 0 and bracket == 0 and left_depth == 0 and env_depth == 0 then
        local lhs = s:sub(seg_start, i - 1):gsub('^%s+', ''):gsub('%s+$', '')
        -- now capture rhs up to next top-level comma or end
        local j = i + 1
        local b, p, br = 0, 0, 0
        local ld, ed = 0, 0
        while j <= n do
          if s:sub(j):find('^\\left') then ld = ld + 1; j = j + 5; goto inner
          elseif s:sub(j):find('^\\right') then if ld > 0 then ld = ld - 1 end; j = j + 6; goto inner
          elseif s:sub(j):find('^\\begin%s*%{') then
            local k = j + 7
            while k <= n and s:sub(k, k) ~= '{' do k = k + 1 end
            if k <= n and s:sub(k, k) == '{' then
              k = k + 1; local depth = 1
              while k <= n and depth > 0 do
                local c = s:sub(k, k)
                if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
                k = k + 1
              end
              ed = ed + 1; j = k; goto inner
            end
          elseif s:sub(j):find('^\\end%s*%{') then
            local k = j + 5
            while k <= n and s:sub(k, k) ~= '{' do k = k + 1 end
            if k <= n and s:sub(k, k) == '{' then
              k = k + 1; local depth = 1
              while k <= n and depth > 0 do
                local c = s:sub(k, k)
                if c == '{' then depth = depth + 1 elseif c == '}' then depth = depth - 1 end
                k = k + 1
              end
              if ed > 0 then ed = ed - 1 end; j = k; goto inner
            end
          end
          local ch2 = s:sub(j, j)
          if ch2 == '{' then b = b + 1
          elseif ch2 == '}' and b > 0 then b = b - 1
          elseif ch2 == '(' then p = p + 1
          elseif ch2 == ')' and p > 0 then p = p - 1
          elseif ch2 == '[' then br = br + 1
          elseif ch2 == ']' and br > 0 then br = br - 1
          elseif ch2 == ',' and b == 0 and p == 0 and br == 0 and ld == 0 and ed == 0 and not (j > 1 and s:sub(j-1, j-1) == '\\') then
            -- end of this assignment
            local rhs = s:sub(i + 1, j - 1):gsub('^%s+', ''):gsub('%s+$', '')
            table.insert(result, { lhs = lhs, rhs = rhs, has_comma = true })
            seg_start = j + 1
            i = j -- continue scanning after comma
            goto step
          end
          j = j + 1
          ::inner::
        end
        -- reached end
        local rhs = s:sub(i + 1):gsub('^%s+', ''):gsub('%s+$', '')
        table.insert(result, { lhs = lhs, rhs = rhs, has_comma = false })
        break
      end
      ::step::
      i = i + 1
    end
    return result
  end

  local assigns = assignments_from_top_level_equals(math_text)
  if #assigns >= 2 then
    local lines = {}
    for idx, ar in ipairs(assigns) do
      local lhs = (ar.lhs or ''):gsub('[\r\n]+', ' ')
      lhs = lhs:gsub('\\quad', ''):gsub('\\qquad', ''):gsub('\\,', ''):gsub('\\;', ''):gsub('\\:', '')
      lhs = lhs:gsub('^%s+', ''):gsub('%s+$', '')
      local rhs = (ar.rhs or ''):gsub('[\r\n]+', ' ')
      if ar.has_comma and idx < #assigns then
        rhs = rhs .. ','
      end
      table.insert(lines, '  ' .. lhs .. ' &= ' .. rhs)
    end
    return "\\begin{align*}\n" .. table.concat(lines, " \\\\\\n") .. "\n\\end{align*}"
  end

  -- Fallback: use dmath* for automatic breaking
  local _len = #(math_text or '')
  if _len > 160 then
    return "\\begin{dmath*}\n" .. math_text .. "\n\\end{dmath*}"
  else
    return "\\[\n" .. math_text .. "\n\\]"
  end
end

-- Replace display math paragraphs with appropriate line-breaking environments
function Para(el)
  if not is_latex then
    return nil
  end
  if #el.content == 1 then
    local m = el.content[1]
    if m.t == 'Math' and m.mathtype == 'DisplayMath' then
      local math_text = m.text or ''
      
      -- Only apply to equations that really need special handling
      if needs_special_handling(math_text) then
        local tex = apply_safe_fixes(math_text)
        return pandoc.RawBlock('latex', tex)
      end
    end
  end
  return nil
end
