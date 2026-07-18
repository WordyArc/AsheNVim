local M = {}

---@class AshenCompletionProvider
---@field plugin string
---@field capabilities fun(capabilities?: lsp.ClientCapabilities): lsp.ClientCapabilities

---@param providers { picker: AshenPickerProvider, completion: AshenCompletionProvider }
---@return LazySpec
function M.spec(providers)
  local servers = {
    lua_ls = {
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          hint = {
            enable = true,
          },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME },
          },
        },
      },
    },
  }

  return {
    {
      "mason-org/mason.nvim",
      cmd = "Mason",
      build = ":MasonUpdate",
      keys = {
        { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
      },
      opts = {},
    },
    {
      "neovim/nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        -- Completion capabilities are configured during LSP setup, so this loads with LSP.
        providers.completion.plugin,
      },
      config = function()
        require("ashenvim.features.lsp").setup(providers.picker)

        vim.diagnostic.config({
          severity_sort = true,
          underline = true,
          update_in_insert = false,
          virtual_text = {
            source = "if_many",
            spacing = 2,
          },
        })

        local capabilities = providers.completion.capabilities()
        vim.lsp.config("*", { capabilities = capabilities })

        for server, config in pairs(servers) do
          vim.lsp.config(server, config)
        end

        require("mason-lspconfig").setup({
          ensure_installed = vim.tbl_keys(servers),
          automatic_enable = false,
        })
        vim.lsp.enable(vim.tbl_keys(servers))
      end,
    },
  }
end

return M
