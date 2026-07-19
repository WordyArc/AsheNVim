local M = {}

local root = require("ashenvim.core.root")

local function git_root()
  local path = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(path ~= "" and path or root.cwd(), ".git") or root.get()
end

local function ensure_lazygit()
  if vim.fn.executable("lazygit") == 1 then
    return true
  end
  vim.notify("lazygit is not installed", vim.log.levels.WARN)
  return false
end

local function lazygit_cwd()
  if ensure_lazygit() then
    require("snacks").lazygit()
  end
end

local function lazygit_root()
  if ensure_lazygit() then
    require("snacks").lazygit({ cwd = git_root() })
  end
end

---@return LazyPluginSpec
function M.spec()
  return {
    "folke/snacks.nvim",
    opts = {
      lazygit = {},
    },
    keys = {
      { "<leader>gg", lazygit_root, desc = "Lazygit (root dir)" },
      { "<leader>gG", lazygit_cwd, desc = "Lazygit (cwd)" },
    },
  }
end

return M
