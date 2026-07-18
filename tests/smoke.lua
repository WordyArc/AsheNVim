assert(vim.g.mapleader == " ", "mapleader was not configured")
assert(vim.g.maplocalleader == "\\", "maplocalleader was not configured")
assert(_G.AshenVim == nil, "AshenVim must not create a global facade")
assert(vim.fn.exists(":Lazy") == 2, "lazy.nvim was not initialized")
assert(vim.g.colors_name == "cyberdream", "cyberdream colorscheme was not applied")
assert(vim.fn.maparg("<Space>?", "n") ~= "", "which-key keymap is missing")
assert(vim.fn.maparg("<Space>ff", "n") ~= "", "picker keymap is missing")
assert(vim.fn.maparg("<Space>e", "n") ~= "", "explorer keymap is missing")
assert(vim.fn.maparg("<Space>bd", "n") ~= "", "core keymap is missing")

local function contains(values, expected)
  for _, value in ipairs(values) do
    if value == expected then
      return true
    end
  end
  return false
end

local function find_spec(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then
      return spec
    end
  end
  error("plugin spec is missing: " .. name)
end

local bootstrap = require("ashenvim.bootstrap")
local specs = bootstrap.build()
local rebuilt_specs = bootstrap.build()
assert(type(specs) == "table", "bootstrap.build() must return plugin specs")
assert(specs ~= rebuilt_specs, "bootstrap.build() must return a fresh spec list")
for index, spec in ipairs(specs) do
  assert(spec ~= rebuilt_specs[index], "bootstrap.build() must return fresh specs")
end

local telescope_spec = find_spec(specs, "nvim-telescope/telescope.nvim")
local explorer_spec = find_spec(specs, "nvim-neo-tree/neo-tree.nvim")
local completion_spec = find_spec(specs, "saghen/blink.cmp")
local lsp_spec = find_spec(specs, "neovim/nvim-lspconfig")
assert(telescope_spec.cmd == "Telescope" and #telescope_spec.keys > 0, "picker triggers are missing")
assert(explorer_spec.cmd == "Neotree" and #explorer_spec.keys > 0, "explorer triggers are missing")
assert(contains(completion_spec.event, "InsertEnter"), "completion InsertEnter trigger is missing")
assert(contains(completion_spec.event, "CmdlineEnter"), "completion CmdlineEnter trigger is missing")
assert(contains(lsp_spec.event, "BufReadPre"), "LSP BufReadPre trigger is missing")
assert(contains(lsp_spec.event, "BufNewFile"), "LSP BufNewFile trigger is missing")
assert(contains(lsp_spec.dependencies, "saghen/blink.cmp"), "completion must be an explicit LSP dependency")

local picker_calls = {}
local fake_picker = {
  open = function(action, opts)
    picker_calls[#picker_calls + 1] = { action = action, opts = opts }
  end,
}
local picker_keys = require("ashenvim.features.picker").keys(fake_picker)
picker_keys[1][2]()
assert(picker_calls[1].action == "buffers", "picker feature did not use the injected provider")

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
assert(require("ashenvim.core.root").cwd() == vim.fs.normalize(vim.fn.getcwd()), "cwd semantics are invalid")

require("ashenvim.features.lsp").setup(fake_picker)
local test_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(test_buf)
vim.bo[test_buf].filetype = "lua"

local function in_process_server(dispatchers)
  local closing = false
  local request_id = 0
  local server = {}

  function server.request(method, _, callback)
    if method == "initialize" then
      callback(nil, {
        capabilities = {
          definitionProvider = true,
        },
      })
    elseif method == "shutdown" then
      callback(nil, nil)
    end
    request_id = request_id + 1
    return true, request_id
  end

  function server.notify(method)
    if method == "exit" then
      closing = true
      dispatchers.on_exit(0, 0)
    end
  end

  function server.is_closing()
    return closing
  end

  function server.terminate()
    closing = true
  end

  return server
end

local client_id = assert(
  vim.lsp.start({
    name = "ashenvim-smoke-test",
    cmd = in_process_server,
    root_dir = vim.fn.getcwd(),
  }, { attach = true }),
  "failed to start the in-process LSP client"
)

assert(
  vim.wait(1000, function()
    return #vim.lsp.get_clients({ bufnr = test_buf, name = "ashenvim-smoke-test" }) == 1
  end),
  "the in-process LSP client did not attach"
)

local definition_mapping = vim.fn.maparg("gd", "n", false, true)
assert(type(definition_mapping.callback) == "function", "LSP definition mapping was not attached")
definition_mapping.callback()
assert(picker_calls[#picker_calls].action == "definitions", "LSP mapping did not use the injected picker")

assert(vim.lsp.get_client_by_id(client_id)):stop(true)
vim.api.nvim_buf_delete(test_buf, { force = true })

print("AshenVim smoke test: ok")
