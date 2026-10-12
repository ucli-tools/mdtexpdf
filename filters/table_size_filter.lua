-- table_size_filter.lua
-- Purpose: Wrap wide tables (5+ columns) in LaTeX \small font group with reduced
-- column padding, preventing them from overflowing page margins; and give the
-- maths in every table cell room above and below, so a row of tall formulas
-- (a displayed fraction) does not touch the rows around it.
--
-- LaTeX stacks a table's rows with no space between them beyond each row's
-- strut. A formula taller than the strut (\displaystyle \frac{2i\pi}{13}) makes
-- its row exactly as tall as itself, and its denominator meets the numerator of
-- the next row. Each formula in a cell is therefore measured, and a strut 3pt
-- taller and deeper than it is set beside it: short formulas are left as they
-- were (the row's own strut is already taller), tall ones get 3pt above and
-- below.

local is_latex = FORMAT:match('latex') ~= nil

local CELL_MATH = '\\providecommand{\\mdtexpdfcellmath}[1]{\\setbox0=\\hbox{#1}'
  .. '\\rule[-\\dimexpr\\dp0+3pt\\relax]{0pt}{\\dimexpr\\ht0+\\dp0+6pt\\relax}\\box0}'

local function pad_maths(cell)
  return pandoc.walk_block(pandoc.Div(cell.contents), {
    Math = function(m)
      if m.mathtype ~= 'InlineMath' then return nil end
      return {pandoc.RawInline('latex', '\\mdtexpdfcellmath{'), m, pandoc.RawInline('latex', '}')}
    end,
  }).content
end

local function each_cell(tbl, f)
  local function rows(list)
    for _, row in ipairs(list) do
      for _, cell in ipairs(row.cells) do
        cell.contents = f(cell)
      end
    end
  end
  rows(tbl.head.rows)
  for _, body in ipairs(tbl.bodies) do
    rows(body.head)
    rows(body.body)
  end
  rows(tbl.foot.rows)
end

function Table(tbl)
  if not is_latex then return nil end

  each_cell(tbl, pad_maths)
  local before = {pandoc.RawBlock('latex', CELL_MATH)}
  local after = {}

  local num_cols = #tbl.colspecs
  if num_cols >= 5 then
    table.insert(before, pandoc.RawBlock('latex',
      '\\begingroup\\small\\setlength{\\tabcolsep}{3pt}\\setlength{\\arrayrulewidth}{0.3pt}'))
    table.insert(after, pandoc.RawBlock('latex', '\\endgroup'))
  end

  local out = before
  table.insert(out, tbl)
  for _, b in ipairs(after) do table.insert(out, b) end
  return out
end
