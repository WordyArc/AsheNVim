local M = {}

function M.setup()
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"
  vim.g.markdown_recommended_style = 0

  local opt = vim.opt

  opt.autowrite = true
  opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
  opt.conceallevel = 2
  opt.confirm = true
  opt.cursorline = true
  opt.expandtab = true
  opt.fillchars:append({ eob = " " })
  opt.foldlevel = 99
  opt.foldmethod = "indent"
  opt.foldtext = ""
  opt.formatoptions = "jcroqlnt"
  opt.grepformat = "%f:%l:%c:%m"
  if vim.fn.executable("rg") == 1 then
    opt.grepprg = "rg --vimgrep --smart-case"
  end
  opt.ignorecase = true
  opt.inccommand = "nosplit"
  opt.jumpoptions = "view"
  opt.laststatus = 3
  opt.linebreak = true
  opt.list = true
  opt.listchars = { tab = "> ", trail = "-", nbsp = "+" }
  opt.mouse = "a"
  opt.number = true
  opt.pumheight = 10
  opt.relativenumber = true
  opt.scrolloff = 4
  opt.shiftround = true
  opt.shiftwidth = 2
  opt.shortmess:append({ I = true, W = true, c = true })
  opt.sidescrolloff = 8
  opt.signcolumn = "yes"
  opt.smartcase = true
  opt.smartindent = true
  opt.smoothscroll = true
  opt.splitbelow = true
  opt.splitkeep = "screen"
  opt.splitright = true
  opt.tabstop = 2
  opt.termguicolors = true
  opt.timeoutlen = 300
  opt.undofile = true
  opt.undolevels = 10000
  opt.updatetime = 200
  opt.virtualedit = "block"
  opt.wildmode = "longest:full,full"
  opt.winborder = "rounded"
  opt.winminwidth = 5
  opt.wrap = false
end

return M
