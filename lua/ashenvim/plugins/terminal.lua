local M = {}

local root = require("ashenvim.core.root")

local function terminal_cwd()
  require("snacks").terminal()
end

local function terminal_root()
  require("snacks").terminal(nil, { cwd = root.get() })
end

local function focus_terminal_root()
  require("snacks").terminal.focus(nil, { cwd = root.get() })
end

---@return LazyPluginSpec
function M.spec()
  return {
    "folke/snacks.nvim",
    opts = {
      terminal = {},
    },
    keys = {
      { "<leader>fT", terminal_cwd, desc = "Terminal (cwd)" },
      { "<leader>ft", terminal_root, desc = "Terminal (root dir)" },
      { "<C-/>", focus_terminal_root, mode = { "n", "t" }, desc = "Terminal (root dir)" },
      -- tmux compatibility: legacy terminals encode Ctrl+/ as Ctrl+_
      { "<C-_>", focus_terminal_root, mode = { "n", "t" }, desc = "which_key_ignore" },
    },
  }
end

return M
