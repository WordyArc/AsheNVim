local M = {}

local function toggle_signs()
  local enabled = require("gitsigns").toggle_signs()
  vim.notify(("Git signs: %s"):format(enabled and "on" or "off"))
end

local function on_attach(buf)
  local gitsigns = require("gitsigns")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end

  map("n", "]h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "]c", bang = true })
    else
      gitsigns.nav_hunk("next")
    end
  end, "Next hunk")
  map("n", "[h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
    else
      gitsigns.nav_hunk("prev")
    end
  end, "Previous hunk")
  map("n", "]H", function()
    gitsigns.nav_hunk("last")
  end, "Last hunk")
  map("n", "[H", function()
    gitsigns.nav_hunk("first")
  end, "First hunk")
  map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
  map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
  map("n", "<leader>ghS", gitsigns.stage_buffer, "Stage buffer")
  map("n", "<leader>ghR", gitsigns.reset_buffer, "Reset buffer")
  map("n", "<leader>ghp", gitsigns.preview_hunk_inline, "Preview hunk inline")
  map("n", "<leader>ghb", function()
    gitsigns.blame_line({ full = true })
  end, "Blame line")
  map("n", "<leader>ghB", gitsigns.blame, "Blame buffer")
  map("n", "<leader>ghd", gitsigns.diffthis, "Diff this")
  map("n", "<leader>ghD", function()
    gitsigns.diffthis("~")
  end, "Diff this against last commit")
  map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
end

---@return LazyPluginSpec
function M.spec()
  return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>uG", toggle_signs, desc = "Toggle git signs" },
    },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = on_attach,
    },
  }
end

return M
