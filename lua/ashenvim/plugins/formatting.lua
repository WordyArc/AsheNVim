local M = {}

---@return LazyPluginSpec
function M.spec()
  return {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({
            async = true,
            lsp_format = "fallback",
          })
        end,
        mode = { "n", "x" },
        desc = "Format",
      },
    },
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        kotlin = { lsp_format = "fallback" },
        lua = { "stylua" },
        rust = { "rustfmt", lsp_format = "fallback" },
      },
    },
  }
end

return M
