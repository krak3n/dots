local M = {}

-- Every sign slot is padded/truncated to this display width, so a line with
-- only one sign (or none) still lines up with a line that has both.
local SLOT_WIDTH = 2

local function pad_slot(text)
  local width = vim.fn.strdisplaywidth(text)
  if width < SLOT_WIDTH then
    return text .. string.rep(" ", SLOT_WIDTH - width)
  end
  return text
end

-- Fixed-width diagnostic slot, blank when there's no diagnostic on the line
local function diagnostic_segment(bufnr, lnum)
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = lnum - 1 })
  if #diagnostics == 0 then
    return pad_slot("")
  end

  local highest = vim.diagnostic.severity.HINT
  for _, d in ipairs(diagnostics) do
    if d.severity < highest then
      highest = d.severity
    end
  end

  local name = vim.diagnostic.severity[highest]
  name = name:sub(1, 1) .. name:sub(2):lower()

  local signs_text = (vim.diagnostic.config().signs or {}).text or {}
  local text = signs_text[highest] or "!"

  return "%#DiagnosticSign" .. name .. "#" .. pad_slot(text) .. "%*"
end

-- Fixed-width git slot, blank when gitsigns has no sign on the line.
-- Reads gitsigns' own extmarks directly since it has no dedicated "get sign for line" API.
local function git_segment(bufnr, lnum)
  local namespaces = vim.api.nvim_get_namespaces()
  for _, ns_name in ipairs({ "gitsigns_signs_staged", "gitsigns_signs_" }) do
    local ns = namespaces[ns_name]
    if ns then
      local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { lnum - 1, 0 }, { lnum - 1, -1 }, { details = true })
      if #marks > 0 and marks[1][4].sign_text then
        local details = marks[1][4]
        if details.sign_hl_group then
          return "%#" .. details.sign_hl_group .. "#" .. pad_slot(details.sign_text) .. "%*"
        end
        return pad_slot(details.sign_text)
      end
    end
  end
  return pad_slot("")
end

-- Line number, respecting relativenumber (absolute on the cursor line)
local function linenr_segment(lnum, relnum)
  local num = relnum == 0 and lnum or relnum
  local hl = relnum == 0 and "CursorLineNr" or "LineNr"
  return "%#" .. hl .. "#" .. string.format("%3d", num) .. "%*"
end

function M.render()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.v.lnum

  return " "
    .. git_segment(bufnr, lnum)
    .. diagnostic_segment(bufnr, lnum)
    .. linenr_segment(lnum, vim.v.relnum)
    .. " "
end

return M
