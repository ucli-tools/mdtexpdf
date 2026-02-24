-- table_size_filter.lua
-- Purpose: Wrap wide tables (5+ columns) in LaTeX \small font group with reduced
-- column padding, preventing them from overflowing page margins.

local is_latex = FORMAT:match('latex') ~= nil

function Table(tbl)
  if not is_latex then return nil end

  local num_cols = #tbl.colspecs
  if num_cols >= 5 then
    local before = pandoc.RawBlock('latex',
      '\\begingroup\\small\\setlength{\\tabcolsep}{3pt}\\setlength{\\arrayrulewidth}{0.3pt}')
    local after = pandoc.RawBlock('latex', '\\endgroup')
    return {before, tbl, after}
  end

  return nil
end
