assert(vim.g.mapleader == " ", "mapleader was not configured")
assert(vim.g.maplocalleader == "\\", "maplocalleader was not configured")
assert(_G.AshenVim == nil, "AshenVim must not create a global facade")
assert(type(require("ashenvim.profile")) == "table", "profile must return a plugin spec")
assert(vim.fn.exists(":Lazy") == 2, "lazy.nvim was not initialized")
assert(vim.fn.maparg("<Space>ff", "n") ~= "", "picker keymap is missing")
assert(vim.fn.maparg("<Space>e", "n") ~= "", "explorer keymap is missing")
assert(vim.fn.maparg("<Space>bd", "n") ~= "", "core keymap is missing")

local telescope = require("ashenvim.providers.picker.telescope")
local original_builtin = package.loaded["telescope.builtin"]
local captured
package.loaded["telescope.builtin"] = setmetatable({}, {
  __index = function(_, action)
    return function(opts)
      captured = { action = action, opts = opts }
    end
  end,
})

telescope.open("buffers", { sort = "mru", ignore_current = true })
assert(captured.action == "buffers", "picker action was not translated")
assert(captured.opts.sort_mru and captured.opts.sort_lastused, "semantic MRU sorting was not translated")
assert(captured.opts.ignore_current_buffer, "semantic current-buffer filtering was not translated")
package.loaded["telescope.builtin"] = original_builtin

local root = require("ashenvim.core.root").get()
assert(type(root) == "string" and root ~= "", "root detection returned an invalid path")

print("AshenVim smoke test: ok")
