local M = {}

local actions = {
  files = true,
  grep = true,
  grep_string = true,
  resume = true,
}

---@param fallback AshenPickerProvider
---@return AshenPickerProvider
function M.new(fallback)
  assert(type(fallback) == "table" and type(fallback.open) == "function", "FFF requires a picker fallback")
  local last_provider

  return {
    open = function(action, opts)
      opts = opts or {}
      if action == "resume" and last_provider == "fallback" then
        fallback.open(action, opts)
        return
      end
      if not actions[action] then
        last_provider = "fallback"
        fallback.open(action, opts)
        return
      end

      last_provider = "fff"
      local fff = require("fff")

      if action == "files" then
        if opts.cwd then
          fff.find_files_in_dir(opts.cwd)
        else
          fff.find_files()
        end
      elseif action == "grep" then
        fff.live_grep({ cwd = opts.cwd })
      elseif action == "grep_string" then
        if opts.word then
          local word = vim.fn.escape(vim.fn.expand("<cword>"), [[\.^$|?*+()[]{}]])
          fff.live_grep({
            cwd = opts.cwd,
            query = "\\b" .. word .. "\\b",
            grep = { modes = { "regex", "plain", "fuzzy" } },
          })
        else
          fff.live_grep_under_cursor({ cwd = opts.cwd })
        end
      elseif action == "resume" then
        fff.resume()
      end
    end,
  }
end

---@param opts { keys: LazyKeysSpec[] }
---@return LazyPluginSpec
function M.spec(opts)
  return {
    "dmtrKovalenko/fff.nvim",
    lazy = false,
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    keys = opts.keys,
    opts = {
      lazy_sync = true,
    },
  }
end

return M
