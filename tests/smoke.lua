assert(vim.g.mapleader == " ", "mapleader was not configured")
assert(vim.g.maplocalleader == "\\", "maplocalleader was not configured")
assert(_G.AshenVim == nil, "AshenVim must not create a global facade")
assert(vim.fn.exists(":Lazy") == 2, "lazy.nvim was not initialized")
assert(vim.g.colors_name == "cyberdream", "cyberdream colorscheme was not applied")
assert(vim.fn.maparg("<Space>?", "n") ~= "", "which-key keymap is missing")
assert(vim.fn.maparg("<Space>ff", "n") ~= "", "picker keymap is missing")
assert(vim.fn.maparg("<Space>e", "n") ~= "", "explorer keymap is missing")
assert(vim.fn.maparg("<Space>bd", "n") ~= "", "core keymap is missing")
assert(vim.fn.maparg("<Space>cs", "n") ~= "", "outline keymap is missing")

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

local fff_spec = find_spec(specs, "dmtrKovalenko/fff.nvim")
local telescope_spec = find_spec(specs, "nvim-telescope/telescope.nvim")
local explorer_spec = find_spec(specs, "nvim-neo-tree/neo-tree.nvim")
local outline_spec = find_spec(specs, "hedyhli/outline.nvim")
local completion_spec = find_spec(specs, "saghen/blink.cmp")
local lsp_spec = find_spec(specs, "neovim/nvim-lspconfig")
assert(fff_spec.lazy == false and #fff_spec.keys > 0, "FFF picker setup is missing")
assert(type(fff_spec.build) == "function" and fff_spec.opts.lazy_sync, "FFF binary setup is missing")
assert(telescope_spec.cmd == "Telescope" and telescope_spec.keys == nil, "Telescope must be a lazy fallback")
assert(explorer_spec.cmd == "Neotree" and #explorer_spec.keys > 0, "explorer triggers are missing")
assert(explorer_spec.opts.window.position == "right", "Neo-tree must open on the right")
assert(contains(outline_spec.cmd, "Outline") and #outline_spec.keys > 0, "outline triggers are missing")
assert(outline_spec.opts.outline_window.position == "left", "outline must open on the left")
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

local fallback_calls = {}
local fff = require("ashenvim.providers.picker.fff").new({
  open = function(action, opts)
    fallback_calls[#fallback_calls + 1] = { action = action, opts = opts }
  end,
})
local original_fff = package.loaded.fff
local fff_calls = {}
package.loaded.fff = {
  find_files_in_dir = function(directory)
    fff_calls[#fff_calls + 1] = { action = "files", cwd = directory }
  end,
  live_grep = function(opts)
    fff_calls[#fff_calls + 1] = { action = "grep", opts = opts }
  end,
  live_grep_under_cursor = function(opts)
    fff_calls[#fff_calls + 1] = { action = "grep_string", opts = opts }
  end,
}

fff.open("files", { cwd = "/tmp/project" })
assert(fff_calls[1].action == "files" and fff_calls[1].cwd == "/tmp/project", "file search did not use FFF")
fff.open("grep", { cwd = "/tmp/project" })
assert(fff_calls[2].action == "grep" and fff_calls[2].opts.cwd == "/tmp/project", "grep did not use FFF")
fff.open("grep_string", { cwd = "/tmp/project", word = true })
assert(
  vim.startswith(fff_calls[3].opts.query, "\\b") and vim.endswith(fff_calls[3].opts.query, "\\b"),
  "whole-word search was not translated for FFF"
)
assert(fff_calls[3].opts.grep.modes[1] == "regex", "FFF whole-word search must start in regex mode")
fff.open("buffers", { sort = "mru", ignore_current = true })
assert(fallback_calls[1].action == "buffers", "unsupported FFF action did not use the fallback")
assert(fallback_calls[1].opts.sort == "mru", "fallback options were not preserved")
fff.open("resume")
assert(fallback_calls[2].action == "resume", "resume did not use the last active picker")
package.loaded.fff = original_fff

local telescope = require("ashenvim.providers.picker.telescope")
local original_builtin = package.loaded["telescope.builtin"]
local telescope_call
package.loaded["telescope.builtin"] = {
  buffers = function(opts)
    telescope_call = opts
  end,
}
telescope.open("buffers", { sort = "mru", ignore_current = true })
assert(telescope_call.sort_mru and telescope_call.sort_lastused, "fallback MRU sorting was not translated")
assert(telescope_call.ignore_current_buffer, "fallback current-buffer filtering was not translated")
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
