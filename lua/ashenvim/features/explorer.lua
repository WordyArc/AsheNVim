local M = {}

---@class AshenExplorerProvider
---@field open fun(opts?: { cwd?: string, source?: "filesystem"|"buffers"|"git_status" })

local function cwd()
  return require("ashenvim.core.root").cwd()
end

local function root()
  return require("ashenvim.core.root").get()
end

---@param explorer AshenExplorerProvider
---@return LazyKeysSpec[]
function M.keys(explorer)
  return {
    {
      "<leader>fe",
      function()
        explorer.open({ cwd = root() })
      end,
      desc = "Explorer (root)",
    },
    {
      "<leader>fE",
      function()
        explorer.open({ cwd = cwd() })
      end,
      desc = "Explorer (cwd)",
    },
    {
      "<leader>e",
      function()
        explorer.open({ cwd = root() })
      end,
      desc = "Explorer (root)",
    },
    {
      "<leader>E",
      function()
        explorer.open({ cwd = cwd() })
      end,
      desc = "Explorer (cwd)",
    },
    {
      "<leader>ge",
      function()
        explorer.open({ source = "git_status" })
      end,
      desc = "Git explorer",
    },
    {
      "<leader>be",
      function()
        explorer.open({ source = "buffers" })
      end,
      desc = "Buffer explorer",
    },
  }
end

return M
