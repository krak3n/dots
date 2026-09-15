--
-- General Settings
--

vim.g.mapleader = " " -- <space> as leader key
vim.o.mouse = "" -- disable mouse input

vim.o.autoread = true -- update file if changed outside of nvim
vim.o.undofile = true -- persistent undo history
vim.o.swapfile = false -- disable swapfile
vim.o.clipboard = "unnamedplus" -- allows neovim to access the system clipboard

vim.o.tabstop = 2 -- how many spaces a tab is
vim.o.softtabstop = 2 -- how many spaces a tab is
vim.o.shiftwidth = 2 -- controls number of spaces whenn using >><< commands
vim.o.expandtab = true -- use spaces with tab
vim.o.autoindent = true -- copy idendent from current line to new line
vim.o.smartindent = true -- indent correctly after a {
vim.o.scrolloff = 8 -- always keep 8 lines above or below cursor
vim.o.showmode = false -- disable mode under the status line

vim.o.termguicolors = true -- 24bit colors
vim.o.cursorline = true -- enable cursor line
vim.o.number = true -- show line numbers
vim.o.relativenumber = true -- use relative line numbers
vim.o.winborder = "rounded" -- rounded window borders
vim.o.statuscolumn = "%!v:lua.require'statuscolumn'.render()" -- custom gutter: fixed diagnostic + git sign columns, so they never shift each other
vim.o.wrap = false -- disable line wrapping
vim.o.breakindent = true -- prevent line wrapping
vim.o.pumheight = 10 -- max size of completion window
vim.opt.list = true -- show certain normally-invisible characters in the buffer.
vim.opt.listchars:append("leadmultispace:┊ ") -- space based indent guides
vim.opt.listchars:append("tab:┊ ") -- tab based indent guides
vim.opt.redrawtime = 10000 -- Give highlighting/parsing more time before it bails out mid-redraw
vim.o.updatetime = 500

local icons = require("icons")

vim.diagnostic.config({
  virtual_text = false,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
      [vim.diagnostic.severity.WARN] = icons.diagnostics.Warning,
      [vim.diagnostic.severity.INFO] = icons.diagnostics.Information,
      [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
    },
  },
})
vim.keymap.set("n", "<leader>e", function() -- Show diagnostic float for current line
  vim.diagnostic.open_float(nil, { focus = false })
end, { desc = "Show Line Diagnostics" })
vim.o.completeopt = "menu,menuone,noselect,preview" -- omnicomplete options for complete window

vim.o.splitbelow = true                             -- better splitting
vim.o.splitright = true                             -- better splitting

vim.o.ignorecase = true                             -- case insensitive search
vim.o.smartcase = true                              -- unless contains uppercase characters
vim.o.incsearch = true                              -- highlights search pattern

--
-- Build blink.cmp fuzzy source on update
--
vim.api.nvim_create_autocmd("PackChanged", {
  pattern = "blink.cmp",
  group = vim.api.nvim_create_augroup("blink_update", { clear = true }),
  callback = function(e)
    if e.data.kind == "update" then
      -- Recommended way to access plugin files inside `PackChanged` event
      -- vim.cmd [[packadd blink.cmp]]
      vim.cmd.packadd({ args = { e.data.spec.name }, bang = false })
      -- Build the plugin from source
      -- vim.cmd [[BlinkCmp build]]
      require("blink.cmp.fuzzy.build").build()
    end
  end,
})

--
-- Build telescope-fzf-native native extension on install/update
--
vim.api.nvim_create_autocmd("PackChanged", {
  pattern = "telescope-fzf-native.nvim",
  group = vim.api.nvim_create_augroup("fzf_native_build", { clear = true }),
  callback = function(e)
    if e.data.kind == "install" or e.data.kind == "update" then
      vim.system({ "make" }, { cwd = e.data.path }):wait()
    end
  end,
})

