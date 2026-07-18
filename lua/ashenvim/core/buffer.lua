local M = {}

local function replacement_for(target)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      buf ~= target
      and vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == ""
    then
      return buf
    end
  end

  return vim.api.nvim_create_buf(true, false)
end

---@param buf? integer
---@param opts? { force?: boolean }
---@return boolean
function M.delete(buf, opts)
  buf = buf or vim.api.nvim_get_current_buf()
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if vim.bo[buf].modified and not opts.force then
    vim.notify("Buffer has unsaved changes", vim.log.levels.WARN)
    return false
  end

  local windows = vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_buf(win) == buf
  end, vim.api.nvim_list_wins())

  if #windows > 0 then
    local replacement = replacement_for(buf)
    for _, win in ipairs(windows) do
      vim.api.nvim_win_set_buf(win, replacement)
    end
  end

  local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = opts.force == true })
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return ok
end

function M.delete_others()
  local current = vim.api.nvim_get_current_buf()
  local skipped = 0

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      if vim.bo[buf].modified then
        skipped = skipped + 1
      else
        vim.api.nvim_buf_delete(buf, {})
      end
    end
  end

  if skipped > 0 then
    vim.notify(("Kept %d modified buffer(s)"):format(skipped), vim.log.levels.WARN)
  end
end

return M
