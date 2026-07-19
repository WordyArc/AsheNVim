local M = {}

local parsers = {
  "kotlin",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "query",
  "rust",
  "toml",
  "vim",
  "vimdoc",
}

local function has_query(lang, query)
  return #vim.api.nvim_get_runtime_file(("queries/%s/%s.scm"):format(lang, query), false) > 0
end

---@return string? lang the language that could not be started, if any
local function enable(buf)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end
  if not pcall(vim.treesitter.start, buf, lang) then
    return lang
  end

  if has_query(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end

  if has_query(lang, "folds") then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.wo[win].foldmethod = "expr"
      vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end
end

---@return LazyPluginSpec
function M.spec()
  return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = parsers,
    },
    config = function(_, opts)
      local treesitter = require("nvim-treesitter")
      treesitter.setup()

      local function enable_loaded()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            enable(buf)
          end
        end
      end

      local installing = false
      local function install_missing()
        if installing or vim.fn.executable("tree-sitter") == 0 then
          return
        end

        local installed = treesitter.get_installed("parsers")
        local missing = vim.tbl_filter(function(parser)
          return not vim.tbl_contains(installed, parser)
        end, opts.ensure_installed)
        if #missing == 0 then
          enable_loaded()
          return
        end

        installing = true
        treesitter.install(missing, { force = true }):await(function()
          installing = false
          vim.schedule(enable_loaded)
        end)
      end

      local group = vim.api.nvim_create_augroup("AshenVimTreesitter", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = group,
        callback = function(event)
          local missing = enable(event.buf)
          if missing and vim.tbl_contains(opts.ensure_installed, missing) then
            install_missing()
          end
        end,
      })

      install_missing()
    end,
  }
end

return M