--
-- Plugins
--
vim.pack.add({
  -- U(I/X)
  { src = "https://github.com/navarasu/onedark.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/ojroques/nvim-bufdel" },
  { src = "https://github.com/akinsho/bufferline.nvim" },
  {
    src = "https://github.com/nvim-mini/mini.icons",
    branch = "stable",
  },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/refractalize/oil-git-status.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  -- Fuzzy Finder
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-frecency.nvim" },
  { src = "https://github.com/abecodes/tabout.nvim" },
  { src = "https://github.com/mawkler/modicator.nvim" },
  { src = "https://github.com/rachartier/tiny-cmdline.nvim" },
  { src = "https://github.com/m4xshen/smartcolumn.nvim" },
  -- LSP
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
  -- Testing
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
  { src = "https://github.com/nvim-neotest/neotest" },
  { src = "https://github.com/fredrikaverpil/neotest-golang" },
  -- Debugging
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/leoluz/nvim-dap-go" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  -- Completion
  { src = "https://github.com/Saghen/blink.lib" },
  { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/zbirenbaum/copilot.lua" },
  { src = "https://github.com/giuxtaposition/blink-cmp-copilot" },
  -- Formatting
  { src = "https://github.com/stevearc/conform.nvim" },
  -- Syntax
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "main",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    version = "main",
  },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
  { src = "https://github.com/windwp/nvim-autopairs" },
  { src = "https://github.com/b0o/SchemaStore.nvim" },
})

--
-- U(I/X)
--

-- Icons
local icons = require("icons")

-- Theme
require("onedark").setup({
  style = "dark",
  highlights = { -- transparent floating windows
    Pmenu = { bg = "none" },
    NormalFloat = { bg = "none" },
    FloatBorder = { bg = "none" },
  },
  diagnostics = {
    darker = true,
    undercurl = true,
    background = true,
  },
})

vim.cmd("colorscheme onedark")

vim.api.nvim_set_hl(0, "@function.definition", { link = "Function" })
vim.api.nvim_set_hl(0, "@function.call", { link = "Function" })
vim.api.nvim_set_hl(0, "@method.call", { link = "Function" })

-- Web Dev Icons
require("nvim-web-devicons").setup({})

-- Mini Icons
require("mini.icons").setup({})

-- Buffers
require("bufdel").setup({
  quit = true,
})

local bufferline = require("bufferline")

bufferline.setup({
  options = {
    mode = "buffers",                                 -- set to "tabs" to only show tabpages instead
    style_preset = bufferline.style_preset.no_italic, -- don't use italics
    themable = true,                                  -- allows highlight groups to be overriden i.e. sets highlights as default
    numbers = "none",                                 -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
    close_command = "BufDel! %d",                     -- can be a string | function, see "Mouse actions"
    buffer_close_icon = icons.ui.BoldClose,
    close_icon = icons.ui.BoldClose,
    path_components = 1, -- Show only the file name without the directory
    modified_icon = icons.ui.Circle,
    left_trunc_marker = icons.ui.BoldArrowLeft,
    right_trunc_marker = icons.ui.BoldArrowRight,
    max_name_length = 30,
    max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
    tab_size = 21,
    diagnostics = false,
    diagnostics_update_in_insert = false,
    color_icons = true,
    show_buffer_icons = true,
    show_buffer_close_icons = true,
    show_close_icon = true,
    persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
    separator_style = "thick",  -- | "thick" | "thin" | { 'any', 'any' },
    enforce_regular_tabs = true,
    always_show_bufferline = true,
    show_tab_indicators = false,
    indicator = {
      icon = "▎", -- this should be omitted if indicator style is not 'icon'
      style = "icon", -- Options: 'icon', 'underline', 'none'
    },
    icon_pinned = icons.ui.Bookmark,
    minimum_padding = 1,
    maximum_padding = 5,
    maximum_length = 15,
    sort_by = "insert_at_end",
  },
})

-- File Explorer
require("oil").setup({
  columns = {
    "icon",
  },
  win_options = {
    signcolumn = "yes:2",
  },
  view_options = {
    show_hidden = true,
  },
  float = {
    padding = 2,
    max_width = 100,
    max_height = 20,
    border = "rounded", -- "single", "double", "shadow", etc.
    win_options = {
      winblend = 0,     -- transparency (0–100)
    },
  },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-t>"] = { "actions.select", opts = { tab = true } },
    ["<C-p>"] = "actions.preview",
    ["q"] = { "actions.close", mode = "n" },
    ["<C-l>"] = "actions.refresh",
    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
})

