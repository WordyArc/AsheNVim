local M = {}

M.plugin = "saghen/blink.cmp"

---@param capabilities? lsp.ClientCapabilities
---@return lsp.ClientCapabilities
function M.capabilities(capabilities)
  return require("blink.cmp").get_lsp_capabilities(capabilities)
end

---@return LazyPluginSpec
function M.spec()
  return {
    M.plugin,
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts_extend = { "sources.default" },
    opts = {
      keymap = {
        preset = "enter",
        ["<C-y>"] = { "select_and_accept" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },
      },
      signature = {
        enabled = true,
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },
    },
  }
end

return M
