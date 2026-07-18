local M = {}

local actions = {
  autocommands = "autocommands",
  buffers = "buffers",
  colorschemes = "colorscheme",
  command_history = "command_history",
  commands = "commands",
  current_buffer = "current_buffer_fuzzy_find",
  definitions = "lsp_definitions",
  diagnostics = "diagnostics",
  document_symbols = "lsp_document_symbols",
  files = "find_files",
  git_commits = "git_commits",
  git_files = "git_files",
  git_stash = "git_stash",
  git_status = "git_status",
  grep = "live_grep",
  grep_string = "grep_string",
  help = "help_tags",
  highlights = "highlights",
  implementations = "lsp_implementations",
  jumplist = "jumplist",
  keymaps = "keymaps",
  location_list = "loclist",
  man_pages = "man_pages",
  marks = "marks",
  oldfiles = "oldfiles",
  quickfix = "quickfix",
  references = "lsp_references",
  registers = "registers",
  resume = "resume",
  search_history = "search_history",
  type_definitions = "lsp_type_definitions",
  vim_options = "vim_options",
  workspace_symbols = "lsp_dynamic_workspace_symbols",
}

local function visual_selection()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  return table.concat(lines, "\n")
end

---@param action AshenPickerAction
---@param opts? AshenPickerOptions
function M.open(action, opts)
  local builtin = actions[action]
  assert(builtin, "Unsupported Telescope action: " .. action)

  opts = opts or {}
  local telescope_opts = { cwd = opts.cwd }
  if action == "files" then
    telescope_opts.hidden = true
    telescope_opts.follow = true
  elseif action == "oldfiles" and opts.cwd then
    telescope_opts.only_cwd = true
  elseif action == "buffers" then
    telescope_opts.sort_mru = opts.sort == "mru"
    telescope_opts.sort_lastused = opts.sort == "mru"
    telescope_opts.ignore_current_buffer = opts.ignore_current == true
  elseif action == "diagnostics" then
    telescope_opts.bufnr = opts.buffer
  elseif action == "grep_string" then
    telescope_opts.word_match = opts.word and "-w" or nil
    telescope_opts.search = opts.selection and visual_selection() or nil
  elseif action == "colorschemes" then
    telescope_opts.enable_preview = opts.preview == true
  elseif action == "definitions" or action == "implementations" or action == "type_definitions" then
    telescope_opts.reuse_win = true
  end

  require("telescope.builtin")[builtin](telescope_opts)
end

local function find_command()
  if vim.fn.executable("rg") == 1 then
    return { "rg", "--files", "--hidden", "--color", "never", "--glob", "!.git/*" }
  end
  if vim.fn.executable("fd") == 1 then
    return { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
  end
end

---@param opts? { keys?: LazyKeysSpec[] }
---@return LazyPluginSpec
function M.spec(opts)
  opts = opts or {}
  return {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = opts.keys,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = vim.fn.executable("make") == 1,
      },
    },
    opts = function()
      local telescope_actions = require("telescope.actions")
      return {
        defaults = {
          mappings = {
            i = {
              ["<C-Down>"] = telescope_actions.cycle_history_next,
              ["<C-Up>"] = telescope_actions.cycle_history_prev,
              ["<C-f>"] = telescope_actions.preview_scrolling_down,
              ["<C-b>"] = telescope_actions.preview_scrolling_up,
            },
            n = {
              q = telescope_actions.close,
            },
          },
          path_display = { "smart" },
        },
        pickers = {
          find_files = {
            find_command = find_command(),
            hidden = true,
          },
        },
      }
    end,
    config = function(_, telescope_opts)
      local telescope = require("telescope")
      telescope.setup(telescope_opts)
      pcall(telescope.load_extension, "fzf")
    end,
  }
end

return M