require("oil-git-status").setup({})

-- Git signs
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end)

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end)

    -- Actions
    map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage Hunk" })
    map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset Hunk" })

    map("v", "<leader>hs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { desc = "Stage Hunk" })

    map("v", "<leader>hr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { desc = "Reset Hunk" })

    map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Stage Buffer" })
    map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset Buffer" })
    map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview Hunk" })
    map("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "Preview Hunk Inline" })

    map("n", "<leader>hb", function()
      gitsigns.blame_line({ full = true })
    end, { desc = "Blame Line" })

    map("n", "<leader>hd", gitsigns.diffthis, { desc = "Diff This" })

    map("n", "<leader>hD", function()
      gitsigns.diffthis("~")
    end, { desc = "Diff This (against ~)" })

    map("n", "<leader>hQ", function()
      gitsigns.setqflist("all")
    end, { desc = "Hunks to Quickfix (all)" })
    map("n", "<leader>hq", gitsigns.setqflist, { desc = "Hunks to Quickfix" })

    -- Toggles
    map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "Toggle Line Blame" })
    map("n", "<leader>tw", gitsigns.toggle_word_diff, { desc = "Toggle Word Diff" })

    -- Text object
    map({ "o", "x" }, "ih", gitsigns.select_hunk)
  end,
})

-- Statusline
local hide_in_width = function()
  return vim.fn.winwidth(0) > 100
end

require("lualine").setup({
  options = {
    icons_enabled = true,
    theme = "onedark",
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
    disabled_filetypes = { "alpha", "oil" },
    always_divide_middle = true,
    globalstatus = true,
  },
  sections = {
    lualine_a = {
      {
        "mode",
        fmt = function(str)
          return " " .. str
        end,
      },
    },
    lualine_b = { "branch" },
    lualine_c = {
      {
        "filename",
        file_status = true,
        path = 1,
      },
    },
    lualine_x = {
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        sections = { "error", "warn" },
        symbols = {
          error = icons.diagnostics.Error .. " ",
          warn = icons.diagnostics.Warning .. " ",
          info = icons.diagnostics.Information .. " ",
          hint = icons.diagnostics.Hint .. " ",
        },
        colored = false,
        update_in_insert = false,
        always_visible = false,
        cond = hide_in_width,
      },
      {
        "diff",
        colored = false,
        symbols = {
          added = icons.git.LineAdded .. " ",
          modified = icons.git.LineModified .. " ",
          removed = icons.git.LineRemoved .. " ",
        },
        cond = hide_in_width,
      },
      { "encoding", cond = hide_in_width },
      { "filetype", cond = hide_in_width },
    },
    lualine_y = { "location" },
    lualine_z = { "progress" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { { "location", padding = 0 } },
    lualine_y = {},
    lualine_z = {},
  },
})

-- Fuzzy search
local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
local telescope_action_state = require("telescope.actions.state")

-- Copy the selected entry's file path (with line number, if any) to clipboard
local function copy_to_clipboard(prompt_bufnr)
  local entry = telescope_action_state.get_selected_entry()
  if not entry then
    return
  end
  local text = entry.path or entry.filename or entry.value
  if entry.lnum then
    text = string.format("%s:%d", text, entry.lnum)
  end
  vim.fn.setreg("+", text)
  telescope_actions.close(prompt_bufnr)
end

telescope.setup({
  defaults = {
    layout_config = {
      width = 0.8, -- 80% of editor
      height = 0.8,
    },
    mappings = {
      i = { ["<C-y>"] = copy_to_clipboard },
      n = { ["<C-y>"] = copy_to_clipboard },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown({}),
    },
    frecency = {
      show_scores = false,
      show_unindexed = true,
    },
  },
})

telescope.load_extension("fzf")
telescope.load_extension("ui-select")
telescope.load_extension("frecency")

