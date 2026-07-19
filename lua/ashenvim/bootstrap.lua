local M = {}

---@return LazySpec
function M.build()
  local picker_fallback = require("ashenvim.providers.picker.telescope")
  local picker = require("ashenvim.providers.picker.fff").new(picker_fallback)
  local explorer = require("ashenvim.providers.explorer.neo_tree")
  local completion = require("ashenvim.providers.completion.blink")

  local specs = {
    require("ashenvim.plugins.colorscheme").spec(),
    require("ashenvim.plugins.outline").spec(),
    require("ashenvim.plugins.terminal").spec(),
    require("ashenvim.plugins.which_key").spec(),
    require("ashenvim.providers.picker.fff").spec({
      keys = require("ashenvim.features.picker").keys(picker),
    }),
    picker_fallback.spec(),
    explorer.spec({
      keys = require("ashenvim.features.explorer").keys(explorer),
    }),
    completion.spec(),
  }

  vim.list_extend(
    specs,
    require("ashenvim.plugins.lsp").spec({
      picker = picker,
      completion = completion,
    })
  )

  return specs
end

return M
