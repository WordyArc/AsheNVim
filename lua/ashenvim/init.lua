local M = {}

local did_setup = false

function M.setup()
  if did_setup then
    return
  end

  if vim.fn.has("nvim-0.11.3") == 0 then
    error("AshenVim requires Neovim >= 0.11.3")
  end

  require("ashenvim.config.options").setup()
  require("ashenvim.config.autocmds").setup()
  require("ashenvim.config.keymaps").setup()

  require("ashenvim.core.lazy").setup(require("ashenvim.profile"))
  did_setup = true
end

return M

