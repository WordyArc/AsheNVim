local M = {}

local function git_root()
  local root = require("ashenvim.core.root")
  local path = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(path ~= "" and path or root.cwd(), ".git") or root.get()
end

local function lazygit_cwd()
  require("snacks").lazygit()
end

local function lazygit_root()
  require("snacks").lazygit({ cwd = git_root() })
end

---@return LazyPluginSpec
function M.spec()
  local keys = {}

  if vim.fn.executable("lazygit") == 1 then
    keys = {
      { "<leader>gg", lazygit_root, desc = "Lazygit (root dir)" },
      { "<leader>gG", lazygit_cwd, desc = "Lazygit (cwd)" },
    }
  end

  return {
    "folke/snacks.nvim",
    opts = {
      lazygit = {},
    },
    keys = keys,
  }
end

return M
