local M = {}

---@return LazyPluginSpec
function M.spec()
  return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    cmd = {
      "MasonToolsInstall",
      "MasonToolsInstallSync",
      "MasonToolsUpdate",
      "MasonToolsUpdateSync",
    },
    opts = {
      ensure_installed = {
        "kotlin-lsp",
        "lua-language-server",
        "rust-analyzer",
        "stylua",
        "tree-sitter-cli",
      },
      run_on_start = true,
    },
  }
end

return M
