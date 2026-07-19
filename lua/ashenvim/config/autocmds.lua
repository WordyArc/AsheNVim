local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("AsheNVim", { clear = true })

  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = group,
    desc = "Reload files changed outside Neovim",
    callback = function()
      vim.cmd("checktime")
    end,
  })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    desc = "Highlight yanked text",
    callback = function()
      vim.hl.on_yank()
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    desc = "Keep splits equally sized",
    callback = function()
      local tab = vim.fn.tabpagenr()
      vim.cmd("tabdo wincmd =")
      vim.cmd("tabnext " .. tab)
    end,
  })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    desc = "Restore the last cursor position",
    callback = function(event)
      if vim.bo[event.buf].filetype == "gitcommit" or vim.b[event.buf].ashenvim_last_location then
        return
      end
      vim.b[event.buf].ashenvim_last_location = true

      local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
      if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Close utility windows with q",
    pattern = { "checkhealth", "help", "lspinfo", "man", "qf" },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<cr>", {
        buffer = event.buf,
        silent = true,
        desc = "Close window",
      })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Wrap and spellcheck prose",
    pattern = { "gitcommit", "markdown", "plaintex", "text", "typst" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Show JSON syntax characters",
    pattern = { "json", "jsonc", "json5" },
    callback = function()
      vim.opt_local.conceallevel = 0
    end,
  })
end

return M
