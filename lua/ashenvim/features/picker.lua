local M = {}

---@alias AshenPickerAction
---| "autocommands"
---| "buffers"
---| "colorschemes"
---| "command_history"
---| "commands"
---| "current_buffer"
---| "definitions"
---| "diagnostics"
---| "git_commits"
---| "git_files"
---| "git_stash"
---| "git_status"
---| "grep"
---| "grep_string"
---| "help"
---| "highlights"
---| "implementations"
---| "jumplist"
---| "keymaps"
---| "location_list"
---| "man_pages"
---| "marks"
---| "oldfiles"
---| "quickfix"
---| "references"
---| "registers"
---| "resume"
---| "search_history"
---| "files"
---| "type_definitions"
---| "vim_options"
---| "document_symbols"
---| "workspace_symbols"

---@class AshenPickerOptions
---@field buffer? integer
---@field cwd? string
---@field ignore_current? boolean
---@field preview? boolean
---@field selection? boolean
---@field sort? "mru"
---@field word? boolean

---@class AshenPickerProvider
---@field open fun(action: AshenPickerAction, opts?: AshenPickerOptions)

local root = require("ashenvim.core.root")

---@param picker AshenPickerProvider
---@param action AshenPickerAction
---@param opts? AshenPickerOptions|fun(): AshenPickerOptions
local function open(picker, action, opts)
  return function()
    local resolved = type(opts) == "function" and opts() or opts
    picker.open(action, resolved)
  end
end

---@param picker AshenPickerProvider
---@return LazyKeysSpec[]
function M.keys(picker)
  return {
    { "<leader>,", open(picker, "buffers", { sort = "mru" }), desc = "Switch buffer" },
    { "<leader>/", open(picker, "grep", function()
      return { cwd = root.get() }
    end), desc = "Grep (root)" },
    { "<leader>:", open(picker, "command_history"), desc = "Command history" },
    {
      "<leader><space>",
      open(picker, "files", function()
        return { cwd = root.get() }
      end),
      desc = "Find files (root)",
    },

    { "<leader>fb", open(picker, "buffers", { sort = "mru", ignore_current = true }), desc = "Buffers" },
    { "<leader>fB", open(picker, "buffers"), desc = "Buffers (all)" },
    {
      "<leader>fc",
      open(picker, "files", function()
        return { cwd = vim.fn.stdpath("config") }
      end),
      desc = "Find config file",
    },
    {
      "<leader>ff",
      open(picker, "files", function()
        return { cwd = root.get() }
      end),
      desc = "Find files (root)",
    },
    {
      "<leader>fF",
      open(picker, "files", function()
        return { cwd = root.cwd() }
      end),
      desc = "Find files (cwd)",
    },
    { "<leader>fg", open(picker, "git_files"), desc = "Find git files" },
    { "<leader>fr", open(picker, "oldfiles"), desc = "Recent files" },
    {
      "<leader>fR",
      open(picker, "oldfiles", function()
        return { cwd = root.cwd() }
      end),
      desc = "Recent files (cwd)",
    },

    { "<leader>gc", open(picker, "git_commits"), desc = "Git commits" },
    { "<leader>gl", open(picker, "git_commits"), desc = "Git commits" },
    { "<leader>gs", open(picker, "git_status"), desc = "Git status" },
    { "<leader>gS", open(picker, "git_stash"), desc = "Git stash" },

    { '<leader>s"', open(picker, "registers"), desc = "Registers" },
    { "<leader>s/", open(picker, "search_history"), desc = "Search history" },
    { "<leader>sa", open(picker, "autocommands"), desc = "Autocommands" },
    { "<leader>sb", open(picker, "current_buffer"), desc = "Buffer lines" },
    { "<leader>sc", open(picker, "command_history"), desc = "Command history" },
    { "<leader>sC", open(picker, "commands"), desc = "Commands" },
    { "<leader>sd", open(picker, "diagnostics"), desc = "Diagnostics" },
    { "<leader>sD", open(picker, "diagnostics", { buffer = 0 }), desc = "Buffer diagnostics" },
    { "<leader>sg", open(picker, "grep", function()
      return { cwd = root.get() }
    end), desc = "Grep (root)" },
    { "<leader>sG", open(picker, "grep", function()
      return { cwd = root.cwd() }
    end), desc = "Grep (cwd)" },
    { "<leader>sh", open(picker, "help"), desc = "Help pages" },
    { "<leader>sH", open(picker, "highlights"), desc = "Highlight groups" },
    { "<leader>sj", open(picker, "jumplist"), desc = "Jumplist" },
    { "<leader>sk", open(picker, "keymaps"), desc = "Keymaps" },
    { "<leader>sl", open(picker, "location_list"), desc = "Location list" },
    { "<leader>sM", open(picker, "man_pages"), desc = "Man pages" },
    { "<leader>sm", open(picker, "marks"), desc = "Marks" },
    { "<leader>so", open(picker, "vim_options"), desc = "Options" },
    { "<leader>sq", open(picker, "quickfix"), desc = "Quickfix list" },
    { "<leader>sR", open(picker, "resume"), desc = "Resume picker" },
    {
      "<leader>sw",
      open(picker, "grep_string", function()
        return { cwd = root.get(), word = true }
      end),
      desc = "Word (root)",
    },
    {
      "<leader>sW",
      open(picker, "grep_string", function()
        return { cwd = root.cwd(), word = true }
      end),
      desc = "Word (cwd)",
    },
    {
      "<leader>sw",
      open(picker, "grep_string", function()
        return { cwd = root.get(), selection = true }
      end),
      mode = "x",
      desc = "Selection (root)",
    },
    {
      "<leader>sW",
      open(picker, "grep_string", function()
        return { cwd = root.cwd(), selection = true }
      end),
      mode = "x",
      desc = "Selection (cwd)",
    },
    { "<leader>uC", open(picker, "colorschemes", { preview = true }), desc = "Colorscheme preview" },
  }
end

return M
