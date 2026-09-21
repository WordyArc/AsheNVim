local M = {}

local function toggle_diff()
  if require("diffview.lib").get_current_view() then
    vim.cmd.DiffviewClose()
  else
    vim.cmd.DiffviewOpen()
  end
end

local function close_with_q()
  local actions = require("diffview.actions")
  local close = { "n", "q", actions.close, { desc = "Close diff view" } }
  return {
    keymaps = {
      view = { close },
      file_panel = { close },
      file_history_panel = { close },
    },
  }
end

---@return LazyPluginSpec
function M.spec()
  return {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    opts = close_with_q,
    keys = {
      { "<leader>gd", toggle_diff, desc = "Diff view (toggle)" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<CR>", desc = "File history (branch)" },
    },
  }
end

return M
