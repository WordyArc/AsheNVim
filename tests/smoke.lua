local t = require("harness")
local h = require("helpers")

t.describe("config", function()
  t.it("sets the leaders", function()
    h.eq(vim.g.mapleader, " ")
    h.eq(vim.g.maplocalleader, "\\")
  end)

  t.it("does not create a global facade", function()
    h.eq(_G.AsheNVim, nil)
  end)

  t.it("initializes lazy.nvim", function()
    h.eq(vim.fn.exists(":Lazy"), 2)
  end)

  t.it("applies the colorscheme", function()
    h.eq(vim.g.colors_name, "cyberdream")
  end)
end)

t.describe("keymaps", function()
  local expected = {
    { "<Space>?", "n", "which-key" },
    { "<Space>ff", "n", "picker" },
    { "<Space>e", "n", "explorer" },
    { "<Space>bd", "n", "buffer delete" },
    { "<Space>cs", "n", "outline" },
    { "<Space>cf", "n", "formatting" },
    { "<Space>ft", "n", "root terminal" },
    { "<Space>fT", "n", "cwd terminal" },
    { "<C-/>", "n", "terminal toggle" },
    { "<C-/>", "t", "terminal toggle from terminal mode" },
    { "<Space>gg", "n", "root lazygit" },
    { "<Space>gG", "n", "cwd lazygit" },
  }
  for _, mapping in ipairs(expected) do
    local lhs, mode, feature = unpack(mapping)
    t.it(("%s is bound to %s"):format(lhs, feature), function()
      assert(vim.fn.maparg(lhs, mode) ~= "", "no mapping for " .. lhs)
    end)
  end
end)

local bootstrap = require("ashenvim.bootstrap")
local specs = bootstrap.build()
local function spec(name)
  return h.spec(specs, name)
end
local function snacks_spec(feature)
  for _, candidate in ipairs(specs) do
    if candidate[1] == "folke/snacks.nvim" and candidate.opts[feature] then
      return candidate
    end
  end
  error("snacks spec is missing: " .. feature)
end

t.describe("bootstrap.build", function()
  t.it("returns a fresh spec list on every call", function()
    local rebuilt = bootstrap.build()
    assert(specs ~= rebuilt, "same list returned twice")
    for index, entry in ipairs(specs) do
      assert(entry ~= rebuilt[index], "same spec table returned twice: " .. tostring(entry[1]))
    end
  end)
end)

