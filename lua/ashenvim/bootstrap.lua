local M = {}

---@return LazySpec
function M.build()
  local picker = require("ashenvim.providers.picker.telescope")
  local explorer = require("ashenvim.providers.explorer.neo_tree")
  local completion = require("ashenvim.providers.completion.blink")

  local specs = {
    require("ashenvim.plugins.colorscheme").spec(),
    require("ashenvim.plugins.outline").spec(),
    require("ashenvim.plugins.which_key").spec(),
    picker.spec({
      keys = require("ashenvim.features.picker").keys(picker),
    }),
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
