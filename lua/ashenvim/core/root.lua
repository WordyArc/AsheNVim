local M = {}

local markers = {
  ".git",
  "lua",
  "package.json",
  "pyproject.toml",
  "go.mod",
  "Cargo.toml",
}

local function contains(root, path)
  root = vim.fs.normalize(root)
  path = vim.fs.normalize(path)
  return path == root or vim.startswith(path, root .. "/")
end

---Return Neovim's effective current directory, including local directory scopes.
---@return string
function M.cwd()
  return vim.fs.normalize(vim.fn.getcwd())
end

---@param buf? integer
---@return string
function M.get(buf)
  if buf == nil or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local path = vim.api.nvim_buf_get_name(buf)
  local roots = {}

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    local root = client.config.root_dir
    if type(root) == "string" and (path == "" or contains(root, path)) then
      roots[#roots + 1] = root
    end

    for _, folder in ipairs(client.workspace_folders or {}) do
      local workspace = vim.uri_to_fname(folder.uri)
      if path == "" or contains(workspace, path) then
        roots[#roots + 1] = workspace
      end
    end
  end

  table.sort(roots, function(a, b)
    return #a > #b
  end)
  if roots[1] then
    return vim.fs.normalize(roots[1])
  end

  if path ~= "" then
    local root = vim.fs.root(path, markers)
    if root then
      return vim.fs.normalize(root)
    end
  end

  return M.cwd()
end

return M
