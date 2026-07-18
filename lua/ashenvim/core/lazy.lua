local M = {}

local function bootstrap()
  local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if vim.uv.fs_stat(path) then
    return path
  end

  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    path,
  })

  if vim.v.shell_error ~= 0 then
    error("Failed to install lazy.nvim:\n" .. output)
  end

  return path
end

---@param spec LazySpec
function M.setup(spec)
  vim.opt.rtp:prepend(bootstrap())

  require("lazy").setup({
    spec = spec,
    defaults = {
      lazy = false,
      version = false,
    },
    install = {
      missing = true,
    },
    checker = {
      enabled = true,
      notify = false,
    },
    change_detection = {
      notify = false,
    },
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  })
end

return M
