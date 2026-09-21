local harness = require("harness")

local M = {}

---@param actual any
---@param expected any
function M.eq(actual, expected)
  if not vim.deep_equal(actual, expected) then
    error(("expected %s, got %s"):format(vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

---@param values any[]
---@param expected any
function M.has(values, expected)
  for _, value in ipairs(values) do
    if value == expected then
      return
    end
  end
  error(("%s is missing from %s"):format(vim.inspect(expected), vim.inspect(values)), 2)
end

---@param files table<string, string[]> relative path -> lines
---@return string root resolved through symlinks, as buffer names are
function M.project(files)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  root = vim.uv.fs_realpath(root)
  for path, lines in pairs(files) do
    local full = root .. "/" .. path
    vim.fn.mkdir(vim.fs.dirname(full), "p")
    vim.fn.writefile(lines, full)
  end
  harness.cleanup(function()
    vim.fn.delete(root, "rf")
  end)
  return root
end

---@param path string
---@return integer buf
function M.open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  harness.cleanup(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
  return buf
end

function M.wipe_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

---@param message string
---@param predicate fun(): boolean
---@param timeout? integer milliseconds
function M.wait_for(message, predicate, timeout)
  if not vim.wait(timeout or 5000, predicate, 50) then
    error(message, 2)
  end
end

---@param owner table
---@param field string
---@param value any
function M.stub(owner, field, value)
  local original = owner[field]
  owner[field] = value
  harness.cleanup(function()
    owner[field] = original
  end)
end

---@param name string
---@param fake table
function M.stub_module(name, fake)
  M.stub(package.loaded, name, fake)
end

---@return { message: string, level: integer }[]
function M.notifications()
  local captured = {}
  M.stub(vim, "notify", function(message, level)
    captured[#captured + 1] = { message = message, level = level }
  end)
  return captured
end

local function in_process_server(capabilities)
  return function(dispatchers)
    local closing = false
    local request_id = 0
    local server = {}

    function server.request(method, _, callback)
      if method == "initialize" then
        callback(nil, { capabilities = capabilities })
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
end

---@param buf integer
---@param opts { root_dir: string, capabilities?: table, workspace_folders?: string[] }
---@return vim.lsp.Client
function M.fake_lsp(buf, opts)
  local name = "ashenvim-test-" .. buf
  local workspace_folders
  if opts.workspace_folders then
    workspace_folders = vim.tbl_map(function(folder)
      return { uri = vim.uri_from_fname(folder), name = folder }
    end, opts.workspace_folders)
  end

  local client_id = assert(
    vim.lsp.start({
      name = name,
      cmd = in_process_server(opts.capabilities or {}),
      root_dir = opts.root_dir,
      workspace_folders = workspace_folders,
    }, { bufnr = buf, attach = true }),
    "failed to start the in-process LSP client"
  )
  harness.cleanup(function()
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
      client:stop(true)
    end
  end)

  M.wait_for(name .. " did not attach", function()
    return #vim.lsp.get_clients({ bufnr = buf, name = name }) == 1
  end)
  return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
end

---@param specs LazyPluginSpec[]
---@param name string
---@return LazyPluginSpec
function M.spec(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then
      return spec
    end
  end
  error("plugin spec is missing: " .. name, 2)
end

---@param spec LazyPluginSpec
---@param lhs string
---@return LazyKeysSpec
function M.key(spec, lhs)
  for _, key in ipairs(spec.keys or {}) do
    if key[1] == lhs then
      return key
    end
  end
  error("plugin key is missing: " .. lhs, 2)
end

return M