vim.keymap.set("n", "<leader>ff", function() -- Find Files
  telescope.extensions.frecency.frecency({ workspace = "CWD" })
end, { desc = "Find Files" })

vim.keymap.set("n", "<leader>ft", function() -- Find Text
  require("telescope.builtin").live_grep()
end, { desc = "Find Text" })

vim.keymap.set("n", "<leader>fr", function() -- Resume last picker (same search, same position)
  require("telescope.builtin").resume()
end, { desc = "Find Resume" })

-- Tab out of quotes etc
require("tabout").setup({})

-- Mode indicator
require("modicator").setup({})

-- Tiny commandline
require("vim._core.ui2").enable({})

vim.o.cmdheight = 0

require("tiny-cmdline").setup({
  width = {
    value = "80%"
  },
})

-- Smart column
require("smartcolumn").setup({
  colorcolumn = "100",
})

-- Key Mappings
vim.keymap.set({ "n" }, "<leader>so", ":update<CR> :source<CR>") -- Reload init.lua
vim.keymap.set({ "n" }, "<leader>M", ":Mason<CR>")               -- Open Mason
vim.keymap.set({ "n" }, "<leader>MU", ":MasonUpdate<CR>")        -- Update all installed LSP servers
vim.keymap.set({ "n" }, "<TAB>", ":bnext<CR>")                   -- Tab moves to next buffer
vim.keymap.set({ "n" }, "<S-TAB>", ":bprevious<CR>")             -- Shift+Tab moves to previous buffer
vim.keymap.set({ "n" }, "<leader>x", ":BufDel<CR>")              -- Close current buffer
vim.keymap.set({ "n" }, "<leader>X", ":BufDelOthers<CR>")        -- Close all but the current buffer
vim.keymap.set({ "n" }, "<leader>Q", ":BufDelAll<CR>")           -- Close all buffers (then quits nvim)
vim.keymap.set({ "n" }, "<leader>o", function()
  require("oil").open_float()
end, { desc = "Open Oil (float)" }) -- Open Oil (floating window)

--
-- LSP
--
require("tiny-inline-diagnostic").setup({
  preset = "modern",
  options = {
    show_source = { enabled = true },
    multilines = { enabled = true },
    add_messages = { display_count = true },
    use_icons_from_diagnostic = true,
  },
})

require("mason").setup({
  ui = {
    border = "rounded",
  },
})

require("mason-lspconfig").setup({
  ensure_installed = { "gopls", "lua_ls", "terraformls", "tflint", "yamlls" },
})

-- Setup LSP mappings
local util = require("lspconfig.util")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

-- Lua
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- Go
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      staticcheck = true,
      analyses = {
        shadow = true,
        nilness = true,
        loopclosure = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
        unusedvariable = true,
      },
      codelenses = {
        generate = true,
        gc_details = true,
        tidy = true,
        upgrade_dependency = true,
      },
      semanticTokens = false,
      completeUnimported = true,
      directoryFilters = {
        "-.git",
      },
      usePlaceholders = true,
    },
  },
})

-- Testing
require("neotest").setup({
  adapters = {
    require("neotest-golang")({}),
  },
})

vim.keymap.set("n", "<leader>tt", function()
  require("neotest").run.run()
end, { desc = "Test Nearest" })

vim.keymap.set("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Test File" })

vim.keymap.set("n", "<leader>to", function()
  require("neotest").output.open({ enter = true })
end, { desc = "Test Output" })

vim.keymap.set("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Test Summary" })

-- Debugging
require("dap-go").setup({
  delve = {
    path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
  },
})

local dap, dapui = require("dap"), require("dapui")

dapui.setup({})
require("nvim-dap-virtual-text").setup({})

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Conditional Breakpoint" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
vim.keymap.set("n", "<leader>dt", function()
  -- Uses neotest-golang's subtest resolution (correctly handles table tests
  -- like `t.Run(tc.name, ...)`), not dap-go's own AST-based lookup, which
  -- only resolves literal t.Run string names, not loop-variable subtests.
  -- For debugging ONE specific table-test case: run the file once (<leader>tf)
  -- to discover its subtests, open the summary (<leader>ts), then press `d`
  -- on the specific case -- neotest's summary panel debugs the exact
  -- selected position, not just "nearest to cursor".
  require("neotest").run.run({ strategy = "dap" })