t.describe("picker specs", function()
  t.it("loads FFF eagerly with keys and a binary build", function()
    local fff = spec("dmtrKovalenko/fff.nvim")
    h.eq(fff.lazy, false)
    assert(#fff.keys > 0, "FFF keys are missing")
    h.eq(type(fff.build), "function")
    h.eq(fff.opts.lazy_sync, true)
  end)

  t.it("keeps Telescope as a lazy fallback", function()
    local telescope = spec("nvim-telescope/telescope.nvim")
    h.eq(telescope.cmd, "Telescope")
    h.eq(telescope.keys, nil)
  end)
end)

t.describe("explorer and outline specs", function()
  t.it("opens Neo-tree on the right with hidden files visible", function()
    local explorer = spec("nvim-neo-tree/neo-tree.nvim")
    h.eq(explorer.cmd, "Neotree")
    assert(#explorer.keys > 0, "explorer keys are missing")
    h.eq(explorer.opts.window.position, "right")
    h.eq(explorer.opts.filesystem.filtered_items.visible, true)
  end)

  t.it("opens the outline on the left", function()
    local outline = spec("hedyhli/outline.nvim")
    h.has(outline.cmd, "Outline")
    assert(#outline.keys > 0, "outline keys are missing")
    h.eq(outline.opts.outline_window.position, "left")
  end)
end)

t.describe("dashboard spec", function()
  local dashboard = snacks_spec("dashboard")

  t.it("loads eagerly with the highest priority", function()
    h.eq(dashboard.lazy, false)
    h.eq(dashboard.priority, 1000)
    h.eq(dashboard.opts.dashboard.enabled, true)
    assert(dashboard.opts.dashboard.preset.header ~= "", "dashboard logo is missing")
  end)

  t.it("routes search actions through the configured picker", function()
    local items = dashboard.opts.dashboard.preset.keys
    local actions = {}
    for _, item in ipairs(items) do
      actions[item.key] = item.action
    end
    h.eq(
      vim.tbl_map(function(item)
        return item.key
      end, items),
      { "f", "n", "g", "r", "c", "l", "q" }
    )
    h.eq(actions.f, "<leader>ff")
    h.eq(actions.g, "<leader>sg")
    h.eq(actions.r, "<leader>fr")
    h.eq(actions.c, "<leader>fc")
  end)
end)

t.describe("terminal and lazygit", function()
  local terminal = snacks_spec("terminal")
  local lazygit = snacks_spec("lazygit")
  local project

  t.before_each(function()
    project = h.project({ [".git"] = {}, ["notes.txt"] = { "x" } })
    h.open(project .. "/notes.txt")
  end)

  t.it("configures both snacks features", function()
    h.eq(type(terminal.opts.terminal), "table")
    h.eq(type(lazygit.opts.lazygit), "table")
    local modes = h.key(terminal, "<C-/>").mode
    h.has(modes, "n")
    h.has(modes, "t")
  end)

  t.it("opens terminals in the project root or cwd", function()
    local calls = {}
    h.stub_module("snacks", {
      terminal = setmetatable({
        focus = function(_, opts)
          calls[#calls + 1] = { action = "focus", opts = opts }
        end,
      }, {
        __call = function(_, _, opts)
          calls[#calls + 1] = { action = "toggle", opts = opts }
        end,
      }),
    })

    h.key(terminal, "<leader>fT")[2]()
    h.key(terminal, "<leader>ft")[2]()
    h.key(terminal, "<C-/>")[2]()

    h.eq(calls, {
      { action = "toggle" },
      { action = "toggle", opts = { cwd = project } },
      { action = "focus", opts = { cwd = project } },
    })
  end)

  local function lazygit_calls()
    local calls = {}
    h.stub_module("snacks", {
      lazygit = function(opts)
        calls[#calls + 1] = { opts = opts }
      end,
    })
    return calls
  end

  t.it("opens lazygit in the Git root or cwd", function()
    h.stub(vim.fn, "executable", function()
      return 1
    end)
    local calls = lazygit_calls()

    h.key(lazygit, "<leader>gg")[2]()
    h.key(lazygit, "<leader>gG")[2]()

    h.eq(calls, { { opts = { cwd = project } }, {} })
  end)

  t.it("warns instead of opening when lazygit is missing", function()
    h.stub(vim.fn, "executable", function()
      return 0
    end)
    local calls = lazygit_calls()
    local notifications = h.notifications()

    h.key(lazygit, "<leader>gg")[2]()
    h.key(lazygit, "<leader>gG")[2]()

    local warning = { message = "lazygit is not installed", level = vim.log.levels.WARN }
    h.eq(calls, {})
    h.eq(notifications, { warning, warning })
  end)
end)

t.describe("git specs", function()
  t.it("triggers diffview by command and toggle key", function()
    local diffview = spec("sindrets/diffview.nvim")
    h.has(diffview.cmd, "DiffviewOpen")
    h.eq(type(h.key(diffview, "<leader>gd")[2]), "function")
  end)

  t.it("closes diffview with q from every main panel", function()
    local keymaps = spec("sindrets/diffview.nvim").opts().keymaps
    local close = { "n", "q", require("diffview.actions").close, { desc = "Close diff view" } }
    for _, panel in ipairs({ "view", "file_panel", "file_history_panel" }) do
      h.eq(keymaps[panel][1], close)
    end
  end)

  t.it("loads gitsigns on buffer read with buffer mappings", function()
    local gitsigns = spec("lewis6991/gitsigns.nvim")
    h.has(gitsigns.event, "BufReadPre")
    h.has(gitsigns.event, "BufNewFile")
    h.eq(type(gitsigns.opts.on_attach), "function")
    h.eq(type(h.key(gitsigns, "<leader>uG")[2]), "function")
  end)
end)

t.describe("editing specs", function()
  t.it("loads completion on insert and cmdline", function()
    local completion = spec("saghen/blink.cmp")
    h.has(completion.event, "InsertEnter")
    h.has(completion.event, "CmdlineEnter")
  end)

  t.it("configures formatters per filetype", function()
    local formatting = spec("stevearc/conform.nvim")
    h.eq(formatting.lazy, true)
    h.eq(formatting.cmd, "ConformInfo")
    h.eq(formatting.opts.formatters_by_ft.lua[1], "stylua")
    h.eq(formatting.opts.formatters_by_ft.rust[1], "rustfmt")
    h.eq(formatting.opts.formatters_by_ft.kotlin.lsp_format, "fallback")
    h.has(h.key(formatting, "<leader>cf").mode, "x")
  end)

  t.it("installs the required tools", function()
    local tooling = spec("WhoIsSethDaniel/mason-tool-installer.nvim")
    for _, tool in ipairs({ "stylua", "tree-sitter-cli", "kotlin-lsp", "rust-analyzer" }) do
      h.has(tooling.opts.ensure_installed, tool)
    end
  end)

  t.it("tracks the Tree-sitter main branch with the required parsers", function()
    local treesitter = spec("nvim-treesitter/nvim-treesitter")
    h.eq(treesitter.branch, "main")
    h.eq(treesitter.lazy, false)
    h.has(treesitter.opts.ensure_installed, "kotlin")
    h.has(treesitter.opts.ensure_installed, "rust")
  end)

  t.it("loads LSP on buffer read with completion as a dependency", function()
    local lsp = spec("neovim/nvim-lspconfig")
    h.has(lsp.event, "BufReadPre")
    h.has(lsp.event, "BufNewFile")
    h.has(lsp.dependencies, "saghen/blink.cmp")
  end)
end)

local function recording_picker()
  local calls = {}
  local picker = {
    open = function(action, opts)
      calls[#calls + 1] = { action = action, opts = opts }
    end,
  }
  return calls, picker
end

t.describe("picker feature", function()
  t.it("uses the injected provider", function()
    local calls, picker = recording_picker()
    local keys = require("ashenvim.features.picker").keys(picker)
    keys[1][2]()
    h.eq(calls[1].action, "buffers")
  end)
end)

t.describe("fff provider", function()
  local calls, fff_calls, provider

  t.before_each(function()
    local fallback
    calls, fallback = recording_picker()
    provider = require("ashenvim.providers.picker.fff").new(fallback)
    fff_calls = {}
    h.stub_module("fff", {
      find_files_in_dir = function(directory)
        fff_calls[#fff_calls + 1] = { action = "files", cwd = directory }
      end,
      live_grep = function(opts)
        fff_calls[#fff_calls + 1] = { action = "grep", opts = opts }
      end,
      live_grep_under_cursor = function(opts)
        fff_calls[#fff_calls + 1] = { action = "grep_string", opts = opts }
      end,
    })
  end)

  t.it("searches files and text in the given directory", function()
    provider.open("files", { cwd = "/tmp/project" })
    provider.open("grep", { cwd = "/tmp/project" })
    h.eq(fff_calls, {
      { action = "files", cwd = "/tmp/project" },
      { action = "grep", opts = { cwd = "/tmp/project" } },
    })
  end)

  t.it("translates the word under the cursor into a regex query", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "needle.rs" })
    vim.api.nvim_set_current_buf(buf)
    t.cleanup(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    provider.open("grep_string", { cwd = "/tmp/project", word = true })

    h.eq(fff_calls[1].opts.query, "\\bneedle\\b")
    h.eq(fff_calls[1].opts.grep.modes[1], "regex")
  end)

  t.it("delegates unsupported actions to the fallback and resumes there", function()
    provider.open("buffers", { sort = "mru", ignore_current = true })
    provider.open("resume")
    h.eq(calls, {
      { action = "buffers", opts = { sort = "mru", ignore_current = true } },
      { action = "resume", opts = {} },
    })
  end)
end)

t.describe("telescope provider", function()
  t.it("translates buffer picker options", function()
    local received
    h.stub_module("telescope.builtin", {
      buffers = function(opts)
        received = opts
      end,
    })
    require("ashenvim.providers.picker.telescope").open("buffers", { sort = "mru", ignore_current = true })
    h.eq(received.sort_mru, true)
    h.eq(received.sort_lastused, true)
    h.eq(received.ignore_current_buffer, true)
  end)
end)

t.describe("lsp feature", function()
  t.it("routes definitions through the injected picker on attach", function()
    local calls, picker = recording_picker()
    require("ashenvim.features.lsp").setup(picker)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    t.cleanup(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    h.fake_lsp(buf, { root_dir = vim.fn.getcwd(), capabilities = { definitionProvider = true } })

    local mapping = vim.fn.maparg("gd", "n", false, true)
    h.eq(type(mapping.callback), "function")
    mapping.callback()
    h.eq(calls[#calls].action, "definitions")
  end)
end)
