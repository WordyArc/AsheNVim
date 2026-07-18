local M = {}

---@return LazyPluginSpec
function M.spec()
  return {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>cs", "<cmd>Outline<cr>", desc = "Toggle outline" },
    },
    opts = {
      outline_window = {
        position = "left",
      },
      keymaps = {
        up_and_jump = "<up>",
        down_and_jump = "<down>",
      },
    },
  }
end

return M