end, { desc = "Debug: Nearest Go Test" })

-- Terraform
vim.lsp.config("terraformls", {
  root_dir = util.root_pattern(".terraform", ".git", "*.tf"),
  settings = {
    terraform = {
      experimentalFeatures = {
        validateOnSave = true,
      },
    },
  },
})

vim.lsp.config("tflint", {
  cmd = { "tflint", "--langserver" },
  filetypes = { "terraform", "terraform-vars", "tf" },
  root_dir = util.root_pattern(".tflint.hcl", ".git", "*.tf"),
})

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
})

vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = {
        -- You must disable built-in schemaStore support if you want to use
        -- this plugin and its advanced options like `ignore`.
        enable = false,
        -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
        url = "",
      },
      schemas = require('schemastore').yaml.schemas(),
    },
  },
})

--
-- Completion
--

require("copilot").setup({
  suggestion = {
    enabled = false,
  },
  panel = {
    enabled = false,
  },
})

require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<CR>"] = { "accept", "fallback" },
    ["<C-Space>"] = { "show" },
    ["<Tab>"] = { "select_next", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },
  },
  appearance = {
    nerd_font_variant = "mono",
    use_nvim_cmp_as_default = true,
  },
  signature = { enabled = true },
  fuzzy = { implementation = "lua" },
  completion = {
    menu = { auto_show = true, auto_show_delay_ms = 100 },
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
  },
  sources = {
    default = { "lsp", "snippets", "copilot", "path", "buffer" },
    providers = {
      copilot = {
        name = "copilot",
        module = "blink-cmp-copilot",
        async = true,
        score_offset = 100,
      },
    },
  },
})

--
-- Formatting
--

local conform = require("conform")
local company_prefixes = os.getenv("GOIMPORTS_REVISER_COMPANY_PREFIXES") or ""

conform.setup({
  format_on_save = {
    timeout_ms = 5000,
    lsp_format = "fallback",
  },
  formatters = {
    ["sql_formatter"] = {
      prepend_args = { "--config", '{"language":"postgresql","paramTypes":{"named":["@"]}}' },
    },
    ["goimports-reviser"] = {
      prepend_args = {
        "-company-prefixes",
        company_prefixes,
        "-imports-order",
        "std,general,company,project,blanked,dotted",
      },
    },
    ["buf"] = {
      args = {
        "format",
        "-w",
        "$FILENAME",
      },
      stdin = false,
    },
  },
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    sql = { "sql_formatter" },
    make = { "bake" },
    go = { "goimports", "goimports-reviser", "gofumpt" },
    terraform = { "terraform_fmt" },
    tf = { "terraform_fmt" },
    proto = { "buf" },
  },
})

--
-- Syntax (Treesitter)
--

require("nvim-treesitter").setup({})
require("nvim-treesitter").install({
  "bash",
  "comment",
  "css",
  "dockerfile",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "luap",
  "make",
  "markdown",
  "markdown_inline",
  "proto",
  "sql",
  "terraform",
  "toml",
  "vim",
  "vimdoc",
  "yaml",
  "zsh",
})

require("nvim-treesitter.config").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
})

require("treesitter-context").setup({
  enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
  multiwindow = false,      -- Enable multiwindow support.
  max_lines = 3,            -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
  trim_scope = "outer",     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = "topline",         -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20,     -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
})

vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"     -- Use treesitter for code folding
vim.bo.indentexpr = "v:lua.vim.treesitter.indentexpr()" -- Use treesitter for autop indentation

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
    local ok, ret = pcall(vim.treesitter.language.add, lang)
    if ok and ret then
      vim.treesitter.start(ev.buf, lang)
    end
  end,
})

require("nvim-autopairs").setup({
  check_ts = true,
  disable_filetype = {
    "oil",
    "TelescopePrompt",
    "gitcommit",
    "vim",
    "help",
    "qf",
  },
})
