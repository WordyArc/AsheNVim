local M = {}

---@param opts? { cwd?: string, source?: "filesystem"|"buffers"|"git_status" }
function M.open(opts)
  opts = opts or {}
  require("neo-tree.command").execute({
    dir = opts.cwd,
    source = opts.source or "filesystem",
    toggle = true,
  })
end

---@param opts { keys: LazyKeysSpec[] }
---@return LazyPluginSpec
function M.spec(opts)
  return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = opts.keys,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("AshenVimNeoTreeDirectory", { clear = true }),
        callback = function(event)
          if package.loaded["neo-tree"] then
            return true
          end

          local path = vim.api.nvim_buf_get_name(event.buf)
          local stat = path ~= "" and vim.uv.fs_stat(path) or nil
          if stat and stat.type == "directory" then
            require("neo-tree")
            vim.schedule(function()
              require("neo-tree.command").execute({ dir = path, source = "filesystem" })
            end)
            return true
          end
        end,
      })
    end,
    deactivate = function()
      vim.cmd("Neotree close")
    end,
    opts = {
      sources = { "filesystem", "buffers", "git_status" },
      open_files_do_not_replace_types = { "terminal", "qf" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_default",
        use_libuv_file_watcher = true,
      },
      window = {
        position = "right",
        mappings = {
          ["<space>"] = "none",
          h = "close_node",
          l = "open",
          O = {
            function(state)
              vim.ui.open(state.tree:get_node().path)
            end,
            desc = "Open with system application",
          },
          P = { "toggle_preview", config = { use_float = false } },
          Y = {
            function(state)
              vim.fn.setreg("+", state.tree:get_node():get_id(), "c")
            end,
            desc = "Copy path",
          },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
        },
      },
    },
    config = function(_, neo_tree_opts)
      require("neo-tree").setup(neo_tree_opts)
    end,
  }
end

return M
