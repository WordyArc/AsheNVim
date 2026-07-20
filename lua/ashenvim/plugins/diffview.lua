local M = {}

local function toggle_diff()
  if require("diffview.lib").get_current_view() then
    vim.cmd.DiffviewClose()
  else
    vim.cmd.DiffviewOpen()
  end
end

---@return LazyPluginSpec
function M.spec()
  return {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", toggle_diff, desc = "Diff view (toggle)" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<CR>", desc = "File history (branch)" },
    },
  }
end

return M
