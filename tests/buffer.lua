local t = require("harness")
local h = require("helpers")
local buffer = require("ashenvim.core.buffer")

local function file(name)
  local path = h.project({ [name] = { name } }) .. "/" .. name
  return h.open(path)
end

local function modify(buf)
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "edited" })
end

t.describe("buffer.delete", function()
  t.before_each(h.wipe_buffers)

  t.it("deletes the current buffer and shows the next listed one", function()
    local first = file("first.txt")
    local second = file("second.txt")

    h.eq(buffer.delete(), true)
    h.eq(vim.api.nvim_buf_is_valid(second), false)
    h.eq(vim.api.nvim_get_current_buf(), first)
  end)

  t.it("leaves an empty buffer when deleting the only one", function()
    local only = file("only.txt")

    h.eq(buffer.delete(only), true)
    h.eq(vim.api.nvim_buf_is_valid(only), false)
    h.eq(vim.api.nvim_buf_get_name(0), "")
  end)

  t.it("keeps a modified buffer and warns", function()
    local buf = file("dirty.txt")
    modify(buf)
    local notifications = h.notifications()

    h.eq(buffer.delete(buf), false)
    h.eq(vim.api.nvim_buf_is_valid(buf), true)
    h.eq(notifications, { { message = "Buffer has unsaved changes", level = vim.log.levels.WARN } })
  end)

  t.it("force deletes a modified buffer", function()
    local buf = file("dirty.txt")
    modify(buf)

    h.eq(buffer.delete(buf, { force = true }), true)
    h.eq(vim.api.nvim_buf_is_valid(buf), false)
  end)

  t.it("returns false for an invalid buffer", function()
    local buf = file("gone.txt")
    vim.api.nvim_buf_delete(buf, { force = true })

    h.eq(buffer.delete(buf), false)
  end)

  t.it("replaces the buffer in every window showing it", function()
    local first = file("first.txt")
    local second = file("second.txt")
    vim.cmd.split()
    t.cleanup(vim.cmd.only)
    h.eq(#vim.api.nvim_list_wins(), 2)

    h.eq(buffer.delete(second), true)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      h.eq(vim.api.nvim_win_get_buf(win), first)
    end
  end)
end)

t.describe("buffer.delete_others", function()
  t.before_each(h.wipe_buffers)

  t.it("keeps the current buffer and drops the rest", function()
    local first = file("first.txt")
    local second = file("second.txt")
    local current = file("current.txt")

    buffer.delete_others()

    h.eq(vim.api.nvim_buf_is_valid(first), false)
    h.eq(vim.api.nvim_buf_is_valid(second), false)
    h.eq(vim.api.nvim_get_current_buf(), current)
  end)

  t.it("keeps modified buffers and reports how many", function()
    local dirty = file("dirty.txt")
    modify(dirty)
    local clean = file("clean.txt")
    file("current.txt")
    local notifications = h.notifications()

    buffer.delete_others()

    h.eq(vim.api.nvim_buf_is_valid(dirty), true)
    h.eq(vim.api.nvim_buf_is_valid(clean), false)
    h.eq(notifications, { { message = "Kept 1 modified buffer(s)", level = vim.log.levels.WARN } })
  end)
end)

t.describe("buffer.delete_all", function()
  t.before_each(h.wipe_buffers)

  t.it("drops every listed buffer and leaves an empty one", function()
    local first = file("first.txt")
    local second = file("second.txt")

    buffer.delete_all()

    h.eq(vim.api.nvim_buf_is_valid(first), false)
    h.eq(vim.api.nvim_buf_is_valid(second), false)
    h.eq(vim.api.nvim_buf_get_name(0), "")
  end)

  t.it("keeps unlisted buffers and their windows", function()
    file("first.txt")
    local sidebar = vim.api.nvim_create_buf(false, true)
    vim.cmd.vsplit()
    t.cleanup(vim.cmd.only)
    local sidebar_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(sidebar_win, sidebar)

    buffer.delete_all()

    h.eq(vim.api.nvim_buf_is_valid(sidebar), true)
    h.eq(vim.api.nvim_win_get_buf(sidebar_win), sidebar)
    h.eq(#vim.api.nvim_list_wins(), 2)
  end)

  t.it("keeps modified buffers and reports how many", function()
    local dirty = file("dirty.txt")
    modify(dirty)
    local clean = file("clean.txt")
    local notifications = h.notifications()

    buffer.delete_all()

    h.eq(vim.api.nvim_buf_is_valid(dirty), true)
    h.eq(vim.api.nvim_buf_is_valid(clean), false)
    h.eq(notifications, { { message = "Kept 1 modified buffer(s)", level = vim.log.levels.WARN } })
  end)
end)
