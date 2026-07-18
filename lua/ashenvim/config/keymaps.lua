local M = {}

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count * vim.v.count1,
      float = true,
      severity = severity,
    })
  end
end

local function toggle_option(name, label)
  return function()
    local value = not vim.opt_local[name]:get()
    vim.opt_local[name] = value
    vim.notify(("%s: %s"):format(label, value and "on" or "off"))
  end
end

local function toggle_list(kind)
  return function()
    local info = kind == "quickfix" and vim.fn.getqflist({ winid = 0 }) or vim.fn.getloclist(0, { winid = 0 })
    local command
    if kind == "quickfix" then
      command = info.winid ~= 0 and vim.cmd.cclose or vim.cmd.copen
    else
      command = info.winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen
    end

    local ok, err = pcall(command)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end

function M.setup()
  local map = vim.keymap.set

  map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
  map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

  map("n", "<C-h>", "<C-w>h", { remap = true, desc = "Go to left window" })
  map("n", "<C-j>", "<C-w>j", { remap = true, desc = "Go to lower window" })
  map("n", "<C-k>", "<C-w>k", { remap = true, desc = "Go to upper window" })
  map("n", "<C-l>", "<C-w>l", { remap = true, desc = "Go to right window" })

  map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
  map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
  map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
  map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

  map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move line down" })
  map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move line up" })
  map("i", "<A-j>", "<esc><cmd>move .+1<cr>==gi", { desc = "Move line down" })
  map("i", "<A-k>", "<esc><cmd>move .-2<cr>==gi", { desc = "Move line up" })
  map("x", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move selection down" })
  map("x", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move selection up" })

  map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
  map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
  map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
  map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
  map("n", "<leader>bb", "<cmd>buffer #<cr>", { desc = "Switch to other buffer" })
  map("n", "<leader>`", "<cmd>buffer #<cr>", { desc = "Switch to other buffer" })
  map("n", "<leader>bd", function()
    require("ashenvim.core.buffer").delete()
  end, { desc = "Delete buffer" })
  map("n", "<leader>bo", function()
    require("ashenvim.core.buffer").delete_others()
  end, { desc = "Delete other buffers" })
  map("n", "<leader>bD", "<cmd>bdelete<cr>", { desc = "Delete buffer and window" })

  map({ "i", "n", "s" }, "<Esc>", function()
    vim.cmd("nohlsearch")
    if vim.snippet.active({ direction = 1 }) then
      vim.snippet.stop()
    end
    return "<Esc>"
  end, { expr = true, desc = "Escape and clear search" })

  map("n", "<leader>ur", "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>", { desc = "Redraw and clear search" })
  map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
  map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
  map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
  map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Previous search result" })
  map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous search result" })
  map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous search result" })

  map("i", ",", ",<C-g>u")
  map("i", ".", ".<C-g>u")
  map("i", ";", ";<C-g>u")
  map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>write<cr><esc>", { desc = "Save file" })
  map("x", "<", "<gv", { desc = "Indent left" })
  map("x", ">", ">gv", { desc = "Indent right" })
  map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add comment below" })
  map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add comment above" })

  map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
  map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })
  map("n", "<leader>xl", toggle_list("location"), { desc = "Location list" })
  map("n", "<leader>xq", toggle_list("quickfix"), { desc = "Quickfix list" })
  map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
  map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

  map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
  map("n", "]d", diagnostic_jump(1), { desc = "Next diagnostic" })
  map("n", "[d", diagnostic_jump(-1), { desc = "Previous diagnostic" })
  map("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })
  map("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), { desc = "Previous error" })
  map("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), { desc = "Next warning" })
  map("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), { desc = "Previous warning" })

  map("n", "<leader>us", toggle_option("spell", "Spelling"), { desc = "Toggle spelling" })
  map("n", "<leader>uw", toggle_option("wrap", "Wrap"), { desc = "Toggle wrap" })
  map("n", "<leader>uL", toggle_option("relativenumber", "Relative numbers"), { desc = "Toggle relative numbers" })
  map("n", "<leader>ud", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end, { desc = "Toggle diagnostics" })
  map("n", "<leader>ub", function()
    vim.o.background = vim.o.background == "dark" and "light" or "dark"
  end, { desc = "Toggle background" })
  map("n", "<leader>uh", function()
    local opts = { bufnr = 0 }
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(opts), opts)
  end, { desc = "Toggle inlay hints" })

  map("n", "<leader>qq", "<cmd>quitall<cr>", { desc = "Quit all" })
  map("n", "<leader>ui", vim.show_pos, { desc = "Inspect position" })
  map("n", "<leader>-", "<C-w>s", { remap = true, desc = "Split below" })
  map("n", "<leader>|", "<C-w>v", { remap = true, desc = "Split right" })
  map("n", "<leader>wd", "<C-w>c", { remap = true, desc = "Delete window" })

  map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last tab" })
  map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close other tabs" })
  map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First tab" })
  map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New tab" })
  map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next tab" })
  map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close tab" })
  map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
end

return M
